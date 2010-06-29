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

module DelugeVolumeManagerP
{
  provides interface DelugeVolumeManager[uint8_t client];
  uses {
    interface BlockWrite[uint8_t volumeId];
    interface Resource[uint8_t volumeId];
  }
}

implementation
{
  uint8_t currentClient;
  bool busy = FALSE;

  command error_t DelugeVolumeManager.erase[uint8_t client](uint8_t imgNum)
  {
    if (busy)
      return FAIL;
    busy = call Resource.request[imgNum]() == SUCCESS;
    if (busy) {
      currentClient = client;
      return SUCCESS;
    }
    return FAIL;
  }

  event void Resource.granted[uint8_t imgNum]()
  {
    call BlockWrite.erase[imgNum]();
  }

  event void BlockWrite.eraseDone[uint8_t imgNum](error_t error)
  {
    busy = FALSE;
    call Resource.release[imgNum]();
    signal DelugeVolumeManager.eraseDone[currentClient](error);
  }

  event void BlockWrite.writeDone[uint8_t imgNum](storage_addr_t addr, void* buf, storage_len_t len, error_t error) {}
  event void BlockWrite.syncDone[uint8_t imgNum](error_t error) {}
  default command error_t BlockWrite.erase[uint8_t imgNum]() { return FAIL; }
  default event void DelugeVolumeManager.eraseDone[uint8_t client](uint8_t imgNum) {}
  default async command error_t Resource.request[uint8_t imgNum]() { return FAIL; }
  default async command error_t Resource.release[uint8_t imgNum]() { return FAIL; }
}
