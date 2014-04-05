/*
 * Copyright (c) 2013 Eric B. Decker
 * Copyright (c) 2000-2003 The Regents of the University of California.
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
 * - Neither the name of the copyright holders nor the names of
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

#include "Timer.h"

/**
 * BusyWaitCounterC uses a Counter to implement the BusyWait interface
 * (block until a specified amount of time elapses). See TEP102 for more
 * details.
 *
 * <p>See TEP102 for more details.
 *
 * @param precision_tag A type indicating the precision of the BusyWait
 *   interface.
 * @param size_type An integer type representing time values for the
 *   BusyWait interface.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 * @author Eric B. Decker <cire831@gmail.com>
 */

generic module BusyWaitCounterC(typedef precision_tag, typedef size_type @integer())
{
  provides interface BusyWait<precision_tag,size_type>;
  uses interface Counter<precision_tag,size_type>;
}
implementation
{
  enum
  {
    HALF_MAX_SIZE_TYPE = ((size_type)1) << (8*sizeof(size_type)-1),
  };

  async command void BusyWait.wait(size_type dt)
  {
    atomic
    {
      // comparisons are <= to guarantee a wait at least as long as dt
      // we need to make sure this works when sizeof(size_type) < sizeof(int)

      size_type t0 = call Counter.get();

      if(dt > HALF_MAX_SIZE_TYPE)
      {
        dt -= HALF_MAX_SIZE_TYPE;
        while((size_type) (call Counter.get() - t0) <= dt);
        t0 += dt;
        dt = HALF_MAX_SIZE_TYPE;
      }

      while((size_type) (call Counter.get() - t0) <= dt);
    }
  }

  async event void Counter.overflow()
  {
  }
}

