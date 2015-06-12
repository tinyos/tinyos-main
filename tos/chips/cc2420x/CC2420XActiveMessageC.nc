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
 * Author: Janos Sallai, Miklos Maroti
 */
 
#include <RadioConfig.h>

#ifdef IEEE154FRAMES_ENABLED
#error "You cannot use CC2420XActiveMessageC with IEEE154FRAMES_ENABLED defined"
#endif

configuration CC2420XActiveMessageC
{
	provides 
	{
		interface SplitControl;

		interface AMSend[am_id_t id];
		interface Receive[am_id_t id];
		interface Receive as Snoop[am_id_t id];
		interface SendNotifier[am_id_t id];
		interface Packet;
		interface AMPacket;

		interface PacketAcknowledgements;
		interface LowPowerListening;
		interface PacketLink;

		interface RadioChannel;

		interface PacketField<uint8_t> as PacketLinkQuality;
		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketField<uint8_t> as PacketRSSI;
		interface LinkPacketMetadata;

		interface LocalTime<TRadio> as LocalTimeRadio;
		interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
		interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;

		interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;
	}

	uses
	{
		interface PacketTimeStamp<T32khz, uint32_t> as UnimplementedPacketTimeStamp32khz;
	}
}

implementation
{
	components CC2420XRadioC as RadioC;

	SplitControl = RadioC;

	AMSend = RadioC;
	Receive = RadioC.Receive;
	Snoop = RadioC.Snoop;
	SendNotifier = RadioC;
	Packet = RadioC.PacketForActiveMessage;
	AMPacket = RadioC;

	PacketAcknowledgements = RadioC;
	LowPowerListening = RadioC;
	PacketLink = RadioC;
	RadioChannel = RadioC;

	PacketLinkQuality = RadioC.PacketLinkQuality;
	PacketTransmitPower = RadioC.PacketTransmitPower;
	PacketRSSI = RadioC.PacketRSSI;
	LinkPacketMetadata = RadioC;

	LocalTimeRadio = RadioC;
	PacketTimeStampMilli = RadioC;
	PacketTimeStampRadio = RadioC;

	PacketTimeStamp32khz = UnimplementedPacketTimeStamp32khz;
}
