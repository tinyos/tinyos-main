/*
 * Copyright (c) 2010, Vanderbilt University
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
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 *
 * Author: Miklos Maroti, Janos Sallai
 * Author: Thomas Schmid (adapted to CC2520)
 */

#include <RadioConfig.h>

configuration CC2520RadioC
{
	provides
	{
		interface SplitControl;

#ifndef IEEE154FRAMES_ENABLED
		interface AMSend[am_id_t id];
		interface Receive[am_id_t id];
		interface Receive as Snoop[am_id_t id];
		interface SendNotifier[am_id_t id];

		interface AMPacket;
		interface Packet as PacketForActiveMessage;
#endif

#ifndef TFRAMES_ENABLED
		interface Ieee154Send;
		interface Receive as Ieee154Receive;
		interface SendNotifier as Ieee154Notifier;

		interface Resource as SendResource[uint8_t clint];

		interface Ieee154Packet;
		interface Packet as PacketForIeee154Message;
#endif

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
	components CC2520RadioP, CC2520RadioAlarmC as RadioAlarmC;

#ifdef RADIO_DEBUG_MESSAGES
	components AssertC;
#endif

	CC2520RadioP.Ieee154PacketLayer -> Ieee154PacketLayerC;
	CC2520RadioP.RadioAlarm -> RadioAlarmC.RadioAlarm[unique("RadioAlarm")];
	CC2520RadioP.PacketTimeStamp -> TimeStampingLayerC;
	CC2520RadioP.CC2520Packet -> CC2520DriverLayerC;

// -------- Active Message

#ifndef IEEE154FRAMES_ENABLED
	components CC2520ActiveMessageLayerC as ActiveMessageLayerC;
	ActiveMessageLayerC.Config -> CC2520RadioP;
	ActiveMessageLayerC.SubSend -> AutoResourceAcquireLayerC;
	ActiveMessageLayerC.SubReceive -> TinyosNetworkLayerC.TinyosReceive;
	ActiveMessageLayerC.SubPacket -> TinyosNetworkLayerC.TinyosPacket;

	AMSend = ActiveMessageLayerC;
	Receive = ActiveMessageLayerC.Receive;
	Snoop = ActiveMessageLayerC.Snoop;
	SendNotifier = ActiveMessageLayerC;
	AMPacket = ActiveMessageLayerC;
	PacketForActiveMessage = ActiveMessageLayerC;
#endif

// -------- Automatic RadioSend Resource

#ifndef IEEE154FRAMES_ENABLED
#ifndef TFRAMES_ENABLED
	components new AutoResourceAcquireLayerC();
	AutoResourceAcquireLayerC.Resource -> SendResourceC.Resource[unique(RADIO_SEND_RESOURCE)];
#else
	components new DummyLayerC() as AutoResourceAcquireLayerC;
#endif
	AutoResourceAcquireLayerC.SubSend -> TinyosNetworkLayerC.TinyosSend;
#endif

// -------- RadioSend Resource

#ifndef TFRAMES_ENABLED
	components new SimpleFcfsArbiterC(RADIO_SEND_RESOURCE) as SendResourceC;
	SendResource = SendResourceC;

// -------- Ieee154 Message

	components new Ieee154MessageLayerC();
	Ieee154MessageLayerC.Ieee154PacketLayer -> Ieee154PacketLayerC;
	//Ieee154MessageLayerC.Ieee154Packet -> Ieee154PacketLayerC;
  Ieee154MessageLayerC.SubSend -> TinyosNetworkLayerC.Ieee154Send;
	Ieee154MessageLayerC.SubReceive -> TinyosNetworkLayerC.Ieee154Receive;
	Ieee154MessageLayerC.RadioPacket -> TinyosNetworkLayerC.Ieee154Packet;

	Ieee154Send = Ieee154MessageLayerC;
	Ieee154Receive = Ieee154MessageLayerC;
	Ieee154Notifier = Ieee154MessageLayerC;
	Ieee154Packet = Ieee154PacketLayerC;
	PacketForIeee154Message = Ieee154MessageLayerC;
#endif

// -------- Tinyos Network

	components new TinyosNetworkLayerC();

	TinyosNetworkLayerC.SubSend -> UniqueLayerC;
	TinyosNetworkLayerC.SubReceive -> LowPowerListeningLayerC;
	TinyosNetworkLayerC.SubPacket -> Ieee154PacketLayerC;

// -------- IEEE 802.15.4 Packet

	components CC2520Ieee154PacketLayerC as Ieee154PacketLayerC;
	Ieee154PacketLayerC.SubPacket -> LowPowerListeningLayerC;

// -------- UniqueLayer Send part (wired twice)

	components CC2520UniqueLayerC as UniqueLayerC;
	UniqueLayerC.Config -> CC2520RadioP;
	UniqueLayerC.SubSend -> LowPowerListeningLayerC;

// -------- Low Power Listening

#ifdef LOW_POWER_LISTENING
	#warning "*** USING LOW POWER LISTENING LAYER"
	components CC2520LowPowerListeningLayerC as LowPowerListeningLayerC;
	LowPowerListeningLayerC.Config -> CC2520RadioP;
#ifdef CC2520_HARDWARE_ACK
	LowPowerListeningLayerC.PacketAcknowledgements -> CC2520DriverLayerC;
#else
	LowPowerListeningLayerC.PacketAcknowledgements -> SoftwareAckLayerC;
#endif
#else
	components CC2520LowPowerListeningDummyC as LowPowerListeningLayerC;
#endif
	LowPowerListeningLayerC.SubControl -> MessageBufferLayerC;
	LowPowerListeningLayerC.SubSend -> PacketLinkLayerC;
	LowPowerListeningLayerC.SubReceive -> MessageBufferLayerC;
	LowPowerListeningLayerC.SubPacket -> PacketLinkLayerC;
	SplitControl = LowPowerListeningLayerC;
	LowPowerListening = LowPowerListeningLayerC;

// -------- Packet Link

#ifdef PACKET_LINK
	components CC2520PacketLinkLayerC as PacketLinkLayerC;
	PacketLink = PacketLinkLayerC;
#ifdef CC2520_HARDWARE_ACK
	PacketLinkLayerC.PacketAcknowledgements -> CC2520DriverLayerC;
#else
	PacketLinkLayerC.PacketAcknowledgements -> SoftwareAckLayerC;
#endif
#else
	components new DummyLayerC() as PacketLinkLayerC;
#endif
	PacketLinkLayerC.SubSend -> MessageBufferLayerC;
	PacketLinkLayerC.SubPacket -> TimeStampingLayerC;

// -------- MessageBuffer

	components CC2520MessageBufferLayerC as MessageBufferLayerC;
	MessageBufferLayerC.RadioSend -> TrafficMonitorLayerC;
	MessageBufferLayerC.RadioReceive -> UniqueLayerC;
	MessageBufferLayerC.RadioState -> TrafficMonitorLayerC;
	RadioChannel = MessageBufferLayerC;

// -------- UniqueLayer receive part (wired twice)

	UniqueLayerC.SubReceive -> TrafficMonitorLayerC;

// -------- Traffic Monitor

#ifdef TRAFFIC_MONITOR
	components CC2520TrafficMonitorLayerC as TrafficMonitorLayerC;
#else
	components new DummyLayerC() as TrafficMonitorLayerC;
#endif
	TrafficMonitorLayerC.Config -> CC2520RadioP;
	TrafficMonitorLayerC -> CollisionAvoidanceLayerC.RadioSend;
	TrafficMonitorLayerC -> CollisionAvoidanceLayerC.RadioReceive;
	TrafficMonitorLayerC -> CC2520DriverLayerC.RadioState;

// -------- CollisionAvoidance

#ifdef SLOTTED_MAC
	components CC2520SlottedCollisionLayerC as CollisionAvoidanceLayerC;
#else
	components CC2520RandomCollisionLayerC as CollisionAvoidanceLayerC;
#endif
	CollisionAvoidanceLayerC.Config -> CC2520RadioP;
#ifdef CC2520_HARDWARE_ACK
	CollisionAvoidanceLayerC.SubSend -> CsmaLayerC;
	CollisionAvoidanceLayerC.SubReceive -> CC2520DriverLayerC;
#else
	CollisionAvoidanceLayerC.SubSend -> SoftwareAckLayerC;
	CollisionAvoidanceLayerC.SubReceive -> SoftwareAckLayerC;
#endif

// -------- SoftwareAcknowledgement

#ifndef CC2520_HARDWARE_ACK
	components CC2520SoftwareAckLayerC as SoftwareAckLayerC;
	SoftwareAckLayerC.Config -> CC2520RadioP;
	SoftwareAckLayerC.SubSend -> CsmaLayerC;
	SoftwareAckLayerC.SubReceive -> CC2520DriverLayerC;
  PacketAcknowledgements = SoftwareAckLayerC;
  //PacketAcknowledgements = CC2520DriverLayerC;
#endif

// -------- Carrier Sense

	components new DummyLayerC() as CsmaLayerC;
	CsmaLayerC.Config -> CC2520RadioP;
	CsmaLayerC -> CC2520DriverLayerC.RadioSend;
	CsmaLayerC -> CC2520DriverLayerC.RadioCCA;

// -------- TimeStamping

	components CC2520TimeStampingLayerC as TimeStampingLayerC;
	TimeStampingLayerC.LocalTimeRadio -> CC2520DriverLayerC;
	TimeStampingLayerC.SubPacket -> MetadataFlagsLayerC;
	PacketTimeStampRadio = TimeStampingLayerC;
	PacketTimeStampMilli = TimeStampingLayerC;

// -------- MetadataFlags

	components CC2520MetadataFlagsLayerC as MetadataFlagsLayerC;
	MetadataFlagsLayerC.SubPacket -> CC2520DriverLayerC;

// -------- CC2520 Driver

#ifdef CC2520_HARDWARE_ACK
	components CC2520DriverHwAckC as CC2520DriverLayerC;
	PacketAcknowledgements = CC2520DriverLayerC;
	CC2520DriverLayerC.Ieee154PacketLayer -> Ieee154PacketLayerC;
#else
	components CC2520DriverLayerC;
#endif
	CC2520DriverLayerC.Config -> CC2520RadioP;
	CC2520DriverLayerC.PacketTimeStamp -> TimeStampingLayerC;
	PacketTransmitPower = CC2520DriverLayerC.PacketTransmitPower;
	PacketLinkQuality = CC2520DriverLayerC.PacketLinkQuality;
	PacketRSSI = CC2520DriverLayerC.PacketRSSI;
	LocalTimeRadio = CC2520DriverLayerC;


}
