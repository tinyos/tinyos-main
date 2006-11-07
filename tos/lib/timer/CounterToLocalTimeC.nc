//$Id: CounterToLocalTimeC.nc,v 1.3 2006-11-07 19:31:20 scipio Exp $

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
 * CounterToLocalTimeC converts a 32-bit LocalTime to a Counter.  
 *
 * <p>See TEP102 for more details.
 * @param precision_tag A type indicating the precision of the LocalTime and
 * Counter being converted.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 */

generic module CounterToLocalTimeC(typedef precision_tag)
{
  provides interface LocalTime<precision_tag>;
  uses interface Counter<precision_tag,uint32_t>;
}
implementation
{
  async command uint32_t LocalTime.get()
  {
    return call Counter.get();
  }

  async event void Counter.overflow()
  {
  }
}

