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

		interface LocalTime<TRadio> as LocalTimeRadio;
	}

	uses
	{
		interface RF230DriverConfig as Config;
		interface PacketTimeStamp<TRadio, uint32_t>;
	}
}

implementation
{
	components RF230DriverLayerP, HplRF230C, BusyWaitMicroC, TaskletC, MainC, RadioAlarmC;

	RadioState = RF230DriverLayerP;
	RadioSend = RF230DriverLayerP;
	RadioReceive = RF230DriverLayerP;
	RadioCCA = RF230DriverLayerP;
	RadioPacket = RF230DriverLayerP;

	LocalTimeRadio = HplRF230C;

	Config = RF230DriverLayerP;

	PacketTransmitPower = RF230DriverLayerP.PacketTransmitPower;
	components new MetadataFlagC() as TransmitPowerFlagC;
	RF230DriverLayerP.TransmitPowerFlag -> TransmitPowerFlagC;

	PacketRSSI = RF230DriverLayerP.PacketRSSI;
	components new MetadataFlagC() as RSSIFlagC;
	RF230DriverLayerP.RSSIFlag -> RSSIFlagC;

	PacketTimeSyncOffset = RF230DriverLayerP.PacketTimeSyncOffset;
	components new MetadataFlagC() as TimeSyncFlagC;
	RF230DriverLayerP.TimeSyncFlag -> TimeSyncFlagC;

	PacketLinkQuality = RF230DriverLayerP.PacketLinkQuality;
	PacketTimeStamp = RF230DriverLayerP.PacketTimeStamp;

	RF230DriverLayerP.LocalTime -> HplRF230C;

	RF230DriverLayerP.RadioAlarm -> RadioAlarmC.RadioAlarm[unique("RadioAlarm")];
	RadioAlarmC.Alarm -> HplRF230C.Alarm;

	RF230DriverLayerP.SELN -> HplRF230C.SELN;
	RF230DriverLayerP.SpiResource -> HplRF230C.SpiResource;
	RF230DriverLayerP.FastSpiByte -> HplRF230C;

	RF230DriverLayerP.SLP_TR -> HplRF230C.SLP_TR;
	RF230DriverLayerP.RSTN -> HplRF230C.RSTN;

	RF230DriverLayerP.IRQ -> HplRF230C.IRQ;
	RF230DriverLayerP.Tasklet -> TaskletC;
	RF230DriverLayerP.BusyWait -> BusyWaitMicroC;

#ifdef RADIO_DEBUG
	components DiagMsgC;
	RF230DriverLayerP.DiagMsg -> DiagMsgC;
#endif

	MainC.SoftwareInit -> RF230DriverLayerP.SoftwareInit;

	components RealMainP;
	RealMainP.PlatformInit -> RF230DriverLayerP.PlatformInit;
}
