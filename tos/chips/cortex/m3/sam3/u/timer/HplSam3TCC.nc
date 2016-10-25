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

	interface HplSam3TC as TC;

        interface HplSam3TCChannel as TCH0;
        interface HplSam3TCChannel as TCH1;
        interface HplSam3TCChannel as TCH2;

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
    }
}

implementation
{
    components HplNVICC,
               HplSam3TCEventP,
               HplSam3uClockC,
               new HplSam3TCChannelP( TC_CH0_BASE ) as TCCH0,
               new HplSam3TCChannelP( TC_CH1_BASE ) as TCCH1,
               new HplSam3TCChannelP( TC_CH2_BASE ) as TCCH2;

    components McuSleepC;
    HplSam3TCEventP.McuSleep -> McuSleepC;

    TCH0 = TCCH0;
    TCH1 = TCCH1;
    TCH2 = TCCH2;

    TCCH0.NVICTCInterrupt -> HplNVICC.TC0Interrupt;
    TCCH0.TimerEvent -> HplSam3TCEventP.TC0Event;
    TCCH0.TCPClockCntl -> HplSam3uClockC.TC0PPCntl;
    TCCH0.ClockConfig -> HplSam3uClockC;

    TCCH1.NVICTCInterrupt -> HplNVICC.TC1Interrupt;
    TCCH1.TimerEvent -> HplSam3TCEventP.TC1Event;
    TCCH1.TCPClockCntl -> HplSam3uClockC.TC1PPCntl;
    TCCH1.ClockConfig -> HplSam3uClockC;

    TCCH2.NVICTCInterrupt -> HplNVICC.TC2Interrupt;
    TCCH2.TimerEvent -> HplSam3TCEventP.TC2Event;
    TCCH2.TCPClockCntl -> HplSam3uClockC.TC2PPCntl;
    TCCH2.ClockConfig -> HplSam3uClockC;

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

    components new HplSam3TCP(TC_BASE);
    Init = HplSam3TCP;
    HplSam3TCP.ClockConfig -> HplSam3uClockC;
    HplSam3TCP.TC0 -> TCCH0;
    HplSam3TCP.TC1 -> TCCH1;
    HplSam3TCP.TC2 -> TCCH2;
    TC = HplSam3TCP;
}
