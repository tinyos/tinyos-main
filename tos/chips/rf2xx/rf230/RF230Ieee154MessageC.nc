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

#include <RadioConfig.h>

configuration RF230Ieee154MessageC
{
	provides 
	{
		interface SplitControl;

		interface Ieee154Send;
		interface Receive as Ieee154Receive;
		interface Ieee154Packet;
		interface Packet;
		interface PacketAcknowledgements;
		interface LowPowerListening;
		interface PacketLink;
		interface SendNotifier;

		interface RadioChannel;

		interface PacketField<uint8_t> as PacketLinkQuality;
		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketField<uint8_t> as PacketRSSI;

		interface LocalTime<TRadio> as LocalTimeRadio;
		interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
		interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
	}
}

implementation
{
	components RF230ActiveMessageP, RadioAlarmC;

#ifdef RADIO_DEBUG
	components AssertC;
#endif

	RF230ActiveMessageP.IEEE154MessageLayer -> IEEE154MessageLayerC;
	RF230ActiveMessageP.RadioAlarm -> RadioAlarmC.RadioAlarm[unique("RadioAlarm")];
	RF230ActiveMessageP.PacketTimeStamp -> TimeStampingLayerC;
	RF230ActiveMessageP.RF230Packet -> RF230DriverLayerC;

// -------- IEEE154 Message

	components IEEE154MessageLayerC;
	IEEE154MessageLayerC.SubPacket -> LowPowerListeningLayerC;
	IEEE154MessageLayerC.SubSend -> UniqueLayerC;
	IEEE154MessageLayerC.SubReceive -> LowPowerListeningLayerC;
	Ieee154Send = IEEE154MessageLayerC;
	Packet = IEEE154MessageLayerC;
	Ieee154Receive = IEEE154MessageLayerC;
	Ieee154Packet = IEEE154MessageLayerC;
	SendNotifier = IEEE154MessageLayerC;

// -------- UniqueLayer Send part (wired twice)

	components UniqueLayerC;
	UniqueLayerC.Config -> RF230ActiveMessageP;
	UniqueLayerC.SubSend -> LowPowerListeningLayerC;

// -------- Low Power Listening 

#ifdef LOW_POWER_LISTENING
	components LowPowerListeningLayerC;
	LowPowerListeningLayerC.Config -> RF230ActiveMessageP;
	LowPowerListeningLayerC.PacketAcknowledgements -> SoftwareAckLayerC;
#else	
	components LowPowerListeningDummyC as LowPowerListeningLayerC;
#endif
	LowPowerListeningLayerC.SubControl -> MessageBufferLayerC;
	LowPowerListeningLayerC.SubSend -> PacketLinkLayerC;
	LowPowerListeningLayerC.SubReceive -> MessageBufferLayerC;
	LowPowerListeningLayerC.SubPacket -> PacketLinkLayerC;
	SplitControl = LowPowerListeningLayerC;
	LowPowerListening = LowPowerListeningLayerC;

// -------- Packet Link

	components PacketLinkLayerC;
	PacketLink = PacketLinkLayerC;
	PacketLinkLayerC.PacketAcknowledgements -> SoftwareAckLayerC;
	PacketLinkLayerC.SubSend -> MessageBufferLayerC;
	PacketLinkLayerC.SubPacket -> TimeStampingLayerC;

// -------- MessageBuffer

	components MessageBufferLayerC;
	MessageBufferLayerC.RadioSend -> CollisionAvoidanceLayerC;
	MessageBufferLayerC.RadioReceive -> UniqueLayerC;
	MessageBufferLayerC.RadioState -> RF230DriverLayerC;
	RadioChannel = MessageBufferLayerC;

// -------- UniqueLayer receive part (wired twice)

	UniqueLayerC.SubReceive -> CollisionAvoidanceLayerC;

// -------- CollisionAvoidance

#ifdef SLOTTED_MAC
	components SlottedCollisionLayerC as CollisionAvoidanceLayerC;
#else
	components RandomCollisionLayerC as CollisionAvoidanceLayerC;
#endif
	CollisionAvoidanceLayerC.Config -> RF230ActiveMessageP;
	CollisionAvoidanceLayerC.SubSend -> SoftwareAckLayerC;
	CollisionAvoidanceLayerC.SubReceive -> SoftwareAckLayerC;

// -------- SoftwareAcknowledgement

	components SoftwareAckLayerC;
	SoftwareAckLayerC.Config -> RF230ActiveMessageP;
	SoftwareAckLayerC.SubSend -> CsmaLayerC;
	SoftwareAckLayerC.SubReceive -> RF230DriverLayerC;
	PacketAcknowledgements = SoftwareAckLayerC;

// -------- Carrier Sense

	components new DummyLayerC() as CsmaLayerC;
	CsmaLayerC.Config -> RF230ActiveMessageP;
	CsmaLayerC -> RF230DriverLayerC.RadioSend;
	CsmaLayerC -> RF230DriverLayerC.RadioCCA;

// -------- TimeStamping

	components TimeStampingLayerC;
	TimeStampingLayerC.LocalTimeRadio -> RF230DriverLayerC;
	TimeStampingLayerC.SubPacket -> MetadataFlagsLayerC;
	PacketTimeStampRadio = TimeStampingLayerC;
	PacketTimeStampMilli = TimeStampingLayerC;

// -------- MetadataFlags

	components MetadataFlagsLayerC;
	MetadataFlagsLayerC.SubPacket -> RF230DriverLayerC;

// -------- RF230 Driver

	components RF230DriverLayerC;
	RF230DriverLayerC.Config -> RF230ActiveMessageP;
	RF230DriverLayerC.PacketTimeStamp -> TimeStampingLayerC;
	PacketTransmitPower = RF230DriverLayerC.PacketTransmitPower;
	PacketLinkQuality = RF230DriverLayerC.PacketLinkQuality;
	PacketRSSI = RF230DriverLayerC.PacketRSSI;
	LocalTimeRadio = RF230DriverLayerC;
}
