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

/**
 * Build a TEP102 32 bit Counter from two M16c/62p hardware timers.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

generic module M16c62pCounter32C(typedef precision_tag)
{
  provides interface Counter<precision_tag, uint32_t> as Counter;
  uses interface HplM16c62pTimer as TimerLow;
  uses interface HplM16c62pTimer as TimerHigh;
}
implementation
{
  async command uint32_t Counter.get()
  {
    uint32_t time = 0;
    atomic
    {
      time = (((uint32_t)call TimerHigh.get()) << 16) + call TimerLow.get();
    }
    // The timers count down so the time needs to be inverted.
    return (0xFFFFFFFF) - time;
  }

  async command bool Counter.isOverflowPending()
  {
    return call TimerHigh.testInterrupt();
  }

  async command void Counter.clearOverflow()
  {
    call TimerHigh.clearInterrupt();
  }

  async event void TimerHigh.fired()
  {
    signal Counter.overflow();
  }

  async event void TimerLow.fired() {}
}

