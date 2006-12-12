//$Id: LocalTime.nc,v 1.4 2006-12-12 18:23:32 vlahan Exp $

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

interface LocalTime<precision_tag>
{
  /** 
   * Return current time. Time starts counting at boot - some time sources
   * may stop counting while the processor is in low-power mode.
   *
   * @return Current time.
   */
  async command uint32_t get();
}

