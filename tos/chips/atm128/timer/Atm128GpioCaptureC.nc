/*
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
 *  All rights reserved.
 *
 *  Permission to use, copy, modify, and distribute this software and its
 *  documentation for any purpose, without fee, and without written
 *  agreement is hereby granted, provided that the above copyright
 *  notice, the (updated) modification history and the author appear in
 *  all copies of this source code.
 *
 *  Permission is also granted to distribute this software under the
 *  standard BSD license as contained in the TinyOS distribution.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 *  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS 
 *  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA, 
 *  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 *  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
 *  THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  $Id: Atm128GpioCaptureC.nc,v 1.3 2006-11-07 19:30:45 scipio Exp $
 */

/**
 * Expose capture capability as a GpioCapture interface from TEP117.
 *
 * @author Martin Turon, Crossbow <mturon@xbow.com>
 */
generic module Atm128GpioCaptureC() {

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
