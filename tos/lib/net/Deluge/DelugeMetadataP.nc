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

#include "imgNum2volumeId.h"

module DelugeMetadataP
{
  provides interface DelugeMetadata[uint8_t client];
  uses {
    interface Boot;
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
    S_BUSY
  };
  
  DelugeIdent ident;
  uint8_t state;
  uint8_t currentVolume;
  uint8_t currentImageIdx;
  uint8_t currentPage;
  nx_uint16_t currentCrc;
  uint8_t currentClient;

  void nextImage()
  {
    if (currentImageIdx < DELUGE_NUM_VOLUMES) {
      state = S_READ_IDENT;
      call BlockRead.read[currentVolume](0, &ident, sizeof(ident));
    } else {
      signal storageReady();
      state = S_READY;
    }
  }

  uint32_t calcCrcAddr()
  {
    return DELUGE_IDENT_SIZE + currentPage * sizeof(uint16_t);
  }

  uint32_t calcPageAddr()
  {
    return DELUGE_IDENT_SIZE + DELUGE_CRC_BLOCK_SIZE + currentPage * DELUGE_BYTES_PER_PAGE;
  }

  event void Boot.booted()
  {
    // We are going to iterate over all the images and verify their
    // integrity. For each image we first read the ident to find the
    // number of pages and then iterate over all of them, compute the
    // CRC and check it against the corresponding value from the CRCs
    // block.
    state = S_READ_IDENT;
    currentImageIdx = 0;
    currentVolume = _imgNum2volumeId[currentImageIdx];
    nextImage();
  }

  command error_t DelugeMetadata.read[uint8_t client](uint8_t imgNum)
  {
    error_t error;
    if (state != S_READY) {
      return FAIL;
    }
    currentClient = client;
    error = call BlockRead.read[imgNum](0, &ident, sizeof(ident));
    state = error == SUCCESS ? S_BUSY : state;
    return error;
  }

  event void BlockRead.readDone[uint8_t imgNum](storage_addr_t addr, void* buf, storage_len_t len, error_t error)
  {
    switch (state) {
    case S_BUSY:
      state = S_READY;
      signal DelugeMetadata.readDone[currentClient](imgNum, buf, error);
      break;
    case S_READ_IDENT:
      if (error == SUCCESS) {
        if (ident.uidhash != DELUGE_INVALID_UID) {
          currentPage = 0;
          state = S_READ_CRC;
          call BlockRead.read[currentVolume](calcCrcAddr(), &currentCrc, sizeof(currentCrc));
        } else {
          currentImageIdx++;
          currentVolume = _imgNum2volumeId[currentImageIdx];
          nextImage();
        }
      }
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
//	printf("%04x %04x\n", crc, currentCrc);
        // invalidate the image by erasing it
        call BlockWrite.erase[currentVolume]();
      } else {
        currentPage++;
        if (currentPage < ident.numPgs) {
          state = S_READ_CRC;
          call BlockRead.read[currentVolume](calcCrcAddr(), &currentCrc, sizeof(currentCrc));
        } else {
          currentImageIdx++;
          currentVolume = _imgNum2volumeId[currentImageIdx];
          nextImage();
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
    case S_CRC:
      currentImageIdx++;
      currentVolume = _imgNum2volumeId[currentImageIdx];
      nextImage();
      break;
    }
  }

  event void BlockWrite.syncDone[uint8_t imgNum](error_t error) {}
  default command error_t BlockWrite.erase[uint8_t imgNum]() { return FAIL; }

  default event void DelugeMetadata.readDone[uint8_t client](uint8_t imgNum, DelugeIdent* i, error_t error) {}
  default event void storageReady() {}
}
