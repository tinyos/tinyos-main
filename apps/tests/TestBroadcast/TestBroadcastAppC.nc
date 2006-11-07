// $Id: TestBroadcastAppC.nc,v 1.3 2006-11-07 19:30:35 scipio Exp $

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
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * This OSKI test application sends broadcasts at 1Hz and blinks
 * LED 0 when it receives a broadcast. It uses the OSKI broadcast
 * service with broadcast ID 240: it does not interoperate with
 * the TestAM or TestAMService applications.
 *
 * @author Philip Levis
 * @date   May 16 2005
 */

configuration TestBroadcastAppC {}
implementation {
  components MainC, TestBroadcastC as App, LedsC;
  components new BroadcastSenderC(240) as Sender;
  components new BroadcastReceiverC(240) as Receiver;
  components new BroadcastServiceC();
  components new TimerMilliC();
  
  
  
  App.Boot -> MainC.Boot;

  App.Receive -> Receiver;
  App.Send -> Sender;
  App.Service -> BroadcastServiceC.Service;
  App.Leds -> LedsC;
  App.MilliTimer -> TimerMilliC;
}


