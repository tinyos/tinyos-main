
#include <ip_malloc.h>
#include <in_cksum.h>
#include <Statistics.h>

module UdpP {
  provides interface UDP[uint8_t clnt];
  provides interface Init;
  provides interface Statistics<udp_statistics_t>;
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
    call Statistics.clear();
    ip_memclr((uint8_t *)local_ports, sizeof(uint16_t) * N_CLIENTS);
    return SUCCESS;
  }

  command error_t UDP.bind[uint8_t clnt](uint16_t port) {
    int i;
    port = htons(port);
    for (i = 0; i < N_CLIENTS; i++)
      if (i != clnt && local_ports[i] == port)
        return FAIL;
    local_ports[clnt] = port;
    return SUCCESS;
  }

  event void IP.recv(struct ip6_hdr *iph,
                     void *payload,
                     struct ip_metadata *meta) {
    int i;
    struct sockaddr_in6 addr;
    struct udp_hdr *udph = (struct udp_hdr *)payload;

    dbg("UDP", "UDP - IP.recv: len: %i srcport: %i dstport: %i\n",
        ntohs(iph->plen), ntohs(udph->srcport), ntohs(udph->dstport));

    for (i = 0; i < N_CLIENTS; i++)
      if (local_ports[i] == udph->dstport)
        break;

    if (i == N_CLIENTS) {
      // TODO : send ICMP port closed message here.
      return;
    }
    ip_memcpy(&addr.sin6_addr, &iph->ip6_src, 16);
    addr.sin6_port = udph->srcport;


    { 
      uint16_t rx_cksum = ntohs(udph->chksum), my_cksum;
      vec_t cksum_vec[4];
      uint32_t hdr[2];

      udph->chksum = 0;

      cksum_vec[0].ptr = (uint8_t *)(iph->ip6_src.s6_addr);
      cksum_vec[0].len = 16;
      cksum_vec[1].ptr = (uint8_t *)(iph->ip6_dst.s6_addr);
      cksum_vec[1].len = 16;
      cksum_vec[2].ptr = (uint8_t *)hdr;
      cksum_vec[2].len = 8;
      hdr[0] = iph->plen;
      hdr[1] = htonl(IANA_UDP);
      cksum_vec[3].ptr = payload;
      cksum_vec[3].len = ntohs(iph->plen);

      my_cksum = in_cksum(cksum_vec, 4);
      printfUART("rx cksum: %x calc: %x\n", rx_cksum, my_cksum);
      if (rx_cksum != my_cksum) {
        BLIP_STATS_INCR(cksum);
        // return;
      }
    }

    BLIP_STATS_INCR(rcvd);
    signal UDP.recvfrom[i](&addr, (void *)(udph + 1), ntohs(iph->plen) - sizeof(struct udp_hdr), meta);
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
    struct split_ip_msg *msg;
    struct udp_hdr *udp;
    struct generic_header *g_udp;
    error_t rc;

    // todo check + alloc local port

    msg = (struct split_ip_msg *)ip_malloc(sizeof(struct split_ip_msg) +
                                        sizeof(struct udp_hdr) +
                                        sizeof(struct generic_header));

    if (msg == NULL) {
      dbg("Drops", "drops: UDP send: malloc failure\n");
      return ERETRY;
    }
    udp = (struct udp_hdr *)(msg + 1);
    g_udp = (struct generic_header *)(udp + 1);

    // fill in all the packet fields
    ip_memclr((uint8_t *)msg, sizeof(struct split_ip_msg));
    ip_memclr((uint8_t *)udp, sizeof(struct udp_hdr));
    
    call IPAddress.setSource(&msg->hdr);
    memcpy(&msg->hdr.ip6_dst, dest->sin6_addr.s6_addr, 16);
    
    if (local_ports[clnt] == 0 && (local_ports[clnt] = alloc_lport(clnt)) == 0) {
      ip_free(msg);
      return FAIL;
    }
    udp->srcport = local_ports[clnt];
    udp->dstport = dest->sin6_port;
    udp->len = htons(len + sizeof(struct udp_hdr));
    udp->chksum = 0;

    // set up the pointers
    g_udp->len = sizeof(struct udp_hdr);
    g_udp->hdr.udp = udp;
    g_udp->next = NULL;
    msg->headers = g_udp;
    msg->data_len = len;
    msg->data = payload;

    udp->chksum = htons(msg_cksum(msg, IANA_UDP)); 

    rc = call IP.send(msg);
    BLIP_STATS_INCR(sent);

    ip_free(msg);
    return rc;

  }

  command void Statistics.clear() {
#ifdef BLIP_STATS
    ip_memclr((uint8_t *)&stats, sizeof(udp_statistics_t));
#endif
  }

  command void Statistics.get(udp_statistics_t *buf) {
#ifdef BLIP_STATS
    ip_memcpy(buf, &stats, sizeof(udp_statistics_t));
#endif
  }

  default event void UDP.recvfrom[uint8_t clnt](struct sockaddr_in6 *from, void *payload,
                                               uint16_t len, struct ip_metadata *meta) {

 }
}
