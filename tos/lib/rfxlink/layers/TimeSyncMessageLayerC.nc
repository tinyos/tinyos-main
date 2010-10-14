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
