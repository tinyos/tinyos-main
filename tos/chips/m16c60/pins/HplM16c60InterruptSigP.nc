/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
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
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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
 *
 * @author Martin Turon <mturon@xbow.com>
 */
 
/**
 * Interrupt interface access for interrupt capable GPIO pins.
 * Exposes just the interrupt vector routine for 
 * easy linking to generic components.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */
module HplM16c60InterruptSigP
{
  provides interface HplM16c60InterruptSig as IntSig0;
  provides interface HplM16c60InterruptSig as IntSig1;
  provides interface HplM16c60InterruptSig as IntSig2;
  provides interface HplM16c60InterruptSig as IntSig3;
  provides interface HplM16c60InterruptSig as IntSig4;
  provides interface HplM16c60InterruptSig as IntSig5;
#ifdef THREADS
  uses interface PlatformInterrupt;
#define POST_AMBLE() call PlatformInterrupt.postAmble()
#else 
#define POST_AMBLE()
#endif 
}
implementation
{
  default async event void IntSig0.fired() { }
  M16C_INTERRUPT_HANDLER(M16C_INT0)
  {
    signal IntSig0.fired();
    POST_AMBLE();
  }

  default async event void IntSig1.fired() { }
  M16C_INTERRUPT_HANDLER(M16C_INT1)
  {
    signal IntSig1.fired();
    POST_AMBLE();
  }

  default async event void IntSig2.fired() { }
  M16C_INTERRUPT_HANDLER(M16C_INT2)
  {
    signal IntSig2.fired();
    POST_AMBLE();
  }

  default async event void IntSig3.fired() { }
  M16C_INTERRUPT_HANDLER(M16C_INT3)
  {
    signal IntSig3.fired();
    POST_AMBLE();
  }

  default async event void IntSig4.fired() { }
  M16C_INTERRUPT_HANDLER(M16C_INT4)
  {
    signal IntSig4.fired();
    POST_AMBLE();
  }

  default async event void IntSig5.fired() { }
  M16C_INTERRUPT_HANDLER(M16C_INT5)
  {
    signal IntSig5.fired();
    POST_AMBLE();
  }

}
