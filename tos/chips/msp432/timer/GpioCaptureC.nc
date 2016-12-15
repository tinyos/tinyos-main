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
 *
 * The default for GpioCapture is CCIxA.  Other channels are available
 * (like B) but they need to be hardcoded in another module.  See
 * tos/platforms/exp5438_2520/hardware/cc2520/P81SfdCaptureC.nc
 *
 * Lower levels have been modified to support being able to change
 * CCIS in the control registers.
 */

generic module GpioCaptureC() @safe() {
  provides interface GpioCapture as Capture;
  uses interface Msp432TimerCCTL;
  uses interface Msp432TimerCapture;
  uses interface HplMsp432Gpio as Gpio;
}

implementation {

  error_t enableCapture(uint8_t mode) {
    atomic {
      call Msp432TimerCCTL.disableEvents();
      call Gpio.makeInput();                    /* for capture to work must be input */
      call Gpio.setFunction(MSP432_GPIO_MOD);   /* and must be assigned to the Module */

      /*
       * setCCRforCapture clears out both CCIE (pending Interrupt
       * as well as COV (overflow).
       *
       * Default setting for CCIS is channel A.
       */
      call Msp432TimerCCTL.setCCRforCapture(mode, MSP432TIMER_CCI_A);
      call Msp432TimerCCTL.enableEvents();
    }
    return SUCCESS;
  }

  async command error_t Capture.captureRisingEdge() {
    return enableCapture(MSP432TIMER_CM_RISING);
  }

  async command error_t Capture.captureFallingEdge() {
    return enableCapture(MSP432TIMER_CM_FALLING);
  }

  async command void Capture.disable() {
    atomic {
      call Msp432TimerCCTL.disableEvents();
      call Gpio.setFunction(MSP432_GPIO_BASIC);
    }
  }

  async event void Msp432Capture.captured(uint16_t time) {
    call Msp432TimerCCTL.clearPendingInterrupt();
    call Msp432TimerCapture.clearOverflow();
    signal Capture.captured(time);
  }
}
