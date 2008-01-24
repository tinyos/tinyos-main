/* Copyright (c) 2007 Johns Hopkins University.
*  All rights reserved.
*
*  Permission to use, copy, modify, and distribute this software and its
*  documentation for any purpose, without fee, and without written
*  agreement is hereby granted, provided that the above copyright
*  notice, the (updated) modification history and the author appear in
*  all copies of this source code.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
*  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
*  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
*  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
*  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
*  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
*  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
*  THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

generic module BlockStorageManagerP(uint8_t clients)
{
  provides {
    interface BlockRead[uint8_t client];
    interface BlockWrite[uint8_t client];
    interface StorageMap[uint8_t volume_id];
  }
  uses {
    interface BlockRead as SubBlockRead[volume_id_t volume_id];
    interface BlockWrite as SubBlockWrite[volume_id_t volume_id];
    interface VolumeId[uint8_t client];
#if defined(PLATFORM_TELOSB)
    interface StorageMap as SubStorageMap[volume_id_t volume_id];
#elif defined(PLATFORM_MICAZ) || defined(PLATFORM_IRIS)
    interface At45dbVolume[volume_id_t volume_id];
#endif
  }
}

implementation
{
  enum {
    S_READY,
    S_BUSY
  };

  uint8_t state = S_READY;
  uint8_t current_client;

  /* BlockRead **************************/
  command error_t BlockRead.read[uint8_t client](storage_addr_t addr, void* buf, storage_len_t len)
  {
    error_t error;
    if (state != S_READY) {
      return EBUSY;
    }
    error = call SubBlockRead.read[call VolumeId.get[client]()](addr, buf, len);
    if (error == SUCCESS)
    {
      state = S_BUSY;
      current_client = client;
      return SUCCESS;
    }
    return error;
  }

  command error_t BlockRead.computeCrc[uint8_t client](storage_addr_t addr, storage_len_t len, uint16_t crc)
  {
    error_t error;
    if (state != S_READY) {
      return EBUSY;
    }
    error = call SubBlockRead.computeCrc[call VolumeId.get[client]()](addr, len, crc);
    if (error == SUCCESS)
    {
      state = S_BUSY;
      current_client = client;
      return SUCCESS;
    }
    return error;
  }

  command storage_len_t BlockRead.getSize[uint8_t client]()
  {
    return call SubBlockRead.getSize[client]();
  }

  event void SubBlockRead.readDone[volume_id_t volume_id](storage_addr_t addr, void* buf, storage_len_t len, error_t error)
  {
    state = S_READY;
    signal BlockRead.readDone[current_client](addr, buf, len, error);
  }

  event void SubBlockRead.computeCrcDone[volume_id_t volume_id](storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error)
  {
    state = S_READY;
    signal BlockRead.computeCrcDone[current_client](addr, len, crc, error);
  }

  default command error_t SubBlockRead.read[uint8_t client](storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  default command error_t SubBlockRead.computeCrc[uint8_t client](storage_addr_t addr, storage_len_t len, uint16_t crc) { return FAIL; }
  default event void BlockRead.readDone[volume_id_t volume_id](storage_addr_t addr, void* buf, storage_len_t len, error_t error) {}
  default event void BlockRead.computeCrcDone[volume_id_t volume_id](storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error) {}


  /* BlockWrite **************************/
  command error_t BlockWrite.write[uint8_t client](storage_addr_t addr, void* buf, storage_len_t len)
  {
    error_t error;
    if (state != S_READY) {
      return EBUSY;
    }
    error = call SubBlockWrite.write[call VolumeId.get[client]()](addr, buf, len);
    if (error == SUCCESS)
    {
      state = S_BUSY;
      current_client = client;
      return SUCCESS;
    }
    return error;
  }

  command error_t BlockWrite.erase[uint8_t client]()
  {
    error_t error;
    if (state != S_READY) {
      return EBUSY;
    }
    error = call SubBlockWrite.erase[call VolumeId.get[client]()]();
    if (error == SUCCESS)
    {
      state = S_BUSY;
      current_client = client;
      return SUCCESS;
    }
    return error;
  }

  command error_t BlockWrite.sync[uint8_t client]()
  {
    error_t error;
    if (state != S_READY) {
      return EBUSY;
    }
    error = call SubBlockWrite.sync[call VolumeId.get[client]()]();
    if (error == SUCCESS)
    {
      state = S_BUSY;
      return SUCCESS;
    }
    return error;
  }

  event void SubBlockWrite.writeDone[volume_id_t volume_id](storage_addr_t addr, void* buf, storage_len_t len, error_t error)
  {
    state = S_READY;
    signal BlockWrite.writeDone[current_client](addr, buf, len, error);
  }

  event void SubBlockWrite.eraseDone[volume_id_t volume_id](error_t error)
  {
    state = S_READY;
    signal BlockWrite.eraseDone[current_client](error);
  }

  event void SubBlockWrite.syncDone[volume_id_t volume_id](error_t error)
  {
    state = S_READY;
    signal BlockWrite.syncDone[current_client](error);
  }

  command storage_addr_t StorageMap.getPhysicalAddress[uint8_t volume_id](storage_addr_t addr)
  {
    storage_addr_t p_addr = 0xFFFFFFFF;
#if defined(PLATFORM_TELOSB)
    p_addr = call SubStorageMap.getPhysicalAddress[volume_id](addr);
#elif defined(PLATFORM_MICAZ)
    at45page_t page = call At45dbVolume.remap[volume_id]((addr >> AT45_PAGE_SIZE_LOG2));
    at45pageoffset_t offset = addr & ((1 << AT45_PAGE_SIZE_LOG2) - 1);
    p_addr = page;
    p_addr = p_addr << AT45_PAGE_SIZE_LOG2;
    p_addr += offset;
#elif defined(PLATFORM_IRIS)
    at45page_t page = call At45dbVolume.remap[volume_id]((addr >> AT45_PAGE_SIZE_LOG2));
    at45pageoffset_t offset = addr & ((1 << AT45_PAGE_SIZE_LOG2) - 1);
    p_addr = page;
    p_addr = p_addr << AT45_PAGE_SIZE_LOG2;
    p_addr += offset;
#endif
    return p_addr;
  }

#if defined(PLATFORM_TELOSB)
  default command storage_addr_t SubStorageMap.getPhysicalAddress[uint8_t volume_id](storage_addr_t addr)
  {
    return 0xffffffff;
  }
#endif

  default command error_t SubBlockWrite.write[uint8_t client](storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  default command error_t SubBlockWrite.erase[uint8_t client]() { return FAIL; }
  default command error_t SubBlockWrite.sync[uint8_t client]() { return FAIL; }
  default event void BlockWrite.writeDone[volume_id_t volume_id](storage_addr_t addr, void* buf, storage_len_t len, error_t error) {}
  default event void BlockWrite.eraseDone[volume_id_t volume_id](error_t error) {}
  default event void BlockWrite.syncDone[volume_id_t volume_id](error_t error) {}


  default command volume_id_t VolumeId.get[uint8_t client]()
  {
    return 0xFF; // This is an invalid volume at least for STM25P.
  }
}
