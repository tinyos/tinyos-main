/// $Id: Atm128InterruptC.nc,v 1.5 2010-06-29 22:07:43 scipio Exp $

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
 * @author Martin Turon
 */

generic module Atm128InterruptC() {
  provides interface Interrupt;
  uses interface HplAtm128Interrupt;
}
implementation {
  /**
   * enable an edge interrupt on the Interrupt pin
   */
  async command error_t Interrupt.startWait(bool low_to_high) {
    atomic {
      call HplAtm128Interrupt.disable();
      call HplAtm128Interrupt.clear();
      call HplAtm128Interrupt.edge(low_to_high);
      call HplAtm128Interrupt.enable();
    }
    return SUCCESS;
  }

  /**
   * disables Interrupt interrupts
   */
  async command error_t Interrupt.disable() {
    call HplAtm128Interrupt.disable();
    return SUCCESS;
  }

  /**
   * Event fired by lower level interrupt dispatch for Interrupt
   */
  async event void HplAtm128Interrupt.fired() {
    // The flag is automatically cleared, clearing it again can cause missed interrupts
    // call HplAtm128Interrupt.clear();
    signal Interrupt.fired();
  }

  default async event void Interrupt.fired() { }
}
