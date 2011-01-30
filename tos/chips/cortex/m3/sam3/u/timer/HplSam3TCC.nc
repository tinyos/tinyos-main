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

        interface HplSam3TCChannel as TC0;
        interface HplSam3TCChannel as TC1;
        interface HplSam3TCChannel as TC2;

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
    HplSam3TCEventP.TC0InterruptWrapper -> McuSleepC;
    HplSam3TCEventP.TC1InterruptWrapper -> McuSleepC;
    HplSam3TCEventP.TC2InterruptWrapper -> McuSleepC;

    TC0 = TCCH0;
    TC1 = TCCH1;
    TC2 = TCCH2;

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

    components new HplSam3TCP();
    Init = HplSam3TCP;
    HplSam3TCP.ClockConfig -> HplSam3uClockC;
    HplSam3TCP.TC0 -> TCCH0;
    HplSam3TCP.TC1 -> TCCH1;
    HplSam3TCP.TC2 -> TCCH2;
    TC = HplSam3TCP;
}
