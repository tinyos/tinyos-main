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

#include "DynamicLoader.h"

module LoadSourceMapP
{
  provides interface BlockRead[uint8_t id];
  
  uses {
    interface BlockRead as SubBlockRead[uint8_t id];
    interface BlockRead as SubMemoryRead;
  }
}

implementation
{
  event void SubMemoryRead.readDone(storage_addr_t addr, void* buf, storage_len_t len, error_t error)
  {
    signal BlockRead.readDone[READSOURCE_MEMORY](addr, buf, len, error);
  }
  
  event void SubBlockRead.readDone[uint8_t id](storage_addr_t addr, void* buf, storage_len_t len, error_t error)
  {
    signal BlockRead.readDone[id](addr, buf, len, error);
  }
                          
  command error_t BlockRead.read[uint8_t id](storage_addr_t addr, void* buf, storage_len_t len)
  {
    error_t error = FAIL;
    
    if (id == READSOURCE_MEMORY) {
      error = call SubMemoryRead.read(addr, buf, len);
    } else {
      error = call SubBlockRead.read[id](addr, buf, len);
    }
    
    return error;
  }

  event void SubMemoryRead.computeCrcDone(storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error)
  {
    signal BlockRead.computeCrcDone[READSOURCE_MEMORY](addr, len, crc, error);
  }

  event void SubBlockRead.computeCrcDone[uint8_t id](storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error)
  {
    signal BlockRead.computeCrcDone[id](addr, len, crc, error);
  }
  
  command error_t BlockRead.computeCrc[uint8_t id](storage_addr_t addr, storage_len_t len, uint16_t crc)
  {
    error_t error = FAIL;
    
    if (id == READSOURCE_MEMORY) {
      error = call SubMemoryRead.computeCrc(addr, len, crc);
    } else {
      error = call SubBlockRead.computeCrc[id](addr, len, crc);
    }
    
    return error;
  }
  
  command storage_len_t BlockRead.getSize[uint8_t id]()
  {
    storage_len_t len;
    
    if (id == READSOURCE_MEMORY) {
      len = call SubMemoryRead.getSize();
    } else {
      len = call SubBlockRead.getSize[id]();
    }
    
    return len;
  }
  
  default command error_t SubBlockRead.read[uint8_t id](storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  default command error_t SubBlockRead.computeCrc[uint8_t id](storage_addr_t addr, storage_len_t len, uint16_t crc) { return FAIL; }
  default command storage_len_t SubBlockRead.getSize[uint8_t id]() { return 0; }
  default event void BlockRead.readDone[uint8_t id](storage_addr_t addr, void* buf, storage_len_t len, error_t error) {}
  default event void BlockRead.computeCrcDone[uint8_t id](storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error) {}
}
