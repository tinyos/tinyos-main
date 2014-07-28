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
 * TestJoin is a simple application used to test the basic functionality of
 * the join() system call for waiting on a set of threads in a TOSThreads 
 * based application.
 * 
 * Upon a successful burn, you should see all LEDs toggle in the following pattern,
 * repeating every 8 seconds:
 * 
 * 0s: (110) LED0  ON, LED1  ON, LED2 OFF  <br>
 * 1s: (000) LED0 OFF, LED1 OFF, LED2 OFF  <br>
 * 2s: (010) LED0 OFF, LED1  ON, LED2 OFF  <br>
 * 3s: (000) LED0 OFF, LED1 OFF, LED2 OFF  <br>
 * 4s: (111) LED0  ON, LED1  ON, LED2  ON  <br>
 * 5s: (001) LED0 OFF, LED1 OFF, LED2  ON  <br>
 * 6s: (011) LED0 OFF, LED1  ON, LED2  ON  <br>
 * 7s: (001) LED0 OFF, LED1 OFF, LED2  ON  <br>
 *
 * @author Kevin Klues (klueska@cs.stanford.edu)
 */

#include "stack.h"
#include "tosthread.h"
#include "tosthread_leds.h"

//Initialize variables associated with each thread
tosthread_t init;
tosthread_t blink0;
tosthread_t blink1;

void init_thread(void* arg);
void blink0_thread(void* arg);
void blink1_thread(void* arg);

void tosthread_main(void* arg) {
  //Use stack estimator to calculate maximum stack size
  //  on a thread by thread basis
  tosthread_create(&init, init_thread, NULL, INIT_STACK_SIZE);
}

void init_thread(void* arg) {
  for(;;) {
    tosthread_create(&blink0, blink0_thread, NULL, BLINK0_STACK_SIZE);
    tosthread_create(&blink1, blink1_thread, NULL, BLINK1_STACK_SIZE);
    tosthread_join(&blink0);
    tosthread_join(&blink1);
    led2Toggle();
  }
}

void blink0_thread(void* arg) {
  int i;
  for(i=0; i<2; i++) {
    led0Toggle();
    tosthread_sleep(1000);
  }
}

void blink1_thread(void* arg) {
  int i;
  for(i=0; i<4; i++) {
    led1Toggle();
    tosthread_sleep(1000);
  }
}

