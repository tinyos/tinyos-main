/* Copyright (c) 2007 Johns Hopkins University.
*  All rights reserved.
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
 * @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

#include "imgNum2volumeId.h"

module DelugeVerifyP
{
  provides interface DelugeVerify[uint8_t client];
  uses {
    interface BlockRead[uint8_t volumeId];
    interface BlockWrite[uint8_t volumeId];
    interface StorageMap[uint8_t volumeId];
    event void storageReady();
  }
}

implementation
{
  enum {
    S_READ_IDENT,
    S_READ_CRC,
    S_CRC,
    S_READY,
    S_BUSY,
  };
  
  DelugeIdent ident;
  uint8_t state;
  uint8_t currentVolume;
  uint8_t currentImageIdx;
  uint8_t currentPage;
  nx_uint16_t currentCrc;
  uint8_t currentClient;

  void setStorageReady()
  {
    signal storageReady();
    state = S_READY;
  }

  uint32_t calcCrcAddr()
  {
    return DELUGE_IDENT_SIZE + currentPage * sizeof(uint16_t);
  }
  
  uint32_t calcPageAddr()
  {
    return DELUGE_IDENT_SIZE + DELUGE_CRC_BLOCK_SIZE + currentPage * DELUGE_BYTES_PER_PAGE;
  }

  command error_t DelugeVerify.verifyImg[uint8_t client](uint8_t imgNum)
  {
    // We are going to verify the integrity of the specified image.
    // We first read the ident to find the number of pages and 
    // then iterate over all of them, compute the CRC and 
    // check it against the corresponding value from the CRCs block.
    state = S_READ_IDENT;
    currentImageIdx = imgNum;
    currentVolume = _imgNum2volumeId[currentImageIdx];

    if (currentImageIdx < DELUGE_NUM_VOLUMES) {
      state = S_READ_IDENT;
      call BlockRead.read[currentVolume](0, &ident, sizeof(ident));
    } else {
      signal storageReady();
      state = S_READY;
    }

    return SUCCESS;
  }

  event void BlockRead.readDone[uint8_t imgNum](storage_addr_t addr, void* buf, storage_len_t len, error_t error)
  {
    switch (state) {
    case S_BUSY:
      setStorageReady();
      signal DelugeVerify.verifyImgDone[currentClient](imgNum, error);
      break;
    case S_READ_IDENT:
      if (error == SUCCESS) {
        if (ident.uidhash != DELUGE_INVALID_UID) {
          currentPage = 0;
          state = S_READ_CRC;
          call BlockRead.read[currentVolume](calcCrcAddr(), &currentCrc, sizeof(currentCrc));
          break;
        } 
      }
      setStorageReady();
      signal DelugeVerify.verifyImgDone[currentClient](imgNum, FAIL);
      break;
    case S_READ_CRC:
      state = S_CRC;
      call BlockRead.computeCrc[currentVolume](calcPageAddr(), DELUGE_BYTES_PER_PAGE, 0);
      break;
    }
  }

  event void BlockRead.computeCrcDone[uint8_t imgNum](storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error)
  {
    switch (state) {
    case S_CRC:
      if (crc != currentCrc) {
        setStorageReady();
        signal DelugeVerify.verifyImgDone[currentClient](imgNum, FAIL);
      } else {
        currentPage++;
        if (currentPage < ident.numPgs) {
          state = S_READ_CRC;
          call BlockRead.read[currentVolume](calcCrcAddr(), &currentCrc, sizeof(currentCrc));
        } 
        else {
          setStorageReady();
          signal DelugeVerify.verifyImgDone[currentClient](imgNum, error); 
        }
      }
      break;
    }
  }

  default command error_t BlockRead.read[uint8_t imgNum](storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  default command error_t BlockRead.computeCrc[uint8_t imgNum](storage_addr_t addr, storage_len_t len, uint16_t crc) { return FAIL; }

  event void BlockWrite.writeDone[uint8_t imgNum](storage_addr_t addr, void* buf, storage_len_t len, error_t error) {}
  event void BlockWrite.eraseDone[uint8_t imgNum](error_t error)
  {
    switch (state) {
    case S_READY:
      signal BlockWrite.eraseDone[imgNum](error);
      break;
    }
  }

  event void BlockWrite.syncDone[uint8_t imgNum](error_t error) {}
  default command error_t BlockWrite.erase[uint8_t imgNum]() { return FAIL; }
  default event void storageReady() {}
  default event void DelugeVerify.verifyImgDone[uint8_t client](uint8_t imgNum, error_t error) {}

}
