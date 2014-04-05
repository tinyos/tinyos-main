/* UDP protocol implementation.
 *
 * @author Stephen Dawson-Haggerty <stevedh@cs.berkeley.edu>
 */

#include <lib6lowpan/in_cksum.h>
#include <BlipStatistics.h>

#include "blip_printf.h"

module UdpP {
  provides {
    interface UDP[uint8_t clnt];
    interface Init @exactlyonce();
    interface BlipStatistics<udp_statistics_t>;
  }
  uses {
    interface IP;
    interface IPAddress;
  }
} implementation {

  enum {
    N_CLIENTS = uniqueCount("UDP_CLIENT"),
  };

  udp_statistics_t stats;
  uint16_t local_ports[N_CLIENTS];

  enum {
    LOCAL_PORT_START = 51024U,
    LOCAL_PORT_STOP  = 54999U,
  };
  uint16_t last_localport = LOCAL_PORT_START;

  uint16_t alloc_lport(uint8_t clnt) {
    int i, done = 0;
    uint16_t compare = htons(last_localport);
    last_localport = (last_localport < LOCAL_PORT_STOP) ? last_localport + 1 : LOCAL_PORT_START;
    while (!done) {
      done = 1;
      for (i = 0; i < N_CLIENTS; i++) {
        if (local_ports[i] == compare) {
          last_localport = (last_localport < LOCAL_PORT_STOP) ? last_localport + 1 : LOCAL_PORT_START;
          compare = htons(last_localport);
          done = 0;
          break;
        }
      }
    }
    return last_localport;
  }

  command error_t Init.init() {
    call BlipStatistics.clear();
    memclr((uint8_t *)local_ports, sizeof(uint16_t) * N_CLIENTS);
    return SUCCESS;
  }

  command error_t UDP.bind[uint8_t clnt](uint16_t port) {
    int i;
    port = htons(port);
    if (port > 0) {
      for (i = 0; i < N_CLIENTS; i++)
        if (i != clnt && local_ports[i] == port)
          return FAIL;
    }
    local_ports[clnt] = port;
    return SUCCESS;
  }

  event void IP.recv(struct ip6_hdr *iph,
                     void *packet,
                     size_t len,
                     struct ip6_metadata *meta) {
    uint8_t i;
    struct sockaddr_in6 addr;
    struct udp_hdr *udph = (struct udp_hdr *)packet;
    uint16_t my_cksum, rx_cksum = ntohs(udph->chksum);
    struct ip_iovec v;

    printf("UDP - IP.recv: len: %i (%i, %i) srcport: %u dstport: %u\n",
        ntohs(iph->ip6_plen), len, ntohs(udph->len),
        ntohs(udph->srcport), ntohs(udph->dstport));

    for (i = 0; i < N_CLIENTS; i++)
      if (local_ports[i] == udph->dstport)
        break;

    if (i == N_CLIENTS) {
      // TODO : send ICMP port closed message here.
      return;
    }
    memcpy(&addr.sin6_addr, &iph->ip6_src, 16);
    addr.sin6_port = udph->srcport;

    udph->chksum = 0;
    v.iov_base = packet;
    v.iov_len  = len;
    v.iov_next = NULL;

    my_cksum = msg_cksum(iph, &v, IANA_UDP);
    printf("rx_cksum: 0x%x my_cksum: 0x%x\n", rx_cksum, my_cksum);
    if (rx_cksum != my_cksum) {
      BLIP_STATS_INCR(stats.cksum);
      printf("udp ckecksum computation failed: mine: 0x%x theirs: 0x%x [0x%x]\n",
                 my_cksum, rx_cksum, len);
      printf_buf((void *)iph, sizeof(struct ip6_hdr));
      // iov_print(&v);
      // drop
      return;
    }

    BLIP_STATS_INCR(stats.rcvd);
    signal UDP.recvfrom[i](&addr, (void *)(udph + 1), len - sizeof(struct udp_hdr), meta);
  }

  /**
   * Injection point of IP datagrams.  This is only called for packets
   * being sent from this mote; packets which are being forwarded
   * never leave the stack and so never use this entry point.
   *
   * @msg an IP datagram with header fields (except for length)
   * @plen the length of the data payload added after the headers.
   */
  command error_t UDP.sendto[uint8_t clnt](struct sockaddr_in6 *dest,
                                           void *payload,
                                           uint16_t len) {
    struct ip_iovec v[1];
    v[0].iov_base = payload;
    v[0].iov_len  = len;
    v[0].iov_next = NULL;
    return call UDP.sendtov[clnt](dest, &v[0]);
  }

  command error_t UDP.sendtov[uint8_t clnt](struct sockaddr_in6 *dest,
                                            struct ip_iovec *iov) {
    error_t rc;
    struct ip6_packet pkt;
    struct udp_hdr    udp;
    struct ip_iovec   v[1];
    size_t len = iov_len(iov);

    // fill in all the packet fields
    memclr((uint8_t *)&pkt.ip6_hdr, sizeof(pkt.ip6_hdr));
    memclr((uint8_t *)&udp, sizeof(udp));
    memcpy(&pkt.ip6_hdr.ip6_dst, dest->sin6_addr.s6_addr, 16);
    call IPAddress.setSource(&pkt.ip6_hdr);

    if (local_ports[clnt] == 0 &&
        (local_ports[clnt] = alloc_lport(clnt)) == 0) {
      return FAIL;
    }
    /* udp fields */
    udp.srcport = local_ports[clnt];
    udp.dstport = dest->sin6_port;
    udp.len = htons(len + sizeof(struct udp_hdr));
    udp.chksum = 0;

    /* ip fields -- everything must be filled in now */
    pkt.ip6_hdr.ip6_vfc = IPV6_VERSION;
    pkt.ip6_hdr.ip6_nxt = IANA_UDP;
    pkt.ip6_hdr.ip6_plen = udp.len;

    // set up the pointers
    v[0].iov_base = (uint8_t *)&udp;
    v[0].iov_len  = sizeof(struct udp_hdr);
    v[0].iov_next = iov;
    pkt.ip6_data = &v[0];

    udp.chksum = htons(msg_cksum(&pkt.ip6_hdr, v, IANA_UDP));

    rc = call IP.send(&pkt);
    BLIP_STATS_INCR(stats.sent);
    return rc;

  }


  command void BlipStatistics.clear() {
#ifdef BLIP_STATS
    memclr((uint8_t *)&stats, sizeof(udp_statistics_t));
#endif
  }

  command void BlipStatistics.get(udp_statistics_t *buf) {
#ifdef BLIP_STATS
    ip_memcpy((uint8_t *)buf, (uint8_t *)&stats, sizeof(udp_statistics_t));
#endif
  }

  default event void UDP.recvfrom[uint8_t clnt](struct sockaddr_in6 *from,
                                                void *payload,
                                                uint16_t len,
                                                struct ip6_metadata *meta) {}

  event void IPAddress.changed(bool global_valid) {}
}
