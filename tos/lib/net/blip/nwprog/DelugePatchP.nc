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

module DelugePatchP
{
  provides interface DelugePatch[uint8_t client];
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
    S_READY,
    S_BUSY,
    S_READ_PATCH_CMD,
    S_READ_PATCH_DATA, 
    S_READ_PATCH_COPY,
    S_WRITE_PATCH,
  };

  DelugeIdent ident;
  DelugePatchCmd patch;

  uint8_t patchData[MAX_PATCH_DATA_SIZE];

  uint8_t state;
  uint8_t currentClient;

  uint16_t patchNumLinesRead;
  uint16_t patchNumLines;

  uint32_t patchByteAddr;  
  uint8_t patchVolume;
  uint8_t patchImageIdx;
  uint8_t patchPage;

  uint32_t dstByteAddr;  
  uint8_t srcVolume;
  uint8_t srcImageIdx;
  uint8_t srcPage;

  uint32_t dstByteAddr;  
  uint8_t dstVolume;
  uint8_t dstImageIdx;
  uint8_t dstPage;


  void setStorageReady()
  {
    signal storageReady();
    state = S_READY;
  }

  void notifySuccess() 
  {
    signal DelugePatch.decodePatchDone[currentClient](
            patchImageIdx, srcImageIdx, dstImageIdx, SUCCESS);
    setStorageReady();
  }

  void notifyFailure(error_t error)
  {
    signal DelugePatch.decodePatchDone[currentClient](
            patchImageIdx, srcImageIdx, dstImageIdx, error);
    setStorageReady();
  }

  command error_t DelugePatch.decodePatch[uint8_t client](uint8_t imgNumPatch,
                                                          uint8_t imgNumSrc,
                                                          uint8_t imgNumDst)
  {
    patchImageIdx = imgNumPatch;
    patchVolume   = _imgNum2volumeId[patchImageIdx];
    srcImageIdx   = imgNumSrc;
    srcVolume     = _imgNum2volumeId[srcImageIdx];
    dstImageIdx   = imgNumDst;
    dstVolume     = _imgNum2volumeId[dstImageIdx];

    // First, read the DelugeIdent section.
    if (patchImageIdx < DELUGE_NUM_VOLUMES) {
      state = S_READ_IDENT;
      call BlockRead.read[patchVolume](0, &ident, sizeof(ident));
    } else {
      signal storageReady();
      state = S_READY;
    }

    return SUCCESS;
  }

  event void BlockRead.readDone[uint8_t imgNum](
    storage_addr_t addr, void* buf, storage_len_t len, error_t error)
  {
    switch (state) {
    case S_BUSY:
      notifyFailure(error);
      break;
    // Read the DelugeIdent structure into ident.
    // If it is valid, ident.userhash contains
    // number of patch command lines.
    // Initialize patchByteAddr to the beginning of
    // the patch commands.
    case S_READ_IDENT:
      if (error == SUCCESS) {
        if (ident.uidhash != DELUGE_INVALID_UID) {
          patchNumLines = ident.userhash;
          state = S_READ_PATCH_CMD;
          patchByteAddr = DELUGE_IDENT_SIZE + DELUGE_CRC_BLOCK_SIZE; 
          call BlockRead.read[patchVolume](patchByteAddr, &patch, sizeof(patch)); 
          break;
        } 
      }
      notifyFailure(error);
      break;
    // Read a patch command.
    // If successful, check it is UPLOAD or COPY.
    // For an UPLOAD commandy
    //   increment the number of patch lines read,
    //   increase patchByteAddr by PATCH_LINE_SIZE,
    //   and read the patch data.
    // For a COPY command,
    //   increment the number of patch lines read,
    //   increase patchByteAddr by PATCH_LINE_SIZE,
    //   and read data from the source volume.
    case S_READ_PATCH_CMD:
      if (error == SUCCESS) {
        if (patch.cmd == PATCH_CMD_UPLOAD) { 
          patchNumLinesRead++;
          patchByteAddr += PATCH_LINE_SIZE;  // read the next line of patch
          state = S_READ_PATCH_DATA;
          call BlockRead.read[patchVolume](patchByteAddr, patchData, patch.data_length);
          break;
        }
        else if (patch.cmd == PATCH_CMD_COPY) { 
          patchNumLinesRead++; 
          patchByteAddr += PATCH_LINE_SIZE;  // read the next line of patch
          state = S_READ_PATCH_COPY;
          call BlockRead.read[srcVolume](patch.src_offset, patchData, patch.data_length);
          break;
        }
      }
      notifyFailure(error);
      break;
    // When the patch data of PATCH_UPLOAD is ready,
    // increase patchByteAddr ceiling(len / PATCH_LINE_SIZE) * PATCH_LINE_SIZE,
    // and  write it into the destination volume.  
    case S_READ_PATCH_DATA:
      if (error == SUCCESS) {
        state = S_WRITE_PATCH;
        patchByteAddr += ((len + PATCH_LINE_SIZE - 1) / PATCH_LINE_SIZE * PATCH_LINE_SIZE); 
        call BlockWrite.write[dstVolume](patch.dst_offset, buf, len);
        break;
      }
      notifyFailure(error);
      break;
    // When the source data of PATCH_COPY is ready,
    // write it into the destination volume.
    case S_READ_PATCH_COPY:
      if (error == SUCCESS) {
        state = S_WRITE_PATCH;
        call BlockWrite.write[dstVolume](patch.dst_offset, buf, len);
        break;
      }
      notifyFailure(error);
      break;
    }
  }

  event void BlockWrite.writeDone[uint8_t imgNum](
    storage_addr_t addr, void* buf, storage_len_t len, error_t error) 
  {
    switch (state) {
    case S_WRITE_PATCH:
      if (error == SUCCESS) {
        // When more patch commands remaining, read the next one.
        if (patchNumLinesRead < patchNumLines) {
          state = S_READ_PATCH_CMD;
          call BlockRead.read[patchVolume](patchByteAddr, &patch, sizeof(patch)); 
        }
        else {
          notifySuccess();
        }
        break;
      }
      notifyFailure(error);
      break;
    }
  }

  event void BlockWrite.eraseDone[uint8_t imgNum](error_t error)
  {
    switch (state) {
    case S_READY:
      signal BlockWrite.eraseDone[imgNum](error);
      break;
    }
  }

  default command error_t BlockWrite.write[uint8_t imgNum](
    storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  default command error_t BlockRead.read[uint8_t imgNum](
    storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  default command error_t BlockRead.computeCrc[uint8_t imgNum](
    storage_addr_t addr, storage_len_t len, uint16_t crc) { return FAIL; }
  event void BlockRead.computeCrcDone[uint8_t imgNum](
    storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error) {}
  event void BlockWrite.syncDone[uint8_t imgNum](error_t error) {}
  default command error_t BlockWrite.erase[uint8_t imgNum]() { return FAIL; }
  default event void storageReady() {}
  default event void DelugePatch.decodePatchDone[uint8_t client](
    uint8_t imgNumPatch, uint8_t imgNumSrc, uint8_t imgNumDst, error_t error) {}

}
