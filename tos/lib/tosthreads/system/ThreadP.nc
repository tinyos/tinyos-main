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

configuration ThreadP {
  provides {
    interface Thread as StaticThread[uint8_t id];
    interface DynamicThread;
    interface ThreadNotification as StaticThreadNotification[uint8_t id];
    interface ThreadNotification as DynamicThreadNotification[uint8_t id];
    interface ThreadCleanup as StaticThreadCleanup[uint8_t id];
  }
  uses {
    interface ThreadInfo as StaticThreadInfo[uint8_t id];
    interface ThreadFunction as StaticThreadFunction[uint8_t id];
  }
}
implementation {
  components StaticThreadP;
  components DynamicThreadP;
  components TinyThreadSchedulerC;
  components ThreadTimersC;
  components ThreadInfoMapP;
  components BitArrayUtilsC;
  components ThreadSleepC;
  components TosMallocC;
  
  StaticThread = StaticThreadP;
  StaticThreadNotification = StaticThreadP;
  StaticThreadP.ThreadInfo = StaticThreadInfo;
  StaticThreadP.ThreadFunction = StaticThreadFunction;
  StaticThreadP.ThreadSleep -> ThreadSleepC;
  StaticThreadP.ThreadScheduler -> TinyThreadSchedulerC;
  
  DynamicThread = DynamicThreadP;
  DynamicThreadP.ThreadNotification = DynamicThreadNotification;
  DynamicThreadP.ThreadSleep -> ThreadSleepC;
  DynamicThreadP.ThreadScheduler -> TinyThreadSchedulerC;
  DynamicThreadP.BitArrayUtils -> BitArrayUtilsC;
  DynamicThreadP.Malloc -> TosMallocC;
  
  TinyThreadSchedulerC.ThreadInfo -> ThreadInfoMapP;
  ThreadInfoMapP.StaticThreadInfo = StaticThreadInfo;
  ThreadInfoMapP.DynamicThreadInfo -> DynamicThreadP;

  ThreadInfoMapP.ThreadCleanup -> TinyThreadSchedulerC;
  DynamicThreadP.ThreadCleanup -> ThreadInfoMapP.DynamicThreadCleanup;
  StaticThreadCleanup = ThreadInfoMapP.StaticThreadCleanup;
  
  components LedsC;
  StaticThreadP.Leds -> LedsC;
  DynamicThreadP.Leds -> LedsC;
  ThreadInfoMapP.Leds -> LedsC;
}

