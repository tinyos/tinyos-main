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
 * This is the barrier implementation.  Every barrier has a pointer to 
 * a linked list of threads.  When a thread calls block() on a barrier 
 * it is pushed onto the thread queue associated with that barrier and
 * it is blocked.  Once some thread calls unblock() on a particular 
 * barrier, all threads on that barrier's thread queue are popped off 
 * and woken up. 
 *
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */

module BarrierP {
  provides {
    interface Barrier;
  }
  uses {
    interface ThreadScheduler;
    interface ThreadQueue;
    interface Leds;
  }
}

implementation {
  command void Barrier.reset(barrier_t* b, uint8_t count) {
    atomic {
      b->count = count;
      //Initialize the thread queue associated with this barrier.
      call ThreadQueue.init(&(b->thread_queue));  
    }
  }
  command void Barrier.block(barrier_t* b) {
    atomic {
      if(b->count > 1) {
        //Push the thread that just called block() onto the thread queue associated with this barrier
        call ThreadQueue.enqueue(&(b->thread_queue), call ThreadScheduler.currentThreadInfo());
        b->count--;
        call ThreadScheduler.suspendCurrentThread();
      }
      else {
        thread_t* t;
        while((t = call ThreadQueue.dequeue(&(b->thread_queue))) != NULL)
          call ThreadScheduler.wakeupThread(t->id);
      }
    }
  }
  command bool Barrier.isBlocking(barrier_t* b) {
    atomic return !(call ThreadQueue.isEmpty(&(b->thread_queue)));
  }
}
