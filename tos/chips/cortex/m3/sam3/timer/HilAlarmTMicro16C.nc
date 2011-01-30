/**
 * "Copyright (c) 2009 The Regents of the University of California.
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
 * @author Kevin Klues <Kevin.Klues@csiro.au>
 *
 */

configuration HilAlarmTMicro16C
{
  provides 
  {
      interface Init;
      interface Alarm<TMicro, uint16_t> as Alarm[ uint8_t num ];
  }
}

implementation
{
  components new VirtualizeAlarmC(TMicro, uint16_t, uniqueCount(UQ_ALARM_TMICRO16)) as VirtAlarmsTMicro16;
  components HilSam3TCCounterTMicroC as HplSam3TCChannel;
  components new HilSam3TCAlarmC(TMicro, 1000) as HilSam3TCAlarm;

  Init = HilSam3TCAlarm;
  Alarm = VirtAlarmsTMicro16.Alarm;

  VirtAlarmsTMicro16.AlarmFrom -> HilSam3TCAlarm;
  HilSam3TCAlarm.HplSam3TCChannel -> HplSam3TCChannel;
  HilSam3TCAlarm.HplSam3TCCompare -> HplSam3TCChannel;
}

