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

		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketField<uint8_t> as PacketRSSI;
		interface PacketField<uint8_t> as PacketTimeSyncOffset;
		interface PacketField<uint8_t> as PacketLinkQuality;

		interface LocalTime<TRadio> as LocalTimeRadio;
	}

	uses
	{
		interface RF230DriverConfig;
		interface PacketTimeStamp<TRadio, uint32_t>;
		interface PacketData<rf230_metadata_t> as PacketRF230Metadata;
	}
}

implementation
{
	components RF230DriverLayerP, HplRF230C, BusyWaitMicroC, TaskletC, MainC, RadioAlarmC;

	RadioState = RF230DriverLayerP;
	RadioSend = RF230DriverLayerP;
	RadioReceive = RF230DriverLayerP;
	RadioCCA = RF230DriverLayerP;

	LocalTimeRadio = HplRF230C;

	RF230DriverConfig = RF230DriverLayerP;
	PacketRF230Metadata = RF230DriverLayerP;

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
