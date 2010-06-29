// $Id: TestCommAppC.nc,v 1.4 2010-06-29 22:07:25 scipio Exp $

/*									tab:4
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * - Neither the name of the University of California nor the names of
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
    AM_TEST  = 133
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


