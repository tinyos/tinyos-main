/*
* Copyright (c) 2009, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
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

configuration RF230DriverHwAckC
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

		interface PacketAcknowledgements;
	}

	uses
	{
		interface RF230DriverConfig as Config;
		interface PacketTimeStamp<TRadio, uint32_t>;
		interface Ieee154PacketLayer;
	}
}

implementation
{
	components RF230DriverHwAckP, HplRF230C, BusyWaitMicroC, TaskletC, MainC, RadioAlarmC;

	RadioState = RF230DriverHwAckP;
	RadioSend = RF230DriverHwAckP;
	RadioReceive = RF230DriverHwAckP;
	RadioCCA = RF230DriverHwAckP;
	RadioPacket = RF230DriverHwAckP;

	LocalTimeRadio = HplRF230C;

	Config = RF230DriverHwAckP;

	PacketTransmitPower = RF230DriverHwAckP.PacketTransmitPower;
	components new MetadataFlagC() as TransmitPowerFlagC;
	RF230DriverHwAckP.TransmitPowerFlag -> TransmitPowerFlagC;

	PacketRSSI = RF230DriverHwAckP.PacketRSSI;
	components new MetadataFlagC() as RSSIFlagC;
	RF230DriverHwAckP.RSSIFlag -> RSSIFlagC;

	PacketTimeSyncOffset = RF230DriverHwAckP.PacketTimeSyncOffset;
	components new MetadataFlagC() as TimeSyncFlagC;
	RF230DriverHwAckP.TimeSyncFlag -> TimeSyncFlagC;

	PacketLinkQuality = RF230DriverHwAckP.PacketLinkQuality;
	PacketTimeStamp = RF230DriverHwAckP.PacketTimeStamp;

	RF230DriverHwAckP.LocalTime -> HplRF230C;

	RF230DriverHwAckP.RadioAlarm -> RadioAlarmC.RadioAlarm[unique("RadioAlarm")];
	RadioAlarmC.Alarm -> HplRF230C.Alarm;

	RF230DriverHwAckP.SELN -> HplRF230C.SELN;
	RF230DriverHwAckP.SpiResource -> HplRF230C.SpiResource;
	RF230DriverHwAckP.FastSpiByte -> HplRF230C;

	RF230DriverHwAckP.SLP_TR -> HplRF230C.SLP_TR;
	RF230DriverHwAckP.RSTN -> HplRF230C.RSTN;

	RF230DriverHwAckP.IRQ -> HplRF230C.IRQ;
	RF230DriverHwAckP.Tasklet -> TaskletC;
	RF230DriverHwAckP.BusyWait -> BusyWaitMicroC;

#ifdef RADIO_DEBUG
	components DiagMsgC;
	RF230DriverHwAckP.DiagMsg -> DiagMsgC;
#endif

	MainC.SoftwareInit -> RF230DriverHwAckP.SoftwareInit;

	components RealMainP;
	RealMainP.PlatformInit -> RF230DriverHwAckP.PlatformInit;

	components new MetadataFlagC(), ActiveMessageAddressC;
	RF230DriverHwAckP.AckReceivedFlag -> MetadataFlagC;
	RF230DriverHwAckP.ActiveMessageAddress -> ActiveMessageAddressC;
	PacketAcknowledgements = RF230DriverHwAckP;
	Ieee154PacketLayer = RF230DriverHwAckP;
}
