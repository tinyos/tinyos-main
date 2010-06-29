/*
 * Copyright (c) 2002, Vanderbilt University
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
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
  components MainC, TestFtspC as App;
  App.Boot -> MainC;

  components ActiveMessageC;
  components TimeSyncMessageC;
  App.RadioControl -> ActiveMessageC;
  App.Receive -> TimeSyncMessageC.Receive[AM_RADIO_COUNT_MSG];
  App.TimeSyncPacket -> TimeSyncMessageC;
  App.AMSend -> ActiveMessageC.AMSend[AM_TEST_FTSP_MSG];
  App.Packet -> ActiveMessageC;
  App.PacketTimeStamp -> ActiveMessageC;
  App.LowPowerListening -> ActiveMessageC;


  components RandomC;
  App.Random -> RandomC;

  components new TimerMilliC() as Timer0;
  App.RandomTimer -> Timer0;

  components LedsC;

#if defined(PLATFORM_MICAZ) || defined(PLATFORM_TELOSB)
  components TimeSync32kC;
  MainC.SoftwareInit -> TimeSync32kC;
  TimeSync32kC.Boot -> MainC;
  App.GlobalTime -> TimeSync32kC;
  App.TimeSyncInfo -> TimeSync32kC;
#else
#error "LPL timesync is not available for your platform"
#endif
  App.Leds -> LedsC;
  
}
