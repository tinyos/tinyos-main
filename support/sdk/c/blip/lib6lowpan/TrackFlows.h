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
