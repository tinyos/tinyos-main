// $Id: TestCommAppC.nc,v 1.2 2007-09-04 17:19:23 scipio Exp $

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
 * This application sends a single active message broadcast if it has
 * address 0, and then starts a timer at 1Hz.  If it has any address 
 * other than 0, it starts a timer at 1 Hz upon receiving a broadcast 
 * message.  The idea is to have one base station with address 0 send 
 * out a broadacst message to synchronize itself with all receivers.  
 * All Leds from the base station and any receivers of the broadcast 
 * should blink together.
 
 * It uses the radio HIL component
 * <tt>ActiveMessageC</tt>, and its packets are AM type 240.
 *
 * @author Phil Levis
 * @author Kevin Klues
 * @date   Nov 7 2005
 */

configuration TestCommAppC {}
implementation {
  enum {
    AM_TEST  = 5
  };
  
  components MainC, TestCommC as App, RandomC, ActiveMessageC, TossimActiveMessageC;
  components new TimerMilliC(), new AMSenderC(AM_TEST), new AMReceiverC(AM_TEST);
  
  App.Boot -> MainC.Boot;
  App.SplitControl -> ActiveMessageC;
  App.Timer -> TimerMilliC;
  App.AMSend -> AMSenderC;
  App.Receive -> AMReceiverC;
  App.Random -> RandomC;
  App.AMPacket -> AMSenderC;
  App.PacketAcknowledgements -> AMSenderC;
  App.TossimPacket -> TossimActiveMessageC;
}


