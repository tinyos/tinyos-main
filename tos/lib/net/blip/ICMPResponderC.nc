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

configuration ICMPResponderC {
  provides interface ICMP;
  provides interface ICMPPing[uint16_t client];
  provides interface Statistics<icmp_statistics_t>;
} implementation {
  components NoLedsC as LedsC;
  components IPDispatchC, IPRoutingP, ICMPResponderP, IPAddressC;

  ICMP = ICMPResponderP;
  ICMPPing = ICMPResponderP;
  Statistics = ICMPResponderP;

  ICMPResponderP.Leds -> LedsC;

  ICMPResponderP.IP -> IPDispatchC.IP[IANA_ICMP];

  ICMPResponderP.IPAddress -> IPAddressC;

  ICMPResponderP.IPRouting -> IPRoutingP;

  components RandomC;
  ICMPResponderP.Random -> RandomC;

  components new TimerMilliC() as STimer,
    new TimerMilliC() as ATimer,
    new TimerMilliC() as PTimer;
  ICMPResponderP.Solicitation -> STimer;
  ICMPResponderP.Advertisement -> ATimer;
  ICMPResponderP.PingTimer -> PTimer;

  components HilTimerMilliC;
  ICMPResponderP.LocalTime -> HilTimerMilliC;
}
