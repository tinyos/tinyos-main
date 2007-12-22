/*
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
 * All rights reserved.
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
