/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */
 
/**
 * Use this component to duty cycle the radio. When a message is heard, 
 * disable DutyCycling.
 *
 * @author David Moss dmm@rincon.com
 */

configuration CC2420DutyCycleC {
  provides {
    interface CC2420DutyCycle;
    interface SplitControl;
    interface State as SplitControlState;
  }
}

implementation {
  components MainC,
      CC2420DutyCycleP,
      CC2420TransmitC,
      CC2420CsmaC,
      LedsC,
      new StateC() as RadioPowerStateC,
      new StateC() as DutyCycleStateC,
      new StateC() as CheckStateC,
      new StateC() as SplitControlStateC,
      new TimerMilliC() as OnTimerC,
      new TimerMilliC() as CheckTimerC,
      RandomC;

#if defined(LOW_POWER_LISTENING) || defined(ACK_LOW_POWER_LISTENING)
  components CC2420AckLplC as LplC;
#elif defined(NOACK_LOW_POWER_LISTENING)
  components CC2420NoAckLplC as LplC;
#else
  components CC2420LplDummyC as LplC;
#endif

  CC2420DutyCycle = CC2420DutyCycleP;
  SplitControl = CC2420DutyCycleP;
  SplitControlState = SplitControlStateC;
  
  MainC.SoftwareInit -> CC2420DutyCycleP;
  
  CC2420DutyCycleP.Random -> RandomC;
  CC2420DutyCycleP.CC2420Cca -> CC2420TransmitC;
  CC2420DutyCycleP.SubControl -> CC2420CsmaC;
  CC2420DutyCycleP.SendState -> LplC;
  CC2420DutyCycleP.RadioPowerState -> RadioPowerStateC;
  CC2420DutyCycleP.DutyCycleState -> DutyCycleStateC;
  CC2420DutyCycleP.SplitControlState -> SplitControlStateC;
  CC2420DutyCycleP.CheckState -> CheckStateC;
  CC2420DutyCycleP.OnTimer -> OnTimerC;
  CC2420DutyCycleP.Leds -> LedsC;
    
}


