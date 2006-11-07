/* $Id: HalTsl2561ReaderP.nc,v 1.3 2006-11-07 19:31:16 scipio Exp $ */
/*
 * Copyright (c) 2005 Arch Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arch Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/**
 *
 * @author Kaisen Lin
 * @author Phil Buonadonna
 */

// someone better power this up via SplitControl

generic module HalTsl2561ReaderP() {
  provides interface Read<uint16_t> as BroadbandPhoto;
  provides interface Read<uint16_t> as IRPhoto;

  uses interface Resource as BroadbandResource;
  uses interface Resource as IRResource;
  uses interface HplTSL256x;

}

implementation {
  enum {
    S_OFF = 0,
    S_READY,
    S_READ_BB,
    S_READ_IR,
  };
  norace uint8_t m_state = S_READY;
  error_t m_error;
  uint16_t m_val;

  task void signalDone_task() {
    switch(m_state) {
    case S_READ_BB:
      m_state = S_READY;
      call BroadbandResource.release();
      signal BroadbandPhoto.readDone(m_error, m_val);
      break;
    case S_READ_IR:
      m_state = S_READY;
      call IRResource.release();
      signal IRPhoto.readDone(m_error, m_val);
      break;
    default:
      m_state = S_READY;
      break;
    }
  }

  command error_t BroadbandPhoto.read() {
    error_t status;
    if(m_state != S_READY)
      return FAIL;
    status = call BroadbandResource.request();
    return status;
  }

  command error_t IRPhoto.read() {
    error_t status;
    if(m_state != S_READY)
      return FAIL;
    status = call IRResource.request();
    return status;
  }

  event void BroadbandResource.granted() {
    error_t result;
    result = call HplTSL256x.measureCh0();
    if(result != SUCCESS) {
      call BroadbandResource.release();
      signal BroadbandPhoto.readDone(result, 0);
    }
  }

  event void IRResource.granted() {
    error_t result;
    result = call HplTSL256x.measureCh1();
    if(result != SUCCESS) {
      call IRResource.release();
      signal IRPhoto.readDone(result, 0);
    }
  }
  
  async event void HplTSL256x.measureCh0Done(error_t error, uint16_t val) {
    m_state = S_READ_BB;
    m_error = error;
    m_val = val;
    post signalDone_task();
  }

  async event void HplTSL256x.measureCh1Done(error_t error, uint16_t val) {
    m_state = S_READ_IR;
    m_error = error;
    m_val = val;
    post signalDone_task();
  }

  async event void HplTSL256x.setCONTROLDone(error_t error) {}
  async event void HplTSL256x.setTIMINGDone(error_t error) {}
  async event void HplTSL256x.setTHRESHLOWDone(error_t error) {}
  async event void HplTSL256x.setTHRESHHIGHDone(error_t error) {}
  async event void HplTSL256x.setINTERRUPTDone(error_t error) {}
  async event void HplTSL256x.getIDDone(error_t error, uint8_t idval) {}
  async event void HplTSL256x.alertThreshold() {}

}
