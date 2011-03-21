/*
 * Copyright (c) 2010, Vanderbilt University
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
 * Author: Janos Sallai
 */

#include "RadioConfig.h"

configuration HplCC2420XC {
	provides {
		interface Resource as SpiResource;
		interface FastSpiByte;
		interface GeneralIO as CCA;
		interface GeneralIO as CSN;
		interface GeneralIO as FIFO;
		interface GeneralIO as FIFOP;
		interface GeneralIO as RSTN;
		interface GeneralIO as SFD;
		interface GeneralIO as VREN;
		interface GpioCapture as SfdCapture;
		interface GpioInterrupt as FifopInterrupt;
		interface LocalTime<TRadio> as LocalTimeRadio;
		interface Init;
		interface Alarm<TRadio,uint16_t>;
	}
}
implementation {

	components Atm128SpiC, MotePlatformC, HplCC2420XSpiP, HplAtm128GeneralIOC as IO;

	Init = Atm128SpiC;

	SpiResource = HplCC2420XSpiP.Resource;
	HplCC2420XSpiP.SubResource -> Atm128SpiC.Resource[ unique("Atm128SpiC.Resource") ];
	HplCC2420XSpiP.SS -> IO.PortB0;
	FastSpiByte = Atm128SpiC;

	CCA    = IO.PortD6;
	CSN    = IO.PortB0;
	FIFO   = IO.PortB7;
	FIFOP  = IO.PortE6;
	RSTN   = IO.PortA6;
	SFD    = IO.PortD4;
	VREN   = IO.PortA5;

	components new Atm128GpioCaptureC() as SfdCaptureC;
	components HplAtm128Timer1C as Timer1C;
	SfdCapture = SfdCaptureC;
	SfdCaptureC.Atm128Capture -> Timer1C.Capture;

	components new Atm128GpioInterruptC() as FifopInterruptC;
  	components HplAtm128InterruptC as Interrupts;
  	FifopInterrupt= FifopInterruptC;
  	FifopInterruptC.Atm128Interrupt -> Interrupts.Int6;

	components LocalTimeMicroC;
	LocalTimeRadio = LocalTimeMicroC.LocalTime;

	components new AlarmThree16C() as AlarmC;
	Alarm = AlarmC;
}
