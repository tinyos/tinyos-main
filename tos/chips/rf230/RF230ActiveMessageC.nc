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

#include <HplRF230.h>

configuration RF230ActiveMessageC
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

		interface PacketField<uint8_t> as PacketLinkQuality;
		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketField<uint8_t> as PacketRSSI;

		interface PacketTimeStamp<TRF230, uint32_t> as PacketTimeStampRadio;
		interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
	}
}

implementation
{
	components RF230ActiveMessageP, RF230PacketC, IEEE154PacketC, RadioAlarmC;

#ifdef RF230_DEBUG
	components AssertC;
#endif

	RF230ActiveMessageP.IEEE154Packet -> IEEE154PacketC;
	RF230ActiveMessageP.Packet -> RF230PacketC;
	RF230ActiveMessageP.RadioAlarm -> RadioAlarmC.RadioAlarm[unique("RadioAlarm")];

	Packet = RF230PacketC;
	AMPacket = RF230PacketC;
	PacketAcknowledgements = RF230PacketC;
	PacketLinkQuality = RF230PacketC.PacketLinkQuality;
	PacketTransmitPower = RF230PacketC.PacketTransmitPower;
	PacketRSSI = RF230PacketC.PacketRSSI;
	PacketTimeStampRadio = RF230PacketC;
	PacketTimeStampMilli = RF230PacketC;
	LowPowerListening = LowPowerListeningLayerC;

	components ActiveMessageLayerC;
#ifdef LOW_POWER_LISTENING
	components LowPowerListeningLayerC;
#else	
	components new DummyLayerC() as LowPowerListeningLayerC;
#endif
	components MessageBufferLayerC;
	components UniqueLayerC;
	components TrafficMonitorLayerC;
#ifdef RF230_SLOTTED_MAC
	components SlottedCollisionLayerC as CollisionAvoidanceLayerC;
#else
	components RandomCollisionLayerC as CollisionAvoidanceLayerC;
#endif
	components SoftwareAckLayerC;
	components new DummyLayerC() as CsmaLayerC;
	components RF230LayerC;

	SplitControl = LowPowerListeningLayerC;
	AMSend = ActiveMessageLayerC;
	Receive = ActiveMessageLayerC.Receive;
	Snoop = ActiveMessageLayerC.Snoop;

	ActiveMessageLayerC.Config -> RF230ActiveMessageP;
	ActiveMessageLayerC.AMPacket -> IEEE154PacketC;
	ActiveMessageLayerC.SubSend -> UniqueLayerC;
	ActiveMessageLayerC.SubReceive -> LowPowerListeningLayerC;

	UniqueLayerC.Config -> RF230ActiveMessageP;
	UniqueLayerC.SubSend -> LowPowerListeningLayerC;

	LowPowerListeningLayerC.SubControl -> MessageBufferLayerC;
	LowPowerListeningLayerC.SubSend -> MessageBufferLayerC;
	LowPowerListeningLayerC.SubReceive -> MessageBufferLayerC;
#ifdef LOW_POWER_LISTENING
	LowPowerListeningLayerC.PacketSleepInterval -> RF230PacketC;
	LowPowerListeningLayerC.IEEE154Packet -> IEEE154PacketC;
	LowPowerListeningLayerC.PacketAcknowledgements -> RF230PacketC;
#endif

	MessageBufferLayerC.Packet -> RF230PacketC;
	MessageBufferLayerC.RadioSend -> TrafficMonitorLayerC;
	MessageBufferLayerC.RadioReceive -> UniqueLayerC;
	MessageBufferLayerC.RadioState -> TrafficMonitorLayerC;

	UniqueLayerC.SubReceive -> TrafficMonitorLayerC;

	TrafficMonitorLayerC.Config -> RF230ActiveMessageP;
	TrafficMonitorLayerC.SubSend -> CollisionAvoidanceLayerC;
	TrafficMonitorLayerC.SubReceive -> CollisionAvoidanceLayerC;
	TrafficMonitorLayerC.SubState -> RF230LayerC;

	CollisionAvoidanceLayerC.Config -> RF230ActiveMessageP;
	CollisionAvoidanceLayerC.SubSend -> SoftwareAckLayerC;
	CollisionAvoidanceLayerC.SubReceive -> SoftwareAckLayerC;

	SoftwareAckLayerC.Config -> RF230ActiveMessageP;
	SoftwareAckLayerC.SubSend -> CsmaLayerC;
	SoftwareAckLayerC.SubReceive -> RF230LayerC;

	CsmaLayerC.Config -> RF230ActiveMessageP;
	CsmaLayerC -> RF230LayerC.RadioSend;
	CsmaLayerC -> RF230LayerC.RadioCCA;

	RF230LayerC.RF230Config -> RF230ActiveMessageP;
}
