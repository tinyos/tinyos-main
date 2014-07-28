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
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */

module MutexP {
  provides {
    interface Mutex;
  }
  uses {
    interface ThreadQueue;
    interface ThreadScheduler;
  }
}

implementation {
  command void Mutex.init(mutex_t* m) {
    m->lock = FALSE;
    call ThreadQueue.init(&(m->thread_queue));  
  }
  
  command error_t Mutex.lock(mutex_t* m) {
    atomic {
      thread_t* t = call ThreadScheduler.currentThreadInfo();
      if(m->lock == FALSE) {
        m->lock = TRUE;
        t->mutex_count++;
      }
      else {
        call ThreadQueue.enqueue(&(m->thread_queue), t);
        call ThreadScheduler.suspendCurrentThread();
      }
      return SUCCESS;
    }
  }
  
  command error_t Mutex.unlock(mutex_t* m) {
    atomic {
      if(m->lock == TRUE) {
        thread_t* t = call ThreadScheduler.currentThreadInfo();
        t->mutex_count--;
        if((t = call ThreadQueue.dequeue(&(m->thread_queue))) != NULL)
          call ThreadScheduler.wakeupThread(t->id);
        else m->lock = FALSE;
      }
      return SUCCESS;
    }    
  }
}
