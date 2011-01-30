/**
 * "Copyright (c) 2009 The Regents of the University of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * The hardware presentation layer for the SAM3U SPI.
 *
 * @author Thomas Schmid
 */

#include "sam3uspihardware.h"

configuration HplSam3uSpiC
{
    provides
    {
       interface AsyncStdControl;
       interface HplSam3uSpiConfig; 
       interface HplSam3uSpiControl; 
       interface HplSam3uSpiInterrupts; 
       interface HplSam3uSpiStatus; 
       interface HplSam3uSpiChipSelConfig as HplSam3uSpiChipSelConfig0;
       interface HplSam3uSpiChipSelConfig as HplSam3uSpiChipSelConfig1;
       interface HplSam3uSpiChipSelConfig as HplSam3uSpiChipSelConfig2;
       interface HplSam3uSpiChipSelConfig as HplSam3uSpiChipSelConfig3;
    }
}
implementation
{
    components HplSam3uSpiP;
    AsyncStdControl = HplSam3uSpiP;
    HplSam3uSpiConfig = HplSam3uSpiP;
    HplSam3uSpiControl = HplSam3uSpiP;
    HplSam3uSpiInterrupts = HplSam3uSpiP;
    HplSam3uSpiStatus = HplSam3uSpiP;
    
    components
        new HplSam3uSpiChipSelP(0x40008030) as CS0,
        new HplSam3uSpiChipSelP(0x40008034) as CS1,
        new HplSam3uSpiChipSelP(0x40008038) as CS2,
        new HplSam3uSpiChipSelP(0x4000803C) as CS3;

    HplSam3uSpiChipSelConfig0 = CS0;
    HplSam3uSpiChipSelConfig1 = CS1;
    HplSam3uSpiChipSelConfig2 = CS2;
    HplSam3uSpiChipSelConfig3 = CS3;

    components HplSam3uClockC;
    HplSam3uSpiP.SpiClockControl -> HplSam3uClockC.SPI0PPCntl;
    HplSam3uSpiP.ClockConfig -> HplSam3uClockC;

    components McuSleepC;
    HplSam3uSpiP.SpiInterruptWrapper -> McuSleepC;
}

