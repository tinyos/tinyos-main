// $Id: TestCommC.nc,v 1.4 2010-06-29 22:07:25 scipio Exp $

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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 *  Implementation of the TestTimer application.
 *
 *  @author Phil Levis
 *  @date   April 7 2007
 *
 **/

module TestCommC {
  uses {
    interface Boot;
    interface Timer<TMilli> as Timer;
    interface Receive;
    interface AMSend;
    interface Random;
    interface SplitControl;
    interface AMPacket;
    interface PacketAcknowledgements;
    interface TossimPacket;
  }
}
implementation {

  message_t packet;
  uint8_t busy;
  
  event void Boot.booted() {
    dbg("TestComm", "Booted @ %s.\n", sim_time_string());
    call SplitControl.start();
  }

  event void SplitControl.startDone(error_t e) {
    if (TOS_NODE_ID == 1 ||
	TOS_NODE_ID == 3) {
      call Timer.startPeriodic(128);
    }
  }
  
  event void SplitControl.stopDone(error_t e) {

  }
    
  event void Timer.fired() {
    if (!busy) {
      call PacketAcknowledgements.requestAck(&packet);
      if (call AMSend.send(2, &packet, call AMSend.maxPayloadLength()) == SUCCESS) {
	dbg("TestComm", "Send succeeded @ %s\n", sim_time_string());
	busy = TRUE;
      }
      else {
	dbg("TestComm", "Send failed at @ %s\n", sim_time_string());
      }
    }
    else {
      dbg("TestComm", "Send when busy at @ %s\n", sim_time_string());
    }
  }

  event void AMSend.sendDone(message_t* m, error_t s) {
    dbg("TestComm", "Send completed with %s @ %s\n", call PacketAcknowledgements.wasAcked(m)? "ACK":"NOACK", sim_time_string());
    busy = FALSE;
  }


  event message_t* Receive.receive(message_t* msg, void* p, uint8_t l) {
    dbg("TestComm", "Received message from %hu @ %s with strength %hhi\n", call AMPacket.source(msg), sim_time_string(), call TossimPacket.strength(msg));
    return msg;
  }
}




