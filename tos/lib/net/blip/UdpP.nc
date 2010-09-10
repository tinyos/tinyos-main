
#include <ip_malloc.h>
#include <in_cksum.h>
#include <BlipStatistics.h>

module UdpP {
  provides interface UDP[uint8_t clnt];
  provides interface Init;
  provides interface BlipStatistics<udp_statistics_t>;
  uses interface IP;
  uses interface IPAddress;
} implementation {

#ifdef PRINTFUART_ENABLED
#undef dbg
#define dbg(X,fmt, args...) printfUART(fmt, ##args)
#endif

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
    last_localport = (last_localport < LOCAL_PORT_START) ? last_localport + 1 : LOCAL_PORT_START;
    while (!done) {
      done = 1;
      for (i = 0; i < N_CLIENTS; i++) {
        if (local_ports[i] == compare) {
          last_localport = (last_localport < LOCAL_PORT_START) ? last_localport + 1 : LOCAL_PORT_START;
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

  event void IP.recv(void *headers,
                     void *payload,
                     size_t len,
                     struct ip6_metadata *meta) {
    int i;
    struct sockaddr_in6 addr;
    struct ip6_hdr *iph = (struct ip6_hdr *)headers;
    struct udp_hdr *udph = (struct udp_hdr *)payload;

    dbg("UDP", "UDP - IP.recv: len: %i srcport: %i dstport: %i\n",
        ntohs(iph->ip6_plen), ntohs(udph->srcport), ntohs(udph->dstport));

    for (i = 0; i < N_CLIENTS; i++)
      if (local_ports[i] == udph->dstport)
        break;

    if (i == N_CLIENTS) {
      // TODO : send ICMP port closed message here.
      return;
    }
    memcpy(&addr.sin6_addr, &iph->ip6_src, 16);
    addr.sin6_port = udph->srcport;
    /* we have to set this here because it is alway elided by the
       hc-06 encoding, and not (currently) recomputed when
       uncompressed. */
    udph->len = htons(len);

    {
      uint16_t my_cksum, rx_cksum = ntohs(udph->chksum);
      struct ip_iovec v;

      udph->chksum = 0;
      v.iov_base = payload;
      v.iov_len  = len;
      v.iov_next = NULL;

      my_cksum = msg_cksum(iph, &v, IANA_UDP);
      if (rx_cksum != my_cksum) {
        BLIP_STATS_INCR(stats.cksum);
        printfUART("udp ckecksum computation failed: mine: 0x%x theirs: 0x%x\n", 
                   my_cksum, rx_cksum);
        // drop
      }
    }

    BLIP_STATS_INCR(stats.rcvd);
    signal UDP.recvfrom[i](&addr, (void *)(udph + 1), len - sizeof(struct udp_hdr), meta);
  }

  /*
   * Injection point of IP datagrams.  This is only called for packets
   * being sent from this mote; packets which are being forwarded
   * never lave the stack and so never use this entry point.
   *
   * @msg an IP datagram with header fields (except for length)
   * @plen the length of the data payload added after the headers.
   */
  command error_t UDP.sendto[uint8_t clnt](struct sockaddr_in6 *dest, void *payload, 
                                           uint16_t len) {
    error_t rc;
    struct ip6_packet pkt;
    struct udp_hdr    udp;
    struct ip_iovec   v[2];

    // fill in all the packet fields
    memclr((uint8_t *)&pkt.ip6_hdr, sizeof(pkt));
    memclr((uint8_t *)&udp, sizeof(udp));

    
    memcpy(&pkt.ip6_hdr.ip6_dst, dest->sin6_addr.s6_addr, 16);
    call IPAddress.setSource(&pkt.ip6_hdr);
    
    if (local_ports[clnt] == 0 && (local_ports[clnt] = alloc_lport(clnt)) == 0) {
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
    v[0].iov_next = &v[1];
    v[1].iov_base = payload;
    v[1].iov_len  = len;
    v[1].iov_next = NULL;
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
    ip_memcpy(buf, &stats, sizeof(udp_statistics_t));
#endif
  }

  default event void UDP.recvfrom[uint8_t clnt](struct sockaddr_in6 *from, void *payload,
                                               uint16_t len, struct ip6_metadata *meta) {

 }
}
