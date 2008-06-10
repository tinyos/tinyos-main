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
 */

#include "TestFTSP.h"
#include "RadioCountToLeds.h"

configuration TestFTSPC {
}

implementation {
	components MainC, TimeSyncC;

  MainC.SoftwareInit -> TimeSyncC;
  TimeSyncC.Boot -> MainC;

	components TestFTSPAppC as App;
  App.Boot -> MainC;

  components ActiveMessageC;
  App.RadioControl -> ActiveMessageC;
  App.Receive -> ActiveMessageC.Receive[AM_RADIO_COUNT_MSG];
  App.AMSend -> ActiveMessageC.AMSend[AM_TEST_FTSP_MSG];
  App.Packet -> ActiveMessageC;
  App.PacketTimeStamp -> ActiveMessageC;

  components LedsC;

  App.GlobalTime -> TimeSyncC;
  App.TimeSyncInfo -> TimeSyncC;
  App.Leds -> LedsC;

}
