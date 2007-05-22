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

#ifndef DELUGEPAGETRANSFER_H
#define DELUGEPAGETRANSFER_H

#include "extra/telosb/TOSBoot_platform.h"

#define AM_DELUGEADVMSG  161
#define AM_DELUGEREQMSG  162
#define AM_DELUGEDATAMSG 163

typedef int32_t object_id_t;
typedef nx_int32_t nx_object_id_t;
typedef uint32_t object_size_t;
typedef nx_uint32_t nx_object_size_t;
typedef uint8_t page_num_t;
typedef nx_uint8_t nx_page_num_t;

enum {
//  DELUGE_PKTS_PER_PAGE    = 48,
//  DELUGE_PKT_PAYLOAD_SIZE = 23,
//  DELUGE_BYTES_PER_PAGE   = (DELUGE_PKTS_PER_PAGE * DELUGE_PKT_PAYLOAD_SIZE),
  DELUGE_PKT_PAYLOAD_SIZE  = TOSH_DATA_LENGTH - sizeof(nx_object_id_t) - sizeof(nx_page_num_t) - sizeof(nx_uint8_t),
  DELUGE_BYTES_PER_PAGE    = 1024,
  DELUGE_PKTS_PER_PAGE     = ((DELUGE_BYTES_PER_PAGE - 1) / DELUGE_PKT_PAYLOAD_SIZE) + 1,
  
  DELUGE_VERSION                    = 2,
  DELUGE_MAX_ADV_PERIOD_LOG2        = 22,
  DELUGE_NUM_NEWDATA_ADVS_REQUIRED  = 2,
  DELUGE_NUM_MIN_ADV_PERIODS        = 2,
  DELUGE_MAX_NUM_REQ_TRIES          = 1,
  DELUGE_REBOOT_DELAY               = 4,
  DELUGE_FAILED_SEND_DELAY          = 16,
  DELUGE_MIN_DELAY                  = 16,
  DELUGE_DATA_OFFSET                = 128,
  DELUGE_IDENT_SIZE                 = 128,
  DELUGE_INVALID_ADDR               = (0x7fffffffL),
  DELUGE_MAX_REQ_DELAY              = (0x1L << (DELUGE_MIN_ADV_PERIOD_LOG2 - 1)),
  DELUGE_NACK_TIMEOUT               = (DELUGE_MAX_REQ_DELAY >> 0x1),
  DELUGE_PKT_BITVEC_SIZE            = (((DELUGE_PKTS_PER_PAGE - 1) / 8) + 1),
  DELUGE_MAX_IMAGE_SIZE             = (128L * 1024L),
  DELUGE_MAX_PAGES                  = 128,
  DELUGE_CRC_SIZE                   = sizeof(uint16_t),
  DELUGE_CRC_BLOCK_SIZE             = DELUGE_MAX_PAGES * DELUGE_CRC_SIZE,
  DELUGE_GOLDEN_IMAGE_NUM           = 0x0,
  DELUGE_INVALID_OBJID              = 0xff,
  DELUGE_INVALID_PKTNUM             = 0xff,
  DELUGE_INVALID_PGNUM              = 0xff,
  
  // From "DelugeMetadata.h"
};

typedef struct DelugeAdvTimer {
  uint32_t timer      : 32;
  uint8_t  periodLog2 : 8;
  bool     overheard  : 1;
  uint8_t  newAdvs    : 7;
} DelugeAdvTimer;

typedef nx_struct DelugeObjDesc {
  nx_object_id_t objid;
  nx_page_num_t  numPgs;         // num pages of complete image
  nx_uint16_t    crc;            // crc for vNum and numPgs
  nx_page_num_t  numPgsComplete; // numPgsComplete in image
  nx_uint8_t     reserved;
} DelugeObjDesc;

#endif
