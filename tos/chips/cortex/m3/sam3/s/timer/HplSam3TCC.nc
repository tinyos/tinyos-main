/*
 * Copyright (c) 2011 University of Utah.
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
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Top level configuration of the timer counter peripheral.
 *
 * @author Thomas Schmid
 */

#include <sam3tchardware.h>

configuration HplSam3TCC
{

    provides
    {
        interface Init;

        interface HplSam3TC as TC0;
        interface HplSam3TC as TC1;

        interface HplSam3TCChannel as TCH0;
        interface HplSam3TCChannel as TCH1;
        interface HplSam3TCChannel as TCH2;
        interface HplSam3TCChannel as TCH3;
        interface HplSam3TCChannel as TCH4;
        interface HplSam3TCChannel as TCH5;

        interface HplSam3TCCapture as TC0Capture;
        interface HplSam3TCCompare as TC0CompareA;
        interface HplSam3TCCompare as TC0CompareB;
        interface HplSam3TCCompare as TC0CompareC;

        interface HplSam3TCCapture as TC1Capture;
        interface HplSam3TCCompare as TC1CompareA;
        interface HplSam3TCCompare as TC1CompareB;
        interface HplSam3TCCompare as TC1CompareC;
        
        interface HplSam3TCCapture as TC2Capture;
        interface HplSam3TCCompare as TC2CompareA;
        interface HplSam3TCCompare as TC2CompareB;
        interface HplSam3TCCompare as TC2CompareC;
        
        interface HplSam3TCCapture as TC3Capture;
        interface HplSam3TCCompare as TC3CompareA;
        interface HplSam3TCCompare as TC3CompareB;
        interface HplSam3TCCompare as TC3CompareC;
        
        interface HplSam3TCCapture as TC4Capture;
        interface HplSam3TCCompare as TC4CompareA;
        interface HplSam3TCCompare as TC4CompareB;
        interface HplSam3TCCompare as TC4CompareC;
        
        interface HplSam3TCCapture as TC5Capture;
        interface HplSam3TCCompare as TC5CompareA;
        interface HplSam3TCCompare as TC5CompareB;
        interface HplSam3TCCompare as TC5CompareC;
    }
}

implementation
{
    components HplNVICC,
               HplSam3TCEventP,
               HplSam3sClockC,
               new HplSam3TCChannelP( TC_CH0_BASE )  as TCCH0,
               new HplSam3TCChannelP( TC_CH1_BASE )  as TCCH1,
               new HplSam3TCChannelP( TC_CH2_BASE )  as TCCH2,
               new HplSam3TCChannelP( TC1_CH0_BASE ) as TCCH3,
               new HplSam3TCChannelP( TC1_CH1_BASE ) as TCCH4,
               new HplSam3TCChannelP( TC1_CH2_BASE ) as TCCH5;

    components McuSleepC;
    HplSam3TCEventP.McuSleep -> McuSleepC;

    TCH0 = TCCH0;
    TCH1 = TCCH1;
    TCH2 = TCCH2;
    TCH3 = TCCH3;
    TCH4 = TCCH4;
    TCH5 = TCCH5;

    TCCH0.NVICTCInterrupt -> HplNVICC.TC0Interrupt;
    TCCH0.TimerEvent -> HplSam3TCEventP.TC0Event;
    TCCH0.TCPClockCntl -> HplSam3sClockC.TC0Cntl;
    TCCH0.ClockConfig -> HplSam3sClockC;

    TCCH1.NVICTCInterrupt -> HplNVICC.TC1Interrupt;
    TCCH1.TimerEvent -> HplSam3TCEventP.TC1Event;
    TCCH1.TCPClockCntl -> HplSam3sClockC.TC1Cntl;
    TCCH1.ClockConfig -> HplSam3sClockC;

    TCCH2.NVICTCInterrupt -> HplNVICC.TC2Interrupt;
    TCCH2.TimerEvent -> HplSam3TCEventP.TC2Event;
    TCCH2.TCPClockCntl -> HplSam3sClockC.TC2Cntl;
    TCCH2.ClockConfig -> HplSam3sClockC;

    TCCH3.NVICTCInterrupt -> HplNVICC.TC3Interrupt;
    TCCH3.TimerEvent -> HplSam3TCEventP.TC3Event;
    TCCH3.TCPClockCntl -> HplSam3sClockC.TC3Cntl;
    TCCH3.ClockConfig -> HplSam3sClockC;

    TCCH4.NVICTCInterrupt -> HplNVICC.TC4Interrupt;
    TCCH4.TimerEvent -> HplSam3TCEventP.TC4Event;
    TCCH4.TCPClockCntl -> HplSam3sClockC.TC4Cntl;
    TCCH4.ClockConfig -> HplSam3sClockC;

    TCCH5.NVICTCInterrupt -> HplNVICC.TC5Interrupt;
    TCCH5.TimerEvent -> HplSam3TCEventP.TC5Event;
    TCCH5.TCPClockCntl -> HplSam3sClockC.TC5Cntl;
    TCCH5.ClockConfig -> HplSam3sClockC;

    TC0Capture = TCCH0.Capture; 
    TC0CompareA = TCCH0.CompareA;
    TC0CompareB = TCCH0.CompareB;
    TC0CompareC = TCCH0.CompareC;

    TC1Capture = TCCH1.Capture; 
    TC1CompareA = TCCH1.CompareA;
    TC1CompareB = TCCH1.CompareB;
    TC1CompareC = TCCH1.CompareC;

    TC2Capture = TCCH2.Capture; 
    TC2CompareA = TCCH2.CompareA;
    TC2CompareB = TCCH2.CompareB;
    TC2CompareC = TCCH2.CompareC;

    TC3Capture = TCCH3.Capture; 
    TC3CompareA = TCCH3.CompareA;
    TC3CompareB = TCCH3.CompareB;
    TC3CompareC = TCCH3.CompareC;

    TC4Capture = TCCH4.Capture; 
    TC4CompareA = TCCH4.CompareA;
    TC4CompareB = TCCH4.CompareB;
    TC4CompareC = TCCH4.CompareC;

    TC5Capture = TCCH5.Capture; 
    TC5CompareA = TCCH5.CompareA;
    TC5CompareB = TCCH5.CompareB;
    TC5CompareC = TCCH5.CompareC;

    components new HplSam3TCP(TC_BASE) as HplTC0;
    components new HplSam3TCP(TC1_BASE) as HplTC1;
    Init = HplTC0;
    Init = HplTC1;

    HplTC0.ClockConfig -> HplSam3sClockC;
    HplTC1.ClockConfig -> HplSam3sClockC;

    HplTC0.TC0 -> TCCH0;
    HplTC0.TC1 -> TCCH1;
    HplTC0.TC2 -> TCCH2;

    HplTC1.TC0 -> TCCH3;
    HplTC1.TC1 -> TCCH4;
    HplTC1.TC2 -> TCCH5;

    HplTC0 = TC0;
    HplTC1 = TC1;
}
