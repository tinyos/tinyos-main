
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
module HplMsp430InterruptP
{
#if defined(__msp430_have_port1) || defined(__MSP430_HAS_PORT1__) || defined(__MSP430_HAS_PORT1_R__)
  provides interface HplMsp430Interrupt as Port10;
  provides interface HplMsp430Interrupt as Port11;
  provides interface HplMsp430Interrupt as Port12;
  provides interface HplMsp430Interrupt as Port13;
  provides interface HplMsp430Interrupt as Port14;
  provides interface HplMsp430Interrupt as Port15;
  provides interface HplMsp430Interrupt as Port16;
  provides interface HplMsp430Interrupt as Port17;
#endif
#if defined(__msp430_have_port2) || defined(__MSP430_HAS_PORT2__) || defined(__MSP430_HAS_PORT2_R__)
  provides interface HplMsp430Interrupt as Port20;
  provides interface HplMsp430Interrupt as Port21;
  provides interface HplMsp430Interrupt as Port22;
  provides interface HplMsp430Interrupt as Port23;
  provides interface HplMsp430Interrupt as Port24;
  provides interface HplMsp430Interrupt as Port25;
  provides interface HplMsp430Interrupt as Port26;
  provides interface HplMsp430Interrupt as Port27;
#endif
  uses interface PlatformInterrupt;
}
implementation
{

#if defined(__msp430_have_port1) || defined(__MSP430_HAS_PORT1__) || defined(__MSP430_HAS_PORT1_R__)
  TOSH_SIGNAL(PORT1_VECTOR)
  {
    volatile int n = P1IFG & P1IE;

    if (n & (1 << 0)) { signal Port10.fired(); }
    else if (n & (1 << 1)) { signal Port11.fired(); }
    else if (n & (1 << 2)) { signal Port12.fired(); }
    else if (n & (1 << 3)) { signal Port13.fired(); }
    else if (n & (1 << 4)) { signal Port14.fired(); }
    else if (n & (1 << 5)) { signal Port15.fired(); }
    else if (n & (1 << 6)) { signal Port16.fired(); }
    else if (n & (1 << 7)) { signal Port17.fired(); }
    call PlatformInterrupt.postAmble();
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

#if defined(__msp430_have_port2) || defined(__MSP430_HAS_PORT2__) || defined(__MSP430_HAS_PORT2_R__)
  TOSH_SIGNAL(PORT2_VECTOR)
  {
    volatile int n = P2IFG & P2IE;

    if (n & (1 << 0)) { signal Port20.fired(); }
    else if (n & (1 << 1)) { signal Port21.fired(); }
    else if (n & (1 << 2)) { signal Port22.fired(); }
    else if (n & (1 << 3)) { signal Port23.fired(); }
    else if (n & (1 << 4)) { signal Port24.fired(); }
    else if (n & (1 << 5)) { signal Port25.fired(); }
    else if (n & (1 << 6)) { signal Port26.fired(); }
    else if (n & (1 << 7)) { signal Port27.fired(); }
    call PlatformInterrupt.postAmble();
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
