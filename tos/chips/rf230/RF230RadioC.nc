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

#include <RadioConfig.h>

configuration RF230RadioC
{
	provides 
	{
		interface SplitControl;

#ifndef IEEE154FRAMES_ENABLED
		interface AMSend[am_id_t id];
		interface Receive[am_id_t id];
		interface Receive as Snoop[am_id_t id];
		interface SendNotifier[am_id_t id];

		// for TOSThreads
		interface Receive as ReceiveDefault[am_id_t id];
		interface Receive as SnoopDefault[am_id_t id];

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
		interface PacketLink;

#ifdef TRAFFIC_MONITOR
		interface TrafficMonitor;
#endif

		interface RadioChannel;

		interface PacketField<uint8_t> as PacketLinkQuality;
		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketField<uint8_t> as PacketRSSI;
		interface LinkPacketMetadata;

		interface LocalTime<TRadio> as LocalTimeRadio;
		interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
		interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
	}
}

implementation
{
	#define UQ_METADATA_FLAGS	"UQ_RF230_METADATA_FLAGS"
	#define UQ_RADIO_ALARM		"UQ_RF230_RADIO_ALARM"

// -------- RadioP

	components RF230RadioP as RadioP;

#ifdef RADIO_DEBUG
	components AssertC;
#endif

	RadioP.Ieee154PacketLayer -> Ieee154PacketLayerC;
	RadioP.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];
	RadioP.PacketTimeStamp -> TimeStampingLayerC;
	RadioP.RF230Packet -> RadioDriverLayerC;

// -------- RadioAlarm

	components new RadioAlarmC();
	RadioAlarmC.Alarm -> RadioDriverLayerC;

// -------- Active Message

#ifndef IEEE154FRAMES_ENABLED
	components new ActiveMessageLayerC();
	ActiveMessageLayerC.Config -> RadioP;
	ActiveMessageLayerC.SubSend -> AutoResourceAcquireLayerC;
	ActiveMessageLayerC.SubReceive -> TinyosNetworkLayerC.TinyosReceive;
	ActiveMessageLayerC.SubPacket -> TinyosNetworkLayerC.TinyosPacket;

	AMSend = ActiveMessageLayerC;
	Receive = ActiveMessageLayerC.Receive;
	Snoop = ActiveMessageLayerC.Snoop;
	SendNotifier = ActiveMessageLayerC;
	AMPacket = ActiveMessageLayerC;
	PacketForActiveMessage = ActiveMessageLayerC;

	ReceiveDefault = ActiveMessageLayerC.ReceiveDefault;
	SnoopDefault = ActiveMessageLayerC.SnoopDefault;
#endif

// -------- Automatic RadioSend Resource

#ifndef IEEE154FRAMES_ENABLED
#ifndef TFRAMES_ENABLED
	components new AutoResourceAcquireLayerC();
	AutoResourceAcquireLayerC.Resource -> SendResourceC.Resource[unique(RADIO_SEND_RESOURCE)];
#else
	components new DummyLayerC() as AutoResourceAcquireLayerC;
#endif
	AutoResourceAcquireLayerC -> TinyosNetworkLayerC.TinyosSend;
#endif

// -------- RadioSend Resource

#ifndef TFRAMES_ENABLED
	components new SimpleFcfsArbiterC(RADIO_SEND_RESOURCE) as SendResourceC;
	SendResource = SendResourceC;

// -------- Ieee154 Message

	components new Ieee154MessageLayerC();
	Ieee154MessageLayerC.Ieee154PacketLayer -> Ieee154PacketLayerC;
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
	TinyosNetworkLayerC.SubReceive -> PacketLinkLayerC;
	TinyosNetworkLayerC.SubPacket -> Ieee154PacketLayerC;

// -------- IEEE 802.15.4 Packet

	components new Ieee154PacketLayerC();
	Ieee154PacketLayerC.SubPacket -> PacketLinkLayerC;

// -------- UniqueLayer Send part (wired twice)

	components new UniqueLayerC();
	UniqueLayerC.Config -> RadioP;
	UniqueLayerC.SubSend -> PacketLinkLayerC;

// -------- Packet Link

	components new PacketLinkLayerC();
	PacketLink = PacketLinkLayerC;
#ifdef RF230_HARDWARE_ACK
	PacketLinkLayerC.PacketAcknowledgements -> RadioDriverLayerC;
#else
	PacketLinkLayerC.PacketAcknowledgements -> SoftwareAckLayerC;
#endif
	PacketLinkLayerC -> LowPowerListeningLayerC.Send;
	PacketLinkLayerC -> LowPowerListeningLayerC.Receive;
	PacketLinkLayerC -> LowPowerListeningLayerC.RadioPacket;

// -------- Low Power Listening

#ifdef LOW_POWER_LISTENING
	#warning "*** USING LOW POWER LISTENING LAYER"
	components new LowPowerListeningLayerC();
	LowPowerListeningLayerC.Config -> RadioP;
#ifdef RF230_HARDWARE_ACK
	LowPowerListeningLayerC.PacketAcknowledgements -> RadioDriverLayerC;
#else
	LowPowerListeningLayerC.PacketAcknowledgements -> SoftwareAckLayerC;
#endif
#else
	components new LowPowerListeningDummyC() as LowPowerListeningLayerC;
