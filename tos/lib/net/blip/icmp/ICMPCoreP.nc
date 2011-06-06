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

/** 
 *
 * This module implements core ICMP functionality, like replying to
 * echo requests and sending time exceeded messages.  Other modules
 * which want to implement other functionality can wire to the IP
 * interface.
 *
 */
#include <lib6lowpan/ip.h>
#include <lib6lowpan/in_cksum.h>

#include "icmp6.h"

module ICMPCoreP {
  provides {
    interface IP as ICMP_IP[uint8_t type];
  }
  uses {
    interface IP;
    interface IPAddress;
    interface Leds;
  }
} implementation {
  
  event void IP.recv(struct ip6_hdr *iph, 
                     void *packet, 
                     size_t len, 
                     struct ip6_metadata *meta) {
    struct ip6_hdr *hdr = iph;
    struct ip6_packet reply;
    struct ip_iovec v;
    struct icmp6_hdr *req = (struct icmp6_hdr *)packet;

    switch (req->type) {
    case ICMP_TYPE_ECHO_REQUEST:
      req->type = ICMP_TYPE_ECHO_REPLY;
      req->cksum = 0;

      memset(&reply, 0, sizeof(reply));
      memcpy(reply.ip6_hdr.ip6_dst.s6_addr, hdr->ip6_src.s6_addr, 16);
      call IPAddress.setSource(&reply.ip6_hdr);

      reply.ip6_hdr.ip6_vfc = IPV6_VERSION;
      reply.ip6_hdr.ip6_nxt = IANA_ICMP;
      reply.ip6_data = &v;

      v.iov_next = NULL;
      v.iov_base = (void *)req;
      v.iov_len  = len;

      reply.ip6_hdr.ip6_plen = htons(len);
      req->cksum = htons(msg_cksum(&reply.ip6_hdr, reply.ip6_data, IANA_ICMP));
      // iov_print(&v);

      call IP.send(&reply);
      break;

    default:
      signal ICMP_IP.recv[req->type](iph, packet, len, meta);
    }
  }

  command error_t ICMP_IP.send[uint8_t type](struct ip6_packet *pkt) {
    struct icmp6_hdr *req = (struct icmp6_hdr *)pkt->ip6_data->iov_base; 
    if (pkt->ip6_data->iov_len >= sizeof(struct icmp6_hdr) && 
        pkt->ip6_hdr.ip6_nxt == IANA_ICMP) {
      req->cksum = 0;
      req->cksum = htons(msg_cksum(&pkt->ip6_hdr, pkt->ip6_data, IANA_ICMP));
    }
    return call IP.send(pkt);
  }

  event void IPAddress.changed(bool valid) {}

  default event void ICMP_IP.recv[uint8_t type](struct ip6_hdr *iph, void *payload, 
                                                size_t len, struct ip6_metadata *meta) {}
}
