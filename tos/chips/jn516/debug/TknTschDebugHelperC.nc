/**
 * Copyright (c) 2015, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 */

/**
 * TODO Configuration description
 */
configuration TknTschDebugHelperC
{
  provides {
    interface TknTschDebugHelperTssm as TssmHelper;
  }
  uses {
    ;
  }
}
implementation
{
  components TknTschDebugHelperP as HelperP;
  HelperP = TssmHelper;

  components HplJn516GeneralIOC as GeneralIOC
        , new Jn516GpioC() as GpioSlotStart
        , new Jn516GpioC() as GpioSlotZero
        , new Jn516GpioC() as GpioPktPrepare
        , new Jn516GpioC() as GpioAlarmIrq
        , new Jn516GpioC() as GpioPhyIrq
      ;
  HelperP.GpioSlotStart -> GpioSlotStart;
  HelperP.GpioSlotZero -> GpioSlotZero;
  HelperP.GpioPktPrepare -> GpioPktPrepare;
  HelperP.GpioAlarmIrq -> GpioAlarmIrq;
  HelperP.GpioPhyIrq -> GpioPhyIrq;
  GpioSlotStart -> GeneralIOC.Port0; // expansion header pin 1
  GpioSlotZero -> GeneralIOC.Port1; // expansion header pin 2
  GpioPktPrepare -> GeneralIOC.Port12; // expansion header pin 13
  GpioAlarmIrq -> GeneralIOC.Port13; // expansion header pin 14
  GpioPhyIrq -> GeneralIOC.Port14; // expansion header pin 15

  components LedsC;
  HelperP.Leds -> LedsC;
}
