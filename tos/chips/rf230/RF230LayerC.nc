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

#include <HplRF230.h>

configuration RF230LayerC
{
	provides
	{
		interface RadioState;
		interface RadioSend;
		interface RadioReceive;
		interface RadioCCA;
	}

	uses 
	{
		interface RF230Config;
		interface PacketField<uint8_t> as PacketLinkQuality;
		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketTimeStamp<TRF230, uint16_t>;

		async event void lastTouch(message_t* msg);
	}
}

implementation
{
	components RF230LayerP, HplRF230C, BusyWaitMicroC, TaskletC, MainC, RadioAlarmC;

	RadioState = RF230LayerP;
	RadioSend = RF230LayerP;
	RadioReceive = RF230LayerP;
	RadioCCA = RF230LayerP;

	RF230Config = RF230LayerP;
	PacketLinkQuality = RF230LayerP.PacketLinkQuality;
	PacketTransmitPower = RF230LayerP.PacketTransmitPower;
	PacketTimeStamp = RF230LayerP.PacketTimeStamp;

	RF230LayerP.RadioAlarm -> RadioAlarmC.RadioAlarm[unique("RadioAlarm")];
	RadioAlarmC.Alarm -> HplRF230C.Alarm;

	RF230LayerP.SELN -> HplRF230C.SELN;
	RF230LayerP.SpiResource -> HplRF230C.SpiResource;
	RF230LayerP.SpiByte -> HplRF230C;
	RF230LayerP.HplRF230 -> HplRF230C;

	RF230LayerP.SLP_TR -> HplRF230C.SLP_TR;
	RF230LayerP.RSTN -> HplRF230C.RSTN;

	RF230LayerP.IRQ -> HplRF230C.IRQ;
	RF230LayerP.Tasklet -> TaskletC;
	RF230LayerP.BusyWait -> BusyWaitMicroC;

	lastTouch = RF230LayerP.lastTouch;

#ifdef RF230_DEBUG
	components DiagMsgC;
	RF230LayerP.DiagMsg -> DiagMsgC;
#endif

	MainC.SoftwareInit -> RF230LayerP.SoftwareInit;

	components RealMainP;
	RealMainP.PlatformInit -> RF230LayerP.PlatformInit;
}
