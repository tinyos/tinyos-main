/*
 * Copyright (c) 2009 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Abstraction of a PIO controller on the SAM3. Has 32 pins.
 *
 * @author wanja@cs.fau.de
 */

generic configuration HplSam3GeneralIOPioC(uint32_t pio_addr)
{
	provides {
		interface GeneralIO as Pin0;
		interface GeneralIO as Pin1;
		interface GeneralIO as Pin2;
		interface GeneralIO as Pin3;
		interface GeneralIO as Pin4;
		interface GeneralIO as Pin5;
		interface GeneralIO as Pin6;
		interface GeneralIO as Pin7;
		interface GeneralIO as Pin8;
		interface GeneralIO as Pin9;
		interface GeneralIO as Pin10;
		interface GeneralIO as Pin11;
		interface GeneralIO as Pin12;
		interface GeneralIO as Pin13;
		interface GeneralIO as Pin14;
		interface GeneralIO as Pin15;
		interface GeneralIO as Pin16;
		interface GeneralIO as Pin17;
		interface GeneralIO as Pin18;
		interface GeneralIO as Pin19;
		interface GeneralIO as Pin20;
		interface GeneralIO as Pin21;
		interface GeneralIO as Pin22;
		interface GeneralIO as Pin23;
		interface GeneralIO as Pin24;
		interface GeneralIO as Pin25;
		interface GeneralIO as Pin26;
		interface GeneralIO as Pin27;
		interface GeneralIO as Pin28;
		interface GeneralIO as Pin29;
		interface GeneralIO as Pin30;
		interface GeneralIO as Pin31;

		interface HplSam3GeneralIOPin as HplPin0;
		interface HplSam3GeneralIOPin as HplPin1;
		interface HplSam3GeneralIOPin as HplPin2;
		interface HplSam3GeneralIOPin as HplPin3;
		interface HplSam3GeneralIOPin as HplPin4;
		interface HplSam3GeneralIOPin as HplPin5;
		interface HplSam3GeneralIOPin as HplPin6;
		interface HplSam3GeneralIOPin as HplPin7;
		interface HplSam3GeneralIOPin as HplPin8;
		interface HplSam3GeneralIOPin as HplPin9;
		interface HplSam3GeneralIOPin as HplPin10;
		interface HplSam3GeneralIOPin as HplPin11;
		interface HplSam3GeneralIOPin as HplPin12;
		interface HplSam3GeneralIOPin as HplPin13;
		interface HplSam3GeneralIOPin as HplPin14;
		interface HplSam3GeneralIOPin as HplPin15;
		interface HplSam3GeneralIOPin as HplPin16;
		interface HplSam3GeneralIOPin as HplPin17;
		interface HplSam3GeneralIOPin as HplPin18;
		interface HplSam3GeneralIOPin as HplPin19;
		interface HplSam3GeneralIOPin as HplPin20;
		interface HplSam3GeneralIOPin as HplPin21;
		interface HplSam3GeneralIOPin as HplPin22;
		interface HplSam3GeneralIOPin as HplPin23;
		interface HplSam3GeneralIOPin as HplPin24;
		interface HplSam3GeneralIOPin as HplPin25;
		interface HplSam3GeneralIOPin as HplPin26;
		interface HplSam3GeneralIOPin as HplPin27;
		interface HplSam3GeneralIOPin as HplPin28;
		interface HplSam3GeneralIOPin as HplPin29;
		interface HplSam3GeneralIOPin as HplPin30;
		interface HplSam3GeneralIOPin as HplPin31;

		interface GpioInterrupt as InterruptPin0;
		interface GpioInterrupt as InterruptPin1;
		interface GpioInterrupt as InterruptPin2;
		interface GpioInterrupt as InterruptPin3;
		interface GpioInterrupt as InterruptPin4;
		interface GpioInterrupt as InterruptPin5;
		interface GpioInterrupt as InterruptPin6;
		interface GpioInterrupt as InterruptPin7;
		interface GpioInterrupt as InterruptPin8;
		interface GpioInterrupt as InterruptPin9;
		interface GpioInterrupt as InterruptPin10;
		interface GpioInterrupt as InterruptPin11;
		interface GpioInterrupt as InterruptPin12;
		interface GpioInterrupt as InterruptPin13;
		interface GpioInterrupt as InterruptPin14;
		interface GpioInterrupt as InterruptPin15;
		interface GpioInterrupt as InterruptPin16;
		interface GpioInterrupt as InterruptPin17;
		interface GpioInterrupt as InterruptPin18;
		interface GpioInterrupt as InterruptPin19;
		interface GpioInterrupt as InterruptPin20;
		interface GpioInterrupt as InterruptPin21;
		interface GpioInterrupt as InterruptPin22;
		interface GpioInterrupt as InterruptPin23;
		interface GpioInterrupt as InterruptPin24;
		interface GpioInterrupt as InterruptPin25;
		interface GpioInterrupt as InterruptPin26;
		interface GpioInterrupt as InterruptPin27;
		interface GpioInterrupt as InterruptPin28;
		interface GpioInterrupt as InterruptPin29;
		interface GpioInterrupt as InterruptPin30;
		interface GpioInterrupt as InterruptPin31;

		interface GpioCapture as CapturePin0;
		interface GpioCapture as CapturePin1;
		interface GpioCapture as CapturePin2;
		interface GpioCapture as CapturePin3;
		interface GpioCapture as CapturePin4;
		interface GpioCapture as CapturePin5;
		interface GpioCapture as CapturePin6;
		interface GpioCapture as CapturePin7;
		interface GpioCapture as CapturePin8;
		interface GpioCapture as CapturePin9;
		interface GpioCapture as CapturePin10;
		interface GpioCapture as CapturePin11;
		interface GpioCapture as CapturePin12;
		interface GpioCapture as CapturePin13;
		interface GpioCapture as CapturePin14;
		interface GpioCapture as CapturePin15;
		interface GpioCapture as CapturePin16;
		interface GpioCapture as CapturePin17;
		interface GpioCapture as CapturePin18;
		interface GpioCapture as CapturePin19;
		interface GpioCapture as CapturePin20;
		interface GpioCapture as CapturePin21;
		interface GpioCapture as CapturePin22;
		interface GpioCapture as CapturePin23;
		interface GpioCapture as CapturePin24;
		interface GpioCapture as CapturePin25;
		interface GpioCapture as CapturePin26;
		interface GpioCapture as CapturePin27;
		interface GpioCapture as CapturePin28;
		interface GpioCapture as CapturePin29;
		interface GpioCapture as CapturePin30;
		interface GpioCapture as CapturePin31;
	}
    uses
    {
        interface HplSam3GeneralIOPort as HplPort;
        interface HplNVICInterruptCntl as PIOIrqControl;
        interface HplSam3PeripheralClockCntl as PIOClockControl;
    }
}
implementation
{
	components 
	new HplSam3GeneralIOPinP(pio_addr, 0) as Bit0,
	new HplSam3GeneralIOPinP(pio_addr, 1) as Bit1,
	new HplSam3GeneralIOPinP(pio_addr, 2) as Bit2,
	new HplSam3GeneralIOPinP(pio_addr, 3) as Bit3,
	new HplSam3GeneralIOPinP(pio_addr, 4) as Bit4,
	new HplSam3GeneralIOPinP(pio_addr, 5) as Bit5,
	new HplSam3GeneralIOPinP(pio_addr, 6) as Bit6,
	new HplSam3GeneralIOPinP(pio_addr, 7) as Bit7,
	new HplSam3GeneralIOPinP(pio_addr, 8) as Bit8,
	new HplSam3GeneralIOPinP(pio_addr, 9) as Bit9,
	new HplSam3GeneralIOPinP(pio_addr, 10) as Bit10,
	new HplSam3GeneralIOPinP(pio_addr, 11) as Bit11,
	new HplSam3GeneralIOPinP(pio_addr, 12) as Bit12,
	new HplSam3GeneralIOPinP(pio_addr, 13) as Bit13,
	new HplSam3GeneralIOPinP(pio_addr, 14) as Bit14,
	new HplSam3GeneralIOPinP(pio_addr, 15) as Bit15,
	new HplSam3GeneralIOPinP(pio_addr, 16) as Bit16,
	new HplSam3GeneralIOPinP(pio_addr, 17) as Bit17,
	new HplSam3GeneralIOPinP(pio_addr, 18) as Bit18,
	new HplSam3GeneralIOPinP(pio_addr, 19) as Bit19,
	new HplSam3GeneralIOPinP(pio_addr, 20) as Bit20,
	new HplSam3GeneralIOPinP(pio_addr, 21) as Bit21,
	new HplSam3GeneralIOPinP(pio_addr, 22) as Bit22,
	new HplSam3GeneralIOPinP(pio_addr, 23) as Bit23,
	new HplSam3GeneralIOPinP(pio_addr, 24) as Bit24,
	new HplSam3GeneralIOPinP(pio_addr, 25) as Bit25,
	new HplSam3GeneralIOPinP(pio_addr, 26) as Bit26,
	new HplSam3GeneralIOPinP(pio_addr, 27) as Bit27,
	new HplSam3GeneralIOPinP(pio_addr, 28) as Bit28,
	new HplSam3GeneralIOPinP(pio_addr, 29) as Bit29,
	new HplSam3GeneralIOPinP(pio_addr, 30) as Bit30,
	new HplSam3GeneralIOPinP(pio_addr, 31) as Bit31;

	Pin0 = Bit0;
	Pin1 = Bit1;
	Pin2 = Bit2;
	Pin3 = Bit3;
	Pin4 = Bit4;
	Pin5 = Bit5;
	Pin6 = Bit6;
	Pin7 = Bit7;
	Pin8 = Bit8;
	Pin9 = Bit9;
	Pin10 = Bit10;
	Pin11 = Bit11;
	Pin12 = Bit12;
	Pin13 = Bit13;
	Pin14 = Bit14;
	Pin15 = Bit15;
	Pin16 = Bit16;
	Pin17 = Bit17;
	Pin18 = Bit18;
	Pin19 = Bit19;
	Pin20 = Bit20;
	Pin21 = Bit21;
	Pin22 = Bit22;
	Pin23 = Bit23;
	Pin24 = Bit24;
	Pin25 = Bit25;
	Pin26 = Bit26;
	Pin27 = Bit27;
	Pin28 = Bit28;
	Pin29 = Bit29;
	Pin30 = Bit30;
	Pin31 = Bit31;

	HplPin0 = Bit0;
	HplPin1 = Bit1;
	HplPin2 = Bit2;
	HplPin3 = Bit3;
	HplPin4 = Bit4;
	HplPin5 = Bit5;
	HplPin6 = Bit6;
	HplPin7 = Bit7;
	HplPin8 = Bit8;
	HplPin9 = Bit9;
	HplPin10 = Bit10;
	HplPin11 = Bit11;
	HplPin12 = Bit12;
	HplPin13 = Bit13;
	HplPin14 = Bit14;
	HplPin15 = Bit15;
	HplPin16 = Bit16;
	HplPin17 = Bit17;
	HplPin18 = Bit18;
	HplPin19 = Bit19;
	HplPin20 = Bit20;
	HplPin21 = Bit21;
	HplPin22 = Bit22;
	HplPin23 = Bit23;
	HplPin24 = Bit24;
	HplPin25 = Bit25;
	HplPin26 = Bit26;
	HplPin27 = Bit27;
	HplPin28 = Bit28;
	HplPin29 = Bit29;
	HplPin30 = Bit30;
	HplPin31 = Bit31;

	InterruptPin0 = Bit0;
	InterruptPin1 = Bit1;
	InterruptPin2 = Bit2;
	InterruptPin3 = Bit3;
	InterruptPin4 = Bit4;
	InterruptPin5 = Bit5;
	InterruptPin6 = Bit6;
	InterruptPin7 = Bit7;
	InterruptPin8 = Bit8;
	InterruptPin9 = Bit9;
	InterruptPin10 = Bit10;
	InterruptPin11 = Bit11;
	InterruptPin12 = Bit12;
	InterruptPin13 = Bit13;
	InterruptPin14 = Bit14;
	InterruptPin15 = Bit15;
	InterruptPin16 = Bit16;
	InterruptPin17 = Bit17;
	InterruptPin18 = Bit18;
	InterruptPin19 = Bit19;
	InterruptPin20 = Bit20;
	InterruptPin21 = Bit21;
	InterruptPin22 = Bit22;
	InterruptPin23 = Bit23;
	InterruptPin24 = Bit24;
	InterruptPin25 = Bit25;
	InterruptPin26 = Bit26;
	InterruptPin27 = Bit27;
	InterruptPin28 = Bit28;
	InterruptPin29 = Bit29;
	InterruptPin30 = Bit30;
	InterruptPin31 = Bit31;

	CapturePin0 = Bit0;
	CapturePin1 = Bit1;
	CapturePin2 = Bit2;
	CapturePin3 = Bit3;
	CapturePin4 = Bit4;
	CapturePin5 = Bit5;
	CapturePin6 = Bit6;
	CapturePin7 = Bit7;
	CapturePin8 = Bit8;
	CapturePin9 = Bit9;
	CapturePin10 = Bit10;
	CapturePin11 = Bit11;
	CapturePin12 = Bit12;
	CapturePin13 = Bit13;
	CapturePin14 = Bit14;
	CapturePin15 = Bit15;
	CapturePin16 = Bit16;
	CapturePin17 = Bit17;
	CapturePin18 = Bit18;
	CapturePin19 = Bit19;
	CapturePin20 = Bit20;
	CapturePin21 = Bit21;
	CapturePin22 = Bit22;
	CapturePin23 = Bit23;
	CapturePin24 = Bit24;
	CapturePin25 = Bit25;
	CapturePin26 = Bit26;
	CapturePin27 = Bit27;
	CapturePin28 = Bit28;
	CapturePin29 = Bit29;
	CapturePin30 = Bit30;
	CapturePin31 = Bit31;

    components new HplSam3GeneralIOPortP(pio_addr) as Port;

    HplPort = Port.HplPort;
    PIOIrqControl = Port.PIOIrqControl;
    PIOClockControl = Port.PIOClockControl;


    Bit0.HplPort -> Port.Bits[0];
    Bit1.HplPort -> Port.Bits[1];
    Bit2.HplPort -> Port.Bits[2];
    Bit3.HplPort -> Port.Bits[3];
    Bit4.HplPort -> Port.Bits[4];
    Bit5.HplPort -> Port.Bits[5];
    Bit6.HplPort -> Port.Bits[6];
    Bit7.HplPort -> Port.Bits[7];
    Bit8.HplPort -> Port.Bits[8];
    Bit9.HplPort -> Port.Bits[9];
    Bit10.HplPort -> Port.Bits[10];
    Bit11.HplPort -> Port.Bits[11];
    Bit12.HplPort -> Port.Bits[12];
    Bit13.HplPort -> Port.Bits[13];
    Bit14.HplPort -> Port.Bits[14];
    Bit15.HplPort -> Port.Bits[15];
    Bit16.HplPort -> Port.Bits[16];
    Bit17.HplPort -> Port.Bits[17];
    Bit18.HplPort -> Port.Bits[18];
    Bit19.HplPort -> Port.Bits[19];
    Bit20.HplPort -> Port.Bits[20];
    Bit21.HplPort -> Port.Bits[21];
    Bit22.HplPort -> Port.Bits[22];
    Bit23.HplPort -> Port.Bits[23];
    Bit24.HplPort -> Port.Bits[24];
    Bit25.HplPort -> Port.Bits[25];
    Bit26.HplPort -> Port.Bits[26];
    Bit27.HplPort -> Port.Bits[27];
    Bit28.HplPort -> Port.Bits[28];
    Bit29.HplPort -> Port.Bits[29];
    Bit30.HplPort -> Port.Bits[30];
    Bit31.HplPort -> Port.Bits[31];
}
