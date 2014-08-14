
/* Copyright (c) 2000-2005 The Regents of the University of California.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
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
 */

/**
 * @author Joe Polastre
 */
module HplMsp430InterruptNMIP
{
  provides interface HplMsp430Interrupt as NMI;
  provides interface HplMsp430Interrupt as OF;
  provides interface HplMsp430Interrupt as ACCV;
  uses interface PlatformInterrupt;
}
implementation
{
  TOSH_SIGNAL(NMI_VECTOR)
  {
    volatile int n = IFG1;
    if (n & NMIIFG) { signal NMI.fired(); }
    else if (n & OFIFG)  { signal OF.fired(); }
    else if (FCTL3 & ACCVIFG) { signal ACCV.fired(); }
    call PlatformInterrupt.postAmble();
  }

  default async event void NMI.fired() { call NMI.clear(); }
  default async event void OF.fired() { call OF.clear(); }
  default async event void ACCV.fired() { call ACCV.clear(); }

  async command void NMI.enable() {
    volatile uint16_t _watchdog;
    atomic {
      _watchdog = WDTCTL;
      _watchdog = WDTPW | (_watchdog & 0x0FF);
      _watchdog |= WDTNMI;
      WDTCTL = _watchdog;
      IE1 |= NMIIE;
    }
  }
  async command void OF.enable() { atomic IE1 |= OFIE; }
  async command void ACCV.enable() { atomic IE1 |= ACCVIE; }

  async command void NMI.disable() {
    volatile uint16_t _watchdog;
    atomic {
      _watchdog = WDTCTL;
      _watchdog = WDTPW | (_watchdog & 0x0FF);
      _watchdog &= ~WDTNMI;
      WDTCTL = _watchdog;
      IE1 &= ~NMIIE;
    }
  }
  async command void OF.disable() { atomic IE1 &= ~OFIE; }
  async command void ACCV.disable() { atomic IE1 &= ~ACCVIE; }

  async command void NMI.clear() { atomic IFG1 &= ~NMIIFG; }
  async command void OF.clear() { atomic IFG1 &= ~OFIFG; }
  async command void ACCV.clear() { atomic FCTL3 &= ~ACCVIFG; }

  async command bool NMI.getValue() { bool b; atomic b=(IFG1 & NMIIFG) & 0x01; return b; }
  async command bool OF.getValue() { bool b; atomic b=(IFG1 & OFIFG) & 0x01; return b; }
  async command bool ACCV.getValue() { bool b; atomic b=(FCTL3 & ACCVIFG) & 0x01; return b; }

  async command void NMI.edge(bool l2h) { 
    volatile uint16_t _watchdog;
    atomic {
      _watchdog = WDTCTL;
      _watchdog = WDTPW | (_watchdog & 0x0FF);
      if (l2h)  _watchdog &= ~(WDTNMIES); 
      else      _watchdog |=  (WDTNMIES);
      WDTCTL = _watchdog;
    }
  }
  // edge does not apply to oscillator faults
  async command void OF.edge(bool l2h) { }
  // edge does not apply to flash access violations
  async command void ACCV.edge(bool l2h) { }
}
