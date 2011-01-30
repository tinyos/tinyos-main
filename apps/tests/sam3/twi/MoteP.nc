/*
 * Copyright (c) 2009 Johns Hopkins University.
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
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author JeongGil Ko
 */

#include "sam3utwihardware.h"
#include <color.h>
#include <lcd.h>

module MoteP
{
  uses {
    interface Boot;
    interface Leds;
    interface I2CPacket<TI2CBasicAddr> as TWI;
    interface Resource;
    interface SplitControl as SerialSplitControl;
    interface Packet;
    interface Timer<TMilli>;
    interface Lcd;
    interface Draw;
    interface ResourceConfigure;
    interface Sam3uTwiInternalAddress as InternalAddr;
  }
}

implementation
{
  norace error_t resultError;
  norace uint32_t resultValue;
  uint8_t temp[4];
  uint8_t tempWrite[2];// = 0x60606060; // for 12bit resolution on temp sensor
  uint16_t tempWriteLimit = 0x4680;

  event void Boot.booted()
  {
    while (call SerialSplitControl.start() != SUCCESS);
    tempWrite[0] = 0x60;//70;
    tempWrite[1] = 0x60;//128;
    call Lcd.initialize();
  }

  event void Lcd.initializeDone(error_t err)
  {
    if(err != SUCCESS)
      {
      }
    else
      {
        call Draw.fill(COLOR_RED);
        call Lcd.start();
      }
  }

  task void sample()
  {
    const char *start = "Resource Request!";
    call Draw.fill(COLOR_BLUE);
    call Draw.drawString(10,50,start,COLOR_BLACK);
    call Resource.request();
  }

  event void Lcd.startDone(){
    post sample();
    call Timer.startPeriodic(4*1024U);
  }

  event void SerialSplitControl.startDone(error_t error)
  {
    if (error != SUCCESS) {
      while (call SerialSplitControl.start() != SUCCESS);
    }
  }
  
  event void SerialSplitControl.stopDone(error_t error) {}
  
  volatile twi_mmr_t* MMR = (volatile twi_mmr_t *) (TWI0_BASE_ADDR + 0x4);
  volatile twi_cwgr_t* CWGR = (volatile twi_cwgr_t *) (TWI0_BASE_ADDR + 0x10);

  task void read(){
    const char *start = "TWI!!";
    call Draw.fill(COLOR_GREEN);
    call Draw.fill(COLOR_WHITE);
    call Draw.drawString(10,30,start,COLOR_BLACK);

    call ResourceConfigure.configure();
    call InternalAddr.setInternalAddrSize(1);
    //call InternalAddr.setInternalAddr(1); // 1 byte configuration register
    call InternalAddr.setInternalAddr(1); // temp Limit register
    call TWI.write(1, 0x48, 1, (uint8_t*)&tempWrite);

    call Draw.drawInt(180,50,MMR->bits.dadr,1,COLOR_BLUE);
    call Draw.drawInt(180,70,MMR->bits.mread,1,COLOR_BLUE);
    call Draw.drawInt(180,90,CWGR->bits.cldiv,1,COLOR_BLUE);
  }

  event void Resource.granted(){
    post read();
  }

  task void drawResult(){
    const char *fail = "Done error";
    const char *good = "Done success";
    //call Draw.fill(COLOR_GREEN);
    if (resultError != SUCCESS) {
      atomic call Draw.drawString(10,150,fail,COLOR_BLACK);
    }else{
      call Draw.drawString(10,150,good,COLOR_BLACK);
      call Draw.drawInt(100,170,temp[0],1,COLOR_BLACK);
      call Draw.drawInt(100,190,temp[1],1,COLOR_BLACK);
      call Draw.drawInt(100,210,temp[2],1,COLOR_BLACK);
      call Draw.drawInt(100,230,temp[3],1,COLOR_BLACK);
      call Draw.drawInt(100,250,resultValue,1,COLOR_BLACK);
    }
  }

  task void callRead(){
    call ResourceConfigure.configure();
    call InternalAddr.setInternalAddrSize(1);
    call InternalAddr.setInternalAddr(0); // 2 byte temperature register
    call TWI.read(1, 0x48, 2, (uint8_t*)temp);
  }

  async event void TWI.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data){
    resultError = error;
    resultValue = length;
    post drawResult();
    post callRead();
  }

  async event void TWI.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data)
  {
    resultError = error;
    resultValue = *data;
    post drawResult();
  }
  
  event void Timer.fired() {
    post read();
  }
}
