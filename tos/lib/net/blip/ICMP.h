/*
 * "Copyright (c) 2008 The Regents of the University  of California.
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
#ifndef _ICMP_H_
#define _ICMP_H_

enum {
  ICMP_EXT_TYPE_PREFIX = 3,
  ICMP_EXT_TYPE_BEACON = 17,
};

#ifndef LOW_POWER_LISTENING     /* parameters for CSMA MAC */
enum {
  // jitter start requests by 10 seconds
  TRICKLE_JITTER = 10240,
  // have a trickle timer with a period of 4
  TRICKLE_PERIOD = 4096,

  // send a maximum of three trickle messages
  TRICKLE_MAX = (TRICKLE_PERIOD << 5),
  
};
#else  /* parameters for LPL */
enum {
  // have a trickle timer with a period of 4
  TRICKLE_PERIOD = 16384L, 
  // jitter start requests by 10 seconds
  TRICKLE_JITTER = TRICKLE_PERIOD,

  // send a maximum of three trickle messages
  TRICKLE_MAX = (TRICKLE_PERIOD << 5),
  
};
#endif

typedef nx_struct icmp6_echo_hdr {
  nx_uint8_t        type;     /* type field */
  nx_uint8_t        code;     /* code field */
  nx_uint16_t       cksum;    /* checksum field */
  nx_uint16_t       ident;
  nx_uint16_t       seqno;
} icmp_echo_hdr_t;

typedef nx_struct radv {
  nx_uint8_t        type;
  nx_uint8_t        code;
  nx_uint16_t       cksum;
  nx_uint8_t        hlim;
  nx_uint8_t        flags;
  nx_uint16_t       lifetime;
  nx_uint32_t       reachable_time;
  nx_uint32_t       retrans_time;
  nx_uint8_t        options[0];
} radv_t;

typedef nx_struct rsol {
  nx_uint8_t type;
  nx_uint8_t code;
  nx_uint16_t cksum;
  nx_uint32_t reserved;
} rsol_t;

typedef nx_struct rpfx {
  nx_uint8_t type;
  nx_uint8_t length;
  nx_uint8_t pfx_len;
  nx_uint8_t flags;
  nx_uint32_t valid_lifetime;
  nx_uint32_t preferred_lifetime;
  nx_uint32_t reserved;
  nx_uint8_t  prefix[16];
} pfx_t;

typedef nx_struct {
  nx_uint8_t type;
  nx_uint8_t length;
  nx_uint16_t metric;
  nx_uint8_t pad[4];
} rqual_t;

struct icmp_stats {
  uint16_t seq;
  uint8_t ttl;
  uint32_t rtt;
};

#endif
