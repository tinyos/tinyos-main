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
#include <HplRF230.h>

configuration TimeSyncMessageC
{
	provides
	{
		interface SplitControl;

		interface Receive[uint8_t id];
		interface Receive as Snoop[am_id_t id];
		interface Packet;
		interface AMPacket;

		interface TimeSyncAMSend<TRF230, uint32_t> as TimeSyncAMSendRadio[am_id_t id];
		interface TimeSyncPacket<TRF230, uint32_t> as TimeSyncPacketRadio;

		interface TimeSyncAMSend<TMilli, uint32_t> as TimeSyncAMSendMilli[am_id_t id];
		interface TimeSyncPacket<TMilli, uint32_t> as TimeSyncPacketMilli;
	}
}

implementation
{
	components TimeSyncMessageP, RF230ActiveMessageC, LocalTimeMilliC, LocalTimeMicroC as LocalTimeRadioC, RF230PacketC;

	TimeSyncAMSendRadio = TimeSyncMessageP;
	TimeSyncPacketRadio = TimeSyncMessageP;

	TimeSyncAMSendMilli = TimeSyncMessageP;
	TimeSyncPacketMilli = TimeSyncMessageP;

	Packet = TimeSyncMessageP;
	TimeSyncMessageP.SubSend -> RF230ActiveMessageC.AMSend;
	TimeSyncMessageP.SubPacket -> RF230ActiveMessageC.Packet;

	TimeSyncMessageP.PacketTimeStampRadio -> RF230ActiveMessageC;
	TimeSyncMessageP.PacketTimeStampMilli -> RF230ActiveMessageC;
	TimeSyncMessageP.LocalTimeRadio -> LocalTimeRadioC;
	TimeSyncMessageP.LocalTimeMilli -> LocalTimeMilliC;

	TimeSyncMessageP.PacketTimeSyncOffset -> RF230PacketC.PacketTimeSyncOffset;

	SplitControl = RF230ActiveMessageC;
	Receive	= RF230ActiveMessageC.Receive;
	Snoop = RF230ActiveMessageC.Snoop;
	AMPacket = RF230ActiveMessageC;
}
