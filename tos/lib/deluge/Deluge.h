// $Id: Deluge.h,v 1.4 2006-12-12 18:23:28 vlahan Exp $

/*									tab:4
 *
 *
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

#ifndef __DELUGE_H__
#define __DELUGE_H__

#include "DelugeMetadata.h"
#include "TOSBoot.h"

#ifndef DELUGE_NUM_IMAGES
#define DELUGE_NUM_IMAGES 3
#endif

enum {
  DELUGE_VERSION                    = 2,
  DELUGE_MAX_ADV_PERIOD_LOG2        = 20,
  DELUGE_NUM_NEWDATA_ADVS_REQUIRED  = 2,
  DELUGE_NUM_MIN_ADV_PERIODS        = 2,
  DELUGE_MAX_NUM_REQ_TRIES          = 1,
  DELUGE_REBOOT_DELAY               = 4,
  DELUGE_FAILED_SEND_DELAY          = 16,
  DELUGE_MIN_DELAY                  = 16,
  DELUGE_PKTS_PER_PAGE              = 48,
  DELUGE_PKT_PAYLOAD_SIZE           = 23,
  DELUGE_DATA_OFFSET                = 128,
  DELUGE_IDENT_SIZE                 = 128,
  DELUGE_INVALID_ADDR               = (0x7fffffffL),
  DELUGE_MAX_REQ_DELAY              = (0x1L << (DELUGE_MIN_ADV_PERIOD_LOG2-1)),
  DELUGE_NACK_TIMEOUT               = (DELUGE_MAX_REQ_DELAY >> 0x1),
  DELUGE_BYTES_PER_PAGE             = (DELUGE_PKTS_PER_PAGE*DELUGE_PKT_PAYLOAD_SIZE),
  DELUGE_PKT_BITVEC_SIZE            = (((DELUGE_PKTS_PER_PAGE-1) / 8) + 1),
  DELUGE_MAX_IMAGE_SIZE             = (128L*1024L),
  DELUGE_MAX_PAGES                  = 128,
  DELUGE_CRC_SIZE                   = sizeof(uint16_t),
  DELUGE_CRC_BLOCK_SIZE             = DELUGE_MAX_PAGES*DELUGE_CRC_SIZE,
  DELUGE_GOLDEN_IMAGE_NUM           = 0x0,
  DELUGE_INVALID_VNUM               = -1,
  DELUGE_INVALID_IMGNUM             = 0xff,
  DELUGE_INVALID_PKTNUM             = 0xff,
  DELUGE_INVALID_PGNUM              = 0xff,
};

#include "Storage.h"

struct deluge_image_t {
  imgnum_t imageNum;
  volume_id_t volumeId;
};

typedef struct DelugeAdvTimer {
  uint32_t timer      : 32;
  uint8_t  periodLog2 : 8;
  bool     overheard  : 1;
  uint8_t  newAdvs    : 7;
} DelugeAdvTimer;

typedef struct DelugeNodeDesc {
  imgvnum_t vNum;
  uint32_t  uid;
  imgnum_t  imgNum;
  uint8_t   dummy;
  uint16_t  crc;
} DelugeNodeDesc;

enum {
  DELUGE_VOLUME_ID_0 = 0,
#if DELUGE_NUM_IMAGES >= 2
  DELUGE_VOLUME_ID_1 = 1,
#if DELUGE_NUM_IMAGES >= 3
  DELUGE_VOLUME_ID_2 = 2,
#if DELUGE_NUM_IMAGES >= 4
  DELUGE_VOLUME_ID_3 = 3,
#if DELUGE_NUM_IMAGES >= 5
  DELUGE_VOLUME_ID_4 = 4,
#if DELUGE_NUM_IMAGES >= 6
  DELUGE_VOLUME_ID_5 = 5,
#if DELUGE_NUM_IMAGES >= 7
  DELUGE_VOLUME_ID_6 = 6,
#if DELUGE_NUM_IMAGES >= 8
  DELUGE_VOLUME_ID_7 = 7,
#endif
#endif
#endif
#endif
#endif
#endif
#endif
};

static const struct deluge_image_t DELUGE_IMAGES[DELUGE_NUM_IMAGES] = {
  { DELUGE_VOLUME_ID_0, 0xDF },
#if DELUGE_NUM_IMAGES >= 2
  { DELUGE_VOLUME_ID_1, 0xD0 },
#if DELUGE_NUM_IMAGES >= 3
  { DELUGE_VOLUME_ID_2, 0xD1 },
#if DELUGE_NUM_IMAGES >= 4
  { DELUGE_VOLUME_ID_3, 0xD2 },
#if DELUGE_NUM_IMAGES >= 5
  { DELUGE_VOLUME_ID_4, 0xD3 },
#if DELUGE_NUM_IMAGES >= 6
  { DELUGE_VOLUME_ID_5, 0xD4 },
#if DELUGE_NUM_IMAGES >= 7
  { DELUGE_VOLUME_ID_6, 0xD5 },
#if DELUGE_NUM_IMAGES >= 8
  { DELUGE_VOLUME_ID_7, 0xD6 },
#endif
#endif
#endif
#endif
#endif
#endif
#endif
};

#endif
