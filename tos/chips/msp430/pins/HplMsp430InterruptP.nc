
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
module HplMsp430InterruptP
{
#ifdef __msp430_have_port1
  provides interface HplMsp430Interrupt as Port10;
  provides interface HplMsp430Interrupt as Port11;
  provides interface HplMsp430Interrupt as Port12;
  provides interface HplMsp430Interrupt as Port13;
  provides interface HplMsp430Interrupt as Port14;
  provides interface HplMsp430Interrupt as Port15;
  provides interface HplMsp430Interrupt as Port16;
  provides interface HplMsp430Interrupt as Port17;
#endif
#ifdef __msp430_have_port2
  provides interface HplMsp430Interrupt as Port20;
  provides interface HplMsp430Interrupt as Port21;
  provides interface HplMsp430Interrupt as Port22;
  provides interface HplMsp430Interrupt as Port23;
  provides interface HplMsp430Interrupt as Port24;
  provides interface HplMsp430Interrupt as Port25;
  provides interface HplMsp430Interrupt as Port26;
  provides interface HplMsp430Interrupt as Port27;
#endif

}
implementation
{

#ifdef __msp430_have_port1
  TOSH_SIGNAL(PORT1_VECTOR)
  {
    volatile int n = P1IFG & P1IE;

    if (n & (1 << 0)) { signal Port10.fired(); return; }
    if (n & (1 << 1)) { signal Port11.fired(); return; }
    if (n & (1 << 2)) { signal Port12.fired(); return; }
    if (n & (1 << 3)) { signal Port13.fired(); return; }
    if (n & (1 << 4)) { signal Port14.fired(); return; }
    if (n & (1 << 5)) { signal Port15.fired(); return; }
    if (n & (1 << 6)) { signal Port16.fired(); return; }
    if (n & (1 << 7)) { signal Port17.fired(); return; }
  }

  default async event void Port10.fired() { call Port10.clear(); }
  default async event void Port11.fired() { call Port11.clear(); }
  default async event void Port12.fired() { call Port12.clear(); }
  default async event void Port13.fired() { call Port13.clear(); }
  default async event void Port14.fired() { call Port14.clear(); }
  default async event void Port15.fired() { call Port15.clear(); }
  default async event void Port16.fired() { call Port16.clear(); }
  default async event void Port17.fired() { call Port17.clear(); }
  async command void Port10.enable() { P1IE |= (1 << 0); }
  async command void Port11.enable() { P1IE |= (1 << 1); }
  async command void Port12.enable() { P1IE |= (1 << 2); }
  async command void Port13.enable() { P1IE |= (1 << 3); }
  async command void Port14.enable() { P1IE |= (1 << 4); }
  async command void Port15.enable() { P1IE |= (1 << 5); }
  async command void Port16.enable() { P1IE |= (1 << 6); }
  async command void Port17.enable() { P1IE |= (1 << 7); }
  async command void Port10.disable() { P1IE &= ~(1 << 0); }
  async command void Port11.disable() { P1IE &= ~(1 << 1); }
  async command void Port12.disable() { P1IE &= ~(1 << 2); }
  async command void Port13.disable() { P1IE &= ~(1 << 3); }
  async command void Port14.disable() { P1IE &= ~(1 << 4); }
  async command void Port15.disable() { P1IE &= ~(1 << 5); }
  async command void Port16.disable() { P1IE &= ~(1 << 6); }
  async command void Port17.disable() { P1IE &= ~(1 << 7); }
  async command void Port10.clear() { P1IFG &= ~(1 << 0); }
  async command void Port11.clear() { P1IFG &= ~(1 << 1); }
  async command void Port12.clear() { P1IFG &= ~(1 << 2); }
  async command void Port13.clear() { P1IFG &= ~(1 << 3); }
  async command void Port14.clear() { P1IFG &= ~(1 << 4); }
  async command void Port15.clear() { P1IFG &= ~(1 << 5); }
  async command void Port16.clear() { P1IFG &= ~(1 << 6); }
  async command void Port17.clear() { P1IFG &= ~(1 << 7); }
  async command bool Port10.getValue() { bool b; atomic b=(P1IN >> 0) & 1; return b; }
  async command bool Port11.getValue() { bool b; atomic b=(P1IN >> 1) & 1; return b; }
  async command bool Port12.getValue() { bool b; atomic b=(P1IN >> 2) & 1; return b; }
  async command bool Port13.getValue() { bool b; atomic b=(P1IN >> 3) & 1; return b; }
  async command bool Port14.getValue() { bool b; atomic b=(P1IN >> 4) & 1; return b; }
  async command bool Port15.getValue() { bool b; atomic b=(P1IN >> 5) & 1; return b; }
  async command bool Port16.getValue() { bool b; atomic b=(P1IN >> 6) & 1; return b; }
  async command bool Port17.getValue() { bool b; atomic b=(P1IN >> 7) & 1; return b; }
  async command void Port10.edge(bool l2h) { 
    atomic {
      if (l2h)  P1IES &= ~(1 << 0); 
      else      P1IES |=  (1 << 0);
    }
  }
  async command void Port11.edge(bool l2h) { 
    atomic {
      if (l2h)  P1IES &= ~(1 << 1); 
      else      P1IES |=  (1 << 1);
    }
  }
  async command void Port12.edge(bool l2h) { 
    atomic {
      if (l2h)  P1IES &= ~(1 << 2); 
      else      P1IES |=  (1 << 2);
    }
  }
  async command void Port13.edge(bool l2h) { 
    atomic {
      if (l2h)  P1IES &= ~(1 << 3); 
      else      P1IES |=  (1 << 3);
    }
  }
  async command void Port14.edge(bool l2h) { 
    atomic {
      if (l2h)  P1IES &= ~(1 << 4); 
      else      P1IES |=  (1 << 4);
    }
  }
  async command void Port15.edge(bool l2h) { 
    atomic {
      if (l2h)  P1IES &= ~(1 << 5); 
      else      P1IES |=  (1 << 5);
    }
  }
  async command void Port16.edge(bool l2h) { 
    atomic {
      if (l2h)  P1IES &= ~(1 << 6); 
      else      P1IES |=  (1 << 6);
    }
  }
  async command void Port17.edge(bool l2h) { 
    atomic {
      if (l2h)  P1IES &= ~(1 << 7); 
      else      P1IES |=  (1 << 7);
    }
  }
#endif

#ifdef __msp430_have_port2
  TOSH_SIGNAL(PORT2_VECTOR)
  {
    volatile int n = P2IFG & P2IE;

    if (n & (1 << 0)) { signal Port20.fired(); return; }
    if (n & (1 << 1)) { signal Port21.fired(); return; }
    if (n & (1 << 2)) { signal Port22.fired(); return; }
    if (n & (1 << 3)) { signal Port23.fired(); return; }
    if (n & (1 << 4)) { signal Port24.fired(); return; }
    if (n & (1 << 5)) { signal Port25.fired(); return; }
    if (n & (1 << 6)) { signal Port26.fired(); return; }
    if (n & (1 << 7)) { signal Port27.fired(); return; }
  }
  default async event void Port20.fired() { call Port20.clear(); }
  default async event void Port21.fired() { call Port21.clear(); }
  default async event void Port22.fired() { call Port22.clear(); }
  default async event void Port23.fired() { call Port23.clear(); }
  default async event void Port24.fired() { call Port24.clear(); }
  default async event void Port25.fired() { call Port25.clear(); }
  default async event void Port26.fired() { call Port26.clear(); }
  default async event void Port27.fired() { call Port27.clear(); }
  async command void Port20.enable() { P2IE |= (1 << 0); }
  async command void Port21.enable() { P2IE |= (1 << 1); }
  async command void Port22.enable() { P2IE |= (1 << 2); }
  async command void Port23.enable() { P2IE |= (1 << 3); }
  async command void Port24.enable() { P2IE |= (1 << 4); }
  async command void Port25.enable() { P2IE |= (1 << 5); }
  async command void Port26.enable() { P2IE |= (1 << 6); }
  async command void Port27.enable() { P2IE |= (1 << 7); }
  async command void Port20.disable() { P2IE &= ~(1 << 0); }
  async command void Port21.disable() { P2IE &= ~(1 << 1); }
  async command void Port22.disable() { P2IE &= ~(1 << 2); }
  async command void Port23.disable() { P2IE &= ~(1 << 3); }
  async command void Port24.disable() { P2IE &= ~(1 << 4); }
  async command void Port25.disable() { P2IE &= ~(1 << 5); }
  async command void Port26.disable() { P2IE &= ~(1 << 6); }
  async command void Port27.disable() { P2IE &= ~(1 << 7); }
  async command void Port20.clear() { P2IFG &= ~(1 << 0); }
  async command void Port21.clear() { P2IFG &= ~(1 << 1); }
  async command void Port22.clear() { P2IFG &= ~(1 << 2); }
  async command void Port23.clear() { P2IFG &= ~(1 << 3); }
  async command void Port24.clear() { P2IFG &= ~(1 << 4); }
  async command void Port25.clear() { P2IFG &= ~(1 << 5); }
  async command void Port26.clear() { P2IFG &= ~(1 << 6); }
  async command void Port27.clear() { P2IFG &= ~(1 << 7); }
  async command bool Port20.getValue() { bool b; atomic b=(P2IN >> 0) & 1; return b; }
  async command bool Port21.getValue() { bool b; atomic b=(P2IN >> 1) & 1; return b; }
  async command bool Port22.getValue() { bool b; atomic b=(P2IN >> 2) & 1; return b; }
  async command bool Port23.getValue() { bool b; atomic b=(P2IN >> 3) & 1; return b; }
  async command bool Port24.getValue() { bool b; atomic b=(P2IN >> 4) & 1; return b; }
  async command bool Port25.getValue() { bool b; atomic b=(P2IN >> 5) & 1; return b; }
  async command bool Port26.getValue() { bool b; atomic b=(P2IN >> 6) & 1; return b; }
  async command bool Port27.getValue() { bool b; atomic b=(P2IN >> 7) & 1; return b; }
  async command void Port20.edge(bool l2h) {
    atomic {
      if (l2h)  P2IES &= ~(1 << 0);
      else      P2IES |=  (1 << 0);
    }
  }
  async command void Port21.edge(bool l2h) {
    atomic {
      if (l2h)  P2IES &= ~(1 << 1);
      else      P2IES |=  (1 << 1);
    }
  }  
  async command void Port22.edge(bool l2h) {
    atomic {
      if (l2h)  P2IES &= ~(1 << 2);
      else      P2IES |=  (1 << 2);
    }
  }  
  async command void Port23.edge(bool l2h) {
    atomic {
      if (l2h)  P2IES &= ~(1 << 3);
      else      P2IES |=  (1 << 3);
    }
  }  
  async command void Port24.edge(bool l2h) {
    atomic {
      if (l2h)  P2IES &= ~(1 << 4);
      else      P2IES |=  (1 << 4);
    }
  }
  async command void Port25.edge(bool l2h) {
    atomic {
      if (l2h)  P2IES &= ~(1 << 5);
      else      P2IES |=  (1 << 5);
    }
  }
  async command void Port26.edge(bool l2h) {
    atomic {
      if (l2h)  P2IES &= ~(1 << 6);
      else      P2IES |=  (1 << 6);
    }
  }
  async command void Port27.edge(bool l2h) {
    atomic {
      if (l2h)  P2IES &= ~(1 << 7);
      else      P2IES |=  (1 << 7);
    }
  }
#endif


}