#endif
	LowPowerListeningLayerC.SubControl -> MessageBufferLayerC;
	LowPowerListeningLayerC.SubSend -> MessageBufferLayerC;
	LowPowerListeningLayerC.SubReceive -> MessageBufferLayerC;
	LowPowerListeningLayerC.SubPacket -> TimeStampingLayerC;
	SplitControl = LowPowerListeningLayerC;
	LowPowerListening = LowPowerListeningLayerC;

// -------- MessageBuffer

	components new MessageBufferLayerC();
	MessageBufferLayerC.RadioSend -> CollisionAvoidanceLayerC;
	MessageBufferLayerC.RadioReceive -> UniqueLayerC;
	MessageBufferLayerC.RadioState -> TrafficMonitorLayerC;
	RadioChannel = MessageBufferLayerC;

// -------- UniqueLayer receive part (wired twice)

	UniqueLayerC.SubReceive -> CollisionAvoidanceLayerC;

// -------- CollisionAvoidance

#ifdef SLOTTED_MAC
	components new SlottedCollisionLayerC() as CollisionAvoidanceLayerC;
#else
	components new RandomCollisionLayerC() as CollisionAvoidanceLayerC;
#endif
	CollisionAvoidanceLayerC.Config -> RadioP;
	CollisionAvoidanceLayerC.SubSend -> SoftwareAckLayerC;
	CollisionAvoidanceLayerC.SubReceive -> SoftwareAckLayerC;
	CollisionAvoidanceLayerC.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];

// -------- SoftwareAcknowledgement

#ifndef RF230_HARDWARE_ACK
	components new SoftwareAckLayerC();
	SoftwareAckLayerC.AckReceivedFlag -> MetadataFlagsLayerC.PacketFlag[unique(UQ_METADATA_FLAGS)];
	SoftwareAckLayerC.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];
	PacketAcknowledgements = SoftwareAckLayerC;
#else
	components new DummyLayerC() as SoftwareAckLayerC;
#endif
	SoftwareAckLayerC.Config -> RadioP;
	SoftwareAckLayerC.SubSend -> CsmaLayerC;
	SoftwareAckLayerC.SubReceive -> CsmaLayerC;

// -------- Carrier Sense

	components new DummyLayerC() as CsmaLayerC;
	CsmaLayerC.Config -> RadioP;
	CsmaLayerC -> TrafficMonitorLayerC.RadioSend;
	CsmaLayerC -> TrafficMonitorLayerC.RadioReceive;
	CsmaLayerC -> RadioDriverLayerC.RadioCCA;

// -------- TimeStamping

	components new TimeStampingLayerC();
	TimeStampingLayerC.LocalTimeRadio -> RadioDriverLayerC;
	TimeStampingLayerC.SubPacket -> MetadataFlagsLayerC;
	PacketTimeStampRadio = TimeStampingLayerC;
	PacketTimeStampMilli = TimeStampingLayerC;
	TimeStampingLayerC.TimeStampFlag -> MetadataFlagsLayerC.PacketFlag[unique(UQ_METADATA_FLAGS)];

// -------- MetadataFlags

	components new MetadataFlagsLayerC();
	MetadataFlagsLayerC.SubPacket -> RadioDriverLayerC;

// -------- Traffic Monitor

#ifdef TRAFFIC_MONITOR
	components new TrafficMonitorLayerC();
	TrafficMonitor = TrafficMonitorLayerC;
#else
	components new DummyLayerC() as TrafficMonitorLayerC;
#endif
	TrafficMonitorLayerC.Config -> RadioP;
	TrafficMonitorLayerC -> RadioDriverLayerC.RadioSend;
	TrafficMonitorLayerC -> RadioDriverLayerC.RadioReceive;
	TrafficMonitorLayerC -> RadioDriverLayerC.RadioState;

// -------- Driver

#ifdef RF230_HARDWARE_ACK
	components RF230DriverHwAckC as RadioDriverLayerC;
	PacketAcknowledgements = RadioDriverLayerC;
	RadioDriverLayerC.Ieee154PacketLayer -> Ieee154PacketLayerC;
	RadioDriverLayerC.AckReceivedFlag -> MetadataFlagsLayerC.PacketFlag[unique(UQ_METADATA_FLAGS)];
#else
	components RF230DriverLayerC as RadioDriverLayerC;
#endif
	RadioDriverLayerC.Config -> RadioP;
	RadioDriverLayerC.PacketTimeStamp -> TimeStampingLayerC;
	PacketTransmitPower = RadioDriverLayerC.PacketTransmitPower;
	PacketLinkQuality = RadioDriverLayerC.PacketLinkQuality;
	PacketRSSI = RadioDriverLayerC.PacketRSSI;
	LinkPacketMetadata = RadioDriverLayerC;
	LocalTimeRadio = RadioDriverLayerC;

	RadioDriverLayerC.TransmitPowerFlag -> MetadataFlagsLayerC.PacketFlag[unique(UQ_METADATA_FLAGS)];
	RadioDriverLayerC.RSSIFlag -> MetadataFlagsLayerC.PacketFlag[unique(UQ_METADATA_FLAGS)];
	RadioDriverLayerC.TimeSyncFlag -> MetadataFlagsLayerC.PacketFlag[unique(UQ_METADATA_FLAGS)];
	RadioDriverLayerC.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];
}
