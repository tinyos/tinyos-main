/*
 * Copyright (c) 2005 Washington University in St. Louis.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
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
 */

/**
 * Please refer to TEP 115 for more information about the components
 * this application is used to test.
 *
 * This component is used to create a "dummy" non-virtualized component for use
 * with the TestPowerManager component.  It can be powered on and off through any
 * of the AsyncStdControl, StdControl, and SplitControl interfaces.
 *
 * @author Kevin Klues <klueska@cs.wustl.edu>
 * @version  $Revision: 1.5 $
 * @date $Date: 2010-06-29 22:07:25 $ 
 */
 
module MyComponentP {
  provides {
    interface SplitControl;
    interface StdControl;
    interface AsyncStdControl;
  }
  uses {
    interface Leds;
    interface Timer<TMilli> as StartTimer;
    interface Timer<TMilli> as StopTimer;
  }
}
implementation {

  #define START_DELAY 10
  #define STOP_DELAY 10

  command error_t SplitControl.start() {
    call StartTimer.startOneShot(START_DELAY);
    return SUCCESS;
  }

  event void StartTimer.fired() {
    call Leds.led0On();
    signal SplitControl.startDone(SUCCESS);
  }

  command error_t SplitControl.stop() {
    call StopTimer.startOneShot(STOP_DELAY);
    return SUCCESS;
  }

  event void StopTimer.fired() {
    call Leds.led0Off();
    signal SplitControl.stopDone(SUCCESS);
  }

  command error_t StdControl.start() {
    call Leds.led0On();
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    call Leds.led0Off();
    return SUCCESS;
  }

  async command error_t AsyncStdControl.start() {
    call Leds.led0On();
    return SUCCESS;
  }

  async command error_t AsyncStdControl.stop() {
    call Leds.led0Off();
    return SUCCESS;
  }

  default event void SplitControl.startDone(error_t error) {}
  default event void SplitControl.stopDone(error_t error) {}
}

