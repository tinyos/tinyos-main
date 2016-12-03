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

#include "Msp432Timer.h"

interface Msp432TimerCCTL {
  async command bool     isInterruptPending();
  async command void     clearPendingInterrupt();

  /* provides raw access to the CCR control register */
  async command void     setCCTL(uint16_t cctl);
  async command uint16_t getCCTL();

  /**
   * setCCRforCompare sets the timer's CCR up for use as
   * a compare block.  Uses default values for control bits.
   */
  async command void setCCRforCompare();
  
  /**
   * setCCRforCapture, sets up the timer/CCR for capture.
   * cm defines the edge, ccis defines what is being captured.
   *
   * @param cm configures the capture to occur on none, rising, falling or rising_and_falling edges
   * @param ccis configures which input channel to use.
   *
   * Msp432Timer.h has convenience definitions:
   *
   *     MSP432TIMER_CM_NONE,            MSP432TIMER_CCI_A
   *     MSP432TIMER_CM_RISING,          MSP432TIMER_CCI_B
   *     MSP432TIMER_CM_FALLING,         MSP432TIMER_CCI_GND
   *     MSP432TIMER_CM_BOTH             MSP432TIMER_CCI_VCC
   */ 

  async command void setCCRforCapture(uint8_t cm, uint8_t ccis);

  /* turn on/off CCIE to enable generation of CCR event interrupt */
  async command void enableEvents();
  async command void disableEvents();
  async command bool areEventsEnabled();
}
