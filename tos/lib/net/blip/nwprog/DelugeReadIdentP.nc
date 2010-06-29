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

module DelugeReadIdentP
{
  provides interface DelugeReadIdent[uint8_t client];
  uses {
    interface Boot;
    interface BlockRead[uint8_t volumeId];
    interface StorageMap[uint8_t volumeId];
    event void storageReady();
  }
}

implementation
{
  enum {
    S_READY,
    S_READ_VOLUME,
    S_READ_NUM_VOLUMES,
  };
  
  DelugeIdent ident;
  uint8_t state;
  uint8_t currentClient;
  uint8_t currentIdx;
  uint8_t currentVolume;
  uint8_t fields;
  uint8_t validVolumes;

  event void Boot.booted() { }

  command error_t DelugeReadIdent.readVolume[uint8_t client](uint8_t imgNum)
  {
    if (state != S_READY) {
      return FAIL;
    }
    else {
      currentClient = client;
      currentIdx = imgNum;
      currentVolume = _imgNum2volumeId[currentIdx];
      if (imgNum < DELUGE_NUM_VOLUMES) {
        state = S_READ_VOLUME;
        return call BlockRead.read[currentVolume](0, &ident, sizeof(ident)); 
      }
      else {
        return FAIL;
      } 
    }
  }

  command error_t DelugeReadIdent.readNumVolumes[uint8_t client]()
  {
    if (state != S_READY) {
      return FAIL;
    }
    else {
      fields = 0;
      validVolumes = 0;
      currentClient = client;
      currentIdx = 0;
      currentVolume = _imgNum2volumeId[currentIdx];
      state = S_READ_NUM_VOLUMES;
      return call BlockRead.read[currentVolume](0, &ident, sizeof(ident)); 
    }
  }


  event void BlockRead.readDone[uint8_t imgNum](
    storage_addr_t addr, void* buf, storage_len_t len, error_t error)
  {
    switch (state) {
    case S_READ_VOLUME:
      if (error == SUCCESS && ident.uidhash != DELUGE_INVALID_UID) {
        signal DelugeReadIdent.readVolumeDone[currentClient](currentIdx, buf, SUCCESS);
      }
      else {
        signal DelugeReadIdent.readVolumeDone[currentClient](currentIdx, buf, FAIL);
      }
      state = S_READY;
      signal storageReady();
      break; 
    case S_READ_NUM_VOLUMES:
      if (error == SUCCESS && ident.uidhash != DELUGE_INVALID_UID) {
        // Increment valid volumes only when uidhash is valid.
        fields |= (1 << currentIdx);
        validVolumes++; 
      } 

      // Increment the number volumes read.
      currentIdx++;
      currentVolume = _imgNum2volumeId[currentIdx];

      // Read the next volume when it didn't reach the end.
      if (currentIdx < DELUGE_NUM_VOLUMES) {
        call BlockRead.read[currentVolume](0, &ident, sizeof(ident)); 
      }
      // Otherwise, notify the success.
      else {
        state = S_READY;
        signal storageReady();
        signal DelugeReadIdent.readNumVolumesDone[currentClient](
          validVolumes, fields, SUCCESS);
      }
      break; 
    }
  }

  event void BlockRead.computeCrcDone[uint8_t imgNum](
    storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error) {}
  default command error_t BlockRead.read[uint8_t imgNum](
    storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  default command error_t BlockRead.computeCrc[uint8_t imgNum](
    storage_addr_t addr, storage_len_t len, uint16_t crc) { return FAIL; }
  default event void storageReady() {} 
  default event void DelugeReadIdent.readNumVolumesDone[uint8_t client](
    uint8_t validVols, uint8_t volumeFields, error_t error) {}
  default event void DelugeReadIdent.readVolumeDone[uint8_t client](
    uint8_t imgNum, DelugeIdent* id, error_t error) {} 

}

