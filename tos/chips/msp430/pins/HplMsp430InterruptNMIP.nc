
/* "Copyright (c) 2000-2005 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * @author Joe Polastre
 */
module HplMsp430InterruptNMIP
{
  provides interface HplMsp430Interrupt as NMI;
  provides interface HplMsp430Interrupt as OF;
  provides interface HplMsp430Interrupt as ACCV;
  uses interface HplMsp430InterruptSig as SIGNAL_NMI_VECTOR;
}
implementation
{
  inline async event void SIGNAL_NMI_VECTOR.fired() 
  {
    volatile int n = IFG1;
    if (n & NMIIFG) { signal NMI.fired(); return; }
    if (n & OFIFG)  { signal OF.fired();  return; }
    if (FCTL3 & ACCVIFG) { signal ACCV.fired(); return; }
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
