// $Id: RadioCountToLedsAppC.nc,v 1.4 2006/12/12 18:22:48 vlahan Exp $

/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.
 * All rights reserved.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA,
 * 94704.  Attention:  Intel License Inquiry.
 */

#include "TestRPL.h"
#include "printf.h"

/**
 * Configuration for the RadioCountToLeds application. RadioCountToLeds
 * maintains a 4Hz counter, broadcasting its value in an AM packet
 * every time it gets updated. A RadioCountToLeds node that hears a counter
 * displays the bottom three bits on its LEDs. This application is a useful
 * test to show that basic AM communication and timers work.
 *
 * @author Philip Levis
 * @date   June 6 2005
 */

configuration TestRPLAppC {}
implementation {
  components MainC, TestRPLC as App, LedsC;
  components new TimerMilliC();
  components new TimerMilliC() as Timer;
  components RandomC;
  components RPLRankC;
  components RPLRoutingEngineC;
  components IPDispatchC;
  //components RPLForwardingEngineC;
  components RPLDAORoutingEngineC;
  components IPStackC;
  components IPProtocolsP;

  App.Boot -> MainC.Boot;
  App.SplitControl -> IPStackC;//IPDispatchC;
  App.Leds -> LedsC;
  App.MilliTimer -> TimerMilliC;
  App.RPLRoute -> RPLRoutingEngineC;
  App.RootControl -> RPLRoutingEngineC;
  App.RoutingControl -> RPLRoutingEngineC;

  components new UdpSocketC() as RPLUDP;
  App.RPLUDP -> RPLUDP;

  App.RPLDAO -> RPLDAORoutingEngineC;
  App.Timer -> Timer;
  App.Random -> RandomC;

  components StaticIPAddressC;

#ifdef RPL_ROUTING
  components RPLRoutingC;
#endif

#ifdef PRINTFUART_ENABLED
  components PrintfC;
  components SerialStartC;
#endif

  //components LcdC;
  //App.Lcd -> LcdC;
  //App.Draw -> LcdC;

}
