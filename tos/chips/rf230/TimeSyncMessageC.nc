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

#include <Timer.h>
#include <AM.h>

configuration TimeSyncMessageC
{
	provides
	{
		interface TimeSyncSend<TMicro> as TimeSyncSendMicro[am_id_t id];
		interface TimeSyncPacket<TMicro> as TimeSyncPacketMicro;
//		interface LocalTime<TMicro> as LocalTimeMicro;

		interface TimeSyncSend<TMilli> as TimeSyncSendMilli[am_id_t id];
		interface TimeSyncPacket<TMilli> as TimeSyncPacketMilli;
		interface LocalTime<TMilli> as LocalTimeMilli;

		interface SplitControl;
		interface Receive[uint8_t id];
		interface Receive as Snoop[am_id_t id];
		interface Packet;
		interface AMPacket;
		interface PacketAcknowledgements;
	}
}

implementation
{
	components TimeSyncMessageP, ActiveMessageC, LocalTimeMilliC;

	TimeSyncSendMicro = TimeSyncMessageP;
	TimeSyncPacketMicro = TimeSyncMessageP;
//	LocalTimeMicro = LocalTimeMicroC;

	TimeSyncSendMilli = TimeSyncMessageP;
	TimeSyncPacketMilli = TimeSyncMessageP;
	LocalTimeMilli = LocalTimeMilliC;

	Packet = TimeSyncMessageP;
	TimeSyncMessageP.SubSend -> ActiveMessageC.AMSend;
	TimeSyncMessageP.SubPacket -> ActiveMessageC.Packet;
	TimeSyncMessageP.PacketTimeStamp -> ActiveMessageC;

	TimeSyncMessageP.LocalTimeMilli -> LocalTimeMilliC;

	TimeSyncMessageP.PacketLastTouch -> ActiveMessageC;

	SplitControl = ActiveMessageC;
	Receive	= ActiveMessageC.Receive;
	Snoop = ActiveMessageC.Snoop;
	AMPacket = ActiveMessageC;
	PacketAcknowledgements = ActiveMessageC;
}
