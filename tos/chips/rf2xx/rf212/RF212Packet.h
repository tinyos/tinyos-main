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

#ifndef __RF212PACKET_H__
#define __RF212PACKET_H__

#include <IEEE154Packet.h>

typedef ieee154_header_t rf212packet_header_t;

typedef nx_struct rf212packet_footer_t
{
	// the time stamp is not recorded here, time stamped messaged cannot have max length
} rf212packet_footer_t;

typedef struct rf212packet_metadata_t
{
	uint8_t flags;
	uint8_t lqi;
	uint8_t power;				// shared between TXPOWER and RSSI
#ifdef LOW_POWER_LISTENING
	uint16_t lpl_sleepint;
#endif
	uint32_t timestamp;
} rf212packet_metadata_t;

enum rf212packet_metadata_flags
{
	RF212PACKET_WAS_ACKED = 0x01,		// PacketAcknowledgements
	RF212PACKET_TIMESTAMP = 0x02,		// PacketTimeStamp
	RF212PACKET_TXPOWER = 0x04,		// PacketTransmitPower
	RF212PACKET_RSSI = 0x08,		// PacketRSSI
	RF212PACKET_TIMESYNC = 0x10,		// PacketTimeSync (update timesync_footer)
	RF212PACKET_LPL_SLEEPINT = 0x20,	// LowPowerListening

	RF212PACKET_CLEAR_METADATA = 0x00,
};

#endif//__RF212PACKET_H__
