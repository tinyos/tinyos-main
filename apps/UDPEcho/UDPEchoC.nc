/*
 * Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
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
 */

#include <6lowpan.h>
#ifdef DBG_TRACK_FLOWS
#include "TestDriver.h"
#endif

configuration UDPEchoC {

} implementation {
  components MainC, LedsC;
  components UDPEchoP;

  UDPEchoP.Boot -> MainC;
  UDPEchoP.Leds -> LedsC;

  components new TimerMilliC();
  components IPDispatchC;

  UDPEchoP.RadioControl -> IPDispatchC;
  components new UdpSocketC() as Echo,
    new UdpSocketC() as Status;
  UDPEchoP.Echo -> Echo;

  UDPEchoP.Status -> Status;

  UDPEchoP.StatusTimer -> TimerMilliC;

  components UdpC;
  UDPEchoP.IPStats -> IPDispatchC.IPStats;
  UDPEchoP.UDPStats -> UdpC;
  UDPEchoP.RouteStats -> IPDispatchC.RouteStats;
  UDPEchoP.ICMPStats -> IPDispatchC.ICMPStats;

  components RandomC;
  UDPEchoP.Random -> RandomC;

  components UDPShellC;

#ifdef SIM
  components BaseStationC;
#endif
#ifdef DBG_TRACK_FLOWS
  components TestDriverP, SerialActiveMessageC as Serial;
  components ICMPResponderC, IPRoutingP;
  TestDriverP.Boot -> MainC;
  TestDriverP.SerialControl -> Serial;
  TestDriverP.ICMPPing -> ICMPResponderC.ICMPPing[unique("PING")];
  TestDriverP.CmdReceive -> Serial.Receive[AM_TESTDRIVER_MSG];
  TestDriverP.IPRouting -> IPRoutingP;
  TestDriverP.DoneSend -> Serial.AMSend[AM_TESTDRIVER_MSG];
  TestDriverP.AckSend -> Serial.AMSend[AM_TESTDRIVER_ACK];
  TestDriverP.RadioControl -> IPDispatchC;
#endif
#ifdef DBG_FLOWS_REPORT
  components TrackFlowsC;
#endif
}
