/**
 * "Copyright (c) 2010 CSIRO Australia
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
 * @author Kevin Klues 
 */
 
configuration HilAlarmMilliC
{
  provides 
  {
      interface Init;
      interface Alarm<TMilli,uint32_t> as AlarmMilli[uint8_t id];
  }
}
implementation
{
  components HalSam3RttC as AlarmC;
  components new VirtualizeAlarmC(TMilli, uint32_t, uniqueCount(UQ_ALARM_TMILLI)) as VirtAlarmsTMilli;

  Init = AlarmC;
  AlarmMilli = VirtAlarmsTMilli.Alarm;
  VirtAlarmsTMilli.AlarmFrom -> AlarmC;
}
