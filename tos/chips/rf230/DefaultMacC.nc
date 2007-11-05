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

configuration DefaultMacC
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
	}
}

implementation
{
	components DefaultMacP, IEEE154PacketC, RadioAlarmC;

#ifdef RF230_DEBUG
	components AssertC;
#endif

	DefaultMacP.IEEE154Packet -> IEEE154PacketC;
	DefaultMacP.RadioAlarm -> RadioAlarmC.RadioAlarm[unique("RadioAlarm")];

	components ActiveMessageLayerC;
	components MessageBufferLayerC;
	components UniqueLayerC;
	components TrafficMonitorLayerC;
	components RandomCollisionLayerC as CollisionAvoidanceLayerC;
//	components SlottedCollisionLayerC as CollisionAvoidanceLayerC;
	components SoftwareAckLayerC;
	components new DummyLayerC() as CsmaLayerC;
	components RF230LayerC;

	SplitControl = MessageBufferLayerC;
	AMSend = ActiveMessageLayerC;
	Receive = ActiveMessageLayerC.Receive;
	Snoop = ActiveMessageLayerC.Snoop;
	Packet = DefaultMacP;
	AMPacket = IEEE154PacketC;
	PacketAcknowledgements = DefaultMacP;

	ActiveMessageLayerC.Config -> DefaultMacP;
	ActiveMessageLayerC.AMPacket -> IEEE154PacketC;
	ActiveMessageLayerC.SubSend -> UniqueLayerC;
	ActiveMessageLayerC.SubReceive -> MessageBufferLayerC;

	UniqueLayerC.Config -> DefaultMacP;
	UniqueLayerC.SubSend -> MessageBufferLayerC;

	MessageBufferLayerC.Packet -> DefaultMacP;
	MessageBufferLayerC.RadioSend -> TrafficMonitorLayerC;
	MessageBufferLayerC.RadioReceive -> UniqueLayerC;
	MessageBufferLayerC.RadioState -> TrafficMonitorLayerC;

	UniqueLayerC.SubReceive -> TrafficMonitorLayerC;

	TrafficMonitorLayerC.Config -> DefaultMacP;
	TrafficMonitorLayerC.SubSend -> CollisionAvoidanceLayerC;
	TrafficMonitorLayerC.SubReceive -> CollisionAvoidanceLayerC;
	TrafficMonitorLayerC.SubState -> RF230LayerC;

	CollisionAvoidanceLayerC.Config -> DefaultMacP;
	CollisionAvoidanceLayerC.SubSend -> SoftwareAckLayerC;
	CollisionAvoidanceLayerC.SubReceive -> SoftwareAckLayerC;

	SoftwareAckLayerC.Config -> DefaultMacP;
	SoftwareAckLayerC.SubSend -> CsmaLayerC;
	SoftwareAckLayerC.SubReceive -> RF230LayerC;

	CsmaLayerC.Config -> DefaultMacP;
	CsmaLayerC.SubSend -> RF230LayerC;
	CsmaLayerC.SubCCA -> RF230LayerC;

	RF230LayerC.RF230Config -> DefaultMacP;
}
