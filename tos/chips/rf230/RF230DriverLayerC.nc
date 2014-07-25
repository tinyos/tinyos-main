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
#include <RF230DriverLayer.h>

configuration RF230DriverLayerC
{
	provides
	{
		interface RadioState;
		interface RadioSend;
		interface RadioReceive;
		interface RadioCCA;
		interface RadioPacket;

		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketField<uint8_t> as PacketRSSI;
		interface PacketField<uint8_t> as PacketTimeSyncOffset;
		interface PacketField<uint8_t> as PacketLinkQuality;
		interface LinkPacketMetadata;

		interface LocalTime<TRadio> as LocalTimeRadio;
		interface Alarm<TRadio, tradio_size>;
	}

	uses
	{
		interface RF230DriverConfig as Config;
		interface PacketTimeStamp<TRadio, uint32_t>;

		interface PacketFlag as TransmitPowerFlag;
		interface PacketFlag as RSSIFlag;
		interface PacketFlag as TimeSyncFlag;
		interface RadioAlarm;
		interface Tasklet;
	}
}

implementation
{
	components RF230DriverLayerP as DriverLayerP, 
		HplRF230C, BusyWaitMicroC, MainC;

	RadioState = DriverLayerP;
	RadioSend = DriverLayerP;
	RadioReceive = DriverLayerP;
	RadioCCA = DriverLayerP;
	RadioPacket = DriverLayerP;

	LocalTimeRadio = HplRF230C;

	Config = DriverLayerP;

	PacketTransmitPower = DriverLayerP.PacketTransmitPower;
	TransmitPowerFlag = DriverLayerP.TransmitPowerFlag;

	PacketRSSI = DriverLayerP.PacketRSSI;
	RSSIFlag = DriverLayerP.RSSIFlag;

	PacketTimeSyncOffset = DriverLayerP.PacketTimeSyncOffset;
	TimeSyncFlag = DriverLayerP.TimeSyncFlag;

	PacketLinkQuality = DriverLayerP.PacketLinkQuality;
	PacketTimeStamp = DriverLayerP.PacketTimeStamp;
	LinkPacketMetadata = DriverLayerP;

	DriverLayerP.LocalTime -> HplRF230C;

	Alarm = HplRF230C.Alarm;
	RadioAlarm = DriverLayerP.RadioAlarm;

	DriverLayerP.SELN -> HplRF230C.SELN;
	DriverLayerP.SpiResource -> HplRF230C.SpiResource;
	DriverLayerP.FastSpiByte -> HplRF230C;

	DriverLayerP.SLP_TR -> HplRF230C.SLP_TR;
	DriverLayerP.RSTN -> HplRF230C.RSTN;

	DriverLayerP.IRQ -> HplRF230C.IRQ;
	Tasklet = DriverLayerP.Tasklet;
	DriverLayerP.BusyWait -> BusyWaitMicroC;

#ifdef RADIO_DEBUG
	components DiagMsgC;
	DriverLayerP.DiagMsg -> DiagMsgC;
#endif

	MainC.SoftwareInit -> DriverLayerP.SoftwareInit;

	components RealMainP;
	RealMainP.PlatformInit -> DriverLayerP.PlatformInit;
}
