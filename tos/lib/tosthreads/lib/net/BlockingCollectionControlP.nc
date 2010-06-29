/*
 * Copyright (c) 2008 Johns Hopkins University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/*
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

module BlockingCollectionControlP {
  provides {
    interface BlockingStdControl;
    interface Init;
  }
  
  uses {
    interface StdControl as RoutingControl;
    interface SystemCall;
    interface Mutex;
  }
}

implementation {
  typedef struct params {
    error_t error;
  } params_t;

  syscall_t* start_call = NULL;
  mutex_t my_mutex;
  
  command error_t Init.init()
  {
    call Mutex.init(&my_mutex);
    return SUCCESS;
  }
  
  void startTask(syscall_t* s)
  {
    params_t* p = s->params;
    p->error = call RoutingControl.start();
    call SystemCall.finish(s);
  }

  command error_t BlockingStdControl.start()
  {
    syscall_t s;
    params_t p;
    
    call Mutex.lock(&my_mutex);
      if (start_call == NULL) {
        start_call = &s;
        call SystemCall.start(&startTask, &s, INVALID_ID, &p);
        start_call = NULL;
      } else {
        p.error = EBUSY;
      }
        
    atomic {
      call Mutex.unlock(&my_mutex);
      return p.error;
    }
  }
  
  command error_t BlockingStdControl.stop() {
    return call RoutingControl.stop();
  }
}
