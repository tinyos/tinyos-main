/*
 * Copyright (c) 2008 Johns Hopkins University.
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
 * - Neither the name of the copyright holders nor the names of
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
*/

/**
 * This application is derived from a similar application in the TinyThread 
 * implementation by William P. McCartney from Cleveland State University (2006)
 * 
 * This application stresses the operation of the thread based AM commands for
 * packet transmission and reception.  To run this application you will need to
 * burn it on one mote with NODE_ID 0, and a second mote with NODE_ID 1. 
 * 
 * Three different threads run that each contain an infinite loop that first sends
 * a message and then waits to receive a message before returning to the top of the
 * loop. After each message reception, one of the onboard LEDs is toggled to
 * indicate that it was received. Thread 0 blinks LED0, thread 1 blinks LED1, and
 * thread 2 blinks LED2. The three threads run independently, and three different
 * messages are bounced back and forth between the two motes in an unsynchronized
 * fashion.  In contrast to the more complicated Bounce application found in the
 * normal nesC threads version of this application, once a thread receives a
 * message it will immediately flip on its LED instead of waiting on a Barrier and
 * synchronizing the LEDs to come on only once messages have been received from all
 * threads.  In this way, messages are bounced back and forth between the two motes
 * in an asynchronous fashion, and LEDS are toggled immediately upon message
 * reception..  
 * 
 * Successful running of this application results in each LED bouncing back and
 * forth between each mote independent of one another.  This will continue in an
 * finite loop forever.
 *  
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

#include "tosthread.h"
#include "tosthread_leds.h"
#include "tosthread_amradio.h"

//Initialize variables associated with each thread
tosthread_t bounceThread0;
tosthread_t bounceThread1;
tosthread_t bounceThread2;

void bounceThread0_start(void* arg);
void bounceThread1_start(void* arg);
void bounceThread2_start(void* arg);

void tosthread_main(void* arg) {
  amRadioStart();
  
  tosthread_create(&bounceThread0, bounceThread0_start, NULL, 300);
  tosthread_create(&bounceThread1, bounceThread1_start, NULL, 300);
  tosthread_create(&bounceThread2, bounceThread2_start, NULL, 300);
}

void bounceThread0_start(void *arg) {
  message_t msg0;
  
  for(;;) {
    while (amRadioSend(AM_BROADCAST_ADDR, &msg0, 0, 20) == EBUSY) {}
    led0Off();
    
    if(amRadioReceive(&msg0, 5000, 20) == SUCCESS) {
      led0On();
    }
    
    tosthread_sleep(500);
  }
}

void bounceThread1_start(void *arg) {
  message_t msg1;
  
  for(;;) {
    while (amRadioSend(AM_BROADCAST_ADDR, &msg1, 0, 21) == EBUSY) {}
    led1Off();
    
    if(amRadioReceive(&msg1, 5000, 21) == SUCCESS) {
      led1On();
    }
    
    tosthread_sleep(500);
  }
}

void bounceThread2_start(void *arg) {
  message_t msg2;
  
  for(;;) {
    while (amRadioSend(AM_BROADCAST_ADDR, &msg2, 0, 22) == EBUSY) {}
    led2Off();
    
    if(amRadioReceive(&msg2, 5000, 22) == SUCCESS) {
      led2On();
    }
    
    tosthread_sleep(500);
  }
}
