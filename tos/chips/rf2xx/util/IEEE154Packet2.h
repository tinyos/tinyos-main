/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 */

#ifndef __IEEE154PACKET2_H__
#define __IEEE154PACKET2_H__

typedef nx_struct ieee154_header_t
{
	nxle_uint8_t length;
	nxle_uint16_t fcf;
	nxle_uint8_t dsn;
	nxle_uint16_t destpan;
	nxle_uint16_t dest;
	nxle_uint16_t src;

// I-Frame 6LowPAN interoperability byte
#ifndef TFRAMES_ENABLED	
	nxle_uint8_t network;
#endif

	nxle_uint8_t type;
} ieee154_header_t;

// the actual radio driver might not use this
typedef nx_struct ieee154_footer_t
{ 
	nxle_uint16_t crc;
} ieee154_footer_t;

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
	IEEE154_TYPE_MASK = 7,
};

enum iee154_fcf_addr_mode_enums {
	IEEE154_ADDR_NONE = 0,
	IEEE154_ADDR_SHORT = 2,
	IEEE154_ADDR_EXT = 3,
	IEEE154_ADDR_MASK = 3,
};

#endif//__IEEE154PACKET2_H__
