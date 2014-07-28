/*
 * Copyright (c) 2009 Johns Hopkins University.
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

/**
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */
 
module BlockingConfigStorageImplP {
  provides {
    interface Init;
    interface BlockingConfig[uint8_t volume_id];
    interface BlockingMount[uint8_t volume_id];
  }
  
  uses {
    interface ConfigStorage[uint8_t volume_id];
    interface Mount as ConfigMount[uint8_t volume_id];
    interface SystemCall;
    interface SystemCallQueue;
  }
}

implementation {
  typedef struct read_write_params {
    storage_addr_t addr;
    void*          buf;
    storage_len_t* len;
    error_t        error;
  } read_write_params_t;
    
  typedef struct commit_mount_params {
    error_t error;
  } commit_mount_params_t;

  syscall_queue_t vol_queue;

  command error_t Init.init()
  {
    call SystemCallQueue.init(&vol_queue);
    return SUCCESS;
  }

  command storage_len_t BlockingConfig.getSize[uint8_t volume_id]() {
    return call ConfigStorage.getSize[volume_id]();
  }
  
  command bool BlockingConfig.valid[uint8_t volume_id]() {
    return call ConfigStorage.valid[volume_id]();
  }
  
  /**************************** Reading ********************************/
  void readTask(syscall_t* s)
  {
    read_write_params_t* p = s->params;
    p->error = call ConfigStorage.read[s->id](p->addr, p->buf, *(p->len));
    if(p->error != SUCCESS) {
      call SystemCall.finish(s);
    }
  }
  
  command error_t BlockingConfig.read[uint8_t volume_id](storage_addr_t addr, void *buf, storage_len_t* len)
  {
    syscall_t s;
    read_write_params_t p;
    atomic {
      if(call SystemCallQueue.find(&vol_queue, volume_id) != NULL) {
        return EBUSY;
      }
      call SystemCallQueue.enqueue(&vol_queue, &s);
    }
    
    p.addr = addr;
    p.buf = buf;
    p.len = len;
    call SystemCall.start(&readTask, &s, volume_id, &p);
    
    atomic {
      call SystemCallQueue.remove(&vol_queue, &s);
      return p.error;
    }
  }

  event void ConfigStorage.readDone[uint8_t volume_id](storage_addr_t addr, void *buf, storage_len_t len, error_t error)
  {
    syscall_t* s = call SystemCallQueue.find(&vol_queue, volume_id);
    read_write_params_t* p = s->params;
    p->error = error;
    *(p->len) = len;
    call SystemCall.finish(s);
  }

  
  /**************************** Writing ********************************/
  void writeTask(syscall_t* s)
  {
    read_write_params_t* p = s->params;
    p->error = call ConfigStorage.write[s->id](p->addr, p->buf, *(p->len));
    if(p->error != SUCCESS) {
      call SystemCall.finish(s);
    }
  }
  
  command error_t BlockingConfig.write[uint8_t volume_id](storage_addr_t addr, void* buf, storage_len_t* len)
  {
    syscall_t s;
    read_write_params_t p;
    atomic {
      if(call SystemCallQueue.find(&vol_queue, volume_id) != NULL) {
        return EBUSY;
      }
      call SystemCallQueue.enqueue(&vol_queue, &s);
    }
    
    p.addr = addr;
    p.buf = buf;
    p.len = len;
    call SystemCall.start(&writeTask, &s, volume_id, &p);

    atomic {
      call SystemCallQueue.remove(&vol_queue, &s);
      return p.error;
    }
  }
  
  event void ConfigStorage.writeDone[uint8_t volume_id](storage_addr_t addr, void* buf, storage_len_t len, error_t error)
  {
    syscall_t* s = call SystemCallQueue.find(&vol_queue, volume_id);
    read_write_params_t* p = s->params;
    *(p->len) = len;
    p->error = error;
    call SystemCall.finish(s);
  }

  /**************************** Committing ********************************/
  void commitTask(syscall_t* s)
  {
    commit_mount_params_t* p = s->params;
    p->error = call ConfigStorage.commit[s->id]();
    if(p->error != SUCCESS) {
      call SystemCall.finish(s);
    }
  }
  
  command error_t BlockingConfig.commit[uint8_t volume_id]()
  {
    syscall_t s;
    commit_mount_params_t p;
    atomic {
      if(call SystemCallQueue.find(&vol_queue, volume_id) != NULL) {
        return EBUSY;
      }
      call SystemCallQueue.enqueue(&vol_queue, &s);
    }
    
    call SystemCall.start(&commitTask, &s, volume_id, &p);
    
    atomic {
      call SystemCallQueue.remove(&vol_queue, &s);
      return p.error;
    }
  }

  event void ConfigStorage.commitDone[uint8_t volume_id](error_t error)
  {
    syscall_t* s = call SystemCallQueue.find(&vol_queue, volume_id);
    commit_mount_params_t* p = s->params;
    p->error = error;
    call SystemCall.finish(s);
  }
  
  /**************************** Mounting ********************************/
  void mountTask(syscall_t* s)
  {
    commit_mount_params_t* p = s->params;
    p->error = call ConfigMount.mount[s->id]();
    if(p->error != SUCCESS) {
      call SystemCall.finish(s);
    }
  }
  
  command error_t BlockingMount.mount[uint8_t volume_id]()
  {
    syscall_t s;
    commit_mount_params_t p;
    atomic {
      if(call SystemCallQueue.find(&vol_queue, volume_id) != NULL) {
        return EBUSY;
      }
      call SystemCallQueue.enqueue(&vol_queue, &s);
    }
    
    call SystemCall.start(&mountTask, &s, volume_id, &p);
    
    atomic {
      call SystemCallQueue.remove(&vol_queue, &s);
      return p.error;
    }
  }

  event void ConfigMount.mountDone[uint8_t volume_id](error_t error)
  {
    syscall_t* s = call SystemCallQueue.find(&vol_queue, volume_id);
    commit_mount_params_t* p = s->params;
    p->error = error;
    call SystemCall.finish(s);
  }  
  
  default command error_t ConfigStorage.read[uint8_t volume_id](storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  default command error_t ConfigStorage.write[uint8_t volume_id](storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  default command error_t ConfigStorage.commit[uint8_t volume_id]() { return FAIL; }
  default command storage_len_t ConfigStorage.getSize[uint8_t volume_id]() { return 0; }
  default command bool ConfigStorage.valid[uint8_t volume_id]() { return FALSE; }
  default command error_t ConfigMount.mount[uint8_t volume_id]() { return FAIL; }
}
