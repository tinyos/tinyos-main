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

#include <Msp432Timer.h>

interface Msp432TimerCaptureV2 {
  /**
   * Reads the value of the last capture event in TAx->CCR[x]
   */
  async command uint16_t getEvent();

  /**
   * Set the edge that the capture should occur
   *
   * @param cm Capture Mode for edge capture.
   * enums exist for:
   *   MSP432TIMER_CM_NONE is no capture.
   *   MSP432TIMER_CM_RISING is rising edge capture.
   *   MSP432TIMER_CM_FALLING is a falling edge capture.
   *   MSP432TIMER_CM_BOTH captures on both rising and falling edges.
   */
  async command void setEdge(uint8_t cm);

  /**
   * Determine if a capture overflow is pending.
   *
   * @return TRUE if the capture register has overflowed
   */
  async command bool isOverflowPending();

  /**
   * Clear the capture overflow flag for when multiple captures occur
   */
  async command void clearOverflow();

  /**
   * Set whether the capture should occur synchronously or asynchronously.
   * TinyOS default is synchronous captures.
   *
   * WARNING: if the capture signal is asynchronous to the timer clock,
   *          it could cause a race condition (see Timer documentation
   *          in MSP432 TRM section 17.2.4.1)
   *
   * @param synchronous TRUE to synchronize the timer capture with the
   *        next timer clock instead of occurring asynchronously.
   */
  async command void setSynchronous(bool synchronous);

  /**
   * Signalled when an event is captured.
   *
   * @param time The time of the capture event.
   * @param overflowed  true if time has overwritten previous unread value.
   */
  async event void captured(uint16_t time, bool overflowed);
}
