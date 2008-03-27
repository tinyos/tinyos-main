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

#ifndef __DEFAULTPACKET_H__
#define __DEFAULTPACKET_H__

#include <IEEE154Packet.h>
#include <TimeSyncMessage.h>

typedef ieee154_header_t defpacket_header_t;

typedef nx_struct defpacket_footer_t
{
	timesync_footer_t timesync;
} defpacket_footer_t;

typedef nx_struct defpacket_metadata_t
{
	nx_uint8_t flags;
	nx_uint8_t lqi;
	nx_uint16_t timestamp;
} defpacket_metadata_t;

enum defpacket_metadata_flags
{
	DEFPACKET_WAS_ACKED = 0x01,
	DEFPACKET_TIMESTAMP = 0x02,

	DEFPACKET_CLEAR_METADATA = 0x00,
};

#endif//__DEFAULTPACKET_H__
