/*
 * Copyright (c) 2008 Johns Hopkins University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the (updated) modification history and the author appear in
 * all copies of this source code.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
 * OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
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
