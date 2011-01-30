/**
 * Copyright (c) 2009 The Regents of the University of California.
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
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
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

