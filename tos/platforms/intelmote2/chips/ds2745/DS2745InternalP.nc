/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arched Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * 
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @version $Revision: 1.4 $ $Date: 2006-12-12 18:23:42 $
 */

module DS2745InternalP {
  provides interface HplDS2745[uint8_t id];
  uses interface HplDS2745 as ToHPLC;
}

implementation {
  uint8_t currentId;
  
  command error_t HplDS2745.setConfig[uint8_t id](uint8_t val) {
    currentId = id;
    return call ToHPLC.setConfig(val);
  }
  command error_t HplDS2745.measureTemperature[uint8_t id]() {
    currentId = id;
    return call ToHPLC.measureTemperature();
  }
  command error_t HplDS2745.measureVoltage[uint8_t id]() {
    currentId = id;
    return call ToHPLC.measureVoltage();
  }
  command error_t HplDS2745.measureCurrent[uint8_t id]() {
    currentId = id;
    return call ToHPLC.measureCurrent();
  }
  command error_t HplDS2745.measureAccCurrent[uint8_t id]() {
    currentId = id;
    return call ToHPLC.measureAccCurrent();
  }
  command error_t HplDS2745.setOffsetBias[uint8_t id](int8_t val) {
    currentId = id;
    return call ToHPLC.setOffsetBias(val);
  }
  command error_t HplDS2745.setAccOffsetBias[uint8_t id](int8_t val) {
    currentId = id;
    return call ToHPLC.setAccOffsetBias(val);
  }
  
  async event void ToHPLC.setConfigDone(error_t error) {
    signal HplDS2745.setConfigDone[currentId](error);
  }
  async event void ToHPLC.measureTemperatureDone(error_t result, uint16_t val) {
    signal HplDS2745.measureTemperatureDone[currentId](result, val);
  }
  async event void ToHPLC.measureVoltageDone(error_t result, uint16_t val) {
    signal HplDS2745.measureVoltageDone[currentId](result, val);
  }
  async event void ToHPLC.measureCurrentDone(error_t result, uint16_t val) {
    signal HplDS2745.measureCurrentDone[currentId](result, val);
  }
  async event void ToHPLC.measureAccCurrentDone(error_t result, uint16_t val) {
    signal HplDS2745.measureAccCurrentDone[currentId](result, val);
  }
  async event void ToHPLC.setOffsetBiasDone(error_t error) {
    signal HplDS2745.setOffsetBiasDone[currentId](error);
  }
  async event void ToHPLC.setAccOffsetBiasDone(error_t error) {
    signal HplDS2745.setAccOffsetBiasDone[currentId](error);
  }

  default async event void HplDS2745.setConfigDone[uint8_t id]( error_t error ){ return; }
  default async event void HplDS2745.measureTemperatureDone[uint8_t id]( error_t error, uint16_t val ){ return; }
  default async event void HplDS2745.measureVoltageDone[uint8_t id]( error_t error, uint16_t val ){ return; }
  default async event void HplDS2745.measureCurrentDone[uint8_t id]( error_t error, uint16_t val ){ return; }
  default async event void HplDS2745.measureAccCurrentDone[uint8_t id]( error_t error, uint16_t val ){ return; }
  default async event void HplDS2745.setOffsetBiasDone[uint8_t id]( error_t error ){ return; }
  default async event void HplDS2745.setAccOffsetBiasDone[uint8_t id](error_t error){ return; }

}


