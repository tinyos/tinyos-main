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
 * Msp432CounterMicroC provides the standard 1 MiHz counter for the MSP432.
 *
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * Originally, this component reached directly into the h/w timer export
 * component and hard coded which timer was being used.  The problem with
 * that is how timers are configured and clocked is inherently a platfrom
 * dependent configuration issue.
 *
 * Instead what should be done, is link to a Mapping component.  Mapping
 * components are a Platform's way of exporting well named h/w resoruces.
 *
 * A default set of maps is provided in tos/chips/msp432/timer.
 * Msp432TimerMicroMapC (TA0 by default) and Msp432TimerMilliMapC (TA1
 * by default).
 *
 * Block 0 is always the main timing block for the TA hardware.
 */

configuration Msp432CounterMicroC {
  provides interface Counter<TMicro, uint16_t> as Msp432CounterMicro;
}
implementation {
  components     Msp432TimerMicroMapC as MicroMap;
  components new Msp432CounterC(TMicro) as Counter;

  Msp432CounterMicro = Counter;
  Counter.Msp432Timer -> MicroMap.Msp432Timer[0];
}
