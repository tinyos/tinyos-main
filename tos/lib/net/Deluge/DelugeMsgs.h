/*
 * Copyright (c) 2000-2004 The Regents of the University  of California.  
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
 * - Neither the name of the University of California nor the names of
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
 * Copyright (c) 2007 Johns Hopkins University.
 * All rights reserved.
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 * @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 */

#ifndef __DELUGE_MSGS_H__
#define __DELUGE_MSGS_H__

#include "DelugePageTransfer.h"

enum {
  DELUGE_ADV_NORMAL = 0,
  DELUGE_ADV_ERROR  = 1,
  DELUGE_ADV_PC     = 2,
  DELUGE_ADV_PING   = 3,
  DELUGE_ADV_RESET  = 4,
};

typedef nx_struct DelugeAdvMsg {
  nx_uint16_t    sourceAddr;
  nx_uint8_t     version;    // Deluge Version
  nx_uint8_t     type;
  DelugeObjDesc  objDesc;
  nx_uint8_t     reserved;
} DelugeAdvMsg;

typedef nx_struct DelugeReqMsg {
  nx_uint16_t    dest;
  nx_uint16_t    sourceAddr;
  nx_object_id_t objid;
  nx_page_num_t  pgNum;
  nx_uint8_t     requestedPkts[DELUGET2_PKT_BITVEC_SIZE];
} DelugeReqMsg;

typedef nx_struct DelugeDataMsg {
  nx_object_id_t objid;
  nx_page_num_t  pgNum;
  nx_uint8_t     pktNum;
  nx_uint8_t     data[DELUGET2_PKT_PAYLOAD_SIZE];
} DelugeDataMsg;

#endif
