/*
 * Copyright (c) 2010 CSIRO Australia
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
 * SD Card Interface Implementation
 * @author Kevin Klues <kevin.klues@csiro.au>
 */

module SDP
{
  provides {
    interface StdControl;
    interface SD;
  }
  uses {
    interface Resource;
    interface Sam3uHsmciInit;
    interface Sam3uHsmci;
    interface Leds;
  }
}

implementation
{
  norace int initialized = FALSE;
  norace volatile bool busy = FALSE;
  norace error_t trans_error;

  error_t init() {
    error_t error;

    busy = TRUE;
    error = call Sam3uHsmciInit.init();
    if(error == SUCCESS) {
      while(busy);
      error = trans_error;
      signal SD.available();
    }
    else {
      signal SD.unavailable();
      busy = FALSE;
    }

    initialized = TRUE;
    return error;
  }

  command error_t StdControl.start() {
    error_t error = call Resource.immediateRequest();
    if(!initialized)
      return ecombine(error, init());
    return error;
  }

  command error_t StdControl.stop() {
    return call Resource.release();
  }

  command uint32_t SD.readCardSize(){
    return call Sam3uHsmci.readCardSize();
  }

  command error_t SD.readBlock(uint32_t sector, uint8_t *buffer) {
    error_t error;
    if(busy)
      return EBUSY;

    busy = TRUE;
    error = call Sam3uHsmci.readBlock(sector, (uint32_t*)buffer);
    if(error == SUCCESS) {
      while(busy);
      error = trans_error;
    }
    else busy = FALSE;
    return error;
  }

  command error_t SD.writeBlock(uint32_t sector, uint8_t *buffer) {
    error_t error;
    if(busy)
      return EBUSY;

    busy = TRUE;
    error = call Sam3uHsmci.writeBlock(sector, (uint32_t*)buffer);
    if(error == SUCCESS) {
      while(busy);
      error = trans_error;
    }
    else busy = FALSE;
    return error;
  }

  async event void Sam3uHsmciInit.initDone(error_t error) {
    trans_error = error;
    busy = FALSE;
  }

  async event void Sam3uHsmci.readBlockDone(uint32_t *buf, error_t error) {
    trans_error = error;
    busy = FALSE;
  }

  async event void Sam3uHsmci.writeBlockDone(uint32_t *buf, error_t error) {
    trans_error = error;
    busy = FALSE;
  }

  event void Resource.granted() {}
}

