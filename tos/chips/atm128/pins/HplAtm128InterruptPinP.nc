/// $Id: HplAtm128InterruptPinP.nc,v 1.4 2006-12-12 18:23:03 vlahan Exp $

/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */

/**
 * Interrupt interface access for interrupt capable GPIO pins.
 *
 * @author Martin Turon <mturon@xbow.com>
 */
generic module HplAtm128InterruptPinP (uint8_t ctrl_addr, 
				 uint8_t edge0bit, 
				 uint8_t edge1bit, 
				 uint8_t bit)
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

#define ctrl  (*(volatile uint8_t *)ctrl_addr)

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
