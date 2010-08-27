/**
 * Copyright (c) 2010 Johns Hopkins University.
 * All rights reserved.
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
*/
#ifndef SOURCEROUTING_H
#define SOURCEROUTING_H

#include "AM.h"
#include "message.h"

#define UQ_SRP_CLIENT "SRP.client"

//TODO: pick new/reserved AM ID

enum {
 SRP_MAX_PATHLEN = 10,
 AM_SRP = 23,
};

typedef uint8_t sourceroute_id_t;
typedef nx_uint8_t nx_sourceroute_id_t;

//NOTE it would be good to make the sub-layer address type a little more flexible. The easiest thing is probably to typedef it, but I guess it could also be a type parameter so that a node could run multiple SRP components (for different underlying protocols)
//TODO: should typedef nx_am_addr_t to nx_sr_sub_addr_t or something like that
//TODO: should typedef am_addr_t to sr_sub_addr_t
//NOTE: resolve payload_id vs. sourceroute_id: should be consistent

typedef nx_struct {
  nx_uint8_t sr_len;
  nx_uint8_t hops_left;
  nx_uint8_t seqno;
  nx_sourceroute_id_t payload_id;
  nx_am_addr_t route[SRP_MAX_PATHLEN];
} sr_header_t;

#endif
