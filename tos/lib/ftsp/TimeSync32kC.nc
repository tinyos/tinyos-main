/*
 * Copyright (c) 2002, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti, Brano Kusy, Janos Sallai
 * Date last modified: 3/17/03
 * Ported to T2: 3/17/08 by Brano Kusy (branislav.kusy@gmail.com)
 * Adapted for 32kHz and LPL: 6/16/09 by Thomas Schmid (thomas.schmid@ucla.edu)
 */

#include "TimeSyncMsg.h"

configuration TimeSync32kC
{
  uses interface Boot;
  provides interface Init;
  provides interface StdControl;
  provides interface GlobalTime<T32khz>;

  //interfaces for extra fcionality: need not to be wired
  provides interface TimeSyncInfo;
  provides interface TimeSyncMode;
  provides interface TimeSyncNotify;
}

implementation
{
  components new TimeSyncP(T32khz) as TimeSyncP;

  GlobalTime      =   TimeSyncP;
  StdControl      =   TimeSyncP;
  Init            =   TimeSyncP;
  Boot            =   TimeSyncP;
  TimeSyncInfo    =   TimeSyncP;
  TimeSyncMode    =   TimeSyncP;
  TimeSyncNotify  =   TimeSyncP;

  components TimeSyncMessageC as ActiveMessageC;
  TimeSyncP.RadioControl    ->  ActiveMessageC;
  TimeSyncP.Send            ->  ActiveMessageC.TimeSyncAMSend32khz[AM_TIMESYNCMSG];
  TimeSyncP.Receive         ->  ActiveMessageC.Receive[AM_TIMESYNCMSG];
  TimeSyncP.TimeSyncPacket  ->  ActiveMessageC;

  components Counter32khz32C, new CounterToLocalTimeC(T32khz) as LocalTime32khzC;
  LocalTime32khzC.Counter -> Counter32khz32C;
  TimeSyncP.LocalTime     -> LocalTime32khzC;

  components new TimerMilliC() as TimerC;
  TimeSyncP.Timer ->  TimerC;

#if defined(TIMESYNC_LEDS)
  components LedsC;
#else
  components NoLedsC as LedsC;
#endif
  TimeSyncP.Leds  ->  LedsC;

#ifdef LOW_POWER_LISTENING
  components CC2420ActiveMessageC;
  TimeSyncP.LowPowerListening -> CC2420ActiveMessageC;
#endif


}
