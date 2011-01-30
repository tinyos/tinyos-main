
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

  provides 
  {
      interface GpioCapture as Capture;
  }
  uses 
  {
      interface HplSam3TCCapture as TCCapture;
      interface HplSam3GeneralIOPin as GeneralIO;
  }

}

implementation {

  error_t enableCapture( uint8_t mode ) {
    atomic {
      call TCCapture.disable();
      call GeneralIO.disablePioControl();
      call GeneralIO.selectPeripheralA();

      call TCCapture.setEdge( mode );
      call TCCapture.clearPendingEvent();
      call TCCapture.clearOverrun();
      call TCCapture.enable();
    }
    return SUCCESS;
  }

  async command error_t Capture.captureRisingEdge() {
    return enableCapture( TC_CMR_ETRGEDG_RISING );
  }

  async command error_t Capture.captureFallingEdge() {
    return enableCapture( TC_CMR_ETRGEDG_FALLING );
  }

  async command void Capture.disable() {
    atomic {
      call TCCapture.disable();
    }
  }

  async event void TCCapture.captured( uint16_t time ) {
    call TCCapture.clearPendingEvent();
    call TCCapture.clearOverrun();
    signal Capture.captured( time );
  }

  async event void TCCapture.overrun()
  {
  }

}
