/*
 * Copyright (c) 2008 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * This application stresses the blocking send and receive commands for the TinyOS 
 * thread implementation.  Three threads are run, each thread toggling a different 
 * colored LED. If a node has TOS_NODE_ID == 0 it will try and receive in 
 * an infinite loop, toggling one of the three Leds upon reception.  If it has 
 * TOS_NODE_ID == 1, it will try to send in an infinite loop, toggling one of the three
 * Leds upon the completion of a send.  Thread 0 toggles the Led0, Thread 1 toggles 
 * Led1, and Thread 2 toggles Led2.
 *
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */

#include "AM.h"

module RadioStressC {
  uses {
    interface Boot;
    interface BlockingStdControl as BlockingAMControl;

    interface Thread as RadioStressThread0;
    interface BlockingAMSend as BlockingAMSend0;
    interface BlockingReceive as BlockingReceive0;
    
    interface Thread as RadioStressThread1;
    interface BlockingAMSend as BlockingAMSend1;
    interface BlockingReceive as BlockingReceive1;
    
    interface Thread as RadioStressThread2;
    interface BlockingAMSend as BlockingAMSend2;
    interface BlockingReceive as BlockingReceive2;

    interface Leds;
  }
}

implementation {
  message_t m0;
  message_t m1;
  message_t m2;
  
  event void Boot.booted() {
    call RadioStressThread0.start(NULL);
    call RadioStressThread1.start(NULL);
    call RadioStressThread2.start(NULL);
  }

  event void RadioStressThread0.run(void* arg) {
    call BlockingAMControl.start();
    for(;;) {
      if(TOS_NODE_ID == 0) {
        call BlockingReceive0.receive(&m0, 5000);
        call Leds.led0Toggle();
      }
      else {
        call BlockingAMSend0.send(!TOS_NODE_ID, &m0, 0);
        call Leds.led0Toggle();
        //call RadioStressThread0.sleep(500);
      }
    }
  }
  
  event void RadioStressThread1.run(void* arg) {
    call BlockingAMControl.start();
    for(;;) {
      if(TOS_NODE_ID == 0) {
        call BlockingReceive1.receive(&m1, 5000);
        call Leds.led1Toggle();
      }
      else {
        call BlockingAMSend1.send(!TOS_NODE_ID, &m1, 0);
        call Leds.led1Toggle();
        //call RadioStressThread1.sleep(500);
      }
    }
  }
  
  event void RadioStressThread2.run(void* arg) {
    call BlockingAMControl.start();
    for(;;) {
      if(TOS_NODE_ID == 0) {
        call BlockingReceive2.receive(&m2, 5000);
        call Leds.led2Toggle();
      }
      else {
        call BlockingAMSend2.send(!TOS_NODE_ID, &m2, 0);
        call Leds.led2Toggle();
        //call RadioStressThread2.sleep(500);
      }
    }
  }
}
