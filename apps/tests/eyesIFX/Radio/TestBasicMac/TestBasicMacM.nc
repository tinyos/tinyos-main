// $Id: TestBasicMacM.nc,v 1.1.1.1 2005-11-04 18:20:16 kristinwright Exp $

/*                                  tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.
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

module TestBasicMacM {
  uses {
    interface Boot;
    interface SplitControl as MacSplitControl;
    interface Alarm<TMilli, uint32_t> as SendTimer;
    interface Leds;
    interface Random;
    interface Send;
    interface Receive;
  }
}

implementation {
  
  #define TIMER_RATE    500
  #define NUM_BYTES     TOSH_DATA_LENGTH
  
  message_t sendMsg;
  
  event void Boot.booted() {
    uint8_t i;
    for(i=0; i<NUM_BYTES; i++)
      sendMsg.data[i] = 0xF0;//call Random.rand16() / 2;
    call MacSplitControl.start();
  }
  
  event void MacSplitControl.startDone(error_t error) {
    call Send.send(&sendMsg, NUM_BYTES);  
  }
  
  event void MacSplitControl.stopDone(error_t error) {
    call SendTimer.stop();
  }  
  
  async event void SendTimer.fired() {
    call Send.send(&sendMsg, NUM_BYTES);
  }
  
  event void Send.sendDone(message_t* msg, error_t error) {
    if(error == SUCCESS)
		  call Leds.led0Toggle();
	  else call Leds.led2Toggle();
    call SendTimer.start(call Random.rand16() % TIMER_RATE);
  }
  
  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    call Leds.led1Toggle();
    return msg;
  }
}


