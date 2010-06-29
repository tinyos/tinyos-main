//$Id: LocalTime64.nc,v 1.2 2010-06-29 22:07:54 scipio Exp $

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
 * A LocalTime interface counts time in some units. If you need to detect
 * time overflow, you should use a component offering the Counter
 * interface.
 *
 * <p>The LocalTime interface is parameterised by its "precision"
 * (milliseconds, microseconds, etc), identified by a type. This prevents,
 * e.g., unintentionally mixing components expecting milliseconds with
 * those expecting microseconds as those interfaces have a different type.
 *
 * <p>See TEP102 for more details.
 *
 * @param precision_tag A type indicating the precision of this Counter.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 */

interface LocalTime64<precision_tag>
{
  /** 
   * Return current time. Time starts counting at boot - some time sources
   * may stop counting while the processor is in low-power mode.
   *
   * @return Current time.
   */
  async command uint64_t get();
}

