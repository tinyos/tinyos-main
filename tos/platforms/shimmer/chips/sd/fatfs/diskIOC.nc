/*
 * Copyright (c) 2009, Shimmer Research, Ltd.
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
 * @date   April, 2009
 * port to tos-2.x
 * @date January, 2010
 *
 * wire the FatFs interface to the current implementation
 * wire the diskIO abstraction in the FatFs module to physical medium
 */

configuration diskIOC {
  provides {
    interface FatFs;
    interface StdControl as diskIOStdControl;
    interface SD as diskIO;
  }
}
implementation {
  components 
    FatFsP, 
    SDP, 
    new Msp430Usart0C(), 
    new TimerMilliC(), 
    HplMsp430InterruptP, 
    LedsC, 
    TimeP;  
  //, NTPClientM;

  FatFs = FatFsP;
  diskIOStdControl = SDP;
  //  diskIOStdControl = TimeP;
  diskIO = SDP;

  FatFsP.Leds        -> LedsC;

  components TimeC;
  FatFsP.Time        -> TimeC;
  //  FatFsP.Time        -> TimeP;

  SDP.Usart          -> Msp430Usart0C;
  SDP.DockInterrupt  -> HplMsp430InterruptP.Port23;
  SDP.Leds           -> LedsC;


  /*
  components Counter32khz64C as Counter;
  components new CounterToLocalTime64C(T32khz);
  CounterToLocalTime64C.Counter -> Counter;
  TimeP.LocalTime64 -> CounterToLocalTime64C;
   
  TimeP.Timer                -> TimerMilliC;
  */
}
