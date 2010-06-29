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
#ifndef TRACKFLOWS_H_
#define TRACKFLOWS_H_

#ifndef PC
enum {
  AM_FLOW_ID_MSG = 248,
};

nx_struct flow_id {
  nxle_uint16_t id;
};

nx_struct flow_id_msg {
  nx_struct flow_id flow;
  nxle_uint16_t src;
  nxle_uint16_t dst;
  nxle_uint16_t local_address;
  nxle_uint8_t nxt_hdr;
  nxle_uint8_t n_attempts;
  nx_struct {
    nxle_uint16_t next_hop;
    nxle_uint16_t tx;
  } attempts[3];
};
#else

#include <stdint.h>
struct flow_id {
  uint16_t id;
};


struct flow_id_msg {
  uint16_t flow;
  uint16_t src;
  uint16_t dst;
  uint16_t local_address;
  uint8_t nxt_hdr;
  uint8_t n_attempts;
  struct {
    uint16_t next_hop;
    uint16_t tx;
  } attempts[3];
};
#endif

#endif
