/// $Id: HplAtm128InterruptSigP.nc,v 1.6 2010-06-29 22:07:43 scipio Exp $

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
 * Exposes just the interrupt vector routine for 
 * easy linking to generic components.
 *
 * @author Martin Turon <mturon@xbow.com>
 */
module HplAtm128InterruptSigP @safe()
{
  provides interface HplAtm128InterruptSig as IntSig0;
  provides interface HplAtm128InterruptSig as IntSig1;
  provides interface HplAtm128InterruptSig as IntSig2;
  provides interface HplAtm128InterruptSig as IntSig3;
  provides interface HplAtm128InterruptSig as IntSig4;
  provides interface HplAtm128InterruptSig as IntSig5;
  provides interface HplAtm128InterruptSig as IntSig6;
  provides interface HplAtm128InterruptSig as IntSig7;
}
implementation
{
  default async event void IntSig0.fired() { }
  AVR_ATOMIC_HANDLER( SIG_INTERRUPT0 ) {
    signal IntSig0.fired();
  }

  default async event void IntSig1.fired() { }
  AVR_ATOMIC_HANDLER( SIG_INTERRUPT1 ) {
    signal IntSig1.fired();
  }

  default async event void IntSig2.fired() { }
  AVR_ATOMIC_HANDLER( SIG_INTERRUPT2 ) {
    signal IntSig2.fired();
  }

  default async event void IntSig3.fired() { }
  AVR_ATOMIC_HANDLER( SIG_INTERRUPT3 ) {
    signal IntSig3.fired();
  }

  default async event void IntSig4.fired() { }
  AVR_ATOMIC_HANDLER( SIG_INTERRUPT4 ) {
    signal IntSig4.fired();
  }

  default async event void IntSig5.fired() { }
  AVR_ATOMIC_HANDLER( SIG_INTERRUPT5 ) {
    signal IntSig5.fired();
  }

  default async event void IntSig6.fired() { }
  AVR_ATOMIC_HANDLER( SIG_INTERRUPT6 ) {
    signal IntSig6.fired();
  }

  default async event void IntSig7.fired() { }
  AVR_ATOMIC_HANDLER( SIG_INTERRUPT7 ) {
    signal IntSig7.fired();
  }
}
