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
 * Alarm32khzC is the alarm for async 32khz alarms
 * @author Thomas Schmid
 * @see  Please refer to TEP 102 for more information about this component and its
 *          intended use.
 */

generic configuration Alarm32khz32C()
{
  provides interface Init;
  provides interface Alarm<T32khz,uint32_t>;
}
implementation
{
  #error The existing implementation that is in here was broken and doesn't work. Check it with an Oscilloscope!
  components HplSam3TC32khzC as HplSam3TCChannel;
  components new HilSam3TCAlarmC(T32khz, 32) as HilSam3TCAlarm;

  Init = HilSam3TCAlarm;
  Alarm = HilSam3TCAlarm;

  HilSam3TCAlarm.HplSam3TCChannel -> HplSam3TCChannel;
  HilSam3TCAlarm.HplSam3TCCompare -> HplSam3TCChannel;
}

