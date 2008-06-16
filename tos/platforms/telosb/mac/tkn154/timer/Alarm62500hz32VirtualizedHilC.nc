
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

/**
 * Alarm62500hzC is the alarm for async 62500hz alarms (virtualized)
 * This is the place where we cheat: since we don't have a clock source
 * running at 62500 Hz, we cast 2 symbols to 1 tick of the 32768
 * clock, which introduces a small error.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * @see  Please refer to TEP 102 for more information about this component and its
 *          intended use.
 */

//#include "Timer.h"
#include "Timer62500hz.h"
generic configuration Alarm62500hz32VirtualizedHilC()
{
  provides interface Alarm<T62500hz,uint32_t>;
}
implementation
{
  components new Alarm32khzTo62500hzTransformC();
  components Alarm62500hz32VirtualizedHilP;
  
  Alarm = Alarm32khzTo62500hzTransformC;
  Alarm32khzTo62500hzTransformC.AlarmFrom -> Alarm62500hz32VirtualizedHilP.Alarm[unique(UQ_ALARM_32KHZ32)];
}

