/*
 * Copyright (c) 2010, Shimmer Research, Ltd.
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of Shimmer Research, Ltd. nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Steve Ayer
 * @date   January, 2010
 *
 * this implements an interrupt-driven capture interface for the cc2420
 * tx-mode use of sfd.  shimmer2 does not have sfd routed to a timer pin
 * on the msp430, so cc2420's capture mechanism fails.  
 * this module will trigger a capture.captured event after receiving the
 * appropriate interrupt from the shimmer2 sfd pin (1.0)
 */

module HplCC2420InterruptsP @safe() {
  provides{
    interface GpioCapture as CaptureSFD;
  }

  uses{
    interface GpioInterrupt as InterruptSFD;
    interface Counter<T32khz,uint16_t>;
  }
}

implementation {
  async command error_t CaptureSFD.captureRisingEdge() { 
    call InterruptSFD.enableRisingEdge();
    return SUCCESS;
  }

  async command error_t CaptureSFD.captureFallingEdge() { 
    call InterruptSFD.enableFallingEdge();
    return SUCCESS;
  }
  
  async command void CaptureSFD.disable() {
    call InterruptSFD.disable();
  }

  async event void InterruptSFD.fired() {
    uint16_t t = call Counter.get();

    signal CaptureSFD.captured(t);
  }

  async event void Counter.overflow() { }
}

