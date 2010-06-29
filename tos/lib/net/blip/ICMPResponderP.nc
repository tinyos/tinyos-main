/*
 * Copyright (c) 2008 The Regents of the University  of California.
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

#include <lib6lowpan.h>
#include <6lowpan.h>
#include <ip_malloc.h>
#include <Statistics.h>
#include "in_cksum.h"
#include "PrintfUART.h"
#include "ICMP.h"

extern uint8_t multicast_prefix[8];

module ICMPResponderP {
  provides interface ICMP;
  provides interface ICMPPing[uint16_t client];
  provides interface Statistics<icmp_statistics_t>;

  uses interface IP;
  uses interface IPAddress;

  uses interface Leds;

  uses interface Timer<TMilli> as Solicitation;
  uses interface Timer<TMilli> as Advertisement;
  uses interface Timer<TMilli> as PingTimer;
  uses interface LocalTime<TMilli>;
  uses interface Random;

  uses interface IPRouting;

} implementation {

  icmp_statistics_t stats;
  uint32_t solicitation_period;
  uint32_t advertisement_period;
  uint16_t nd_seqno = 0;

  uint16_t ping_seq, ping_n, ping_rcv, ping_ident;
  struct in6_addr ping_dest;

#ifdef PRINTFUART_ENABLED
#undef dbg
#define dbg(X, fmt, args ...) printfUART(fmt, ## args)
#endif

  command uint16_t ICMP.cksum(struct split_ip_msg *msg, uint8_t nxt_hdr) {
    return msg_cksum(msg, nxt_hdr);
  }


  command void ICMP.sendSolicitations() {
    uint16_t jitter = (call Random.rand16()) % TRICKLE_JITTER;
    if (call Solicitation.isRunning()) return;
    solicitation_period = TRICKLE_PERIOD;
    call Solicitation.startOneShot(jitter);
  }

  command void ICMP.sendAdvertisements() {


    uint16_t jitter = (call Random.rand16()) % TRICKLE_JITTER;
    if (call Advertisement.isRunning()) return;
    advertisement_period = TRICKLE_PERIOD;
    call Advertisement.startOneShot(jitter);
  }

  command void ICMP.sendTimeExceeded(struct ip6_hdr *hdr, unpack_info_t *u_info, uint16_t amount_here) {
    uint8_t i_hdr_buf[sizeof(struct icmp6_hdr) + 4];
    struct split_ip_msg *msg = (struct split_ip_msg *)ip_malloc(sizeof(struct split_ip_msg));
    struct generic_header g_hdr[3];
    struct icmp6_hdr *i_hdr = (struct icmp6_hdr *)i_hdr_buf;

    if (msg == NULL) return;

    dbg("ICMPResponder", "send time exceeded\n");

    msg->headers = NULL;
    msg->data = u_info->payload_start;
    msg->data_len = amount_here;

    // make sure to include the udp header if necessary
    if (u_info->nxt_hdr == IANA_UDP) {
      g_hdr[2].hdr.udp = (struct udp_hdr *)u_info->transport_ptr;
      g_hdr[2].len = sizeof(struct udp_hdr);
      g_hdr[2].next = NULL;
      
      // since the udp headers are included in the offset we need to
      // add that length so the payload length in the encapsulated
      // packet will be correct.
      hdr->plen = htons(ntohs(hdr->plen) + sizeof(struct udp_hdr));
      msg->headers = &g_hdr[2];
    }
    // the fields in the packed packet is not necessarily the same as
    // the fields in canonical packet which was packed.  This is due
    // to the insertion of transient routing headers.
    hdr->nxt_hdr = u_info->nxt_hdr;
    hdr->plen = htons(ntohs(hdr->plen) - u_info->payload_offset);

    // the IP header is part of the payload
    g_hdr[1].hdr.data = (void *)hdr;
    g_hdr[1].len = sizeof(struct ip6_hdr);
    g_hdr[1].next = msg->headers;
    msg->headers = &g_hdr[1];

    // and is preceeded by the icmp time exceeded message
    g_hdr[0].hdr.data = (void *)i_hdr;
    g_hdr[0].len = sizeof(struct icmp6_hdr) + 4;
    g_hdr[0].next = msg->headers;
    msg->headers = &g_hdr[0];

    ip_memcpy(&msg->hdr.ip6_dst, &hdr->ip6_src, 16);
    call IPAddress.getIPAddr(&msg->hdr.ip6_src);

    i_hdr->type = ICMP_TYPE_ECHO_TIME_EXCEEDED;
    i_hdr->code = ICMP_CODE_HOPLIMIT_EXCEEDED;
    i_hdr->cksum = 0;
    ip_memclr((void *)(i_hdr + 1), 4);

    msg->hdr.nxt_hdr = IANA_ICMP;

    i_hdr->cksum = htons(call ICMP.cksum(msg, IANA_ICMP));

    call IP.send(msg);

    ip_free(msg);
  }
  /*
   * Solicitations
   */ 
  void sendSolicitation() {
    struct split_ip_msg *ipmsg = (struct split_ip_msg *)ip_malloc(sizeof(struct split_ip_msg) + sizeof(rsol_t));
    rsol_t *msg = (rsol_t *)(ipmsg + 1);

    if (ipmsg == NULL) return;

    BLIP_STATS_INCR(stats.sol_tx);

    msg->type = ICMP_TYPE_ROUTER_SOL;
    msg->code = 0;
    msg->cksum = 0;
    msg->reserved = 0;

    ipmsg->headers = NULL;
    ipmsg->data = (void *)msg;
    ipmsg->data_len = sizeof(rsol_t);
    
    // this is required for solicitation messages
    ipmsg->hdr.hlim = 0xff;


    call IPAddress.getLLAddr(&ipmsg->hdr.ip6_src);
    ip_memclr((uint8_t *)&ipmsg->hdr.ip6_dst, 16);
    ipmsg->hdr.ip6_dst.s6_addr16[0] = htons(0xff02);
    ipmsg->hdr.ip6_dst.s6_addr16[7] = htons(2);

    msg->cksum = call ICMP.cksum(ipmsg, IANA_ICMP);

    call IP.send(ipmsg);

    ip_free(ipmsg);
  }

  void sendPing(struct in6_addr *dest, uint16_t seqno) {
    struct split_ip_msg *ipmsg = (struct split_ip_msg *)ip_malloc(sizeof(struct split_ip_msg) + 
                                                                  sizeof(icmp_echo_hdr_t) + 
                                                                  sizeof(nx_uint32_t));
    icmp_echo_hdr_t *e_hdr = (icmp_echo_hdr_t *)ipmsg->next;
    nx_uint32_t *sendTime = (nx_uint32_t *)(e_hdr + 1);

    if (ipmsg == NULL) return;
    ipmsg->headers = NULL;
    ipmsg->data = (void *)e_hdr;
    ipmsg->data_len = sizeof(icmp_echo_hdr_t) + sizeof(nx_uint32_t);

    e_hdr->type = ICMP_TYPE_ECHO_REQUEST;
    e_hdr->code = 0;
    e_hdr->cksum = 0;
    e_hdr->ident = ping_ident;
    e_hdr->seqno = seqno;
    *sendTime = call LocalTime.get();

    memcpy(&ipmsg->hdr.ip6_dst, dest->s6_addr, 16);
    call IPAddress.getIPAddr(&ipmsg->hdr.ip6_src);

    e_hdr->cksum = call ICMP.cksum(ipmsg,IANA_ICMP);

    call IP.send(ipmsg);
    ip_free(ipmsg);
  }

  /*
   * Router advertisements
   */ 
  void handleRouterAdv(void *payload, uint16_t len, struct ip_metadata *meta) {
    
    radv_t *r = (radv_t *)payload;
    pfx_t  *pfx = (pfx_t *)(r->options);
    rqual_t *beacon = (rqual_t *)(pfx + 1);

    if (len > sizeof(radv_t) + sizeof(pfx_t) && 
        beacon->type == ICMP_EXT_TYPE_BEACON) {

      printfUART("beacon seqno: %i my seqno: %i\n", beacon->seqno, nd_seqno);

      if (beacon->seqno > nd_seqno || 
          (nd_seqno > 0 && beacon->seqno == 0) ||
          !call IPRouting.hasRoute()) {
        call IPRouting.reset();
        nd_seqno = beacon->seqno;
      }

      if (beacon->seqno == nd_seqno) {
        call IPRouting.reportAdvertisement(meta->sender, r->hlim,
                                           meta->lqi, beacon->metric);
        // push out the seqno update
        // call Advertisement.stop();
        // call ICMP.sendAdvertisements();

        if (pfx->type != ICMP_EXT_TYPE_PREFIX) return;

        call IPAddress.setPrefix((uint8_t *)pfx->prefix);
      }


      dbg("ICMPResponder", " * beacon cost: 0x%x\n", beacon->metric);
    } else {
        dbg("ICMPResponder", " * no beacon cost\n");
    }


    // TODO : get short address here...
  }

  void sendAdvertisement() {
    struct split_ip_msg *ipmsg = (struct split_ip_msg *)ip_malloc(sizeof(struct split_ip_msg) + 
                                                                  sizeof(radv_t) + 
                                                                  sizeof(pfx_t) +
                                                                  sizeof(rqual_t));
    uint16_t len = sizeof(radv_t);
    radv_t *r = (radv_t *)(ipmsg + 1);
    pfx_t *p = (pfx_t *)r->options;
    rqual_t *q = (rqual_t *)(p + 1);

    if (ipmsg == NULL) return;
    // don't sent the advertisement if we don't have a valid route
    if (!call IPRouting.hasRoute()) {
      ip_free(ipmsg);
      return;
    }
    BLIP_STATS_INCR(stats.adv_tx);

    r->type = ICMP_TYPE_ROUTER_ADV;
    r->code = 0;
    r->hlim = call IPRouting.getHopLimit();
    r->flags = 0;
    r->lifetime = 1;
    r->reachable_time = 0;
    r->retrans_time = 0;

    ipmsg->hdr.hlim = 0xff;
    
    if (globalPrefix) {
      len += sizeof(pfx_t);
      p->type = ICMP_EXT_TYPE_PREFIX;
      p->length = sizeof(pfx_t) >> 3;
      p->pfx_len = 64;
      memcpy(p->prefix, call IPAddress.getPublicAddr(), 8);
    }

    len += sizeof(rqual_t);
    q->type = ICMP_EXT_TYPE_BEACON;
    q->length = sizeof(rqual_t) >> 3;;
    q->metric = call IPRouting.getQuality();
    q->seqno = nd_seqno;

    call IPAddress.getLLAddr(&ipmsg->hdr.ip6_src);
    ip_memclr((uint8_t *)&ipmsg->hdr.ip6_dst, 16);
    ipmsg->hdr.ip6_dst.s6_addr16[0] = htons(0xff02);
    ipmsg->hdr.ip6_dst.s6_addr16[7] = htons(1);

    //dbg("ICMPResponder", "My Address: [0x%x] [0x%x] [0x%x] [0x%x]\n", ipmsg->hdr.src_addr[12], ipmsg->hdr.src_addr[13], ipmsg->hdr.src_addr[14], ipmsg->hdr.src_addr[15]);
    dbg("ICMPResponder", "adv hop limit: 0x%x\n", r->hlim);

    if (r->hlim >= 0xf0) {
      ip_free(ipmsg);
      return;
    }

    ipmsg->data = (void *)r;
    ipmsg->data_len = len;
    ipmsg->headers = NULL;

    r->cksum = 0;
    r->cksum = call ICMP.cksum(ipmsg, IANA_ICMP);

    call IP.send(ipmsg);
    ip_free(ipmsg);
  }


  event void IP.recv(struct ip6_hdr *iph,
                     void *payload, 
                     struct ip_metadata *meta) {
    icmp_echo_hdr_t *req = (icmp_echo_hdr_t *)payload;
    uint16_t len = ntohs(iph->plen);
    BLIP_STATS_INCR(stats.rx);
  
    // for checksum calculation
    printfUART ("icmp type: 0x%x code: 0x%x cksum: 0x%x ident: 0x%x seqno: 0x%x len: 0x%x\n",
                req->type, req->code, req->cksum, req->ident, req->seqno, len);

    switch (req->type) {
    case ICMP_TYPE_ROUTER_ADV:
      handleRouterAdv(payload, len, meta);
      BLIP_STATS_INCR(stats.adv_rx);
      break;
    case ICMP_TYPE_ROUTER_SOL:
      // only reply to solicitations if we have established a default route.
      if (call IPRouting.hasRoute()) {
          call ICMP.sendAdvertisements();
      }
      BLIP_STATS_INCR(stats.sol_rx);
      break;
    case ICMP_TYPE_ECHO_REPLY:
      {
        nx_uint32_t *sendTime = (nx_uint32_t *)(req + 1);
        struct icmp_stats p_stat;
        p_stat.seq = req->seqno;
        p_stat.ttl = iph->hlim;
        p_stat.rtt = (call LocalTime.get()) - (*sendTime);
        signal ICMPPing.pingReply[req->ident](&iph->ip6_src, &p_stat);
        ping_rcv++;
        BLIP_STATS_INCR(stats.echo_rx);
      }
      break;
    case ICMP_TYPE_ECHO_REQUEST:
      {
        // send a ping reply.
        struct split_ip_msg msg;
        msg.headers = NULL;
        msg.data = payload;
        msg.data_len = len;

        memcpy(&msg.hdr.ip6_dst, &iph->ip6_src, 16);      
        call IPAddress.setSource(&msg.hdr);
        
        req->type = ICMP_TYPE_ECHO_REPLY;
        req->code = 0;
        req->cksum = 0;
        req->cksum = call ICMP.cksum(&msg, IANA_ICMP);
        
        // remember, this can't really fail in a way we care about
        call IP.send(&msg);
        BLIP_STATS_INCR(stats.echo_tx);
        break;
      }
    default:
      BLIP_STATS_INCR(stats.unk_rx);
    }
  }


  event void Solicitation.fired() {
    sendSolicitation();
    dbg("ICMPResponder", "solicitation period: 0x%x max: 0x%x seq: %i\n", solicitation_period, TRICKLE_MAX, nd_seqno);
    solicitation_period <<= 1;
    if (solicitation_period < TRICKLE_MAX) {
      call Solicitation.startOneShot(solicitation_period);
    } else {
      signal ICMP.solicitationDone();
    }
  }

  event void Advertisement.fired() {
    dbg("ICMPResponder", "==> Sending router advertisement\n");
    sendAdvertisement();
    advertisement_period <<= 1;
    if (advertisement_period < TRICKLE_MAX) {
      call Advertisement.startOneShot(advertisement_period);
    }
  }


  
  command error_t ICMPPing.ping[uint16_t client](struct in6_addr *target, uint16_t period, uint16_t n) {
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



  command void Statistics.get(icmp_statistics_t *statistics) {
    memcpy(statistics, &stats, sizeof(icmp_statistics_t));
  }
  
  command void Statistics.clear() {
    ip_memclr((uint8_t *)&stats, sizeof(icmp_statistics_t));
  }

  default event void ICMPPing.pingReply[uint16_t client](struct in6_addr *source, 
                                                         struct icmp_stats *ping_stats) {
  }

  default event void ICMPPing.pingDone[uint16_t client](uint16_t n, uint16_t m) {

  }

}
