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
#include <RadioConfig.h>
#include <TimeSyncMessageLayer.h>

configuration TimeSyncMessageLayerC
{
	provides
	{
		interface Receive[uint8_t id];
		interface Receive as Snoop[am_id_t id];
		interface AMPacket;
		interface Packet;

		interface TimeSyncAMSend<TRadio, uint32_t> as TimeSyncAMSendRadio[am_id_t id];
		interface TimeSyncPacket<TRadio, uint32_t> as TimeSyncPacketRadio;

		interface TimeSyncAMSend<TMilli, uint32_t> as TimeSyncAMSendMilli[am_id_t id];
		interface TimeSyncPacket<TMilli, uint32_t> as TimeSyncPacketMilli;
	}

	uses
	{
		interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
		interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;

		interface LocalTime<TRadio> as LocalTimeRadio;
		interface PacketField<uint8_t> as PacketTimeSyncOffset;
	}
}

implementation
{
	components TimeSyncMessageLayerP, LocalTimeMilliC;

	AMPacket = TimeSyncMessageLayerP;
	Packet = TimeSyncMessageLayerP;

	Receive = TimeSyncMessageLayerP.Receive;
	Snoop = TimeSyncMessageLayerP.Snoop;

	TimeSyncAMSendRadio = TimeSyncMessageLayerP;
	TimeSyncPacketRadio = TimeSyncMessageLayerP;

	TimeSyncAMSendMilli = TimeSyncMessageLayerP;
	TimeSyncPacketMilli = TimeSyncMessageLayerP;

	// Ok, we use the AMSenderC infrastructure to avoid concurrent send clashes
	components new AMSenderC(AM_TIMESYNCMSG);
	TimeSyncMessageLayerP.SubAMSend -> AMSenderC;
	TimeSyncMessageLayerP.SubAMPacket -> AMSenderC;
	TimeSyncMessageLayerP.SubPacket -> AMSenderC;

	components ActiveMessageC;
	TimeSyncMessageLayerP.SubReceive -> ActiveMessageC.Receive[AM_TIMESYNCMSG];
	TimeSyncMessageLayerP.SubSnoop -> ActiveMessageC.Snoop[AM_TIMESYNCMSG];;

	PacketTimeStampRadio = TimeSyncMessageLayerP;
	PacketTimeStampMilli = TimeSyncMessageLayerP;
	
	TimeSyncMessageLayerP.LocalTimeMilli -> LocalTimeMilliC;
	LocalTimeRadio = TimeSyncMessageLayerP;
	PacketTimeSyncOffset = TimeSyncMessageLayerP;
}
