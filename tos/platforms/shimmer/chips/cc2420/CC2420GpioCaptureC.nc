
/* Copyright (c) 2000-2003 The Regents of the University of California.
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
 */
/**
 * @author Jonathan Hui
 * @author Joe Polastre
 * @author Steve Ayer/Miklos Maroti
 * @date   February, 2011
 *
 * re-named indicating that this HAL module is specifically required to handle anomalies in the 
 * cc2420 stack that require sfd capture to happen on a timerb pin;  designs that use a timera pin 
 * need this code to resolve the aliasing between timestamps from 32khz and 1mhz timers.
 * thanks to miklos for providing this re-written captured event handler as a straight-forward work-around!
 */

generic module CC2420GpioCaptureC() @safe() {

  provides interface GpioCapture as Capture;
  uses interface Msp430TimerControl;
  uses interface Msp430Capture;
  uses interface HplMsp430GeneralIO as GeneralIO;
  uses interface LocalTime<T32khz> as LocalTime32khz;
  uses interface LocalTime<TMicro> as LocalTimeMicro;
}

implementation {

  error_t enableCapture( uint8_t mode ) {
    atomic {
      call Msp430TimerControl.disableEvents();
      call GeneralIO.selectModuleFunc();
      call Msp430TimerControl.clearPendingInterrupt();
      call Msp430Capture.clearOverflow();
      call Msp430TimerControl.setControlAsCapture( mode );
      call Msp430TimerControl.enableEvents();
    }
    return SUCCESS;
  }

  async command error_t Capture.captureRisingEdge() {
    return enableCapture( MSP430TIMER_CM_RISING );
  }

  async command error_t Capture.captureFallingEdge() {
    return enableCapture( MSP430TIMER_CM_FALLING );
  }

  async command void Capture.disable() {
    atomic {
      call Msp430TimerControl.disableEvents();
      call GeneralIO.selectIOFunc();
    }
  }

  async event void Msp430Capture.captured(uint16_t capturedMicro) {
    uint16_t elapsedMicro;
    uint16_t captured32khz;
    
    atomic {
      elapsedMicro = call LocalTimeMicro.get() - capturedMicro;
      captured32khz = call LocalTime32khz.get();
    }
    
    captured32khz -= elapsedMicro >> 5;
    
    signal Capture.captured(captured32khz);
  }
}
