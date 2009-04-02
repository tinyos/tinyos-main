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

#ifndef __RF212ACTIVEMESSAGE_H__
#define __RF212ACTIVEMESSAGE_H__

#include <IEEE154PacketLayer.h>
#include <MetadataFlagsLayer.h>
#include <RF212DriverLayer.h>
#include <TimeStampingLayer.h>
#include <LowPowerListeningLayer.h>
#include <PacketLinkLayer.h>

typedef ieee154_header_t rf212packet_header_t;

typedef nx_struct rf212packet_footer_t
{
	// the time stamp is not recorded here, time stamped messaged cannot have max length
} rf212packet_footer_t;

typedef struct rf212packet_metadata_t
{
	flags_metadata_t flags;
	rf212_metadata_t rf212;
	timestamp_metadata_t timestamp;
#ifdef LOW_POWER_LISTENING
	lpl_metadata_t lpl;
#endif
#ifdef PACKET_LINK
	link_metadata_t link;
#endif
} rf212packet_metadata_t;

#endif//__RF212ACTIVEMESSAGE_H__
