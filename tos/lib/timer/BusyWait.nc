//$Id: BusyWait.nc,v 1.4 2006-12-12 18:23:32 vlahan Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

#include "Timer.h"

/**
 * BusyWait is a low-level interface intended for busy waiting for short
 * durations.
 *
 * <p>BusyWait is parameterised by its "precision" (milliseconds,
 * microseconds, etc), identified by a type. This prevents, e.g.,
 * unintentionally mixing components expecting milliseconds with those
 * expecting microseconds as those interfaces have a different type.
 *
 * <p>BusyWait's second parameter is its "width", i.e., the number of bits
 * used to represent time values. Width is indicated by including the
 * appropriate size integer type as a BusyWait parameter.
 *
 * <p>See TEP102 for more details.
 *
 * @param precision_tag A type indicating the precision of this BusyWait
 *   interface.
 * @param size_type An integer type representing time values for this 
 *   BusyWait interface.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 */

interface BusyWait<precision_tag, size_type>
{
  /**
   * Busy wait for (at least) dt time units. Use sparingly, when the
   * cost of using an Alarm or Timer would be too high.
   * @param dt Time to busy wait for.
   */
  async command void wait(size_type dt);
}

