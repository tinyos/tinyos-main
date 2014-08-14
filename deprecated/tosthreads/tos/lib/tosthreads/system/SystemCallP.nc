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
 
module SystemCallP {
  provides {
    interface SystemCall;
  }
  uses {
    interface ThreadScheduler;
  }
}
implementation {

  syscall_t* current_call = NULL;
  
  task void threadTask() {
    (*(current_call->syscall_ptr))(current_call);
  }
  
  //Had originally planned on using a thread queue here to
  //  hold and keep track of multiple system call requests 
  //Observation though is that only one outstanding system 
  //  call can exist in the system at any given time
  //Some thread calls this function, and the task gets posted,
  //  the TOS kernel thread gets woken up, and the task is run
  //  immediately before any other threads get the chance to
  //  make any system calls. 
  //If semantics change in the future, a thread queue could
  //  be used here with a single TinyOS task servicing all them
  //  by popping threads off the queue and reposting itself
  command error_t SystemCall.start(void* syscall_ptr, syscall_t* s, syscall_id_t id, void* p) {
    atomic {

      current_call = s; 
      current_call->id = id;
      current_call->thread = call ThreadScheduler.currentThreadInfo();
      current_call->thread->syscall = s;
      current_call->params = p;
      
      if(syscall_ptr != SYSCALL_WAIT_ON_EVENT) {
        current_call->syscall_ptr = syscall_ptr;
        post threadTask();
        call ThreadScheduler.wakeupThread(TOSTHREAD_TOS_THREAD_ID);
      }
      
      return call ThreadScheduler.suspendCurrentThread();
    }
  }
 
  command error_t SystemCall.finish( syscall_t* s ) {
    return call ThreadScheduler.wakeupThread(s->thread->id);
  }
}
