/*
 * Copyright (c) 2011 University of Utah
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
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include <sam3uusarthardware.h>

module HplSam3uUsart2P{
  provides interface HplSam3uUsartControl as Usart; 
  
  uses{
    interface HplNVICInterruptCntl as USARTInterrupt2;
    interface HplSam3GeneralIOPin as USART_CTS2;
    interface HplSam3GeneralIOPin as USART_RTS2;
    interface HplSam3GeneralIOPin as USART_RXD2;
    interface HplSam3GeneralIOPin as USART_SCK2;
    interface HplSam3GeneralIOPin as USART_TXD2;
    interface HplSam3PeripheralClockCntl as USARTClockControl2;
    interface HplSam3Clock as ClockConfig;
    interface FunctionWrapper as Usart2InterruptWrapper;
    interface Leds;
  }

}
implementation{

#define USART2_BASE_ADDR 0x40098000

  enum{
    S_READ,
    S_WRITE,
    S_IDLE,
  };

  uint8_t STATE;

  void enableInterruptRead(){
    // enables interrupt for read
    volatile usart_ier_t *IER = (volatile usart_ier_t*) (USART2_BASE_ADDR + 0x8);
    usart_ier_t ier = *IER;

    ier.bits.endrx = 1;

    *IER = ier;
  }

  void enableInterruptWrite(){
    // enables interrupt for write    
    volatile usart_ier_t *IER = (volatile usart_ier_t*) (USART2_BASE_ADDR + 0x8);
    usart_ier_t ier = *IER;

    ier.bits.endtx = 1;

    *IER = ier;
  }

  void disableInterrupt(){
    // disable all interrupts
    volatile usart_idr_t *IDR = (volatile usart_idr_t*) (USART2_BASE_ADDR + 0xC);
    usart_idr_t idr = *IDR;
    idr.bits.endtx = 1;
    idr.bits.endrx = 1;
    *IDR = idr;
  }

  command void Usart.init(){

    // init pins and clock

    call USARTInterrupt2.configure(IRQ_PRIO_USART2);
    call USARTInterrupt2.enable();

    call USARTClockControl2.enable();

    call USART_CTS2.disablePioControl();
    call USART_CTS2.selectPeripheralB();

    call USART_RTS2.disablePioControl();
    call USART_RTS2.selectPeripheralB();

    call USART_RXD2.disablePioControl();
    call USART_RXD2.selectPeripheralA();

    call USART_SCK2.disablePioControl();
    call USART_SCK2.selectPeripheralB();

    call USART_TXD2.disablePioControl();
    call USART_TXD2.selectPeripheralA();
  }

  command void Usart.configure(uint32_t mode, uint32_t baudrate){
    //configure control mode and baud rate
    volatile usart_cr_t *CR = (volatile usart_cr_t*) (USART2_BASE_ADDR + 0x0);
    usart_cr_t cr = *CR;

    volatile usart_mr_t *MR = (volatile usart_mr_t*) (USART2_BASE_ADDR + 0x4);
    usart_mr_t mr = *MR;

    volatile usart_brgr_t *BRGR = (volatile usart_brgr_t*) (USART2_BASE_ADDR + 0x20);
    usart_brgr_t brgr = *BRGR;

    uint32_t cd;
    uint32_t masterClock = call ClockConfig.getMainClockSpeed();
    cd = (masterClock * 1000 / baudrate) / 16;

    cr.bits.rsttx = 1;
    cr.bits.rstrx = 1;
    cr.bits.rxdis = 1;
    cr.bits.txdis = 1;
    *CR = cr;

    mr = (usart_mr_t) mode;
    *MR = mr;

    if(mr.bits.sync_cpha == 0 && mr.bits.over == 0){
      // Async mode and no oversampling
      brgr.bits.fp = 0;
      brgr.bits.cd = cd; // check 35.7.9 of sam3u specs for other modes
      *BRGR = brgr;
    }
    STATE = S_IDLE;
  }

  command void Usart.enableTx(){
    volatile usart_cr_t *CR = (volatile usart_cr_t*) (USART2_BASE_ADDR + 0x0);
    usart_cr_t cr;

    cr.bits.txdis = 0;
    *CR = cr;

    cr.bits.txen = 1;
    *CR = cr;
  }

  command void Usart.disableTx(){
    volatile usart_cr_t *CR = (volatile usart_cr_t*) (USART2_BASE_ADDR + 0x0);
    usart_cr_t cr = *CR;
    cr.bits.txdis = 1;
    *CR = cr;
  }

  command void Usart.enableRx(){
    volatile usart_cr_t *CR = (volatile usart_cr_t*) (USART2_BASE_ADDR + 0x0);
    usart_cr_t cr = *CR;
    cr.bits.rxen = 1;
    *CR = cr;
  }

  command void Usart.enableRxInterrupt(){
    enableInterruptRead();
  }

  command void Usart.enableTxInterrupt(){
    enableInterruptWrite();
  }

  command void Usart.disableRx(){
    volatile usart_cr_t *CR = (volatile usart_cr_t*) (USART2_BASE_ADDR + 0x0);
    usart_cr_t cr = *CR;
    cr.bits.rxdis = 1;
    *CR = cr;
  }

  command error_t Usart.write(uint8_t sync, uint16_t data, uint32_t timeout){
    volatile usart_thr_t *THR = (volatile usart_thr_t*) (USART2_BASE_ADDR + 0x1C);
    usart_thr_t thr = *THR;

    call Usart.enableTx();

    thr.bits.txsynh = sync;
    thr.bits.txchr = data;
    *THR = thr;

    // enable interrupts here!

    STATE = S_WRITE;

    enableInterruptWrite();

    return SUCCESS;
  }

  command error_t Usart.read(uint16_t *data, uint32_t timeout){
    volatile usart_csr_t *CSR = (volatile usart_csr_t*) (USART2_BASE_ADDR + 0x14);
    usart_csr_t csr = *CSR;

    volatile usart_rhr_t *RHR = (volatile usart_rhr_t*) (USART2_BASE_ADDR + 0x18);
    usart_rhr_t rhr = *RHR;

    /*
    if(timeout == 0){
      while(csr.bits.rxrdy == 0);
    }else{
      while(csr.bits.txrdy == 0){
	timeout --;
	if(timeout == 0)
	  return FAIL;
      }
    }
    */

    STATE = S_READ;

    *data = rhr.bits.rxchr;
    //&recv_data = data;
    // enable interrupts here!
    enableInterruptRead();

    return SUCCESS;
  }

  command bool Usart.isDataAvailable(){
    volatile usart_csr_t *CSR = (volatile usart_csr_t*) (USART2_BASE_ADDR + 0x14);
    usart_csr_t csr = *CSR;
    if(csr.bits.rxrdy != 0)
      return TRUE;
    else
      return FALSE;
  }

  command void Usart.setIrdaFilter(uint32_t filter){
    volatile usart_if_t *IF = (volatile usart_if_t*) (USART2_BASE_ADDR + 0x4C);
    usart_if_t if_usart = *IF;

    if_usart = (usart_if_t) filter;
    *IF = if_usart;
  }

  command error_t Usart.putChar(uint8_t sync, uint16_t data){

    volatile usart_csr_t *CSR = (volatile usart_csr_t*) (USART2_BASE_ADDR + 0x14);
    usart_csr_t csr = *CSR;

    volatile usart_thr_t *THR = (volatile usart_thr_t*) (USART2_BASE_ADDR + 0x1C);
    usart_thr_t thr = *THR;

    while(csr.bits.txempty == 0);

    thr.bits.txsynh = sync;
    thr.bits.txchr = data;
    *THR = thr;

    csr = *CSR;
    while(csr.bits.txempty == 0);

    STATE = S_WRITE;

    // enable interrupts here!
    enableInterruptWrite();

    return SUCCESS;
  }

  command bool Usart.isRxReady(){
    volatile usart_csr_t *CSR = (volatile usart_csr_t*) (USART2_BASE_ADDR + 0x14);
    usart_csr_t csr = *CSR;
    if(csr.bits.rxrdy != 0)
      return FALSE;
    else
      return TRUE;
  }

  command error_t Usart.getChar(uint16_t *data){
    
    volatile usart_csr_t *CSR = (volatile usart_csr_t*) (USART2_BASE_ADDR + 0x14);
    usart_csr_t csr = *CSR;

    volatile usart_rhr_t *RHR = (volatile usart_rhr_t*) (USART2_BASE_ADDR + 0x18);
    usart_rhr_t rhr = *RHR;

    while(csr.bits.rxrdy == 0);

    *data = rhr.bits.rxchr;

    STATE = S_READ;

    // enable interrupts here!
    enableInterruptRead();

    return SUCCESS;
  }


  __attribute__((interrupt)) void Usart1IrqHandler() @C() @spontaneous(){

    uint8_t recv_data;

    atomic {
      call Usart2InterruptWrapper.preamble();
      disableInterrupt();
    }

      if(STATE == S_WRITE && CSR->bits.txrdy){
	signal Usart.writeDone(); // tx done
      }else if(CSR->bits.rxrdy){
	atomic recv_data = (uint8_t) RHR->bits.rxchr;
	signal Usart.readDone(recv_data);
      }

    atomic {
      STATE = S_IDLE;
      enableInterruptRead();
      call Usart2InterruptWrapper.postamble();
    }
  }

  async event void ClockConfig.mainClockChanged() {};
 default event void Usart.writeDone(){}
 default event void Usart.readDone(uint8_t data){}


}
