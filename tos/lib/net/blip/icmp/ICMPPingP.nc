/*
 * Copyright (c) 2008-2010 The Regents of the University  of California.
 * All rights reserved."
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

module ICMPPingP {
  provides interface ICMPPing[uint8_t client];
  uses {
    interface Timer<TMilli> as PingTimer;
    interface IP as IP_ECHO;
    interface IPAddress;
  }
} implementation {

  uint16_t ping_seq, ping_n, ping_rcv, ping_ident;
  struct in6_addr ping_dest;

  void sendPing(struct in6_addr *dest, uint16_t seqno) {
    struct ip6_packet *ipmsg = (struct ip6_packet *)ip_malloc(sizeof(struct ip6_packet) + 
                                                              sizeof(icmp_echo_hdr_t) + 
                                                              sizeof(nx_uint32_t));
    icmp_echo_hdr_t *e_hdr = (icmp_echo_hdr_t *)(ipmsg + 1);
    nx_uint32_t *sendTime = (nx_uint32_t *)(e_hdr + 1);
    struct ip_iovec v;

    if (ipmsg == NULL) return;

    // iovec
    v.iov_base = (void *)(ipmsg + 1);
    v.iov_len = sizeof(icmp_echo_hdr_t) + sizeof(nx_uint32_t);
    v.iov_next = NULL;
    ipmsg->ip6_data = &v;

    // icmp hdr
    e_hdr->type = ICMP_TYPE_ECHO_REQUEST;
    e_hdr->code = 0;
    e_hdr->cksum = 0;
    e_hdr->ident = ping_ident;
    e_hdr->seqno = seqno;
    *sendTime = call PingTimer.getNow();

    // ip hdr
    memclr(&ipmsg->ip6_hdr, sizeof(struct ip6_hdr));
    ipmsg->ip6_hdr.ip6_vfc = IPV6_VERSION;
    ipmsg->ip6_hdr.ip6_nxt = IANA_ICMP;
    ipmsg->ip6_hdr.ip6_plen = htons(v.iov_len);
    memcpy(&ipmsg->ip6_hdr.ip6_dst, dest->s6_addr, 16);
    call IPAddress.setSource(&ipmsg->ip6_hdr);

    e_hdr->cksum = msg_cksum(&ipmsg->ip6_hdr, ipmsg->ip6_data, IANA_ICMP);

    call IP_ECHO.send(ipmsg);
    ip_free(ipmsg);
  }

  command error_t ICMPPing.ping[uint8_t client](struct in6_addr *target, 
                                                 uint16_t period, 
                                                 uint16_t n) {
    if (call PingTimer.isRunning()) return ERETRY;
    call PingTimer.startPeriodic(period);
    memcpy(&ping_dest, target, 16);
    ping_n = n;
    ping_seq = 0;
    ping_rcv = 0;
    ping_ident = client;
    return SUCCESS;
  }

  event void PingTimer.fired() {
    // send a ping request
    if (ping_seq == ping_n) {
      signal ICMPPing.pingDone[ping_ident](ping_rcv, ping_n);
      call PingTimer.stop();
      return;
    }
    sendPing(&ping_dest, ping_seq);
    ping_seq++;
  }

  // ping replies come here.
  event void IP_ECHO.recv(struct ip6_hdr *iph, 
                          void *packet, 
                          size_t len, 
                          struct ip6_metadata *meta) {
    icmp_echo_hdr_t *req = (icmp_echo_hdr_t *)packet;
    nx_uint32_t *sendTime = (nx_uint32_t *)(req + 1);
    struct icmp_stats p_stat;

    p_stat.seq = req->seqno;
    p_stat.ttl = iph->ip6_hlim;
    p_stat.rtt = (call PingTimer.getNow()) - (*sendTime);
    signal ICMPPing.pingReply[req->ident](&iph->ip6_src, &p_stat);
    ping_rcv++;
//     BLIP_STATS_INCR(stats.echo_rx);

  }
  default event void ICMPPing.pingReply[uint8_t client](struct in6_addr *source, 
                                                         struct icmp_stats *ping_stats) {
  }

  default event void ICMPPing.pingDone[uint8_t client](uint16_t n, uint16_t m) {

  }

  event void IPAddress.changed(bool global_valid) {}

}
