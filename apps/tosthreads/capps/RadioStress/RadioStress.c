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
 * This application stresses the blocking send and receive commands for the c based 
 * API of tosthreads.  Three threads are run, each thread toggling a different 
 * colored LED. If a node has TOS_NODE_ID == 0 it will try and receive in 
 * an infinite loop, toggling one of the three Leds upon reception.  If it has 
 * TOS_NODE_ID == 1, it will try to send in an infinite loop, toggling one of the three
 * Leds upon the completion of a send.  Thread 0 toggles the Led0, Thread 1 toggles 
 * Led1, and Thread 2 toggles Led2.
 *
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */

//#include "stack.h"
#include "tosthread.h"
#include "tosthread_amradio.h"
#include "tosthread_leds.h"

//Initialize variables associated with each thread
tosthread_t radioStress0;
tosthread_t radioStress1;
tosthread_t radioStress2;

void radioStress0_thread(void* arg);
void radioStress1_thread(void* arg);
void radioStress2_thread(void* arg);

//Initialize messages for sending out over the radio
message_t msg0;
message_t msg1;
message_t msg2;

void tosthread_main(void* arg) {
  while( amRadioStart() != SUCCESS );
  tosthread_create(&radioStress0, radioStress0_thread, &msg0, 200);
  tosthread_create(&radioStress1, radioStress1_thread, &msg1, 200);
  tosthread_create(&radioStress2, radioStress2_thread, &msg2, 200);
}

void radioStress0_thread(void* arg) {
  message_t* m = (message_t*)arg;
  for(;;) {
    if(TOS_NODE_ID == 0) {
      amRadioReceive(m, 2000, 20);
      led0Toggle();
    }
    else {
      if(amRadioSend(!TOS_NODE_ID, m, 0, 20) == SUCCESS)
        led0Toggle(); 
    }
  }
}

void radioStress1_thread(void* arg) {
  message_t* m = (message_t*)arg;
  for(;;) {
    if(TOS_NODE_ID == 0) {
      amRadioReceive(m, 2000, 21);
      led1Toggle();
    }
    else {
      if(amRadioSend(!TOS_NODE_ID, m, 0, 21) == SUCCESS)
        led1Toggle();
    }
  }
}

void radioStress2_thread(void* arg) {
  message_t* m = (message_t*)arg;
  for(;;) {
    if(TOS_NODE_ID == 0) {
      amRadioReceive(m, 2000, 22);
      led2Toggle();
    }
    else {
      if(amRadioSend(!TOS_NODE_ID, m, 0, 22) == SUCCESS)
        led2Toggle();
    }
  }
}
