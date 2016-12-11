/*
 * Copyright (c) 2016 Eric B. Decker
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
 * - Neither the name of the copyright holders nor the names of
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
 * Msp432Timer32khzMapC presents as paramaterized interfaces all of the 32khz
 * hardware timers on the MSP432 that are available for compile time allocation
 * by "new Alarm32khz16C()", "new AlarmMilli32C()", and so on.
 *
 * Platforms based on the MSP432 are encouraged to copy in and override this
 * file, presenting only the hardware timers that are available for allocation
 * on that platform.
 *
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * TMilli (32KiHz) timing is assigned to TA1.   TMicro is assigned to TA0.
 */

configuration Msp432Timer32khzMapC {
  provides {
    interface Msp432Timer[uint8_t id];
    interface Msp432TimerCCTL[uint8_t id];
    interface Msp432TimerCompare[uint8_t id];
  }
}
implementation {
  components Msp432TimerC, PlatformC;

  PlatformC.PeripheralInit -> Msp432TimerC.Timer_A1_Init;
  Msp432Timer[0]        = Msp432TimerC.xTimer_A1;
  Msp432TimerCCTL[0]    = Msp432TimerC.Timer_CCTLA1_0;
  Msp432TimerCompare[0] = Msp432TimerC.Timer_COMPA1_0;

  Msp432Timer[1]        = Msp432TimerC.xTimer_A1;
  Msp432TimerCCTL[1]    = Msp432TimerC.Timer_CCTLA1_1;
  Msp432TimerCompare[1] = Msp432TimerC.Timer_COMPA1_1;

  Msp432Timer[2]        = Msp432TimerC.xTimer_A1;
  Msp432TimerCCTL[2]    = Msp432TimerC.Timer_CCTLA1_2;
  Msp432TimerCompare[2] = Msp432TimerC.Timer_COMPA1_2;

  Msp432Timer[3]        = Msp432TimerC.xTimer_A1;
  Msp432TimerCCTL[3]    = Msp432TimerC.Timer_CCTLA1_3;
  Msp432TimerCompare[3] = Msp432TimerC.Timer_COMPA1_3;

  Msp432Timer[4]        = Msp432TimerC.xTimer_A1;
  Msp432TimerCCTL[4]    = Msp432TimerC.Timer_CCTLA1_4;
  Msp432TimerCompare[4] = Msp432TimerC.Timer_COMPA1_4;
}
