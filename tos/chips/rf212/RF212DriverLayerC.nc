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
#include <RF212DriverLayer.h>

configuration RF212DriverLayerC
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
		interface RF212DriverConfig as Config;
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
	components RF212DriverLayerP, HplRF212C, BusyWaitMicroC, MainC;

	RadioState = RF212DriverLayerP;
	RadioSend = RF212DriverLayerP;
	RadioReceive = RF212DriverLayerP;
	RadioCCA = RF212DriverLayerP;
	RadioPacket = RF212DriverLayerP;

	LocalTimeRadio = HplRF212C;

	Config = RF212DriverLayerP;

	PacketTransmitPower = RF212DriverLayerP.PacketTransmitPower;
	TransmitPowerFlag = RF212DriverLayerP.TransmitPowerFlag;

	PacketRSSI = RF212DriverLayerP.PacketRSSI;
	RSSIFlag = RF212DriverLayerP.RSSIFlag;

	PacketTimeSyncOffset = RF212DriverLayerP.PacketTimeSyncOffset;
	TimeSyncFlag = RF212DriverLayerP.TimeSyncFlag;

	PacketLinkQuality = RF212DriverLayerP.PacketLinkQuality;
	PacketTimeStamp = RF212DriverLayerP.PacketTimeStamp;
	LinkPacketMetadata = RF212DriverLayerP;

	RF212DriverLayerP.LocalTime -> HplRF212C;

	Alarm = HplRF212C.Alarm;
	RadioAlarm = RF212DriverLayerP.RadioAlarm;

	RF212DriverLayerP.SELN -> HplRF212C.SELN;
	RF212DriverLayerP.SpiResource -> HplRF212C.SpiResource;
	RF212DriverLayerP.FastSpiByte -> HplRF212C;

	RF212DriverLayerP.SLP_TR -> HplRF212C.SLP_TR;
	RF212DriverLayerP.RSTN -> HplRF212C.RSTN;

	RF212DriverLayerP.IRQ -> HplRF212C.IRQ;
	Tasklet = RF212DriverLayerP.Tasklet;
	RF212DriverLayerP.BusyWait -> BusyWaitMicroC;

#ifdef RADIO_DEBUG
	components DiagMsgC;
	RF212DriverLayerP.DiagMsg -> DiagMsgC;
#endif

	MainC.SoftwareInit -> RF212DriverLayerP.SoftwareInit;

	components RealMainP;
	RealMainP.PlatformInit -> RF212DriverLayerP.PlatformInit;
}
