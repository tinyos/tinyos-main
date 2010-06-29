/*
 * Copyright (c) 2007, Vanderbilt University
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
 * - Neither the name of the copyright holder nor the names of
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
 * Author: Miklos Maroti
 */

#ifndef __IEEE154PACKETLAYER_H__
#define __IEEE154PACKETLAYER_H__

typedef nx_struct ieee154_header_t
{
	nxle_uint16_t fcf;
	nxle_uint8_t dsn;
	nxle_uint16_t destpan;
	nxle_uint16_t dest;
	nxle_uint16_t src;
} ieee154_header_t;

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

#endif//__IEEE154PACKETLAYER_H__
