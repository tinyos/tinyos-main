/*
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
 *  All rights reserved.
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
 * - Neither the name of the copyright holder nor the names of
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
 *  $Id: Atm128GpioCaptureC.nc,v 1.6 2010-06-29 22:07:43 scipio Exp $
 */

/**
 * Expose capture capability as a GpioCapture interface from TEP117.
 *
 * @author Martin Turon, Crossbow <mturon@xbow.com>
 */
generic module Atm128GpioCaptureC() @safe() {

  provides interface GpioCapture as Capture;
  uses interface HplAtm128Capture<uint16_t> as Atm128Capture;

}

implementation {

  error_t enableCapture( uint8_t mode ) {
    atomic {
      call Atm128Capture.stop();
      call Atm128Capture.reset();
      call Atm128Capture.setEdge( mode );
      call Atm128Capture.start();
    }
    return SUCCESS;
  }

  async command error_t Capture.captureRisingEdge() {
    return enableCapture( TRUE );
  }

  async command error_t Capture.captureFallingEdge() {
    return enableCapture( FALSE );
  }

  async command void Capture.disable() {
    call Atm128Capture.stop();
  }

  async event void Atm128Capture.captured( uint16_t time ) {
    call Atm128Capture.reset();
    signal Capture.captured( time );
  }

}
