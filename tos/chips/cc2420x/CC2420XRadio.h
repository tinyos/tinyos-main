 /*
 * Copyright (c) 2010, Vanderbilt University
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
 * Author: Janos Sallai
 */

#ifndef __CC2420XRADIO_H__
#define __CC2420XRADIO_H__

#include <RadioConfig.h>
#include <TinyosNetworkLayer.h>
#include <Ieee154PacketLayer.h>
#include <ActiveMessageLayer.h>
#include <MetadataFlagsLayer.h>
#include <CC2420XDriverLayer.h>
#include <TimeStampingLayer.h>
#include <LowPowerListeningLayer.h>
#include <PacketLinkLayer.h>

typedef nx_struct cc2420xpacket_header_t
{
	cc2420x_header_t cc2420x;
	ieee154_simple_header_t ieee154;
#ifndef TFRAMES_ENABLED
	network_header_t network;
#endif
#ifndef IEEE154FRAMES_ENABLED
	activemessage_header_t am;
#endif
} cc2420xpacket_header_t;

typedef nx_struct cc2420xpacket_footer_t
{
	// the time stamp is not recorded here, time stamped messaged cannot have max length
} cc2420xpacket_footer_t;

typedef struct cc2420xpacket_metadata_t
{
#ifdef LOW_POWER_LISTENING
	lpl_metadata_t lpl;
#endif
#ifdef PACKET_LINK
	link_metadata_t link;
#endif
	timestamp_metadata_t timestamp;
	flags_metadata_t flags;
	cc2420x_metadata_t cc2420x;
} cc2420xpacket_metadata_t;

#endif//__CC2420XRADIO_H__
