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
 * This example validates that the values for the PDC registers are correctly written
 *
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
    interface HplSam3uPdc as PDC;
    interface HplSam3uPeripheralClockCntl as ClockControl;
  }
}

implementation{

  uint16_t msg = 48;
  uint16_t msg2 = 0;
  uint8_t channel = 0;
  uint32_t addr = 0;

  task void setup();
  task void tx();

  event void Boot.booted()
  {
    call Lcd.initialize();
    call ClockControl.enable();
    call Timer.startPeriodic(1024);
  }

  event void Lcd.initializeDone(error_t err)
  {
    if(err != SUCCESS)
      {
      }
    else
      {
	call Draw.fill(COLOR_GREEN);
	call Lcd.start();
      }
  }

  event void Lcd.startDone(){
  }

  event void SerialSplitControl.startDone(error_t error)
  {
    if (error != SUCCESS) {
      while (call SerialSplitControl.start() != SUCCESS);
    }else{
    }
  }
  
  event void SerialSplitControl.stopDone(error_t error) {}

  uint8_t tmp_s = 88;
  uint8_t tmp_d = 0;
  
  task void setup(){    
    post tx();
  }
  uint8_t temp = 99;
  uint8_t temp_d = 0;
  bool status;

  enum {
    UART_BASE = 0x400E0600,
    USART0_BASE = 0x40090000,
    USART1_BASE = 0x40094000,
    USART2_BASE = 0x40098000,
    USART3_BASE = 0x4009C000,
    TWI0_BASE = 0x40084000,
    TWI1_BASE = 0x40088000,
    PWM_BASE = 0x4008C000
  };

  task void tx()
  {
    volatile periph_rpr_t* RPR = (volatile periph_rpr_t*) (TWI0_BASE + 0x100);
    volatile periph_rcr_t* RCR = (volatile periph_rcr_t*) (TWI0_BASE + 0x104);
    volatile periph_tpr_t* TPR = (volatile periph_tpr_t*)  (TWI0_BASE + 0x108);
    volatile periph_tcr_t* TCR = (volatile periph_tcr_t*)  (TWI0_BASE + 0x10C);
    volatile periph_ptcr_t* PTCR = (volatile periph_ptcr_t*) (TWI0_BASE + 0x120);
    volatile periph_ptsr_t* PTSR = (volatile periph_ptsr_t*)  (TWI0_BASE + 0x124);

    call PDC.setRxPtr((uint32_t*)&temp);
    call PDC.setTxPtr((uint32_t*)&temp_d);
    call PDC.setTxCounter(10);
    call PDC.setRxCounter(10);
    call PDC.enablePdcRx();

    call Draw.fill(COLOR_WHITE);
    call Leds.led1Toggle();
    call Draw.drawInt(180,10,RPR->bits.rxptr,1,COLOR_BLUE);
    call Draw.drawInt(180,30,(uint32_t)&temp,1,COLOR_RED);
    call Draw.drawInt(180,50,TPR->bits.txptr,1,COLOR_BLUE);
    call Draw.drawInt(180,70,(uint32_t)&temp_d,1,COLOR_GREEN);
    call Draw.drawInt(100,90,RCR->bits.rxctr,1,COLOR_RED);
    call Draw.drawInt(100,110,TCR->bits.txctr,1,COLOR_RED);
    call Draw.drawInt(100,130,PTCR->bits.rxten,1,COLOR_RED);
    call Draw.drawInt(100,150,PTSR->bits.rxten,1,COLOR_RED);

    /*For testing*/
    ADC12B->mr.bits.startup = 104;
    call Draw.drawInt(100,210,ADC12B->mr.bits.startup,1,COLOR_BLUE);
  }

  event void Timer.fired() {
    post tx();
  }

}
