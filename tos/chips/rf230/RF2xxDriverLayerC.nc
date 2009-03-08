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

configuration RF2xxDriverLayerC
{
	provides
	{
		interface RadioState;
		interface RadioSend;
		interface RadioReceive;
		interface RadioCCA;
	}

	uses interface RF2xxDriverConfig;
}

implementation
{
	components RF2xxDriverLayerP, HplRF2xxC, BusyWaitMicroC, TaskletC, MainC, RadioAlarmC, RF2xxPacketC, LocalTimeMicroC as LocalTimeRadioC;

	RadioState = RF2xxDriverLayerP;
	RadioSend = RF2xxDriverLayerP;
	RadioReceive = RF2xxDriverLayerP;
	RadioCCA = RF2xxDriverLayerP;

	RF2xxDriverConfig = RF2xxDriverLayerP;

	RF2xxDriverLayerP.PacketLinkQuality -> RF2xxPacketC.PacketLinkQuality;
	RF2xxDriverLayerP.PacketTransmitPower -> RF2xxPacketC.PacketTransmitPower;
	RF2xxDriverLayerP.PacketRSSI -> RF2xxPacketC.PacketRSSI;
	RF2xxDriverLayerP.PacketTimeSyncOffset -> RF2xxPacketC.PacketTimeSyncOffset;
	RF2xxDriverLayerP.PacketTimeStamp -> RF2xxPacketC;
	RF2xxDriverLayerP.LocalTime -> LocalTimeRadioC;

	RF2xxDriverLayerP.RadioAlarm -> RadioAlarmC.RadioAlarm[unique("RadioAlarm")];
	RadioAlarmC.Alarm -> HplRF2xxC.Alarm;

	RF2xxDriverLayerP.SELN -> HplRF2xxC.SELN;
	RF2xxDriverLayerP.SpiResource -> HplRF2xxC.SpiResource;
	RF2xxDriverLayerP.FastSpiByte -> HplRF2xxC;

	RF2xxDriverLayerP.SLP_TR -> HplRF2xxC.SLP_TR;
	RF2xxDriverLayerP.RSTN -> HplRF2xxC.RSTN;

	RF2xxDriverLayerP.IRQ -> HplRF2xxC.IRQ;
	RF2xxDriverLayerP.Tasklet -> TaskletC;
	RF2xxDriverLayerP.BusyWait -> BusyWaitMicroC;

#ifdef RF2XX_DEBUG
	components DiagMsgC;
	RF2xxDriverLayerP.DiagMsg -> DiagMsgC;
#endif

	MainC.SoftwareInit -> RF2xxDriverLayerP.SoftwareInit;

	components RealMainP;
	RealMainP.PlatformInit -> RF2xxDriverLayerP.PlatformInit;
}
