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

configuration RF212ActiveMessageC
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
	components RF212ActiveMessageP, RF212PacketC, IEEE154PacketC, RadioAlarmC;

#ifdef RADIO_DEBUG
	components AssertC;
#endif

	RF212ActiveMessageP.IEEE154Packet -> IEEE154PacketC;
	RF212ActiveMessageP.Packet -> RF212PacketC;
	RF212ActiveMessageP.RadioAlarm -> RadioAlarmC.RadioAlarm[unique("RadioAlarm")];

	Packet = RF212PacketC;
	AMPacket = RF212PacketC;
	PacketAcknowledgements = RF212PacketC;
	PacketLinkQuality = RF212PacketC.PacketLinkQuality;
	PacketTransmitPower = RF212PacketC.PacketTransmitPower;
	PacketRSSI = RF212PacketC.PacketRSSI;
	PacketTimeStampRadio = RF212PacketC;
	PacketTimeStampMilli = RF212PacketC;
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
#ifdef SLOTTED_MAC
	components SlottedCollisionLayerC as CollisionAvoidanceLayerC;
#else
	components RandomCollisionLayerC as CollisionAvoidanceLayerC;
#endif
	components SoftwareAckLayerC;
	components new DummyLayerC() as CsmaLayerC;
	components RF212DriverLayerC;

	SplitControl = LowPowerListeningLayerC;
	AMSend = ActiveMessageLayerC;
	Receive = ActiveMessageLayerC.Receive;
	Snoop = ActiveMessageLayerC.Snoop;

	ActiveMessageLayerC.Config -> RF212ActiveMessageP;
	ActiveMessageLayerC.AMPacket -> IEEE154PacketC;
	ActiveMessageLayerC.SubSend -> IEEE154NetworkLayerC;
	ActiveMessageLayerC.SubReceive -> IEEE154NetworkLayerC;

	IEEE154NetworkLayerC.SubSend -> UniqueLayerC;
	IEEE154NetworkLayerC.SubReceive -> LowPowerListeningLayerC;

	// the UniqueLayer is wired at two points
	UniqueLayerC.Config -> RF212ActiveMessageP;
	UniqueLayerC.SubSend -> LowPowerListeningLayerC;

	LowPowerListeningLayerC.SubControl -> MessageBufferLayerC;
	LowPowerListeningLayerC.SubSend -> MessageBufferLayerC;
	LowPowerListeningLayerC.SubReceive -> MessageBufferLayerC;
#ifdef LOW_POWER_LISTENING
	LowPowerListeningLayerC.PacketSleepInterval -> RF212PacketC;
	LowPowerListeningLayerC.IEEE154Packet -> IEEE154PacketC;
	LowPowerListeningLayerC.PacketAcknowledgements -> RF212PacketC;
#endif

	MessageBufferLayerC.Packet -> RF212PacketC;
	MessageBufferLayerC.RadioSend -> TrafficMonitorLayerC;
	MessageBufferLayerC.RadioReceive -> UniqueLayerC;
	MessageBufferLayerC.RadioState -> TrafficMonitorLayerC;

	UniqueLayerC.SubReceive -> TrafficMonitorLayerC;

	TrafficMonitorLayerC.Config -> RF212ActiveMessageP;
	TrafficMonitorLayerC.SubSend -> CollisionAvoidanceLayerC;
	TrafficMonitorLayerC.SubReceive -> CollisionAvoidanceLayerC;
	TrafficMonitorLayerC.SubState -> RF212DriverLayerC;

	CollisionAvoidanceLayerC.Config -> RF212ActiveMessageP;
	CollisionAvoidanceLayerC.SubSend -> SoftwareAckLayerC;
	CollisionAvoidanceLayerC.SubReceive -> SoftwareAckLayerC;

	SoftwareAckLayerC.Config -> RF212ActiveMessageP;
	SoftwareAckLayerC.SubSend -> CsmaLayerC;
	SoftwareAckLayerC.SubReceive -> RF212DriverLayerC;

	CsmaLayerC.Config -> RF212ActiveMessageP;
	CsmaLayerC -> RF212DriverLayerC.RadioSend;
	CsmaLayerC -> RF212DriverLayerC.RadioCCA;

	RF212DriverLayerC.RF212DriverConfig -> RF212ActiveMessageP;
}
