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

configuration RF230ActiveMessageC
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

#ifdef PACKET_LINK
		interface PacketLink;
#endif

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
	RF230ActiveMessageP.ActiveMessagePacket -> ActiveMessageLayerC;
	RF230ActiveMessageP.RF230Packet -> RF230DriverLayerC;

// -------- Active Message

	components ActiveMessageLayerC;
	ActiveMessageLayerC.Config -> RF230ActiveMessageP;
	ActiveMessageLayerC.SubSend -> LowpanNetworkLayerC;
	ActiveMessageLayerC.SubReceive -> LowpanNetworkLayerC;
	ActiveMessageLayerC.SubPacket ->LowpanNetworkLayerC;
	AMSend = ActiveMessageLayerC;
	Packet = ActiveMessageLayerC;
	Receive = ActiveMessageLayerC.Receive;
	Snoop = ActiveMessageLayerC.Snoop;
	AMPacket = ActiveMessageLayerC;
	SendNotifier = ActiveMessageLayerC;

// -------- Lowpan Network

#ifdef TFRAMES_ENABLED
	components new DummyLayerC() as LowpanNetworkLayerC;
#else
	components LowpanNetworkLayerC;
#endif
	LowpanNetworkLayerC.SubSend -> UniqueLayerC;
	LowpanNetworkLayerC.SubReceive -> LowPowerListeningLayerC;
	LowpanNetworkLayerC.SubPacket -> IEEE154MessageLayerC;

// -------- IEEE154 Message

	components IEEE154MessageLayerC;
	IEEE154MessageLayerC.SubPacket -> LowPowerListeningLayerC;

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

#ifdef PACKET_LINK
	components PacketLinkLayerC;
	PacketLink = PacketLinkLayerC;
	PacketLinkLayerC.PacketAcknowledgements -> SoftwareAckLayerC;
#else
	components new DummyLayerC() as PacketLinkLayerC;
#endif
	PacketLinkLayerC.SubSend -> MessageBufferLayerC;
	PacketLinkLayerC.SubPacket -> TimeStampingLayerC;

// -------- MessageBuffer

	components MessageBufferLayerC;
	MessageBufferLayerC.Packet -> ActiveMessageLayerC;
	MessageBufferLayerC.RadioSend -> TrafficMonitorLayerC;
	MessageBufferLayerC.RadioReceive -> UniqueLayerC;
	MessageBufferLayerC.RadioState -> TrafficMonitorLayerC;
	RadioChannel = MessageBufferLayerC;

// -------- UniqueLayer receive part (wired twice)

	UniqueLayerC.SubReceive -> TrafficMonitorLayerC;

// -------- Traffic Monitor

	components TrafficMonitorLayerC;
	TrafficMonitorLayerC.Config -> RF230ActiveMessageP;
	TrafficMonitorLayerC.SubSend -> CollisionAvoidanceLayerC;
	TrafficMonitorLayerC.SubReceive -> CollisionAvoidanceLayerC;
	TrafficMonitorLayerC.SubState -> RF230DriverLayerC;

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
