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

#ifndef __DEFAULTMAC_H__
#define __DEFAULTMAC_H__

#include <IEEE154Packet.h>

typedef ieee154_header_t defaultmac_header_t;

typedef nx_struct defaultmac_metadata_t
{
	nx_uint8_t flags;
	nx_uint8_t lqi;
	nx_uint16_t timestamp;
} defaultmac_metadata_t;

enum defaultmac_metadata_flags
{
	DEFAULTMAC_WAS_ACKED = 0x01,
	DEFAULTMAC_SCHEDULED_TX = 0x02,
};

/* This is the default value of the TX_PWR field of the PHY_TX_PWR register. */
#ifndef RF230_DEF_RFPOWER
#define RF230_DEF_RFPOWER	0
#endif

/* This is the default value of the CHANNEL field of the PHY_CC_CCA register. */
#ifndef RF230_DEF_CHANNEL
#define RF230_DEF_CHANNEL	11
#endif

#endif//__DEFAULTMAC_H__
