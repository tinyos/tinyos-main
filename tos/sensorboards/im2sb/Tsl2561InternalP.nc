/* $Id: Tsl2561InternalP.nc,v 1.3 2006-11-07 19:31:27 scipio Exp $ */
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
module Tsl2561InternalP {
  provides interface Init;
  provides interface HplTSL256x[uint8_t id];
  uses interface Init as SubInit;
  uses interface HplTSL256x as ToHPLC;
  uses interface GpioInterrupt as InterruptAlert;
}

implementation {
  uint8_t currentId;
  
  command error_t Init.init() {
    call SubInit.init();
    // The Intel Mote 2 Sensorboard multiplexes the TSL interrupt through a NAND
    // gate.  Need to overrid the edge trigger from the driver default
    call InterruptAlert.enableRisingEdge();
    return SUCCESS;
  }

  command error_t HplTSL256x.measureCh0[uint8_t id]() {
    currentId = id;
    return call ToHPLC.measureCh0();
  }
  command error_t HplTSL256x.measureCh1[uint8_t id]() {
    currentId = id;
    return call ToHPLC.measureCh1();
  }
  command error_t HplTSL256x.setCONTROL[uint8_t id](uint8_t val) {
    currentId = id;
    return call ToHPLC.setCONTROL(val);
  }
  command error_t HplTSL256x.setTIMING[uint8_t id](uint8_t val) {
    currentId = id;
    return call ToHPLC.setTIMING(val);
  }
  command error_t HplTSL256x.setTHRESHLOW[uint8_t id](uint16_t val) {
    currentId = id;
    return call ToHPLC.setTHRESHLOW(val);
  }
  command error_t HplTSL256x.setTHRESHHIGH[uint8_t id](uint16_t val) {
    currentId = id;
    return call ToHPLC.setTHRESHHIGH(val);
  }
  command error_t HplTSL256x.setINTERRUPT[uint8_t id](uint8_t val) {
    currentId = id;
    return call ToHPLC.setINTERRUPT(val);
  }
  command error_t HplTSL256x.getID[uint8_t id]() {
    currentId = id;
    return call ToHPLC.getID();
  }
  
  async event void ToHPLC.measureCh0Done(error_t result, uint16_t val) {
    signal HplTSL256x.measureCh0Done[currentId](result, val);
  }
  async event void ToHPLC.measureCh1Done(error_t result, uint16_t val) {
    signal HplTSL256x.measureCh1Done[currentId](result, val);
  }
  async event void ToHPLC.setCONTROLDone(error_t error) {
    signal HplTSL256x.setCONTROLDone[currentId](error);
  }
  async event void ToHPLC.setTIMINGDone(error_t error) {
    signal HplTSL256x.setTIMINGDone[currentId](error);
  }
  async event void ToHPLC.setTHRESHLOWDone(error_t error) {
    signal HplTSL256x.setTHRESHLOWDone[currentId](error);
  }
  async event void ToHPLC.setTHRESHHIGHDone(error_t error) {
    signal HplTSL256x.setTHRESHHIGHDone[currentId](error);
  }
  async event void ToHPLC.setINTERRUPTDone(error_t error) {
    signal HplTSL256x.setINTERRUPTDone[currentId](error);
  }
  async event void ToHPLC.getIDDone(error_t error, uint8_t idval) {
    signal HplTSL256x.getIDDone[currentId](error, idval);
  }
  async event void ToHPLC.alertThreshold() {
    signal HplTSL256x.alertThreshold[currentId]();
  }

  async event InterruptAlert.fired() {}

  default async event void HplTSL256x.measureCh0Done[uint8_t id]( error_t error, uint16_t val ){ return; }
  default async event void HplTSL256x.measureCh1Done[uint8_t id]( error_t error, uint16_t val ){ return; }
  default async event void HplTSL256x.setCONTROLDone[uint8_t id]( error_t error ){ return; }
  default async event void HplTSL256x.setTIMINGDone[uint8_t id](error_t error){ return; }
  default async event void HplTSL256x.setTHRESHLOWDone[uint8_t id](error_t error){ return;} 
  default async event void HplTSL256x.setTHRESHHIGHDone[uint8_t id](error_t error){ return; }
  default async event void HplTSL256x.setINTERRUPTDone[uint8_t id](error_t error){ return;} 
  default async event void HplTSL256x.getIDDone[uint8_t id](error_t error, uint8_t idval){ return; }
  default async event void HplTSL256x.alertThreshold[uint8_t id](){ return; }
}
