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
 * Author: Andras Biro
 */

#include <RadioConfig.h>
#include <RFA1DriverLayer.h>

configuration RFA1DriverHwAckC
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
		
		interface PacketAcknowledgements;
	}

	uses
	{
		interface RFA1DriverConfig as Config;
		interface PacketTimeStamp<TRadio, uint32_t>;
		interface Ieee154PacketLayer;

		interface PacketFlag as TransmitPowerFlag;
		interface PacketFlag as RSSIFlag;
		interface PacketFlag as TimeSyncFlag;
		interface PacketFlag as AckReceivedFlag;
		interface AsyncStdControl as ExtAmpControl;
		interface Tasklet;
	}
}

implementation
{
	components RFA1DriverHwAckP as RFA1DriverLayerP, BusyWaitMicroC,
		LocalTime62khzC, new Alarm62khz32C(), HplAtmRfa1TimerMacC, ActiveMessageAddressC;

	RadioState = RFA1DriverLayerP;
	RadioSend = RFA1DriverLayerP;
	RadioReceive = RFA1DriverLayerP;
	RadioCCA = RFA1DriverLayerP;
	RadioPacket = RFA1DriverLayerP;

	LocalTimeRadio = LocalTime62khzC;

	Config = RFA1DriverLayerP;

	PacketTransmitPower = RFA1DriverLayerP.PacketTransmitPower;
	TransmitPowerFlag = RFA1DriverLayerP.TransmitPowerFlag;

	PacketRSSI = RFA1DriverLayerP.PacketRSSI;
	RSSIFlag = RFA1DriverLayerP.RSSIFlag;

	PacketTimeSyncOffset = RFA1DriverLayerP.PacketTimeSyncOffset;
	TimeSyncFlag = RFA1DriverLayerP.TimeSyncFlag;

	PacketLinkQuality = RFA1DriverLayerP.PacketLinkQuality;
	PacketTimeStamp = RFA1DriverLayerP.PacketTimeStamp;
	LinkPacketMetadata = RFA1DriverLayerP;

	RFA1DriverLayerP.LocalTime -> LocalTime62khzC;
	RFA1DriverLayerP.SfdCapture -> HplAtmRfa1TimerMacC.SfdCapture;

	Alarm = Alarm62khz32C;

	Tasklet = RFA1DriverLayerP.Tasklet;
	RFA1DriverLayerP.BusyWait -> BusyWaitMicroC;

#ifdef RADIO_DEBUG
	components DiagMsgC;
	RFA1DriverLayerP.DiagMsg -> DiagMsgC;
#endif

	components MainC, RealMainP;
	RealMainP.PlatformInit -> RFA1DriverLayerP.PlatformInit;
	MainC.SoftwareInit -> RFA1DriverLayerP.SoftwareInit;

	components McuSleepC;
	RFA1DriverLayerP.McuPowerState -> McuSleepC;
	RFA1DriverLayerP.McuPowerOverride <- McuSleepC;

	ExtAmpControl = RFA1DriverLayerP;
	
	AckReceivedFlag = RFA1DriverLayerP.AckReceivedFlag;
	RFA1DriverLayerP.ActiveMessageAddress -> ActiveMessageAddressC;
	PacketAcknowledgements = RFA1DriverLayerP;
	Ieee154PacketLayer = RFA1DriverLayerP;
	
	#ifdef RFA1_HWACK_64BIT
	components LocalIeeeEui64C;
	RFA1DriverLayerP.LocalIeeeEui64 -> LocalIeeeEui64C;
	#endif
}
