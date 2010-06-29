/*
 * Copyright (c) 2008, 2009 The Regents of the University  of California.
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
#ifndef _BLIP_STATISTICS_H_
#define _BLIP_STATISTICS_H_

/* Different IP components provide statistics about their operation. 
 *
 * Structures with this information is available here.
 */

#ifdef BLIP_STATS
// if we get rid of the increments the compiler can optimize out the
// statistics data structures when we don't use them.
#define BLIP_STATS_INCR(X) X++
#else
#define BLIP_STATS_INCR(X)
#endif


/* Statistics from the core 6lowpan/IPv6 fragmentation and forwarding engine */
typedef nx_struct {
  nx_uint16_t sent;       // total IP datagrams sent
  nx_uint16_t forwarded;  // total IP datagrams forwarded
  nx_uint8_t rx_drop;     // L2 frags dropped due to 6lowpan failure
  nx_uint8_t tx_drop;     // L2 frags dropped due to link failures
  nx_uint8_t fw_drop;     // L2 frags dropped when forwarding due to queue overflow
  nx_uint8_t rx_total;    // L2 frags received
  nx_uint8_t encfail;     // frags dropped due to send queue

#ifdef BLIP_STATS_IP_MEM
  // statistics about free memory
  // mostly useful for looking for memory leaks, or looking at
  // forwarding queue depth.
  nx_uint8_t fragpool;    // free fragments in pool
  nx_uint8_t sendinfo;    // free sendinfo structures
  nx_uint8_t sendentry;   // free send entryies
  nx_uint8_t sndqueue;    // free send queue entries
  nx_uint16_t heapfree;   // available free space in the heap
#endif
} ip_statistics_t;


typedef nx_struct {
  nx_uint8_t hop_limit;
  nx_uint16_t parent;
  nx_uint16_t parent_metric;
  nx_uint16_t parent_etx;
} route_statistics_t;

typedef nx_struct {
  nx_uint8_t sol_rx;
  nx_uint8_t sol_tx;
  nx_uint8_t adv_rx;
  nx_uint8_t adv_tx;
  nx_uint8_t echo_rx;
  nx_uint8_t echo_tx;
  nx_uint8_t unk_rx;
  nx_uint16_t rx;
} icmp_statistics_t;

/* Statistics from the UDP transport protocol  */
typedef nx_struct {
  nx_uint16_t sent;  // UDP datagrams sent from app
  nx_uint16_t rcvd;  // UDP datagrams delivered to apps
  nx_uint16_t cksum; // UDP datagrams dropped due to checksum error
} udp_statistics_t;


#endif
