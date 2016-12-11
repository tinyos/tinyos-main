/*
 * Copyright (c) 2016 Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
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
 *
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * When instantiated, Msp432Timer32khzC maps an underlying hardware
 * timer to the 3 interfaces exported.
 *
 * For example, the first invokation will expose Timer32khzMap[0]
 * the next, [1], and so on.  When you run out of timers from the
 * map the wiring will fail.
 *
 * The default wiring has TA1 clocking at 32KiHz and it has 5 CCRs.
 * All Msp432Timer[x] expose the base timer.  Msp432TimerCCTL[n] exposes
 * the CCR control for CCRn, and Msp432TimerCompare[n] exposes basic
 * compare (timing events) for CCRn.
 *
 * Msp432Timer32khzMapC defines which timer block is allocated (default is
 * TA1) and how many CCRs are exposed.  The msp432p401r for example has
 * 5,5,5,5, 4 TAs, TA0-TA3 each with 5 CCRs.  Note that a different packaging
 * of the chip only has 5,5,5 TA0-TA2.  This is not reflected in the chip
 * header.  The platform has to reflect this in the map.
 */

generic configuration Msp432Timer32khzC() {
  provides interface Msp432Timer;
  provides interface Msp432TimerCCTL;
  provides interface Msp432TimerCompare;
}
implementation {
  components Msp432Timer32khzMapC as Map;

  enum { ALARM_ID = unique("Msp432Timer32khzMapC") };

  Msp432Timer = Map.Msp432Timer[ALARM_ID];
  Msp432TimerCCTL = Map.Msp432TimerCCTL[ALARM_ID];
  Msp432TimerCompare = Map.Msp432TimerCompare[ALARM_ID];
}
