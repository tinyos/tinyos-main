/*
 * Copyright (c) 2005 Arched Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arched Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/** 
 * @author Phil Buonadonna
 *
 */

configuration HplPXA27xOSTimerC {

  provides {
    interface Init;
    interface HplPXA27xOSTimer as OST0;
    interface HplPXA27xOSTimer as OST0M1;
    interface HplPXA27xOSTimer as OST0M2;
    interface HplPXA27xOSTimer as OST0M3;
    interface HplPXA27xOSTimer as OST4;
    interface HplPXA27xOSTimer as OST5;
    interface HplPXA27xOSTimer as OST6;
    interface HplPXA27xOSTimer as OST7;
    interface HplPXA27xOSTimer as OST8;
    interface HplPXA27xOSTimer as OST9;
    interface HplPXA27xOSTimer as OST10;
    interface HplPXA27xOSTimer as OST11;
    interface HplPXA27xOSTimerWatchdog as OSTWDCntl;
  }

}

implementation {
  components HplPXA27xOSTimerM, HplPXA27xInterruptM;

  Init = HplPXA27xOSTimerM;

  OST0 = HplPXA27xOSTimerM.PXA27xOST[0];
  OST0M1 = HplPXA27xOSTimerM.PXA27xOST[1];
  OST0M2 = HplPXA27xOSTimerM.PXA27xOST[2];
  OST0M3 = HplPXA27xOSTimerM.PXA27xOST[3];
  OST4 = HplPXA27xOSTimerM.PXA27xOST[4];
  OST5 = HplPXA27xOSTimerM.PXA27xOST[5];
  OST6 = HplPXA27xOSTimerM.PXA27xOST[6];
  OST7 = HplPXA27xOSTimerM.PXA27xOST[7];
  OST8 = HplPXA27xOSTimerM.PXA27xOST[8];
  OST9 = HplPXA27xOSTimerM.PXA27xOST[9];
  OST10 = HplPXA27xOSTimerM.PXA27xOST[10];
  OST11 = HplPXA27xOSTimerM.PXA27xOST[11];
  OSTWDCntl = HplPXA27xOSTimerM.PXA27xWD;
  
  HplPXA27xOSTimerM.OST0Irq -> HplPXA27xInterruptM.PXA27xIrq[PPID_OST_0];
  HplPXA27xOSTimerM.OST1Irq -> HplPXA27xInterruptM.PXA27xIrq[PPID_OST_1];
  HplPXA27xOSTimerM.OST2Irq -> HplPXA27xInterruptM.PXA27xIrq[PPID_OST_2];
  HplPXA27xOSTimerM.OST3Irq -> HplPXA27xInterruptM.PXA27xIrq[PPID_OST_3];
  HplPXA27xOSTimerM.OST4_11Irq -> HplPXA27xInterruptM.PXA27xIrq[PPID_OST_4_11];
}
