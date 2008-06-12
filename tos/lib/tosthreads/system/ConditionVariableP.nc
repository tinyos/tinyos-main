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

module ConditionVariableP {
  provides {
    interface ConditionVariable;
  }
  uses {
    interface ThreadScheduler;
    interface ThreadQueue;
    interface Mutex;
    interface Leds;
  }
}

implementation {
  command void ConditionVariable.init(condvar_t* c) {
    //Initialize the thread queue associated with this condition variable.
    call ThreadQueue.init(&(c->thread_queue));  
  }
  command void ConditionVariable.wait(condvar_t* c, mutex_t* m) {
    atomic {
      //Push the thread that just called wait() onto the thread queue associated with 
      //  this condition variable
      call ThreadQueue.enqueue(&(c->thread_queue), call ThreadScheduler.currentThreadInfo());
      call Mutex.unlock(m);
      call ThreadScheduler.suspendCurrentThread();
      call Mutex.lock(m);
    }
  }
  command void ConditionVariable.signalNext(condvar_t* c) {
    atomic {
      thread_t* t;
      //Pop all threads currently blocking on this barrier from its thread queue
      if((t = call ThreadQueue.dequeue(&(c->thread_queue))) != NULL) {
        call ThreadScheduler.wakeupThread(t->id);
      }
    }
  }
  command void ConditionVariable.signalAll(condvar_t* c) {
    atomic {
      thread_t* t;
      //Pop all threads currently blocking on this barrier from its thread queue
      while((t = call ThreadQueue.dequeue(&(c->thread_queue))) != NULL) {
        call ThreadScheduler.wakeupThread(t->id);
      }
    }
  }
  command bool ConditionVariable.isBlocking(condvar_t* c) {
    atomic return !(call ThreadQueue.isEmpty(&(c->thread_queue)));
;
  }
}
