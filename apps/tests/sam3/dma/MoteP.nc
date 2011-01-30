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


#include "sam3uDmahardware.h"
#include "sam3updchardware.h"
#include "sam3uadc12bhardware.h"
#include "sam3umatrixhardware.h"
#include <color.h>
#include <lcd.h>

module MoteP
{
  uses {
    interface Boot;
    interface Leds;
    interface SplitControl as SerialSplitControl;
    interface Packet;
    interface Timer<TMilli>;
    interface Lcd;
    interface Draw;
    interface Sam3uDmaControl as DMAControl;
    interface Sam3uDmaChannel as Dma;
  }
}

implementation{

  uint16_t msg = 48;
  uint16_t msg2 = 0;
  uint8_t channel = 0;

  task void setup();
  task void tx();

  event void Boot.booted(){
    call Lcd.initialize();
    call DMAControl.init();
    call DMAControl.setArbitor(TRUE);
    post setup();
    post tx();
    call Timer.startPeriodic(1024);
  }

  event void Lcd.initializeDone(error_t err){
    if(err != SUCCESS){
    }else{
      call Draw.fill(COLOR_GREEN);
      call Lcd.start();
    }
  }
  

  uint8_t tmp_s = 88;
  uint8_t tmp_d = 0;
  
  task void setup(){    
    call Dma.setupTransfer(0, (uint32_t*)&tmp_s, (uint32_t*)&tmp_d, 1 , 0, 0, 0, 0, 1, 1, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    //post tx();
  }

  task void tx(){
    call Draw.fill(COLOR_WHITE);
    call Draw.drawInt(100,80,tmp_s,1,COLOR_RED);
    call Draw.drawInt(150,80,tmp_d,1,COLOR_RED);

    tmp_d = 0;

    call Leds.led1Toggle();

    call Dma.startTransfer(0);
    call Draw.drawInt(100,100,tmp_s,1,COLOR_RED);
    call Draw.drawInt(150,100,tmp_d,1,COLOR_RED);
  }

  task void repeat(){
    call Draw.fill(COLOR_WHITE);
    call Draw.drawInt(100,80,tmp_s,1,COLOR_RED);
    call Draw.drawInt(150,80,tmp_d,1,COLOR_RED);
    tmp_s++;
    tmp_d = 0;
    call Draw.drawInt(100,100,tmp_s,1,COLOR_RED);
    call Draw.drawInt(150,100,tmp_d,1,COLOR_RED);

    call Leds.led1Toggle();

    call Dma.repeatTransfer((uint32_t*)&tmp_s, (uint32_t*)&tmp_d, 1, 0);
  }
  async event void Dma.transferDone(error_t success){
    call Leds.led0Toggle();
  }

  event void Timer.fired() {
    post repeat();
  }

  event void Lcd.startDone(){}
  event void SerialSplitControl.startDone(error_t error){}
  event void SerialSplitControl.stopDone(error_t error) {}
}
