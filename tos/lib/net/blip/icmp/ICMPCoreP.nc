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
#include "blip_printf.h"

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
    uint16_t my_cksum, rx_cksum = ntohs(req->cksum);

    // SDH : we can compute the checksum for all ICMP messages here
    // this, for instance, protects RPL and ND since they sits on top
    // of ICMP.
    req->cksum = 0;
    v.iov_base = packet;
    v.iov_len  = len;
    v.iov_next = NULL;
    my_cksum = msg_cksum(iph, &v, IANA_ICMP);
    //printf("ICMP: type: %i rx_cksum: 0x%x my_cksum: 0x%x\n",
    //       req->type, rx_cksum, my_cksum);

    printf("ICMP: Received type ");
    switch (req->type) {
      case ICMP_TYPE_ECHO_DEST_UNREACH:  printf("ICMP_TYPE_ECHO_DEST_UNREACH\n"); break;
      case ICMP_TYPE_ECHO_PKT_TOO_BIG:   printf("ICMP_TYPE_ECHO_PKT_TOO_BIG\n"); break;
      case ICMP_TYPE_ECHO_TIME_EXCEEDED: printf("ICMP_TYPE_ECHO_TIME_EXCEEDED\n"); break;
      case ICMP_TYPE_ECHO_PARAM_PROBLEM: printf("ICMP_TYPE_ECHO_PARAM_PROBLEM\n"); break;
      case ICMP_TYPE_ECHO_REQUEST:       printf("ICMP_TYPE_ECHO_REQUEST\n"); break;
      case ICMP_TYPE_ECHO_REPLY:         printf("ICMP_TYPE_ECHO_REPLY\n"); break;
      case ICMP_TYPE_ROUTER_SOL:         printf("ICMP_TYPE_ROUTER_SOL\n"); break;
      case ICMP_TYPE_ROUTER_ADV:         printf("ICMP_TYPE_ROUTER_ADV\n"); break;
      case ICMP_TYPE_NEIGHBOR_SOL:       printf("ICMP_TYPE_NEIGHBOR_SOL\n"); break;
      case ICMP_TYPE_NEIGHBOR_ADV:       printf("ICMP_TYPE_NEIGHBOR_ADV\n"); break;
      case ICMP_TYPE_RPL_CONTROL:        printf("ICMP_TYPE_RPL_CONTROL\n"); break;
      default:                           printf("%i\n", req->type); break;
    }

    if (my_cksum != rx_cksum) {
      printf("ICMP: invalid checksum\n");
      return;
    }

    switch (req->type) {
    case ICMP_TYPE_ECHO_REQUEST:
      req->type = ICMP_TYPE_ECHO_REPLY;

      memset(&reply, 0, sizeof(reply));
      memcpy(reply.ip6_hdr.ip6_dst.s6_addr, hdr->ip6_src.s6_addr, 16);
      call IPAddress.setSource(&reply.ip6_hdr);

      reply.ip6_hdr.ip6_vfc = IPV6_VERSION;
      reply.ip6_hdr.ip6_nxt = IANA_ICMP;
      reply.ip6_data = &v;

      reply.ip6_hdr.ip6_plen = htons(len);
      call ICMP_IP.send[ICMP_TYPE_ECHO_REPLY](&reply);
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

    printf("ICMPCoreP: Sending ICMP type: ");
    switch (type) {
      case ICMP_TYPE_ECHO_DEST_UNREACH:  printf("ICMP_TYPE_ECHO_DEST_UNREACH\n"); break;
      case ICMP_TYPE_ECHO_PKT_TOO_BIG:   printf("ICMP_TYPE_ECHO_PKT_TOO_BIG\n"); break;
      case ICMP_TYPE_ECHO_TIME_EXCEEDED: printf("ICMP_TYPE_ECHO_TIME_EXCEEDED\n"); break;
      case ICMP_TYPE_ECHO_PARAM_PROBLEM: printf("ICMP_TYPE_ECHO_PARAM_PROBLEM\n"); break;
      case ICMP_TYPE_ECHO_REQUEST:       printf("ICMP_TYPE_ECHO_REQUEST\n"); break;
      case ICMP_TYPE_ECHO_REPLY:         printf("ICMP_TYPE_ECHO_REPLY\n"); break;
      case ICMP_TYPE_ROUTER_SOL:         printf("ICMP_TYPE_ROUTER_SOL\n"); break;
      case ICMP_TYPE_ROUTER_ADV:         printf("ICMP_TYPE_ROUTER_ADV\n"); break;
      case ICMP_TYPE_NEIGHBOR_SOL:       printf("ICMP_TYPE_NEIGHBOR_SOL\n"); break;
      case ICMP_TYPE_NEIGHBOR_ADV:       printf("ICMP_TYPE_NEIGHBOR_ADV\n"); break;
      case ICMP_TYPE_RPL_CONTROL:        printf("ICMP_TYPE_RPL_CONTROL\n"); break;
      default:                           printf("%i\n", type); break;
    }

    return call IP.send(pkt);
  }

  event void IPAddress.changed(bool valid) {}

  default event void ICMP_IP.recv[uint8_t type](struct ip6_hdr *iph, void *payload,
                                                size_t len, struct ip6_metadata *meta) {}
}
