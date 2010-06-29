//$Id: Counter.nc,v 1.5 2010-06-29 22:07:50 scipio Exp $

/* Copyright (c) 2000-2003 The Regents of the University of California.  
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

#include "Timer.h"

/**
 * A Counter counts time in some units and in some width, signaling
 * overflow.
 *
 * <p>A Counter is parameterised by its "precision" (milliseconds,
 * microseconds, etc), identified by a type. This prevents, e.g.,
 * unintentionally mixing components expecting milliseconds with those
 * expecting microseconds as those interfaces have a different type.
 *
 * <p>A Counter's second parameter is its "width", i.e., the number of
 * bits used to represent time values. Width is indicated by including
 * the appropriate size integer type as a Counter parameter.
 *
 * <p>See TEP102 for more details.
 *
 * @param precision_tag A type indicating the precision of this Counter.
 * @param size_type An integer type representing time values for this Counter.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 */

interface Counter<precision_tag, size_type>
{
  /** 
   * Return counter value. Counters start at boot - some time sources may
   * stop counting while the processor is in low-power mode.
   * @return Current counter value.
   */
  async command size_type get();

  /** 
   * Return TRUE if an overflow event will occur after the outermost atomic
   * block is exits.  FALSE otherwise.
   * @return Counter pending overflow status.
   */
  async command bool isOverflowPending();

  /**
   * Cancel a pending overflow interrupt.
   */
  async command void clearOverflow();

  /**
   * Signals that the current time has overflowed.  That is, the current
   * time has wrapped around from its maximum value to zero.
   */ 
  async event void overflow();
}

