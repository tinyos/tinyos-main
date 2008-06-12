/*
 * Copyright (c) 2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCH ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * @author Alec Woo <awoo@archrock.com>
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.1 $ $Date: 2008-06-12 14:02:24 $
 */

/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */

/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */

/** 
 * Private component of the Atmega1281 serial port HPL.
 *
 * @author Martin Turon <mturon@xbow.com>
 * @author David Gay
 * @author Janos Sallai <janos.sallai@vanderbilt.edu>
 */

#include <Atm128Uart.h>

module HplAtm128UartP {
  
  provides interface Init as Uart0Init;
  provides interface StdControl as Uart0TxControl;
  provides interface StdControl as Uart0RxControl;
  provides interface HplAtm128Uart as HplUart0;
    
  provides interface Init as Uart1Init;
  provides interface StdControl as Uart1TxControl;
  provides interface StdControl as Uart1RxControl;
  provides interface HplAtm128Uart as HplUart1;
  
  uses interface Atm128Calibrate;
  uses interface McuPowerState;
  
  uses interface PlatformInterrupt;
}
implementation {
  
  //=== Uart Init Commands. ====================================
  command error_t Uart0Init.init() {
    Atm128UartMode_t    mode;
    Atm128UartStatus_t  stts;
    Atm128UartControl_t ctrl;
    uint16_t ubrr0;

    ctrl.bits = (struct Atm128_UCSRB_t) {rxcie:0, txcie:0, rxen:0, txen:0};
    stts.bits = (struct Atm128_UCSRA_t) {u2x:1};
    mode.bits = (struct Atm128_UCSRC_t) {ucsz:ATM128_UART_DATA_SIZE_8_BITS};

    ubrr0 = call Atm128Calibrate.baudrateRegister(PLATFORM_BAUDRATE);
    UBRR0L = ubrr0;
    UBRR0H = ubrr0 >> 8;
    UCSR0A = stts.flat;
    UCSR0C = mode.flat;
    UCSR0B = ctrl.flat;

    return SUCCESS;
  }

  command error_t Uart0TxControl.start() {
    SET_BIT(UCSR0B, TXEN0);
    call McuPowerState.update();
    return SUCCESS;
  }

  command error_t Uart0TxControl.stop() {
    CLR_BIT(UCSR0B, TXEN0);
    call McuPowerState.update();
    return SUCCESS;
  }

  command error_t Uart0RxControl.start() {
    SET_BIT(UCSR0B, RXEN0);
    call McuPowerState.update();
    return SUCCESS;
  }

  command error_t Uart0RxControl.stop() {
    CLR_BIT(UCSR0B, RXEN0);
    call McuPowerState.update();
    return SUCCESS;
  }
  
  async command error_t HplUart0.enableTxIntr() {
    SET_BIT(UCSR0A, TXC0);
    SET_BIT(UCSR0B, TXCIE0);
    return SUCCESS;
  }
  
  async command error_t HplUart0.disableTxIntr(){
    CLR_BIT(UCSR0B, TXCIE0);
    return SUCCESS;
  }
  
  async command error_t HplUart0.enableRxIntr(){
    SET_BIT(UCSR0B, RXCIE0);
    return SUCCESS;
  }

  async command error_t HplUart0.disableRxIntr(){
    CLR_BIT(UCSR0B, RXCIE0);
    return SUCCESS;
  }
  
  async command bool HplUart0.isTxEmpty(){
    return READ_BIT(UCSR0A, TXC0);
  }

  async command bool HplUart0.isRxEmpty(){
    return !READ_BIT(UCSR0A, RXC0);
  }
  
  async command uint8_t HplUart0.rx(){
    return UDR0;
  }

  async command void HplUart0.tx(uint8_t data) {
    atomic{
      UDR0 = data; 
      SET_BIT(UCSR0A, TXC0);
    }
  }
  
  AVR_ATOMIC_HANDLER(SIG_USART0_RECV) {
    if (READ_BIT(UCSR0A, RXC0)) {
      signal HplUart0.rxDone(UDR0);
    }
    call PlatformInterrupt.postAmble();
  }
  
  AVR_NONATOMIC_HANDLER(SIG_USART0_TRANS) {
    signal HplUart0.txDone();
    call PlatformInterrupt.postAmble();
  }
  
  command error_t Uart1Init.init() {
    Atm128UartMode_t    mode;
    Atm128UartStatus_t  stts;
    Atm128UartControl_t ctrl;
    uint16_t ubrr1;
    
    ctrl.bits = (struct Atm128_UCSRB_t) {rxcie:0, txcie:0, rxen:0, txen:0};
    stts.bits = (struct Atm128_UCSRA_t) {u2x:1};
    mode.bits = (struct Atm128_UCSRC_t) {ucsz:ATM128_UART_DATA_SIZE_8_BITS};

    ubrr1 = call Atm128Calibrate.baudrateRegister(PLATFORM_BAUDRATE);
    UBRR1L = ubrr1;
    UBRR1H = ubrr1 >> 8;
    UCSR1A = stts.flat;
    UCSR1C = mode.flat;
    UCSR1B = ctrl.flat;

    return SUCCESS;
  }

  command error_t Uart1TxControl.start() {
    SET_BIT(UCSR1B, TXEN1);
    call McuPowerState.update();
    return SUCCESS;
  }

  command error_t Uart1TxControl.stop() {
    CLR_BIT(UCSR1B, TXEN1);
    call McuPowerState.update();
    return SUCCESS;
  }

  command error_t Uart1RxControl.start() {
    SET_BIT(UCSR1B, RXEN1);
    call McuPowerState.update();
    return SUCCESS;
  }

  command error_t Uart1RxControl.stop() {
    CLR_BIT(UCSR1B, RXEN1);
    call McuPowerState.update();
    return SUCCESS;
  }
  
  async command error_t HplUart1.enableTxIntr() {
    SET_BIT(UCSR1A, TXC1);
    SET_BIT(UCSR1B, TXCIE1);
    return SUCCESS;
  }
  
  async command error_t HplUart1.disableTxIntr(){
    CLR_BIT(UCSR1B, TXCIE1);
    return SUCCESS;
  }
  
  async command error_t HplUart1.enableRxIntr(){
    SET_BIT(UCSR1B, RXCIE1);
    return SUCCESS;
  }

  async command error_t HplUart1.disableRxIntr(){
    CLR_BIT(UCSR1B, RXCIE1);
    return SUCCESS;
  }
  
  async command bool HplUart1.isTxEmpty() {
    return READ_BIT(UCSR1A, TXC1);
  }

  async command bool HplUart1.isRxEmpty() {
    return !READ_BIT(UCSR1A, RXC1);
  }
  
  async command uint8_t HplUart1.rx(){
    return UDR1;
  }

  async command void HplUart1.tx(uint8_t data) {
    atomic{
      UDR1 = data; 
      SET_BIT(UCSR1A, TXC1);
    }
  }
  
  AVR_ATOMIC_HANDLER(SIG_USART1_RECV) {
    if (READ_BIT(UCSR1A, RXC1))
      signal HplUart1.rxDone(UDR1);
    call PlatformInterrupt.postAmble();
  }
  
  AVR_NONATOMIC_HANDLER(SIG_USART1_TRANS) {
    signal HplUart1.txDone();
    call PlatformInterrupt.postAmble();
  }
  
  default async event void HplUart0.txDone() {} 
  default async event void HplUart0.rxDone(uint8_t data) {}
  default async event void HplUart1.txDone() {}
  default async event void HplUart1.rxDone(uint8_t data) {}
  
}
