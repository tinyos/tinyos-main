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
 * @author Eric B. Decker <cire831@gmail.com>
 */

#ifndef __MSP432TIMER_H__
#define __MSP432TIMER_H__

enum {
  /* clock src (TAx->CTL.SSEL) */
  MSP432TIMER_TACLK             = 0,
  MSP432TIMER_ACLK              = 1,
  MSP432TIMER_SMCLK             = 2,
  MSP432TIMER_INCLK             = 3,

  /* divider (TAx->CTL.ID) */
  MSP432TIMER_CLOCKDIV_1        = 0,
  MSP432TIMER_CLOCKDIV_2        = 1,
  MSP432TIMER_CLOCKDIV_4        = 2,
  MSP432TIMER_CLOCKDIV_8        = 3,

  /* mode control (TAx->CTL.MC) */
  MSP432TIMER_STOP_MODE         = 0,
  MSP432TIMER_UP_MODE           = 1,
  MSP432TIMER_CONTINUOUS_MODE   = 2,
  MSP432TIMER_UPDOWN_MODE       = 3,

  /* capture mode (TAn->CCTLn) */
  MSP432TIMER_CM_NONE           = 0,
  MSP432TIMER_CM_RISING         = 1,
  MSP432TIMER_CM_FALLING        = 2,
  MSP432TIMER_CM_BOTH           = 3,

  MSP432TIMER_CCI_A             = 0,
  MSP432TIMER_CCI_B             = 1,
  MSP432TIMER_CCI_GND           = 2,
  MSP432TIMER_CCI_VCC           = 3,
};

#endif  // __MSP432TIMER_H__
