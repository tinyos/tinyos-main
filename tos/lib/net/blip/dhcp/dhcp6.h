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
#ifndef _DHCP_H
#define _DHCP_H

#include <stdint.h>

/* Error Values */
#define DH6ERR_FAILURE          16
#define DH6ERR_AUTHFAIL         17
#define DH6ERR_POORLYFORMED     18
#define DH6ERR_UNAVAIL          19
#define DH6ERR_OPTUNAVAIL       20

/* Message type */
#define DH6_SOLICIT     1
#define DH6_ADVERTISE   2
#define DH6_REQUEST     3
#define DH6_CONFIRM     4
#define DH6_RENEW       5
#define DH6_REBIND      6
#define DH6_REPLY       7
#define DH6_RELEASE     8
#define DH6_DECLINE     9
#define DH6_RECONFIGURE 10
#define DH6_INFORM_REQ  11
#define DH6_RELAY_FORW  12
#define DH6_RELAY_REPLY 13

/* Predefined addresses */
#define DH6ADDR_ALLAGENT        "ff02::1:2"
#define DH6ADDR_ALLSERVER       "ff05::1:3"
#define DH6PORT_DOWNSTREAM      546
#define DH6PORT_UPSTREAM        547

/* Protocol constants */

/* timer parameters (msec, unless explicitly commented) */
#define SOL_MAX_DELAY   1000
#define SOL_TIMEOUT     1000
#define SOL_MAX_RT      120000
#define INF_TIMEOUT     1000
#define INF_MAX_RT      120000
#define REQ_TIMEOUT     1000
#define REQ_MAX_RT      30000
#define REQ_MAX_RC      10      /* Max Request retry attempts */
#define REN_TIMEOUT     10000   /* 10secs */
#define REN_MAX_RT      600000  /* 600secs */
#define REB_TIMEOUT     10000   /* 10secs */
#define REB_MAX_RT      600000  /* 600secs */
#define REL_TIMEOUT     1000    /* 1 sec */
#define REL_MAX_RC      5


#define DH6OPT_CLIENTID 1
#define DH6OPT_SERVERID 2
#define DH6OPT_IA_NA 3
#define DH6OPT_IA_TA 4
#define DH6OPT_IAADDR 5
#define DH6OPT_ORO 6
#define DH6OPT_PREFERENCE 7

#define HWTYPE_EUI64 27
#define DH6_MAX_DUIDLEN 24

struct dh6_header {
  uint32_t dh6_type_txid;
};

struct dh6_opt_header {
  uint16_t type;
  uint16_t len;
} __attribute__ ((__packed__));

struct dh6_clientid {
  uint16_t type;
  uint16_t len;
  struct {
    uint16_t duid_type;
    uint16_t hw_type;
    uint8_t eui64[8];
  } duid_ll;
} __attribute__ ((__packed__));

struct dh6_ia {
  uint16_t type;
  uint16_t len;
  uint32_t iaid;
  uint32_t t1;
  uint32_t t2;
} __attribute__ ((__packed__));;

struct dh6_iaaddr {
  uint16_t type;
  uint16_t len;
  struct in6_addr addr;
  uint32_t preferred_lifetime;
  uint32_t valid_lifetime;
} __attribute__ ((__packed__));;

struct dh6_status {
  uint16_t type;
  uint16_t len;
  uint16_t code;
};

struct dh6_solicit {
  struct dh6_header dh6_hdr;
  struct dh6_clientid dh6_id;
} __attribute__ ((__packed__));

struct dh6_request {
  struct dh6_header dh6_hdr;
  struct dh6_clientid dh6_id;
  struct dh6_ia dh6_ia;
} __attribute__ ((__packed__));

struct dh6_relay_hdr {
  uint8_t type;
  uint8_t hopcount;
  struct in6_addr link_addr;
  struct in6_addr peer_addr;
  uint16_t opt_type;
  uint16_t opt_len;
} __attribute__ ((__packed__));

struct dh6_timers {
  int iaid;
  uint32_t valid_lifetime;
  uint32_t clock;
  uint32_t t1;
  uint32_t t2;
};

#endif
