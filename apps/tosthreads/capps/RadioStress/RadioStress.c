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

typedef nx_struct RadioCountMsg {
  nx_uint16_t counter;
} RadioCountMsg;

enum {
  AM_RADIOCOUNTMSG = 6,
};

//Initialize variables associated with the RadioStress thread
tosthread_t timerHandle;
tosthread_t receiveHandle;
tosthread_t sendHandle;
void timer_thread(void* arg);
void receive_thread(void* arg);
void send_thread(void* arg);

//Initialize the message variable
message_t send_packet; 
message_t receive_packet;  
  
//Initalize counter variables
uint32_t txCounter = 0;
uint32_t ackCounter = 0;
uint32_t rxCounter = 0;
int16_t timerCounter = -1;
uint16_t errorCounter = 0;

void tosthread_main(void* arg) {
  led0On();
  while( amRadioStart() != SUCCESS );
  led1On();
  tosthread_create(&timerHandle, timer_thread, NULL, 200);
  tosthread_create(&receiveHandle, receive_thread, NULL, 200);
}

void sendPacket() {
  RadioCountMsg* rcm = (RadioCountMsg*)radioGetPayload(&send_packet, sizeof(RadioCountMsg));
  rcm->counter = txCounter;
  while( amRadioSend(AM_BROADCAST_ADDR, &send_packet, 2, AM_RADIOCOUNTMSG) != SUCCESS )
    errorCounter++; 
}

void timer_thread(void* arg) {
  tosthread_sleep(1000);
  tosthread_create(&sendHandle, send_thread, NULL, 200);
  for(;;) {
    led2Toggle();
    timerCounter++;
    tosthread_sleep(1000);
    sendPacket();
  }
}

void receive_thread(void* arg) {
  for(;;) {
    amRadioReceive(&receive_packet, 0, AM_RADIOCOUNTMSG);
    rxCounter++;
    if ((rxCounter % 32) == 0) {
      led0Toggle();
    }
  }
}

void send_thread(void* arg) {
  for(;;) {
    sendPacket();
    txCounter++;
    if (txCounter % 32 == 0) {
      led1Toggle();
    }
    if ( radioWasAcked(&send_packet) ) {
      ackCounter++;
      if (ackCounter % 32 == 0) {
	    led2Toggle();
      }
    }
  }
}
