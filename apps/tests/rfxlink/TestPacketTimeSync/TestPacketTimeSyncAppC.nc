/*
 * Copyright (c) 2002-2011, Vanderbilt University
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
 * Author: Janos Sallai
 */

#include "TestPacketTimeSync.h"

configuration TestPacketTimeSyncAppC {}
implementation {
  components MainC, TestPacketTimeSyncC as App, LedsC;
  components ActiveMessageC;
  components TimeSyncMessageC;
  components new TimerMilliC();
  components LocalTimeMicroC;
  components NoSleepC;

  App.Boot -> MainC.Boot;

  App.PingReceive -> TimeSyncMessageC.Receive[AM_PING_MSG];
  App.PingAMSend -> TimeSyncMessageC.TimeSyncAMSendRadio[AM_PING_MSG];
  App.PongAMSend -> ActiveMessageC.AMSend[AM_PONG_MSG];
  App.AMControl -> ActiveMessageC;
  App.Leds -> LedsC;
  App.MilliTimer -> TimerMilliC;
  App.Packet -> ActiveMessageC;
  App.AMPacket -> ActiveMessageC;
  App.PacketTimeStamp -> ActiveMessageC;
  App.TimeSyncPacket -> TimeSyncMessageC;
  App.LocalTime -> LocalTimeMicroC;
  
}


