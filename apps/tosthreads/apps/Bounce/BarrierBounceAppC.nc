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
 * This application is derived from a similar application in the TinyThread 
 * implementation by William P. McCartney from Cleveland State University (2006)
 *
 * This application implements a threaded approach to bouncing messages back and forth
 * between two motes.  To run it you will need to burn one mote with node ID 0, and a 
 * second mote with node ID 1.  Three different threads run that each send a 
 * message and then wait to receive a message before sending their next one.  After
 * each message reception, an LED is toggled to indicate that it was received.  Thread
 * 0 blinks led0, thread 1 blinks led1, and thread 2 blinks led2.  The three 
 * threads run independently, and three different messages are bounced back and 
 * forth between the two motes in an unsynchronized fashion.  In contrast to the simple
 * Bounce application also found in this directory, once a thread receives a message
 * it waits on a Barrier before continuing on and turning on its led.  A synchronization 
 * thread is used to wait until all three messages have been received before unblocking
 * the barrier.  In this way, messages are still bounced back and forth between the 
 * two motes in an asynchronous fashion, but all leds come on at the same time 
 * because of the Barrier and the synchronization thread.  The effect is that all three
 * leds on one mote flash in unison, followed by all three on the other mote back
 * and forth forever.  
 *
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */

#include "barrier_bounce.h"
#include "stack.h"

configuration BarrierBounceAppC {
}
implementation {
  components MainC, BarrierBounceC as BounceC,  LedsC;
  components BlockingActiveMessageC;
  MainC.Boot <- BounceC;
  BounceC.BlockingAMControl -> BlockingActiveMessageC;
  BounceC.Leds -> LedsC;
  
  // Included to allow the use of barriers in our application
  components ThreadSynchronizationC;
  BounceC.Barrier -> ThreadSynchronizationC;
  
  // Thread and Bounce Message handlers for thread 0
  components new ThreadC(BOUNCE_THREAD0_STACK_SIZE) as BounceThread0;
  components new BlockingAMSenderC(AM_BOUNCE0_MSG) as BlockingAMSender0;
  components new BlockingAMReceiverC(AM_BOUNCE0_MSG) as BlockingAMReceiver0;
  BounceC.BounceThread0 -> BounceThread0;
  BounceC.BlockingAMSend0 -> BlockingAMSender0;
  BounceC.BlockingReceive0 -> BlockingAMReceiver0;
  
  // Thread and Bounce Message handlers for thread 1
  components new ThreadC(BOUNCE_THREAD1_STACK_SIZE) as BounceThread1;
  components new BlockingAMSenderC(AM_BOUNCE1_MSG) as BlockingAMSender1;
  components new BlockingAMReceiverC(AM_BOUNCE1_MSG) as BlockingAMReceiver1;
  BounceC.BounceThread1 -> BounceThread1;
  BounceC.BlockingAMSend1 -> BlockingAMSender1;
  BounceC.BlockingReceive1 -> BlockingAMReceiver1;
  
  // Thread and Bounce Message handlers for thread 2
  components new ThreadC(BOUNCE_THREAD2_STACK_SIZE) as BounceThread2;
  components new BlockingAMSenderC(AM_BOUNCE2_MSG) as BlockingAMSender2;
  components new BlockingAMReceiverC(AM_BOUNCE2_MSG) as BlockingAMReceiver2;
  BounceC.BounceThread2 -> BounceThread2;
  BounceC.BlockingAMSend2 -> BlockingAMSender2;
  BounceC.BlockingReceive2 -> BlockingAMReceiver2;
  
  // Synchronization thread to keep all threads in sync so that
  // none of them are able to continue execution until all of them
  // have both sent and received a message
  components new ThreadC(SYNC_THREAD_STACK_SIZE) as SyncThread;
  BounceC.SyncThread -> SyncThread;
}

