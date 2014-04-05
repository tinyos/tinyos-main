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
 *
 * @author Mike Healy
 * @date February, 2013
 * Removed connectionTimer as no longer required
 */

configuration DigitalHeartRateC {
  provides{
    interface Init;
    interface DigitalHeartRate;
  }
}

implementation {
  components Rmcm01P;
  Init             = Rmcm01P;
  DigitalHeartRate = Rmcm01P;

  components HplMsp430InterruptP, HplMsp430GeneralIOC as GpioC; 
  Rmcm01P.BeatInterrupt -> HplMsp430InterruptP.Port20;
  Rmcm01P.Msp430GeneralIO -> GpioC.Port20;
  
  components Counter32khz32C as Counter, new CounterToLocalTimeC(T32khz);
  CounterToLocalTimeC.Counter -> Counter;
  Rmcm01P.LocalTime -> CounterToLocalTimeC;
}
