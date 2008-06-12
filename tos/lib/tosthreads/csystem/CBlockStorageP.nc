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

module CBlockStorageP {
  uses {
    interface BlockingBlock[uint8_t volume_id];
  }
}

implementation {
  error_t volumeBlockRead(uint8_t volumeId, storage_addr_t addr, void* buf, storage_len_t* len) @C() @spontaneous()
  {
    return call BlockingBlock.read[volumeId](addr, buf, len);
  }
  
  error_t volumeBlockWrite(uint8_t volumeId, storage_addr_t addr, void* buf, storage_len_t* len)  @C() @spontaneous()
  {
    return call BlockingBlock.write[volumeId](addr, buf, len);
  }
  
  error_t volumeBlockCrc(uint8_t volumeId, storage_addr_t addr, storage_len_t* len, uint16_t crc, uint16_t *finalCrc) @C() @spontaneous()
  {
    return call BlockingBlock.computeCrc[volumeId](addr, len, crc, finalCrc);
  }
  
  error_t volumeBlockErase(uint8_t volumeId) @C() @spontaneous()
  {
    return call BlockingBlock.erase[volumeId]();
  }
  
  error_t volumeBlockSync(uint8_t volumeId) @C() @spontaneous()
  {
    return call BlockingBlock.sync[volumeId]();
  }
}
