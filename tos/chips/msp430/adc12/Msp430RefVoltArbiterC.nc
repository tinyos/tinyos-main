/*
 * Copyright (c) 2004, Technische Universität Berlin
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
 * - Neither the name of the Technische Universität Berlin nor the names 
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
 * - Revision -------------------------------------------------------------
 * $Revision: 1.3 $
 * $Date: 2006-12-12 18:23:07 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * This component is meant to intercept requests to the <code>Resource</code>
 * interface on their way to the arbiter. It checks whether the client requires
 * the internal reference voltage generator of the MSP430 to be switched on by
 * pulling its configuration data via <code>Msp430Adc12Config</code>. If (and
 * only if) this is the case it enables the generator and forwards the
 * <code>Resource.granted()</code> event from the arbiter when the reference
 * voltage is stable.  Clients SHOULD NOT wire to
 * <code>Msp430RefVoltArbiterC</code> but wire to
 * <code>Msp430Adc12RefVoltAutoClientC</code>.
 * 
 * @author Jan Hauer
 */

configuration Msp430RefVoltArbiterC
{
  provides interface Resource as ClientResource[uint8_t client];
  uses {
    interface Resource as AdcResource[uint8_t client];
    interface Msp430Adc12Config as Config[uint8_t client];
  }
} implementation {
  components Msp430RefVoltGeneratorP, Msp430RefVoltArbiterP,
             new TimerMilliC() as SwitchOnDelayTimer, 
             new TimerMilliC() as SwitchOffDelayTimer,
             HplAdc12P;

  ClientResource = Msp430RefVoltArbiterP.ClientResource;
  AdcResource = Msp430RefVoltArbiterP.AdcResource;
  Config = Msp430RefVoltArbiterP;

  Msp430RefVoltArbiterP.RefVolt_1_5V -> Msp430RefVoltGeneratorP.RefVolt_1_5V;
  Msp430RefVoltArbiterP.RefVolt_2_5V -> Msp430RefVoltGeneratorP.RefVolt_2_5V;
  Msp430RefVoltGeneratorP.SwitchOnTimer -> SwitchOnDelayTimer;
  Msp430RefVoltGeneratorP.SwitchOffTimer -> SwitchOffDelayTimer;
  Msp430RefVoltGeneratorP.HplAdc12 -> HplAdc12P;
}  

