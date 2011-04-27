/*
 * Copyright (c) 2011, Vanderbilt University
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

	components HplMsp430GeneralIOC as IO, new Msp430Spi1C() as SpiC;

	// pins
	components new Msp430GpioC() as CCAM;
	components new Msp430GpioC() as CSNM;
	components new Msp430GpioC() as FIFOM;
	components new Msp430GpioC() as FIFOPM;
	components new Msp430GpioC() as RSTNM;
	components new Msp430GpioC() as SFDM;
	components new Msp430GpioC() as VRENM;
	
	CCAM -> IO.Port27;
	CSNM -> IO.Port54;
	FIFOM -> IO.Port15;
	FIFOPM -> IO.Port10;
	RSTNM -> IO.Port57;
	SFDM -> IO.Port12;
	VRENM -> IO.Port56;
	
	CCA = CCAM;
	CSN = CSNM;
	FIFO = FIFOM;
	FIFOP = FIFOPM;
	RSTN = RSTNM;
	SFD = SFDM;
	VREN = VRENM;

	// spi	
	SpiResource = SpiC.Resource;
	FastSpiByte = SpiC;

	// capture
	components Msp430TimerC as TimerC;
	components new GpioCaptureC();
	GpioCaptureC.Msp430TimerControl -> TimerC.ControlA1;
	GpioCaptureC.Msp430Capture -> TimerC.CaptureA1;
	GpioCaptureC.GeneralIO -> IO.Port12;
 	SfdCapture = GpioCaptureC;

  	components new Msp430InterruptC() as FifopInterruptC, HplMsp430InterruptC;
	FifopInterruptC.HplInterrupt -> HplMsp430InterruptC.Port10;
	FifopInterrupt = FifopInterruptC.Interrupt; 

	// alarm
	components new AlarmMicro16C() as AlarmC;
	Alarm = AlarmC;
	Init = AlarmC;

	// localTime
	components LocalTimeMicroC;
	LocalTimeRadio = LocalTimeMicroC.LocalTime;

}
