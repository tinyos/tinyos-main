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

configuration RF212DriverLayerC
{
	provides
	{
		interface RadioState;
		interface RadioSend;
		interface RadioReceive;
		interface RadioCCA;
	}

	uses interface RF212DriverConfig;
}

implementation
{
	components RF212DriverLayerP, HplRF212C, BusyWaitMicroC, TaskletC, MainC, RadioAlarmC, RF212PacketC, LocalTimeMicroC as LocalTimeRadioC;

	RadioState = RF212DriverLayerP;
	RadioSend = RF212DriverLayerP;
	RadioReceive = RF212DriverLayerP;
	RadioCCA = RF212DriverLayerP;

	RF212DriverConfig = RF212DriverLayerP;

	RF212DriverLayerP.PacketLinkQuality -> RF212PacketC.PacketLinkQuality;
	RF212DriverLayerP.PacketTransmitPower -> RF212PacketC.PacketTransmitPower;
	RF212DriverLayerP.PacketRSSI -> RF212PacketC.PacketRSSI;
	RF212DriverLayerP.PacketTimeSyncOffset -> RF212PacketC.PacketTimeSyncOffset;
	RF212DriverLayerP.PacketTimeStamp -> RF212PacketC;
	RF212DriverLayerP.LocalTime -> LocalTimeRadioC;

	RF212DriverLayerP.RadioAlarm -> RadioAlarmC.RadioAlarm[unique("RadioAlarm")];
	RadioAlarmC.Alarm -> HplRF212C.Alarm;

	RF212DriverLayerP.SELN -> HplRF212C.SELN;
	RF212DriverLayerP.SpiResource -> HplRF212C.SpiResource;
	RF212DriverLayerP.FastSpiByte -> HplRF212C;

	RF212DriverLayerP.SLP_TR -> HplRF212C.SLP_TR;
	RF212DriverLayerP.RSTN -> HplRF212C.RSTN;

	RF212DriverLayerP.IRQ -> HplRF212C.IRQ;
	RF212DriverLayerP.Tasklet -> TaskletC;
	RF212DriverLayerP.BusyWait -> BusyWaitMicroC;

#ifdef RADIO_DEBUG
	components DiagMsgC;
	RF212DriverLayerP.DiagMsg -> DiagMsgC;
#endif

	MainC.SoftwareInit -> RF212DriverLayerP.SoftwareInit;

	components RealMainP;
	RealMainP.PlatformInit -> RF212DriverLayerP.PlatformInit;
}
