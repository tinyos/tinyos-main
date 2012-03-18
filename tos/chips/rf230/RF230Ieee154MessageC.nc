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

#ifdef TFRAMES_ENABLED
#error "You cannot use Ieee154MessageC with TFRAMES_ENABLED defined"
#endif

configuration RF230Ieee154MessageC
{
	provides
	{
		interface SplitControl;
		interface Resource as SendResource[uint8_t clint];

		interface Ieee154Send;
		interface Receive as Ieee154Receive;
		interface Ieee154Packet;
		interface Packet;

		interface Send as BareSend;
		interface Receive as BareReceive;
		interface Packet as BarePacket;

		interface SendNotifier;
		interface PacketAcknowledgements;
		interface LowPowerListening;
		interface PacketLink;
		interface RadioChannel;

		interface PacketField<uint8_t> as PacketLinkQuality;
		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketField<uint8_t> as PacketRSSI;

		interface LocalTime<TRadio> as LocalTimeRadio;
		interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
		interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
	}
}

implementation
{
// -------- Ieee154 Message

	components new Ieee154MessageLayerC();
	Ieee154MessageLayerC.Ieee154PacketLayer -> RadioC;
	Ieee154MessageLayerC.SubSend -> RadioC.Ieee154Send;
	Ieee154MessageLayerC.SubReceive -> RadioC.Ieee154Receive;
	Ieee154MessageLayerC.RadioPacket -> RadioC.Ieee154Packet;

	Ieee154Send = Ieee154MessageLayerC.Ieee154Send;
	Ieee154Receive = Ieee154MessageLayerC.Ieee154Receive;
	Ieee154Packet = Ieee154MessageLayerC.Ieee154Packet;
	Packet = Ieee154MessageLayerC.Packet;

	BareSend = Ieee154MessageLayerC.BareSend;
	BareReceive = Ieee154MessageLayerC.BareReceive;
	BarePacket = Ieee154MessageLayerC.BarePacket;

	SendNotifier = Ieee154MessageLayerC;

// -------- Radio

	components RF230RadioC as RadioC;

	SplitControl = RadioC;
	SendResource = RadioC;

	PacketAcknowledgements = RadioC;
	LowPowerListening = RadioC;
	PacketLink = RadioC;
	RadioChannel = RadioC;

	PacketLinkQuality = RadioC.PacketLinkQuality;
	PacketTransmitPower = RadioC.PacketTransmitPower;
	PacketRSSI = RadioC.PacketRSSI;

	LocalTimeRadio = RadioC;
	PacketTimeStampMilli = RadioC;
	PacketTimeStampRadio = RadioC;
}
