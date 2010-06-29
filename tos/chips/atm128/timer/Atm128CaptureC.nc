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
 *  $Id: Atm128CaptureC.nc,v 1.5 2010-06-29 22:07:43 scipio Exp $
 */

/**
 * Exposes Capture capability of hardware as general interface, 
 * with some ATmega128 specific dependencies including:
 *     Only available with the two 16-bit timers.
 *     Each Timer has only one dedicated capture pin.
 *         Timer1 == PortD.Pin4 [D4]
 *         Timer3 == PortE.Pin7 [E7]
 * So selection of 16-bit timer gives implicit wiring of actual Pin to capture.
 *
 *  @author Alan Broad, Crossbow <abroad@xbow.com>
 *  @author Matt Miller, Crossbow <mmiller@xbow.com>
 *  @author Martin Turon, Crossbow <mturon@xbow.com>
 */
generic module Atm128CaptureC () 
{
  provides {
    interface Capture as CapturePin;
  }
  uses {
    interface HplAtm128Capture<uint16_t>;
    // interface HplAtm128Timer<uint16_t> as Timer;
    // interface GeneralIO as PinToCapture;       // implicit to timer used
  }
}
implementation
{
  // ************* CapturePin Interrupt handlers and dispatch *************

  /**
   *  CapturePin.enableCapture
   *
   * Configure Atmega128 TIMER to capture edge input of CapturePin signal.
   * This will cause an interrupt and save TIMER count.
   * TIMER Timebase is set by stdControl.start
   *  -- see HplAtm128Capture interface and HplAtm128TimerM implementation
   */
  async command error_t CapturePin.enableCapture(bool low_to_high) {
    atomic {
      call HplAtm128Capture.stop();  // clear any capture interrupt
      call HplAtm128Capture.setEdge(low_to_high);
      call HplAtm128Capture.reset();
      call HplAtm128Capture.start();
    }
    return SUCCESS;
  }
    
  async command error_t CapturePin.disable() {
    call HplAtm128Capture.stop();
    return SUCCESS;
  }
    
  /**
   * Handle signal from HplAtm128Capture interface indicating an external 
   * event has been timestamped. 
   * Signal client with time and disable capture timer if nolonger needed.
   */
  async event void HplAtm128Capture.captured(uint16_t time) {
    // first, signal client
    error_t val = signal CapturePin.captured(time);     

    if (val == FAIL) {
      // if client returns failure, stop time capture
      call HplAtm128Capture.stop();
    } else { 
      // otherwise, time capture keeps running, reset if needed
      if (call HplAtm128Capture.test()) 
	call HplAtm128Capture.reset();
    }         
  }
}
