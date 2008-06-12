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
 * Interface for using Conddition Variables for synchronization 
 * with tosthreads.
 *
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */

#include "condvar.h"

interface ConditionVariable {
  /**
   * Reset a condition variable for use.
   * @param c The condition variable you would like to reset.
   */
  command void init(condvar_t* c);
  /**
   * Wait on a condition variable until one of the signal
   * calls unbocks me.  In the process, unlock the mutex 
   * passed in to me.
   * @param c The condition variable you would like to wait on.
   * @param m The mutex you would like to unlock
   */
  command void wait(condvar_t* c, mutex_t* m);
  /**
   * Signal the next thread waiting on this condition variable 
   * to continue execution.  To unblock all threads waiting on 
   * this condition vairable use signalAll().
   * @param c The condition variable associated with the thread 
   *          you would like to signal.
   */
  command void signalNext(condvar_t* c);
  /**
   * Signal all threads waiting on this condition variable 
   * to continue execution.  To unblock just the next thread
   * waiting on this condition vairable use signalNext().
   * @param c The condition variable associated with the thread 
   *          you would like to signal.
   */
  command void signalAll(condvar_t* c);
  /**
   * Query whether a condition variable is currently blocking 
   * any threads from executing.
   * @param c The cndition variable you would like to query.
   * @return  TRUE or FALSE
   */
  command bool isBlocking(condvar_t* c);
}  
