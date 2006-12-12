/// $Id: HplAtm128InterruptSigP.nc,v 1.4 2006-12-12 18:23:04 vlahan Exp $

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
 * Exposes just the interrupt vector routine for 
 * easy linking to generic components.
 *
 * @author Martin Turon <mturon@xbow.com>
 */
module HplAtm128InterruptSigP
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
