/**
 * Copyright (c) 2015, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Tim Bormann <code@tkn.tu-berlin.de>
 */

generic module CounterMilli16P(uint8_t timer_id) {
  provides interface Counter<TMilli,uint16_t>;
  provides interface Init;
  uses interface Jn516Timer;
}
implementation
{
  bool int_pending;
  #define MAX_COUNTER 0xFFFF
  async event void Jn516Timer.fired(uint8_t jn516timer_id)
  {
    atomic {
      if (jn516timer_id == timer_id) {
        int_pending = TRUE;
        signal Counter.overflow();
      }
    }
  }

  command error_t Init.init()
  {
    int_pending = FALSE;
    call Jn516Timer.init(timer_id);
    call Jn516Timer.startRepeat(timer_id,MAX_COUNTER);
    return SUCCESS;
  }

  async command uint16_t Counter.get()
  {
    uint16_t value = call Jn516Timer.read(timer_id);
    //return MAX_COUNTER-value;
    return value;
  }

  async command bool Counter.isOverflowPending()
  {
    return int_pending;
  }

  async command void Counter.clearOverflow()
  {
    atomic {
      call Jn516Timer.clearFiredStatus(timer_id);
      int_pending = FALSE;
    }
  }

  default async event void Counter.overflow()
  {
  }
}
