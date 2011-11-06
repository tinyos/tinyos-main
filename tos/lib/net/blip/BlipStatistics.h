/*
 * "Copyright (c) 2008, 2009 The Regents of the University  of California.
 * All rights reserved."
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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
