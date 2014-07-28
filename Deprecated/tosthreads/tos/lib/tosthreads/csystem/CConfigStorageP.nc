/*
 * Copyright (c) 2009 RWTH Aachen University.
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
 * @author J— çgila Bitsch Link <jo.bitsch@cs.rwth-aachen.de>
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

module CConfigStorageP {
  uses {
    interface BlockingConfig[uint8_t volume_id];
    interface BlockingMount[uint8_t volume_id];
  }
}

implementation {
  error_t volumeConfigMount(uint8_t volumeId) @C() AT_SPONTANEOUS {
    return call BlockingMount.mount[volumeId]();
  }
  
  error_t volumeConfigRead(uint8_t volumeId, storage_addr_t addr, void* buf, storage_len_t* len) @C() AT_SPONTANEOUS {
    return call BlockingConfig.read[volumeId](addr, buf, len);
  }
  
  error_t volumeConfigWrite(uint8_t volumeId, storage_addr_t addr, void* buf, storage_len_t* len) @C() AT_SPONTANEOUS {
    return call BlockingConfig.write[volumeId](addr, buf, len);
  }
  
  error_t volumeConfigCommit(uint8_t volumeId) @C() AT_SPONTANEOUS {
    return call BlockingConfig.commit[volumeId]();
  }
  
  storage_len_t volumeConfigGetSize(uint8_t volumeId) @C() AT_SPONTANEOUS {
    return call BlockingConfig.getSize[volumeId]();
  }
  
  bool volumeConfigValid(uint8_t volumeId) @C() AT_SPONTANEOUS {
    return call BlockingConfig.valid[volumeId]();
  }
}
