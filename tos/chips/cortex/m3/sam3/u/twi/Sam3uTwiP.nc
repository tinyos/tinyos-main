/*
* Copyright (c) 2009 Johns Hopkins University.
* Copyright (c) 2010 CSIRO Australia
* All rights reserved.
*
* Permission to use, copy, modify, and distribute this software and its
* documentation for any purpose, without fee, and without written
* agreement is hereby granted, provided that the above copyright
* notice, the (updated) modification history and the author appear in
* all copies of this source code.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS  `AS IS'
* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED  TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR  PURPOSE
* ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR  CONTRIBUTORS
* BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE,  DATA,
* OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
* CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR  OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
* THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * @author JeongGil Ko
 * @author Kevin Klues
 */

#include <I2C.h>
#include "sam3utwihardware.h"

generic module Sam3uTwiP() {
  provides {
    interface I2CPacket<TI2CBasicAddr> as TwiBasicAddr;
    interface ResourceConfigure[uint8_t id];
    interface Sam3uTwiInternalAddress as InternalAddr;
  }
  uses {
    interface BusyWait<TMicro, uint16_t>;
    interface Sam3uTwiConfigure[ uint8_t id ];
    interface HplSam3uTwiInterrupt as TwiInterrupt;  
    interface HplSam3uTwi as HplTwi;
    interface Alarm<TMicro, uint16_t>;
    interface Leds;
  }
}
implementation {

  enum {
    IDLE_STATE,
    TX_STATE,
    RX_STATE,
  };
  norace uint8_t STATE = IDLE_STATE;

  const sam3u_twi_union_config_t sam3u_twi_default_config = {
  cldiv: 0,
  chdiv: 0,
  ckdiv: 0
  };

  norace i2c_flags_t FLAGS;
  norace uint16_t ADDR;
  norace uint8_t INIT_LEN;
  norace uint8_t* INIT_BUFFER;
  norace uint8_t READ;
  norace uint8_t WRITE;
  norace uint8_t IASIZE = 0;
  norace uint32_t INTADDR = 0;

  async command error_t InternalAddr.setInternalAddr(uint32_t intAddr, uint8_t size){
    if(STATE == IDLE_STATE) {
      IASIZE = size;
      INTADDR = intAddr;
      return SUCCESS;
    }
    return FAIL;
  }

  async command void ResourceConfigure.configure[ uint8_t id ]() {
    const sam3u_twi_union_config_t* ONE config;
    config  = call Sam3uTwiConfigure.getConfig[id]();
    call HplTwi.configureTwi(config);
  }

  async command void ResourceConfigure.unconfigure[ uint8_t id ]() {
    // set a parameter CLEAR!
    call HplTwi.configureTwi(&sam3u_twi_default_config);
  }

  async command error_t TwiBasicAddr.read(i2c_flags_t flags, uint16_t addr, uint8_t len, uint8_t* buf ) {
    atomic {
      if(STATE != IDLE_STATE)
        return EBUSY;
      STATE = RX_STATE;
    }
    FLAGS = flags;
    ADDR = addr;
    INIT_LEN = len;
    INIT_BUFFER = buf;
    READ = 0;

    call HplTwi.getStatus();
    if(FLAGS & I2C_START) {
      call HplTwi.init();
      call HplTwi.disSlave();
      call HplTwi.setMaster();
      call HplTwi.addrSize(IASIZE);
      call HplTwi.setDeviceAddr((uint8_t)addr);
      if(IASIZE > 0)
        call HplTwi.setInternalAddr(INTADDR);
      call HplTwi.setDirection(1); // read direction
      call HplTwi.setStart();
    }
    if(INIT_LEN == 1)
      call HplTwi.setStop();
    call HplTwi.setIntNack();
    call HplTwi.setIntRxReady();
    return SUCCESS;
  }

  async command error_t TwiBasicAddr.write(i2c_flags_t flags, uint16_t addr, uint8_t len, uint8_t* buf ) {
    atomic {
      if(STATE != IDLE_STATE)
        return EBUSY;
      STATE = TX_STATE;
    }
    FLAGS = flags;
    ADDR = addr;
    INIT_LEN = len;
    INIT_BUFFER = buf;
    WRITE = 0;

    call HplTwi.getStatus();
    if(FLAGS & I2C_START) {
      call HplTwi.init();
      call HplTwi.disSlave();
      call HplTwi.setMaster();
      call HplTwi.addrSize(IASIZE);
      call HplTwi.setDeviceAddr((uint8_t)addr);
      if(IASIZE > 0)
        call HplTwi.setInternalAddr(INTADDR);
      call HplTwi.setDirection(0); // write direction
    }
    call HplTwi.setTxReg((uint8_t)INIT_BUFFER[WRITE]);
    call HplTwi.setIntTxReady();  
    return SUCCESS;
  }

  void transferComplete(error_t error) {
    if(STATE == TX_STATE) {
      atomic STATE = IDLE_STATE;
      signal TwiBasicAddr.writeDone(error, ADDR, INIT_LEN, INIT_BUFFER);
    }
    else if(STATE == RX_STATE) {
      atomic STATE = IDLE_STATE;
      signal TwiBasicAddr.readDone(error, ADDR, INIT_LEN, INIT_BUFFER);
    }
  }

  void handleInterrupt(twi_sr_t *status) {
    call Leds.led2Toggle();
    if(call HplTwi.getNack(status)) {
      transferComplete(FAIL);
    }
  
    else if(call HplTwi.getRxReady(status)) {
      INIT_BUFFER[READ] = call HplTwi.readRxReg(); // read out rx buffer     
      READ++;
      if(READ == INIT_LEN) {
        call HplTwi.setIntTxComp();
        return;
      }

      if(READ == (INIT_LEN-1)) {
        if(FLAGS & I2C_STOP) {
          call HplTwi.setStop();
        }
      }
      call HplTwi.setIntRxReady();
    }

    else if(call HplTwi.getTxCompleted(status)) {
      transferComplete(SUCCESS);
    }

    else if(call HplTwi.getTxReady(status)) {
      WRITE++; 
      if(WRITE == INIT_LEN) {
        if(FLAGS & I2C_STOP)
          call HplTwi.setStop();		        
        call HplTwi.setIntTxComp();
      }     
      else {
        call HplTwi.setTxReg((uint8_t)INIT_BUFFER[WRITE]);      
        call HplTwi.setIntTxReady();
      }
    }

  }
  async event void TwiInterrupt.fired() {
    twi_sr_t status;
    call HplTwi.disableAllInterrupts();

    /* NACK errata handling */
    /* Do not poll the TWI_SR */
    /* Wait 3 x 9 TWCK pulse (max) 2 if IADRR not used, before reading TWI_SR */
    /* From 400Khz down to 1Khz, the time to wait will be in us range.*/
    // TODO: Fixme
    // The delay used below is specific fo 100KHz, ned to change it to depend on 
    //  the clock frequency actually specified in the configuration
    call HplTwi.disableClock();
    //call Alarm.start(160);
    call BusyWait.wait(160); 
    status = call HplTwi.getStatus();
    call HplTwi.enableClock();
    handleInterrupt(&status);
  }
  async event void Alarm.fired() {
    twi_sr_t status;
    call Leds.led1On();
    status = call HplTwi.getStatus();
    call HplTwi.enableClock();
    handleInterrupt(&status);
  }

  default async command const sam3u_twi_union_config_t* Sam3uTwiConfigure.getConfig[uint8_t id]() {
    return &sam3u_twi_default_config;
  }
  default async event void TwiBasicAddr.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data){}
  default async event void TwiBasicAddr.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data){}
}
