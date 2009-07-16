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
 * @author: Miklos Maroti, Brano Kusy (kusy@isis.vanderbilt.edu)
 * Ported to T2: 3/17/08 by Brano Kusy (branislav.kusy@gmail.com)
 * Adapted for LPL: 6/16/09 by Thomas Schmid (thomas.schmid@ucla.edu)
 */

#include "TestFtsp.h"
#include "RadioCountToLeds.h"

configuration TestFtspAppC {
}

implementation {
  components MainC, TimeSync32kC;

  MainC.SoftwareInit -> TimeSync32kC;
  TimeSync32kC.Boot -> MainC;

  components TestFtspC as App;
  App.Boot -> MainC;

  components ActiveMessageC;
  components TimeSyncMessageC;
  App.RadioControl -> ActiveMessageC;
  App.Receive -> TimeSyncMessageC.Receive[AM_RADIO_COUNT_MSG];
  App.TimeSyncPacket -> TimeSyncMessageC;
  App.AMSend -> ActiveMessageC.AMSend[AM_TEST_FTSP_MSG];
  App.Packet -> ActiveMessageC;
  App.PacketTimeStamp -> ActiveMessageC;

  components RandomC;
  App.Random -> RandomC;

  components new TimerMilliC() as Timer0;
  App.RandomTimer -> Timer0;

  components LedsC;

  App.GlobalTime -> TimeSync32kC;
  App.TimeSyncInfo -> TimeSync32kC;
  App.Leds -> LedsC;

#ifdef LOW_POWER_LISTENING
  components CC2420ActiveMessageC;
  App.LowPowerListening -> CC2420ActiveMessageC;
#endif

}
