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
  norace uint8_t resultError;
  norace uint32_t resultValue;
  uint8_t rx_len,tx_len;
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
    call Timer.startPeriodic(2*1024U);
  }

  event void SerialSplitControl.startDone(error_t error)
  {
    if (error != SUCCESS) {
      while (call SerialSplitControl.start() != SUCCESS);
    }
  }
  
  event void SerialSplitControl.stopDone(error_t error) {}

  volatile twi_mmr_t* MMR = (volatile twi_mmr_t *) (TWI0_BASE_ADDR + 0x4);
  volatile twi_sr_t* SR = (volatile twi_sr_t *) (TWI0_BASE_ADDR + 0x20);
  volatile twi_cwgr_t* CWGR = (volatile twi_cwgr_t *) (TWI0_BASE_ADDR + 0x10);
  volatile periph_ptsr_t* PTSR = (volatile periph_ptsr_t *) (0x40084000 + 0x124);
  volatile periph_rpr_t* RPR = (volatile periph_rpr_t *) (0x40084000 + 0x100);
  volatile periph_rcr_t* RCR = (volatile periph_rcr_t *) (0x40084000 + 0x104);
  volatile periph_tcr_t* TCR = (volatile periph_tcr_t *) (0x40084000 + 0x10C);
  uint8_t count = 0;

  task void read(){
    call Draw.fill(COLOR_WHITE);
    
    call Draw.drawInt(100,10,SR->bits.txcomp,1,COLOR_BLUE);
    call Draw.drawInt(100,30,SR->bits.rxrdy,1,COLOR_RED);
    call Draw.drawInt(100,50,SR->bits.txrdy,1,COLOR_BLUE);
    call Draw.drawInt(100,70,SR->bits.svread,1,COLOR_BLUE);
    call Draw.drawInt(100,90,SR->bits.svacc,1,COLOR_BLUE);
    call Draw.drawInt(100,110,SR->bits.gacc,1,COLOR_BLUE);
    call Draw.drawInt(100,130,SR->bits.ovre,1,COLOR_BLUE);
    call Draw.drawInt(100,150,SR->bits.nack,1,COLOR_BLUE);
    call Draw.drawInt(100,170,SR->bits.arblst,1,COLOR_BLUE);
    call Draw.drawInt(100,190,SR->bits.sclws,1,COLOR_BLUE);
    call Draw.drawInt(100,210,SR->bits.eosacc,1,COLOR_BLUE);
    call Draw.drawInt(100,230,SR->bits.endrx,1,COLOR_BLACK);
    call Draw.drawInt(100,250,SR->bits.endtx,1,COLOR_BLUE);
    call Draw.drawInt(100,270,SR->bits.rxbuff,1,COLOR_BLUE);
    call Draw.drawInt(100,290,SR->bits.txbufe,1,COLOR_BLUE);

    count++;

    call ResourceConfigure.configure();
    call InternalAddr.setInternalAddrSize(1);
    call InternalAddr.setInternalAddr(1); // sensor config register
    call TWI.write(1, 0x48, 1, (uint8_t*)&tempWrite);

    call Draw.drawInt(140,230,TCR->bits.txctr,1,COLOR_BLUE);
    call Draw.drawInt(140,250,SR->bits.endtx,1,COLOR_BLUE);
    call Draw.drawInt(140,270,SR->bits.txbufe,1,COLOR_BLUE);

    /*
    call Draw.drawInt(180,70,MMR->bits.dadr,1,COLOR_BLUE);
    call Draw.drawInt(180,90,MMR->bits.mread,1,COLOR_BLUE);
    call Draw.drawInt(180,110,CWGR->bits.cldiv,1,COLOR_BLUE);
    call Draw.drawInt(180,130,PTSR->bits.rxten,1,COLOR_BLUE);
    call Draw.drawInt(180,150,RPR->bits.rxptr,1,COLOR_BLUE);
    call Draw.drawInt(180,170,RCR->bits.rxctr,1,COLOR_BLUE);

    call Draw.drawInt(180,230,SR->bits.endrx,1,COLOR_BLUE);
    call Draw.drawInt(100,250,temp[0],1,COLOR_BLACK);
    call Draw.drawInt(100,270,temp[1],1,COLOR_BLACK);
    */
  }

  event void Resource.granted(){
    post read();
  }

  task void drawResult(){
    const char *fail = "Done error";
    //call Draw.fill(COLOR_GREEN);
    if (0/*resultError != SUCCESS*/) {
      atomic call Draw.drawString(10,70,fail,COLOR_BLACK);
    }else{
      call Draw.drawInt(180,10,SR->bits.txcomp,1,COLOR_BLUE);
      call Draw.drawInt(180,30,SR->bits.rxrdy,1,COLOR_RED);
      call Draw.drawInt(180,50,SR->bits.txrdy,1,COLOR_BLUE);
      call Draw.drawInt(180,70,SR->bits.svread,1,COLOR_BLUE);
      call Draw.drawInt(180,90,SR->bits.svacc,1,COLOR_BLUE);
      call Draw.drawInt(180,110,SR->bits.gacc,1,COLOR_BLUE);
      call Draw.drawInt(180,130,SR->bits.ovre,1,COLOR_BLUE);
      call Draw.drawInt(180,150,SR->bits.nack,1,COLOR_BLUE);
      call Draw.drawInt(180,170,SR->bits.arblst,1,COLOR_BLUE);
      call Draw.drawInt(180,190,SR->bits.sclws,1,COLOR_BLUE);
      call Draw.drawInt(180,210,SR->bits.eosacc,1,COLOR_BLUE);
      call Draw.drawInt(180,230,SR->bits.endrx,1,COLOR_BLACK);
      call Draw.drawInt(180,250,SR->bits.endtx,1,COLOR_BLUE);
      call Draw.drawInt(180,270,SR->bits.rxbuff,1,COLOR_BLUE);
      call Draw.drawInt(180,290,SR->bits.txbufe,1,COLOR_BLUE);

      call Draw.drawInt(140,170,TCR->bits.txctr,1,COLOR_RED);
      call Draw.drawInt(140,190,PTSR->bits.txten,1,COLOR_BLACK);

      call Draw.drawInt(30,180,resultValue,1,COLOR_DARKCYAN);
      call Draw.drawInt(30,200,resultError,1,COLOR_DARKCYAN);
      //call Draw.drawInt(30,100,temp[0],1,COLOR_BLACK);
      //call Draw.drawInt(30,120,temp[1],1,COLOR_BLACK);
    }
  }

  task void readread(){ 
    call Draw.drawInt(30,80,rx_len,1,COLOR_DARKGREEN);
    call Draw.drawInt(30,100,temp[0],1,COLOR_DARKGREEN);
    call Draw.drawInt(30,120,temp[1],1,COLOR_DARKGREEN);
    call Draw.drawInt(30,140,temp[2],1,COLOR_DARKGREEN);
    call Draw.drawInt(30,160,temp[3],1,COLOR_DARKGREEN);
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
    //resultError = error;
    //resultValue = *data;
    //post drawResult();
    rx_len=length;
    post readread();
  }

  event void Timer.fired() {
    post read();
  }
}
