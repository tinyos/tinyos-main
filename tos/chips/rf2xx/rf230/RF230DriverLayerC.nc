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

configuration RF230DriverLayerC
{
	provides
	{
		interface RadioState;
		interface RadioSend;
		interface RadioReceive;
		interface RadioCCA;
	}

	uses interface RF230DriverConfig;
}

implementation
{
	components RF230DriverLayerP, HplRF230C, BusyWaitMicroC, TaskletC, MainC, RadioAlarmC, RF230PacketC, LocalTimeMicroC as LocalTimeRadioC;

	RadioState = RF230DriverLayerP;
	RadioSend = RF230DriverLayerP;
	RadioReceive = RF230DriverLayerP;
	RadioCCA = RF230DriverLayerP;

	RF230DriverConfig = RF230DriverLayerP;

	RF230DriverLayerP.PacketLinkQuality -> RF230PacketC.PacketLinkQuality;
	RF230DriverLayerP.PacketTransmitPower -> RF230PacketC.PacketTransmitPower;
	RF230DriverLayerP.PacketRSSI -> RF230PacketC.PacketRSSI;
	RF230DriverLayerP.PacketTimeSyncOffset -> RF230PacketC.PacketTimeSyncOffset;
	RF230DriverLayerP.PacketTimeStamp -> RF230PacketC;
	RF230DriverLayerP.LocalTime -> LocalTimeRadioC;

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
