/*
 * Copyright (c) 2004, Technische Universitat Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitat Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2006-12-12 18:23:13 $
 * ========================================================================
 */

 /**
 * Tda5250RegistersP Module
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 */

module Tda5250RegistersP {
  provides {
    interface Init;
    interface Tda5250WriteReg<TDA5250_REG_TYPE_CONFIG>      as CONFIG;
    interface Tda5250WriteReg<TDA5250_REG_TYPE_FSK>         as FSK;
    interface Tda5250WriteReg<TDA5250_REG_TYPE_XTAL_TUNING> as XTAL_TUNING;
    interface Tda5250WriteReg<TDA5250_REG_TYPE_LPF>         as LPF;
    interface Tda5250WriteReg<TDA5250_REG_TYPE_ON_TIME>     as ON_TIME;
    interface Tda5250WriteReg<TDA5250_REG_TYPE_OFF_TIME>    as OFF_TIME;
    interface Tda5250WriteReg<TDA5250_REG_TYPE_COUNT_TH1>   as COUNT_TH1;
    interface Tda5250WriteReg<TDA5250_REG_TYPE_COUNT_TH2>   as COUNT_TH2;
    interface Tda5250WriteReg<TDA5250_REG_TYPE_RSSI_TH3>    as RSSI_TH3;
    interface Tda5250WriteReg<TDA5250_REG_TYPE_RF_POWER>    as RF_POWER;
    interface Tda5250WriteReg<TDA5250_REG_TYPE_CLK_DIV>     as CLK_DIV;
    interface Tda5250WriteReg<TDA5250_REG_TYPE_XTAL_CONFIG> as XTAL_CONFIG;
    interface Tda5250WriteReg<TDA5250_REG_TYPE_BLOCK_PD>    as BLOCK_PD;
    interface Tda5250ReadReg<TDA5250_REG_TYPE_STATUS>       as STATUS;
    interface Tda5250ReadReg<TDA5250_REG_TYPE_ADC>          as ADC;
  }
  uses {
        interface Tda5250RegComm;
        interface Pot;
        interface GeneralIO as ENTDA;
  }
}
implementation {

   error_t writeByte(uint8_t addr, uint16_t data) {
     error_t result;
     call ENTDA.clr();
     result = call Tda5250RegComm.writeByte(addr, data);
     call ENTDA.set();
     return result;
   }
   error_t writeWord(uint8_t addr, uint16_t data) {
     error_t result;
     call ENTDA.clr();
     result = call Tda5250RegComm.writeWord(addr, data);
     call ENTDA.set();
     return result;
   }
   uint8_t readByte(uint8_t addr) {
     uint8_t result;
     call ENTDA.clr();
     result = call Tda5250RegComm.readByte(addr);
     call ENTDA.set();
     return result;
   }

   command error_t Init.init() {
     // setting pins to output
     call ENTDA.makeOutput();

     // initializing pin values
     call ENTDA.set();

    return SUCCESS;
   }

   async command error_t CONFIG.set(uint16_t data) {
     return writeWord(TDA5250_REG_ADDR_CONFIG, data);
   };
   async command error_t FSK.set(uint16_t data) {
     return writeWord(TDA5250_REG_ADDR_FSK, data);
   };
   async command error_t XTAL_TUNING.set(uint16_t data) {
     return writeWord(TDA5250_REG_ADDR_XTAL_TUNING, data);
   };
   async command error_t LPF.set(uint8_t data) {
     return writeByte(TDA5250_REG_ADDR_LPF, data);
   };
   async command error_t ON_TIME.set(uint16_t data) {
     return writeWord(TDA5250_REG_ADDR_ON_TIME, data);
   };
   async command error_t OFF_TIME.set(uint16_t data) {
     return writeWord(TDA5250_REG_ADDR_OFF_TIME, data);
   };
   async command error_t COUNT_TH1.set(uint16_t data) {
     return writeWord(TDA5250_REG_ADDR_COUNT_TH1, data);
   };
   async command error_t COUNT_TH2.set(uint16_t data) {
     return writeWord(TDA5250_REG_ADDR_COUNT_TH2, data);
   };
   async command error_t RSSI_TH3.set(uint8_t data) {
     return writeByte(TDA5250_REG_ADDR_RSSI_TH3, data);
   };
   async command error_t RF_POWER.set(uint8_t data) {
     return call Pot.set(data);
   };
   async command error_t CLK_DIV.set(uint8_t data) {
     return writeByte(TDA5250_REG_ADDR_CLK_DIV, data);
   };
   async command error_t XTAL_CONFIG.set(uint8_t data) {
     return writeByte(TDA5250_REG_ADDR_XTAL_CONFIG, data);
   };
   async command error_t BLOCK_PD.set(uint16_t data) {
     return writeWord(TDA5250_REG_ADDR_BLOCK_PD, data);
   };
   async command uint8_t STATUS.get() {
     return readByte(TDA5250_REG_ADDR_STATUS);
   };
   async command uint8_t ADC.get() {
     return readByte(TDA5250_REG_ADDR_ADC);
   };
}

