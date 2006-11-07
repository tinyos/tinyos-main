//$Id: BusyWaitCounterC.nc,v 1.3 2006-11-07 19:31:20 scipio Exp $

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

      size_type t0 = call Counter.get();

      if(dt > HALF_MAX_SIZE_TYPE)
      {
        dt -= HALF_MAX_SIZE_TYPE;
        while((call Counter.get() - t0) <= dt);
        t0 += dt;
        dt = HALF_MAX_SIZE_TYPE;
      }

      while((call Counter.get() - t0) <= dt);
    }
  }

  async event void Counter.overflow()
  {
  }
}

