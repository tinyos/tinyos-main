/*
 * Copyright (c) 2011, Shimmer Research, Ltd.
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
 * @date   January, 2011
 *
 * this is a Notify wrapper for pulling heart rate from a Polar RMCM01 
 * module, which provides a positive digital pulse on the line connected 
 * to GPIO_EXTERNAL on the anex board.
 * @date   July, 2011
 * updates for platform-specifics
 *
 * @author Mike Healy
 * @date   February, 2013
 * Greatly simplified. Removed unused, inaccurate, functionality
 * Now the timestamp of when the heart beat is detected is passed to the 
 * higher level application.
 * Remove spurious beats added by some (non-rmcm01) coded sensors
 */

module Rmcm01P {
  provides{
    interface Init;
    interface DigitalHeartRate;
  }
  uses{
    interface HplMsp430Interrupt as BeatInterrupt;
    interface HplMsp430GeneralIO as Msp430GeneralIO;
    interface LocalTime<T32khz>;
  }
}

implementation {
  uint32_t last, incoming;

  command error_t Init.init() {
    TOSH_MAKE_ADC_0_INPUT();
    TOSH_MAKE_ADC_7_INPUT();

    atomic {
      call Msp430GeneralIO.makeInput();
      call Msp430GeneralIO.selectIOFunc();

      call BeatInterrupt.disable();
      call BeatInterrupt.edge(TRUE);

      call BeatInterrupt.clear();
      call BeatInterrupt.enable();
    }

    last = 0;

    return SUCCESS;
  }

  async event void BeatInterrupt.fired() {
    
    incoming = call LocalTime.get();

    /*
     * we're skipping spurious beats caused by some coded sensors, which
     * send two pulses after beat indication
     * localtime is in increments of 1 / 32768 s (30.5us), so
     * 8190 * 30.5 = 250ms.  this covers the span between beats 
     * at a nominally-maximum pulse of 240bpm
     */

    if((incoming - last) > 8190){
      signal DigitalHeartRate.beat(incoming - last);
      last = incoming;
    }
    
    call BeatInterrupt.clear();
  }
}
