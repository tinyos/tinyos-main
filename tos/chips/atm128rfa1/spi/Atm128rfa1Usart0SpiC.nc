/*
* Copyright (c) 2011, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Zsolt Szabo
*/


configuration Atm128rfa1Usart0SpiC {
  provides interface Init;
  provides interface SpiByte;
  provides interface FastSpiByte;
  provides interface SpiPacket;
  provides interface Resource[uint8_t id];
}
implementation {
  components new Atm128SpiP(), HplAtm128rfa1Usart0SpiC;
  components new SimpleFcfsArbiterC("Atm128SpiC.Resource") as Arbiter;
  components McuSleepC;

  Init        = Atm128SpiP;
  SpiByte     = Atm128SpiP;
  FastSpiByte = Atm128SpiP;
  SpiPacket   = Atm128SpiP;
  Resource    = Atm128SpiP;

  Atm128SpiP.ArbiterInfo -> Arbiter;
  Atm128SpiP.ResourceArbiter -> Arbiter;
  Atm128SpiP.Spi -> HplAtm128rfa1Usart0SpiC;
  Atm128SpiP.McuPowerState -> McuSleepC;

}
