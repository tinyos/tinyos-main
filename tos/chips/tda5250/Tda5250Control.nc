/*
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 * - Revision -------------------------------------------------------------
 * $Revision: 1.3 $
 * $Date: 2006-11-07 19:31:15 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

#include "tda5250Control.h"
/** 
 * This interface provides commands and events for controlling the radio modes.
 * 
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 *
 */
interface Tda5250Control {
   
   /**
    * Switches radio to TimerMode.
    * 
    * @param on_time Sets the time (ms) the radio is on.
    * @param off_time Sets the time (ms) the radio is off.
    *
    * @return SUCCESS on success
    *         FAIL otherwise.
    */
   async command error_t TimerMode(float on_time, float off_time);
   
   /**
   * Resets the timers set in TimerMode(). 
   * 
   * @return SUCCESS on success
   *         FAIL otherwise.
   */
   async command error_t ResetTimerMode();
   
   /**
   * Switches radio to SelfPollingMode.
   * 
   * @param on_time Sets the time (ms) the radio is on.
   * @param off_time Sets the time (ms) the radio is off.
   *
   * @return SUCCESS on success
   *         FAIL otherwise.
   */
   async command error_t SelfPollingMode(float on_time, float off_time);
   
   /**
    * Resets the timers set in SelfPollingMode(float, float). 
    * 
    * @return SUCCESS on success
    *         FAIL otherwise.
    */
   async command error_t ResetSelfPollingMode();
   
   /**
   * Switches radio to TxMode.
   * 
   * @return SUCCESS on success
   *         FAIL otherwise.
   */
   async command error_t TxMode();
   
   /**
   * Switches radio to RxMode.
   * 
   * @return SUCCESS on success
   *         FAIL otherwise.
   */
   async command error_t RxMode();
   
   /**
   * Switches radio to SleepMode.
   * 
   * @return SUCCESS on success
   *         FAIL otherwise.
   */
   async command error_t SleepMode();

   
   /**
    * Notification that radio mode is switched to TimerModeDone.
    */
   async event void TimerModeDone();
   
   /**
   * Notification that radio mode is switched to SelfPollingMode.
   */
   async event void SelfPollingModeDone();
   
   /**
   * Notification that radio mode is switched to TxMode.
   */
   async event void TxModeDone();
   
   /**
   * Notification that radio mode is switched to RxMode.
   */
   async event void RxModeDone();
   
   /**
   * Notification that the rssi is stable.
   */
   async event void RssiStable();
   
   /**
   * Notification that radio mode is switched to SleepMode.
   */
   async event void SleepModeDone();

   /**
    * Notification of interrupt when in
    * TimerMode or SelfPollingMode.
    */
   async event void PWDDDInterrupt();
}

