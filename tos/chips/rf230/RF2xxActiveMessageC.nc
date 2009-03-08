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

#include <RadioAlarm.h>

configuration RF2xxActiveMessageC
{
	provides 
	{
		interface SplitControl;

		interface AMSend[am_id_t id];
		interface Receive[am_id_t id];
		interface Receive as Snoop[am_id_t id];

		interface Packet;
		interface AMPacket;
		interface PacketAcknowledgements;
		interface LowPowerListening;
		interface RadioChannel;

		interface PacketField<uint8_t> as PacketLinkQuality;
		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketField<uint8_t> as PacketRSSI;

		interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
		interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
	}
}

implementation
{
	components RF2xxActiveMessageP, RF2xxPacketC, IEEE154PacketC, RadioAlarmC;

#ifdef RF2XX_DEBUG
	components AssertC;
#endif

	RF2xxActiveMessageP.IEEE154Packet -> IEEE154PacketC;
	RF2xxActiveMessageP.Packet -> RF2xxPacketC;
	RF2xxActiveMessageP.RadioAlarm -> RadioAlarmC.RadioAlarm[unique("RadioAlarm")];

	Packet = RF2xxPacketC;
	AMPacket = RF2xxPacketC;
	PacketAcknowledgements = RF2xxPacketC;
	PacketLinkQuality = RF2xxPacketC.PacketLinkQuality;
	PacketTransmitPower = RF2xxPacketC.PacketTransmitPower;
	PacketRSSI = RF2xxPacketC.PacketRSSI;
	PacketTimeStampRadio = RF2xxPacketC;
	PacketTimeStampMilli = RF2xxPacketC;
	LowPowerListening = LowPowerListeningLayerC;
	RadioChannel = MessageBufferLayerC;

	components ActiveMessageLayerC;
#ifdef TFRAMES_ENABLED
	components new DummyLayerC() as IEEE154NetworkLayerC;
#else
	components IEEE154NetworkLayerC;
#endif
#ifdef LOW_POWER_LISTENING
	components LowPowerListeningLayerC;
#else	
	components new DummyLayerC() as LowPowerListeningLayerC;
#endif
	components MessageBufferLayerC;
	components UniqueLayerC;
	components TrafficMonitorLayerC;
#ifdef RF2XX_SLOTTED_MAC
	components SlottedCollisionLayerC as CollisionAvoidanceLayerC;
#else
	components RandomCollisionLayerC as CollisionAvoidanceLayerC;
#endif
	components SoftwareAckLayerC;
	components new DummyLayerC() as CsmaLayerC;
	components RF2xxDriverLayerC;

	SplitControl = LowPowerListeningLayerC;
	AMSend = ActiveMessageLayerC;
	Receive = ActiveMessageLayerC.Receive;
	Snoop = ActiveMessageLayerC.Snoop;

	ActiveMessageLayerC.Config -> RF2xxActiveMessageP;
	ActiveMessageLayerC.AMPacket -> IEEE154PacketC;
	ActiveMessageLayerC.SubSend -> IEEE154NetworkLayerC;
	ActiveMessageLayerC.SubReceive -> IEEE154NetworkLayerC;

	IEEE154NetworkLayerC.SubSend -> UniqueLayerC;
	IEEE154NetworkLayerC.SubReceive -> LowPowerListeningLayerC;

	// the UniqueLayer is wired at two points
	UniqueLayerC.Config -> RF2xxActiveMessageP;
	UniqueLayerC.SubSend -> LowPowerListeningLayerC;

	LowPowerListeningLayerC.SubControl -> MessageBufferLayerC;
	LowPowerListeningLayerC.SubSend -> MessageBufferLayerC;
	LowPowerListeningLayerC.SubReceive -> MessageBufferLayerC;
#ifdef LOW_POWER_LISTENING
	LowPowerListeningLayerC.PacketSleepInterval -> RF2xxPacketC;
	LowPowerListeningLayerC.IEEE154Packet -> IEEE154PacketC;
	LowPowerListeningLayerC.PacketAcknowledgements -> RF2xxPacketC;
#endif

	MessageBufferLayerC.Packet -> RF2xxPacketC;
	MessageBufferLayerC.RadioSend -> TrafficMonitorLayerC;
	MessageBufferLayerC.RadioReceive -> UniqueLayerC;
	MessageBufferLayerC.RadioState -> TrafficMonitorLayerC;

	UniqueLayerC.SubReceive -> TrafficMonitorLayerC;

	TrafficMonitorLayerC.Config -> RF2xxActiveMessageP;
	TrafficMonitorLayerC.SubSend -> CollisionAvoidanceLayerC;
	TrafficMonitorLayerC.SubReceive -> CollisionAvoidanceLayerC;
	TrafficMonitorLayerC.SubState -> RF2xxDriverLayerC;

	CollisionAvoidanceLayerC.Config -> RF2xxActiveMessageP;
	CollisionAvoidanceLayerC.SubSend -> SoftwareAckLayerC;
	CollisionAvoidanceLayerC.SubReceive -> SoftwareAckLayerC;

	SoftwareAckLayerC.Config -> RF2xxActiveMessageP;
	SoftwareAckLayerC.SubSend -> CsmaLayerC;
	SoftwareAckLayerC.SubReceive -> RF2xxDriverLayerC;

	CsmaLayerC.Config -> RF2xxActiveMessageP;
	CsmaLayerC -> RF2xxDriverLayerC.RadioSend;
	CsmaLayerC -> RF2xxDriverLayerC.RadioCCA;

	RF2xxDriverLayerC.RF2xxDriverConfig -> RF2xxActiveMessageP;
}
