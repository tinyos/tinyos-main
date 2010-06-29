/// $Id: HplAtm128InterruptPinP.nc,v 1.7 2010-06-29 22:07:43 scipio Exp $

/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
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
 * - Neither the name of Crossbow Technology nor the names of
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
 * Interrupt interface access for interrupt capable GPIO pins.
 *
 * @author Martin Turon <mturon@xbow.com>
 */
generic module HplAtm128InterruptPinP (uint8_t ctrl_addr, 
				 uint8_t edge0bit, 
				 uint8_t edge1bit, 
				 uint8_t bit) @safe()
{
  provides interface HplAtm128Interrupt as Irq;
  uses interface HplAtm128InterruptSig as IrqSignal;
}
implementation
{
  inline async command bool Irq.getValue() { return (EIFR & (1 << bit)) != 0; }
  inline async command void Irq.clear()    { EIFR = 1 << bit; }
  inline async command void Irq.enable()   { EIMSK |= 1 << bit; }
  inline async command void Irq.disable()  { EIMSK &= ~(1 << bit); }

#define ctrl  (*TCAST(volatile uint8_t * ONE, ctrl_addr))

  inline async command void Irq.edge(bool low_to_high) {
    ctrl |= 1 << edge1bit; // use edge mode
    // and select rising vs falling
    if (low_to_high)
      ctrl |= 1 << edge0bit;
    else
      ctrl &= ~(1 << edge0bit);
  }

  /** 
   * Forward the external interrupt event.  This ties the statically
   * allocated interrupt vector SIG_INTERRUPT##bit to a particular
   * pin passed in via the generic component instantiation.
   */
  async event void IrqSignal.fired() { signal Irq.fired(); }

  default async event void Irq.fired() { }
}
