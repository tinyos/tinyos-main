/*
* Copyright (c) 2010, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Krisztian Veress
*         veresskrisztian@gmail.com
*/

#define ATOMIC_PERIODIC_TIME 4096

#define _MAX_(a,b) (((a) < (b)) ? (b) : (a))
#define _MIN_(a,b) (((a) > (b)) ? (b) : (a))

module CodeProfileP @safe() {
  provides {
    interface StdControl;
    interface CodeProfile;
  }
  uses {
    interface Alarm<TMicro, uint32_t> as Alarm;
  }
}

implementation {

  int32_t        max_mil;           // Maximum Interrupt Length
  int32_t        max_mal;           // Maximum Atomic Length
  int32_t        max_mtl;           // Maximum Task Latency
  
  int32_t        min_mil;           // Mininum Interrupt Length
  int32_t        min_mal;           // Mininum Atomic Length
  int32_t        min_mtl;           // Mininum Task Latency
  
  uint32_t       mtl_offset;
  uint32_t       mal_offset;
  norace bool    alive;

  command int32_t CodeProfile.getMaxInterruptLength()  { return max_mil; }
  command int32_t CodeProfile.getMaxAtomicLength()     { atomic {return max_mal;} }
  command int32_t CodeProfile.getMaxTaskLatency()      { return max_mtl; }

  command int32_t CodeProfile.getMinInterruptLength()  { return min_mil; }
  command int32_t CodeProfile.getMinAtomicLength()     { atomic {return min_mal;} }
  command int32_t CodeProfile.getMinTaskLatency()      { return min_mtl; }

  task void measureTask() {
    
    uint32_t t1 = call Alarm.getNow();
    uint32_t t2 = call Alarm.getNow();
    
    // The difference between two consecutive getNow() call can be
    // significantly greater than zero, if interrupt(s) occured in between. That
    // difference is proportional to the running time of the 
    // interrupt handler.
    max_mil = _MAX_((int32_t)(t2-t1),max_mil);
    min_mil = _MIN_((int32_t)(t2-t1),min_mil);
    
    // The difference between the posting time of this task (mtl_offset)
    // and the first expression's execution time ( t1 ) is the time
    // between two measureTask tasks.
    // This way, interleaving tasks' running time is measured.    
    max_mtl = _MAX_((int32_t)(t1-mtl_offset),max_mtl);
    min_mtl = _MIN_((int32_t)(t1-mtl_offset),min_mtl);

    if ( alive ) {
      mtl_offset = call Alarm.getNow();
      post measureTask();
    }
    
  }


  command error_t StdControl.start() {
    
    alive = TRUE;
    min_mil = min_mtl = 0x7fffffffL;
    max_mil = max_mtl = -(0x7fffffffL-1L);
    
    // Atomic Length Measurement Init
    atomic {
      max_mal = -(0x7fffffffL-1L);
      min_mal = 0x7fffffffL;
      call Alarm.stop();
      mal_offset = call Alarm.getNow();
      call Alarm.startAt(mal_offset, ATOMIC_PERIODIC_TIME);
    }
    
    mtl_offset = call Alarm.getNow();
    post measureTask();
    
    return SUCCESS;
  }
  
  command error_t StdControl.stop() {
    call Alarm.stop();
    alive = FALSE;
    return SUCCESS;
  }
  
  async event void Alarm.fired() {    
    // Get the time
    int64_t delay = (int64_t)call Alarm.getNow();
  
    atomic {
      // When the alarm should have been fired?
      // This is also the base of the next fire target.
      mal_offset += ATOMIC_PERIODIC_TIME;
      
      // Compute the shift between now and the target
      delay -= mal_offset;
    
      max_mal = _MAX_((int32_t)delay,max_mal);
      min_mal = _MIN_((int32_t)delay,min_mal);
    }    
      
    if ( alive )
      call Alarm.startAt(mal_offset,ATOMIC_PERIODIC_TIME);
  }
   
}

