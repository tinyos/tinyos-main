/*
 * Copyright (c) 2016, Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Author: Eric B. Decker <cire831@gmail.com>
 *
 * Msp432TimerMicroMapC
 *
 * The msp432 has 2 T32 (32 bit) and 3-4 TA (16 bit) timer blocks.
 * We only deal with the TA timers here.
 * 
 * TA0 is a Tmicro (usec) and TA1 is a Tmilli (msec, 32KiHz ticked).
 */

configuration Msp432TimerMicroMapC {
  provides interface Msp432Timer[uint8_t id];
  provides interface Msp432TimerCCTL[uint8_t id];
  provides interface Msp432TimerCompare[uint8_t id];
}
implementation {
  components Msp432TimerC, PlatformC;

  PlatformC.PeripheralInit -> Msp432TimerC.Timer_A0_Init;
  Msp432Timer[0] = Msp432TimerC.xTimer_A0;
  Msp432TimerCCTL[0] = Msp432TimerC.CCTLA0_0;
  Msp432TimerCompare[0] = Msp432TimerC.COMPA0_0;

  Msp432Timer[1] = Msp432TimerC.xTimer_A0;
  Msp432TimerCCTL[1] = Msp432TimerC.CCTLA0_1;
  Msp432TimerCompare[1] = Msp432TimerC.COMPA0_1;

  Msp432Timer[2] = Msp432TimerC.xTimer_A0;
  Msp432TimerCCTL[2] = Msp432TimerC.CCTLA0_2;
  Msp432TimerCompare[2] = Msp432TimerC.COMPA0_2;

  Msp432Timer[3] = Msp432TimerC.xTimer_A0;
  Msp432TimerCCTL[3] = Msp432TimerC.CCTLA0_3;
  Msp432TimerCompare[3] = Msp432TimerC.COMPA0_3;

  Msp432Timer[4] = Msp432TimerC.xTimer_A0;
  Msp432TimerCCTL[4] = Msp432TimerC.CCTLA0_4;
  Msp432TimerCompare[4] = Msp432TimerC.COMPA0_4;
}
