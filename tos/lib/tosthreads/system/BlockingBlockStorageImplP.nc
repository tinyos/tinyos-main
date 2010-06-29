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

/**
 * @author Kevin Klues <klueska@cs.stanford.edu>
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */
 
module BlockingBlockStorageImplP {
  provides {
    interface Init;
    interface BlockingBlock[uint8_t volume_id];
  }
  uses {
    interface BlockRead[uint8_t volume_id];
    interface BlockWrite[uint8_t volume_id];
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
  
  typedef struct crc_params {
    storage_addr_t addr;
    storage_len_t* len;
    uint16_t       crc;
    uint16_t       *finalCrc;    
    error_t        error;
  } crc_params_t;
  
  typedef struct erase_sync_params {
    error_t error;
  } erase_sync_params_t;

  syscall_queue_t vol_queue;

  command error_t Init.init() {
    call SystemCallQueue.init(&vol_queue);
    return SUCCESS;
  }

  command storage_len_t BlockingBlock.getSize[uint8_t volume_id]() {
    return call BlockRead.getSize[volume_id]();
  }
  
  /**************************** Reading ********************************/
  void readTask(syscall_t* s) {
    read_write_params_t* p = s->params;
    p->error = call BlockRead.read[s->id](p->addr, p->buf, *(p->len));
    if(p->error != SUCCESS)
      call SystemCall.finish(s);
  }
  
  command error_t BlockingBlock.read[uint8_t volume_id](storage_addr_t addr, void *buf, storage_len_t* len) {
    syscall_t s;
    read_write_params_t p;
    atomic {
      if(call SystemCallQueue.find(&vol_queue, volume_id) != NULL)
        return EBUSY;
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

  event void BlockRead.readDone[uint8_t volume_id](storage_addr_t addr, void *buf, storage_len_t len, error_t error) {
    syscall_t* s = call SystemCallQueue.find(&vol_queue, volume_id);
    read_write_params_t* p = s->params;
    p->error = error;
    *(p->len) = len;
    call SystemCall.finish(s);
  }

  
  /**************************** Writing ********************************/
  void writeTask(syscall_t* s) {
    read_write_params_t* p = s->params;
    p->error = call BlockWrite.write[s->id](p->addr, p->buf, *(p->len));
    if(p->error != SUCCESS)
      call SystemCall.finish(s);
  }
  
  command error_t BlockingBlock.write[uint8_t volume_id](storage_addr_t addr, void* buf, storage_len_t* len) {
    syscall_t s;
    read_write_params_t p;
    atomic {
      if(call SystemCallQueue.find(&vol_queue, volume_id) != NULL)
        return EBUSY;
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
  
  event void BlockWrite.writeDone[uint8_t volume_id](storage_addr_t addr, void* buf, storage_len_t len, error_t error) {
    syscall_t* s = call SystemCallQueue.find(&vol_queue, volume_id);
    read_write_params_t* p = s->params;
    *(p->len) = len;
    p->error = error;
    call SystemCall.finish(s);
  }

  /**************************** Computing CRC ********************************/
  void crcTask(syscall_t* s) {
    crc_params_t* p = s->params;
    p->error = call BlockRead.computeCrc[s->id](p->addr, *(p->len), p->crc);
    if(p->error != SUCCESS)
      call SystemCall.finish(s);
  }
  
  command error_t BlockingBlock.computeCrc[uint8_t volume_id](storage_addr_t addr, storage_len_t* len, uint16_t crc, uint16_t *finalCrc) {
    syscall_t s;
    crc_params_t p;
    atomic {
      if(call SystemCallQueue.find(&vol_queue, volume_id) != NULL)
        return EBUSY;
      call SystemCallQueue.enqueue(&vol_queue, &s);
    }
    
    p.addr = addr;
    p.len = len;
    p.crc = crc;
    p.finalCrc = finalCrc;
    call SystemCall.start(&crcTask, &s, volume_id, &p);
    
    atomic {
      call SystemCallQueue.remove(&vol_queue, &s);
      return p.error;
    }
  }
  
  event void BlockRead.computeCrcDone[uint8_t volume_id](storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error) {
    syscall_t* s = call SystemCallQueue.find(&vol_queue, volume_id);
    crc_params_t* p = s->params;
    *(p->finalCrc) = crc;
    *(p->len) = len;
    p->error = error;
    call SystemCall.finish(s);
  }

  /**************************** Erasing ********************************/
  void eraseTask(syscall_t* s) {
    erase_sync_params_t* p = s->params;
    p->error = call BlockWrite.erase[s->id]();
    if(p->error != SUCCESS)
      call SystemCall.finish(s);
  }
  
  command error_t BlockingBlock.erase[uint8_t volume_id]() {
    syscall_t s;
    erase_sync_params_t p;
    atomic {
      if(call SystemCallQueue.find(&vol_queue, volume_id) != NULL)
        return EBUSY;
      call SystemCallQueue.enqueue(&vol_queue, &s);
    }
    
    call SystemCall.start(&eraseTask, &s, volume_id, &p);
    
    atomic {
      call SystemCallQueue.remove(&vol_queue, &s);
      return p.error;
    }
  }

  event void BlockWrite.eraseDone[uint8_t volume_id](error_t error) {
    syscall_t* s = call SystemCallQueue.find(&vol_queue, volume_id);
    erase_sync_params_t* p = s->params;
    p->error = error;
    call SystemCall.finish(s);
  }

  /**************************** Syncing ********************************/
  void syncTask(syscall_t* s) {
    erase_sync_params_t* p = s->params;
    p->error = call BlockWrite.sync[s->id]();
    if(p->error != SUCCESS)
      call SystemCall.finish(s);
  }
  
  command error_t BlockingBlock.sync[uint8_t volume_id]() {
    syscall_t s;
    erase_sync_params_t p;
    atomic {
      if(call SystemCallQueue.find(&vol_queue, volume_id) != NULL)
        return EBUSY;
      call SystemCallQueue.enqueue(&vol_queue, &s);
    }
    
    call SystemCall.start(&syncTask, &s, volume_id, &p);
    
    atomic {
      call SystemCallQueue.remove(&vol_queue, &s);
      return p.error;
    }
  }
  
  event void BlockWrite.syncDone[uint8_t volume_id](error_t error) {
    syscall_t* s = call SystemCallQueue.find(&vol_queue, volume_id);
    erase_sync_params_t* p = s->params;
    p->error = error;
    call SystemCall.finish(s);
  }
  
  default command error_t BlockRead.read[uint8_t volume_id](storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  default command error_t BlockRead.computeCrc[uint8_t volume_id](storage_addr_t addr, storage_len_t len, uint16_t crc) { return FAIL; }
  default command storage_len_t BlockRead.getSize[uint8_t volume_id]() { return 0; }
  default command error_t BlockWrite.write[uint8_t volume_id](storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  default command error_t BlockWrite.erase[uint8_t volume_id]() { return FAIL; }
  default command error_t BlockWrite.sync[uint8_t volume_id]() { return FAIL; }
}
