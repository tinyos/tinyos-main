/*
 * "Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

#include <6lowpan.h>

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

  UDPEchoP.IPStats -> IPDispatchC.IPStats;
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
  components new TimerMilliC() as Mark;
  TestDriverP.Boot -> MainC;
  TestDriverP.SerialControl -> Serial;
  TestDriverP.ICMPPing -> ICMPResponderC.ICMPPing[unique("PING")];
  TestDriverP.CmdReceive -> Serial.Receive[AM_TESTDRIVER_MSG];
  TestDriverP.IPRouting -> IPRoutingP;
  TestDriverP.DoneSend -> Serial.AMSend[AM_TESTDRIVER_MSG];
  TestDriverP.RadioControl -> IPDispatchC;
  TestDriverP.MarkTimer -> Mark;
#endif
}
