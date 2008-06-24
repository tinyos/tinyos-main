
/* "Copyright (c) 2000-2003 The Regents of the University of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * @author Jonathan Hui
 * @author Joe Polastre
 */

generic module GpioCaptureC() @safe() {

  provides interface GpioCapture as Capture;
  uses interface Msp430TimerControl;
  uses interface Msp430Capture;
  uses interface HplMsp430GeneralIO as GeneralIO;

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

  async event void Msp430Capture.captured( uint16_t time ) {
    call Msp430TimerControl.clearPendingInterrupt();
    call Msp430Capture.clearOverflow();
    signal Capture.captured( time );
  }

}
