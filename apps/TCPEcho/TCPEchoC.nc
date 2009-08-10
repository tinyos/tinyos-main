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

configuration TCPEchoC {

} implementation {
  components MainC, LedsC;
  components TCPEchoP;

  TCPEchoP.Boot -> MainC;
  TCPEchoP.Leds -> LedsC;

  components new TimerMilliC();
  components IPDispatchC;

  TCPEchoP.RadioControl -> IPDispatchC;
  components new UdpSocketC() as Echo,
    new UdpSocketC() as Status;
  TCPEchoP.Echo -> Echo;

  components new TcpSocketC() as TcpEcho;
  TCPEchoP.TcpEcho -> TcpEcho;

  components new TcpSocketC() as TcpWeb, HttpdP;
  HttpdP.Boot -> MainC;
  HttpdP.Leds -> LedsC;
  HttpdP.Tcp -> TcpWeb;

  TCPEchoP.Status -> Status;

  TCPEchoP.StatusTimer -> TimerMilliC;

  components UdpC;

  TCPEchoP.IPStats -> IPDispatchC.IPStats;
  TCPEchoP.RouteStats -> IPDispatchC.RouteStats;
  TCPEchoP.ICMPStats -> IPDispatchC.ICMPStats;
  TCPEchoP.UDPStats -> UdpC;

  components RandomC;
  TCPEchoP.Random -> RandomC;

  components UDPShellC;
}
