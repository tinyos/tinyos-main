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

/**
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

module BlockingLogStorageImplP {
  provides {
    interface Init;
    interface BlockingLog[uint8_t volume_id];
  }
  
  uses {
    interface LogRead[uint8_t volume_id];
    interface LogWrite[uint8_t volume_id];
    interface SystemCall;
    interface SystemCallQueue;
  }
}

implementation {
  typedef struct read_params {
    void *buf;
    storage_len_t* len;
    error_t error;
  } read_params_t;
  
  typedef struct append_params {
    void *buf;
    storage_len_t* len;
    bool* recordsLost;
    error_t error;
  } append_params_t;
  
  typedef struct seek_params {
    storage_cookie_t offset;
    error_t error;
  } seek_params_t;
  
  typedef struct erase_sync_params {
    error_t error;
  } erase_sync_params_t;

  syscall_queue_t vol_queue;

  command error_t Init.init()
  {
    call SystemCallQueue.init(&vol_queue);
    return SUCCESS;
  }

   // ===== READ ===== //
  void readTask(syscall_t *s)
  {
    read_params_t *p = s->params;
    p->error = call LogRead.read[s->id](p->buf, *(p->len));
    if(p->error != SUCCESS) {
      call SystemCall.finish(s);
    }
  }
  
  command error_t BlockingLog.read[uint8_t volume_id](void *buf, storage_len_t *len)
  {
    syscall_t s;
    read_params_t p;
    atomic {
      if(call SystemCallQueue.find(&vol_queue, volume_id) != NULL)
        return EBUSY;
      call SystemCallQueue.enqueue(&vol_queue, &s);
    }
    
    p.buf = buf;
    p.len = len;
    call SystemCall.start(&readTask, &s, volume_id, &p);
    
    atomic {
      call SystemCallQueue.remove(&vol_queue, &s);
      return p.error;
    }
  }

  event void LogRead.readDone[uint8_t volume_id](void *buf, storage_len_t len, error_t error)
  {
    syscall_t *s = call SystemCallQueue.find(&vol_queue, volume_id);
    read_params_t *p = s->params;
    if (p->buf == buf) {
      p->error = error;
      *(p->len) = len;
      call SystemCall.finish(s);
    }
  }
  
  // ===== SEEK ===== //
  void seekTask(syscall_t *s)
  {
    seek_params_t *p = s->params;
    p->error = call LogRead.seek[s->id](p->offset);
    if(p->error != SUCCESS) {
      call SystemCall.finish(s);
    }
  }
  
  command error_t BlockingLog.seek[uint8_t volume_id](storage_cookie_t offset)
  {
    syscall_t s;
    seek_params_t p;
    atomic {
      if(call SystemCallQueue.find(&vol_queue, volume_id) != NULL)
        return EBUSY;
      call SystemCallQueue.enqueue(&vol_queue, &s);
    }
    
    p.offset = offset;
    call SystemCall.start(&seekTask, &s, volume_id, &p);
    
    atomic {
      call SystemCallQueue.remove(&vol_queue, &s);
      return p.error;
    }
  }
  
  event void LogRead.seekDone[uint8_t volume_id](error_t error)
  {
    syscall_t *s = call SystemCallQueue.find(&vol_queue, volume_id);
    seek_params_t *p = s->params;
    p->error = error;
    call SystemCall.finish(s);
  }
  
  // ===== APPEND ===== //
  void appendTask(syscall_t *s)
  {
    append_params_t *p = s->params;
    p->error = call LogWrite.append[s->id](p->buf, *(p->len));
    if(p->error != SUCCESS) {
      call SystemCall.finish(s);
    }
  }
  
  command error_t BlockingLog.append[uint8_t volume_id](void* buf, storage_len_t *len, bool *recordsLost)
  {
    syscall_t s;
    append_params_t p;
    atomic {
      if(call SystemCallQueue.find(&vol_queue, volume_id) != NULL)
        return EBUSY;
      call SystemCallQueue.enqueue(&vol_queue, &s);
    }
    
    p.buf = buf;
    p.len = len;
    p.recordsLost = recordsLost;
    call SystemCall.start(&appendTask, &s, volume_id, &p);
    
    atomic {
      call SystemCallQueue.remove(&vol_queue, &s);
      return p.error;
    }
  }

  event void LogWrite.appendDone[uint8_t volume_id](void* buf, storage_len_t len, bool recordsLost, error_t error)
  {
    syscall_t *s = call SystemCallQueue.find(&vol_queue, volume_id);
    append_params_t *p = s->params;
    if (p->buf == buf) {
      p->error = error;
      *(p->len) = len;
      *(p->recordsLost) = recordsLost;
      call SystemCall.finish(s);
    }
  }
  
  // ===== ERASE ===== //
  void eraseTask(syscall_t *s)
  {
    erase_sync_params_t *p = s->params;
    p->error = call LogWrite.erase[s->id]();
    if(p->error != SUCCESS) {
      call SystemCall.finish(s);
    }
  }
  
  command error_t BlockingLog.erase[uint8_t volume_id]()
  {
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
  
  event void LogWrite.eraseDone[uint8_t volume_id](error_t error)
  {
    syscall_t *s = call SystemCallQueue.find(&vol_queue, volume_id);
    erase_sync_params_t *p = s->params;
    p->error = error;
    call SystemCall.finish(s);
  }
  
  // ===== SYNC ===== //
  void syncTask(syscall_t *s)
  {
    erase_sync_params_t *p = s->params;
    p->error = call LogWrite.sync[s->id]();
    if(p->error != SUCCESS) {
      call SystemCall.finish(s);
    }
  }
  
  command error_t BlockingLog.sync[uint8_t volume_id]()
  {
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
  
  event void LogWrite.syncDone[uint8_t volume_id](error_t error)
  {
    syscall_t *s = call SystemCallQueue.find(&vol_queue, volume_id);
    erase_sync_params_t *p = s->params;
    p->error = error;
    call SystemCall.finish(s);
  }
  
  // ===== MISC ===== //
  command storage_cookie_t BlockingLog.currentWriteOffset[uint8_t volume_id]() { return call LogWrite.currentOffset[volume_id](); }
  command storage_cookie_t BlockingLog.currentReadOffset[uint8_t volume_id]() { return call LogRead.currentOffset[volume_id](); }
  command storage_len_t BlockingLog.getSize[uint8_t volume_id]() { return call LogRead.getSize[volume_id](); }
  
  default command error_t LogRead.read[uint8_t volume_id](void* buf, storage_len_t len) { return FAIL; }
  default command storage_cookie_t LogRead.currentOffset[uint8_t volume_id]() { return SEEK_BEGINNING; }
  default command error_t LogRead.seek[uint8_t volume_id](storage_cookie_t offset) { return FAIL; }
  default command storage_len_t LogRead.getSize[uint8_t volume_id]() { return 0; }
  
  default command error_t LogWrite.append[uint8_t volume_id](void* buf, storage_len_t len) { return FAIL; }
  default command storage_cookie_t LogWrite.currentOffset[uint8_t volume_id]() { return SEEK_BEGINNING; }
  default command error_t LogWrite.erase[uint8_t volume_id]() { return FAIL; }
  default command error_t LogWrite.sync[uint8_t volume_id]() { return FAIL; }
}
