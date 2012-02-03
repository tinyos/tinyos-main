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

configuration CC2420XRadioC
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
	#define UQ_METADATA_FLAGS	"UQ_CC2420X_METADATA_FLAGS"
	#define UQ_RADIO_ALARM		"UQ_CC2420X_RADIO_ALARM"

// -------- RadioP

	components CC2420XRadioP as RadioP;

#ifdef RADIO_DEBUG
	components AssertC;
#endif

	RadioP.Ieee154PacketLayer -> Ieee154PacketLayerC;
	RadioP.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];
	RadioP.PacketTimeStamp -> TimeStampingLayerC;
	RadioP.CC2420XPacket -> RadioDriverLayerC;

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
	PacketLinkLayerC.PacketAcknowledgements -> SoftwareAckLayerC;
	PacketLinkLayerC -> LowPowerListeningLayerC.Send;
	PacketLinkLayerC -> LowPowerListeningLayerC.Receive;
	PacketLinkLayerC -> LowPowerListeningLayerC.RadioPacket;

// -------- Low Power Listening

#ifdef LOW_POWER_LISTENING
	#warning "*** USING LOW POWER LISTENING LAYER"
	components new LowPowerListeningLayerC();
	LowPowerListeningLayerC.Config -> RadioP;
	LowPowerListeningLayerC.PacketAcknowledgements -> SoftwareAckLayerC;
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

	components new SoftwareAckLayerC();
	SoftwareAckLayerC.AckReceivedFlag -> MetadataFlagsLayerC.PacketFlag[unique(UQ_METADATA_FLAGS)];
	SoftwareAckLayerC.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];
	PacketAcknowledgements = SoftwareAckLayerC;
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

	components CC2420XDriverLayerC as RadioDriverLayerC;
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
