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
 * @author Kevin Klues (klueska@cs.stanford.edu)
 */

#include "tosthread.h"
#include "tosthread_leds.h"

//Initialize variables associated with each thread
tosthread_t thread_handler;
void blink0_thread(void* arg);
void blink1_thread(void* arg);
void blink2_thread(void* arg);

void tosthread_main(void* arg) {
  while(1) {
    tosthread_create(&thread_handler, blink0_thread, NULL, 100);
    tosthread_create(&thread_handler, blink1_thread, NULL, 100);
    tosthread_create(&thread_handler, blink2_thread, NULL, 100);
  }
}

uint8_t blink0_count = 0;
void blink0_thread(void* arg) {
  if(blink0_count++ == 0)
    led0Toggle();
  tosthread_create(&thread_handler, blink1_thread, NULL, 100);
  tosthread_create(&thread_handler, blink2_thread, NULL, 100);
  tosthread_create(&thread_handler, blink0_thread, NULL, 100);
}

uint8_t blink1_count = 0;
void blink1_thread(void* arg) {
  if(blink1_count++ == 85)
    led1Toggle();
  tosthread_create(&thread_handler, blink2_thread, NULL, 100);
  tosthread_create(&thread_handler, blink0_thread, NULL, 100);
  tosthread_create(&thread_handler, blink1_thread, NULL, 100);
}

uint8_t blink2_count = 0;
void blink2_thread(void* arg) {
  if(blink2_count++ == 170)
    led2Toggle();
  tosthread_create(&thread_handler, blink0_thread, NULL, 100);
  tosthread_create(&thread_handler, blink1_thread, NULL, 100);
  tosthread_create(&thread_handler, blink2_thread, NULL, 100);
}
