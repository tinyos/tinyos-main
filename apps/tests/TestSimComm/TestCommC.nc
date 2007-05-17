// $Id: TestCommC.nc,v 1.1 2007-05-17 22:06:10 scipio Exp $

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
  }
}
implementation {

  message_t packet;
  uint8_t busy;
  
  event void Boot.booted() {
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
    dbg("TestComm", "Received message from %hu @ %s\n", call AMPacket.source(msg), sim_time_string());
    return msg;
  }
}




