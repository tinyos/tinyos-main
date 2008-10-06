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

module CThreadSynchronizationP {
  uses {
    interface Mutex;
    interface Semaphore;
    interface Barrier;
    interface ConditionVariable;
    interface ReferenceCounter;
  }
}
implementation {
  /******************** Mutex ***************************/
  void mutex_init(mutex_t* m) @C() AT_SPONTANEOUS {
    call Mutex.init(m);
  }
  error_t mutex_lock(mutex_t* m) @C() AT_SPONTANEOUS {
    return call Mutex.lock(m);
  }
  error_t mutex_unlock(mutex_t* m) @C() AT_SPONTANEOUS {
    return call Mutex.unlock(m);
  }
  
  /******************** Semaphore ***************************/
  void semaphore_reset(semaphore_t* s, uint8_t v) @C() AT_SPONTANEOUS {
    call Semaphore.reset(s, v);
  }
  error_t semaphore_acquire(semaphore_t* s) @C() AT_SPONTANEOUS {
    return call Semaphore.acquire(s);
  }
  error_t semaphore_release(semaphore_t* s) @C() AT_SPONTANEOUS {
    return call Semaphore.release(s);
  }
  
  /******************** Barrier ***************************/
  void barrier_reset(barrier_t* b, uint8_t count) @C() AT_SPONTANEOUS {
    call Barrier.reset(b, count);
  }
  void barrier_block(barrier_t* b) @C() AT_SPONTANEOUS {
    call Barrier.block(b);
  }
  bool barrier_isBlocking(barrier_t* b) @C() AT_SPONTANEOUS {
    return call Barrier.isBlocking(b);
  }
  void condvar_init(condvar_t* c) @C() AT_SPONTANEOUS {
    call ConditionVariable.init(c);
  }
  
  /******************** Condition Variable ***************************/
  void condvar_wait(condvar_t* c, mutex_t* m) @C() AT_SPONTANEOUS {
    call ConditionVariable.wait(c, m);
  }
  void condvar_signalNext(condvar_t* c) @C() AT_SPONTANEOUS {
    call ConditionVariable.signalNext(c);
  }
  void condvar_signalAll(condvar_t* c) @C() AT_SPONTANEOUS {
    call ConditionVariable.signalAll(c);
  }
  bool condvar_isBlocking(condvar_t* c) @C() AT_SPONTANEOUS {
    return call ConditionVariable.isBlocking(c);
  }
  
  /******************** Reference Counter ***************************/
  void refcounter_init(refcounter_t* r) @C() AT_SPONTANEOUS {
    call ReferenceCounter.init(r);
  }
  void refcounter_increment(refcounter_t* r) @C() AT_SPONTANEOUS {
    call ReferenceCounter.increment(r);
  }
  void refcounter_decrement(refcounter_t* r) @C() AT_SPONTANEOUS {
    call ReferenceCounter.decrement(r);
  }
  void refcounter_waitOnValue(refcounter_t* r, uint8_t count) @C() AT_SPONTANEOUS {
    call ReferenceCounter.waitOnValue(r, count);
  }
  uint8_t refcounter_count(refcounter_t* r) @C() AT_SPONTANEOUS {
    return call ReferenceCounter.count(r);
  }
}
