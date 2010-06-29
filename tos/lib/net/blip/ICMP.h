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
  nx_uint16_t seqno;
  nx_uint8_t pad[2];
} rqual_t;

struct icmp_stats {
  uint16_t seq;
  uint8_t ttl;
  uint32_t rtt;
};

#endif
