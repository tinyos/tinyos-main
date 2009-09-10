/*
 * Copyright (c) 2009 RWTH Aachen University.
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
