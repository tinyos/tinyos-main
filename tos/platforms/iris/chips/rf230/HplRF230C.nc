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

configuration HplRF230C
{
	provides
	{
		interface GeneralIO as SELN;
		interface Resource as SpiResource;
		interface SpiByte;

		interface GeneralIO as SLP_TR;
		interface GeneralIO as RSTN;

		interface GpioCapture as IRQ;
		interface Alarm<TRF230, uint16_t> as Alarm;

		interface HplRF230;
	}
}

implementation
{
	components HplRF230P;
	IRQ = HplRF230P.IRQ;

	HplRF230P.PortCLKM -> IO.PortD6;
	HplRF230P.PortIRQ -> IO.PortD4;
	
	// TODO: Ask why the HplAtm128SpiC does SlaveSelect via PortB0
	// TODO: Remove the unused started field from Atm128SpiP
	components Atm128SpiC as SpiC;
	SpiResource = SpiC.Resource[unique("Atm128SpiC.Resource")];
	SpiByte = SpiC;

	HplRF230 = HplRF230P;

	components HplAtm128GeneralIOC as IO;
	SLP_TR = IO.PortB7;
	RSTN = IO.PortA6;
	SELN = IO.PortB0;

	components HplAtm128Timer1C as TimerC;
	HplRF230P.Capture -> TimerC.Capture;

	components new AlarmOne16C() as AlarmC;
	Alarm = AlarmC;

	components RealMainP;
	RealMainP.PlatformInit -> HplRF230P.PlatformInit;
}
