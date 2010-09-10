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
 /*
 *
 * @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu>
 * @version $Revision: 1.1 $ $Date: 2009/08/19 17:54:35 $
 */

#ifndef __IEEE154_H__
#define __IEEE154_H__

#include "IeeeEui64.h"

#define IEEE154_SEND_CLIENT "IEEE154_SEND_CLIENT"

typedef uint16_t       ieee154_panid_t;
typedef uint16_t       ieee154_saddr_t;
typedef ieee_eui64_t   ieee154_laddr_t;

typedef struct {
  uint8_t ieee_mode:2;
  union {
    ieee154_saddr_t saddr;
    ieee154_laddr_t laddr;
  } ieee_addr;
} ieee154_addr_t;
#define i_saddr ieee_addr.saddr
#define i_laddr ieee_addr.laddr

enum {
  IEEE154_BROADCAST_ADDR = 0xffff,
  IEEE154_LINK_MTU   = 127,
};

struct ieee154_frame_addr {
  ieee154_addr_t ieee_src;
  ieee154_addr_t ieee_dst;
  ieee154_panid_t ieee_dstpan;
};

enum {
  IEEE154_MIN_HDR_SZ = 6,
};

#if 0
struct ieee154_header_base {
  uint8_t length;
  uint16_t fcf;
  uint8_t dsn;
  uint16_t destpan;
} __attribute__((packed));
#else
#endif

enum ieee154_fcf_enums {
  IEEE154_FCF_FRAME_TYPE = 0,
  IEEE154_FCF_SECURITY_ENABLED = 3,
  IEEE154_FCF_FRAME_PENDING = 4,
  IEEE154_FCF_ACK_REQ = 5,
  IEEE154_FCF_INTRAPAN = 6,
  IEEE154_FCF_DEST_ADDR_MODE = 10,
  IEEE154_FCF_SRC_ADDR_MODE = 14,
};

enum ieee154_fcf_type_enums {
  IEEE154_TYPE_BEACON = 0,
  IEEE154_TYPE_DATA = 1,
  IEEE154_TYPE_ACK = 2,
  IEEE154_TYPE_MAC_CMD = 3,
};

enum iee154_fcf_addr_mode_enums {
  IEEE154_ADDR_NONE = 0,
  IEEE154_ADDR_SHORT = 2,
  IEEE154_ADDR_EXT = 3,
};

#endif
