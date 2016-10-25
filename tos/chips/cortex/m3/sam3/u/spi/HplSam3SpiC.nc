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

#include "sam3spihardware.h"

configuration HplSam3SpiC
{
    provides
    {
       interface AsyncStdControl;
       interface HplSam3SpiConfig; 
       interface HplSam3SpiControl; 
       interface HplSam3SpiInterrupts; 
       interface HplSam3SpiStatus; 
       interface HplSam3SpiChipSelConfig as HplSam3SpiChipSelConfig0;
       interface HplSam3SpiChipSelConfig as HplSam3SpiChipSelConfig1;
       interface HplSam3SpiChipSelConfig as HplSam3SpiChipSelConfig2;
       interface HplSam3SpiChipSelConfig as HplSam3SpiChipSelConfig3;
    }
}
implementation
{
    components HplSam3SpiP;
    AsyncStdControl = HplSam3SpiP;
    HplSam3SpiConfig = HplSam3SpiP;
    HplSam3SpiControl = HplSam3SpiP;
    HplSam3SpiInterrupts = HplSam3SpiP;
    HplSam3SpiStatus = HplSam3SpiP;
    
    components
        new HplSam3SpiChipSelP(0x40008030) as CS0,
        new HplSam3SpiChipSelP(0x40008034) as CS1,
        new HplSam3SpiChipSelP(0x40008038) as CS2,
        new HplSam3SpiChipSelP(0x4000803C) as CS3;

    HplSam3SpiChipSelConfig0 = CS0;
    HplSam3SpiChipSelConfig1 = CS1;
    HplSam3SpiChipSelConfig2 = CS2;
    HplSam3SpiChipSelConfig3 = CS3;

    components HplSam3uClockC;
    HplSam3SpiP.SpiClockControl -> HplSam3uClockC.SPI0PPCntl;
    HplSam3SpiP.ClockConfig -> HplSam3uClockC;

    components McuSleepC;
    HplSam3SpiP.McuSleep -> McuSleepC;
}

