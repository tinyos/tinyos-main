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

module CLogStorageP {
  uses {
    interface BlockingLog[uint8_t volume_id];
  }
}
implementation {
  error_t volumeLogRead(uint8_t volumeId, void *buf, storage_len_t *len) @C() AT_SPONTANEOUS {
    return call BlockingLog.read[volumeId](buf, len);
  }
  storage_cookie_t volumeLogCurrentReadOffset(uint8_t volumeId) @C() AT_SPONTANEOUS {
    return call BlockingLog.currentReadOffset[volumeId]();
  }
  error_t volumeLogSeek(uint8_t volumeId, storage_cookie_t offset) @C() AT_SPONTANEOUS {
    return call BlockingLog.seek[volumeId](offset);
  }
  storage_len_t volumeLogGetSize(uint8_t volumeId) @C() AT_SPONTANEOUS {
    return call BlockingLog.getSize[volumeId]();
  }  
  error_t volumeLogAppend(uint8_t volumeId, void* buf, storage_len_t *len, bool *recordsLost) @C() AT_SPONTANEOUS {
    return call BlockingLog.append[volumeId](buf, len, recordsLost);
  }
  storage_cookie_t volumeLogCurrentWriteOffset(uint8_t volumeId) @C() AT_SPONTANEOUS {
    return call BlockingLog.currentWriteOffset[volumeId]();
  }
  error_t volumeLogErase(uint8_t volumeId) @C() AT_SPONTANEOUS {
    return call BlockingLog.erase[volumeId]();
  }
  error_t volumeLogSync(uint8_t volumeId) @C() AT_SPONTANEOUS {
    return call BlockingLog.sync[volumeId]();
  }
}
