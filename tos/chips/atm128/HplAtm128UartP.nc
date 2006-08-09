/// $Id: HplAtm128UartP.nc,v 1.3 2006-08-09 22:43:20 idgay Exp $

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

#include <Atm128Uart.h>

/** 
 * Private component of the Atmega128 serial port HPL.
 *
 * @author Martin Turon <mturon@xbow.com>
 * @author David Gay
 */

module HplAtm128UartP
{
  provides {
    interface Init as Uart0Init;
    interface StdControl as Uart0TxControl;
    interface StdControl as Uart0RxControl;
    interface SerialByteComm as Uart0;
    
    interface Init as Uart1Init;
    interface StdControl as Uart1TxControl;
    interface StdControl as Uart1RxControl;
    interface SerialByteComm as Uart1;
  }
  uses {
    interface Atm128Calibrate;
    interface McuPowerState;
  }
}
implementation
{
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
    Atm128UartControl_t ctrl;
    ctrl.flat = UCSR0B;
    ctrl.bits.txcie = 1;
    ctrl.bits.txen  = 1;
    UCSR0B = ctrl.flat;
    call McuPowerState.update();
    return SUCCESS;
  }

  command error_t Uart0TxControl.stop() {
    Atm128UartControl_t ctrl;
    ctrl.flat = UCSR0B;
    ctrl.bits.txcie = 0;
    ctrl.bits.txen  = 0;
    UCSR0B = ctrl.flat;
    call McuPowerState.update();
    return SUCCESS;
  }

  command error_t Uart0RxControl.start() {
    Atm128UartControl_t ctrl;
    ctrl.flat = UCSR0B;
    ctrl.bits.rxcie = 1;
    ctrl.bits.rxen  = 1;
    UCSR0B = ctrl.flat;
    call McuPowerState.update();
    return SUCCESS;
  }

  command error_t Uart0RxControl.stop() {
    Atm128UartControl_t ctrl;
    ctrl.flat = UCSR0B;
    ctrl.bits.rxcie = 0;
    ctrl.bits.rxen  = 0;
    UCSR0B = ctrl.flat;
    call McuPowerState.update();
    return SUCCESS;
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
    Atm128UartControl_t ctrl;
    ctrl.flat = UCSR1B;
    ctrl.bits.txcie = 1;
    ctrl.bits.txen  = 1;
    UCSR1B = ctrl.flat;
    call McuPowerState.update();
    return SUCCESS;
  }

  command error_t Uart1TxControl.stop() {
    Atm128UartControl_t ctrl;
    ctrl.flat = UCSR1B;
    ctrl.bits.txcie = 0;
    ctrl.bits.txen  = 0;
    UCSR1B = ctrl.flat;
    call McuPowerState.update();
    return SUCCESS;
  }

  command error_t Uart1RxControl.start() {
    Atm128UartControl_t ctrl;
    ctrl.flat = UCSR1B;
    ctrl.bits.rxcie = 1;
    ctrl.bits.rxen  = 1;
    UCSR1B = ctrl.flat;
    call McuPowerState.update();
    return SUCCESS;
  }

  command error_t Uart1RxControl.stop() {
    Atm128UartControl_t ctrl;
    ctrl.flat = UCSR1B;
    ctrl.bits.rxcie = 0;
    ctrl.bits.rxen  = 0;
    UCSR1B = ctrl.flat;
    call McuPowerState.update();
    return SUCCESS;
  }

  /*   //=== Uart Stop Commands. ==================================== */
  /*   async command error_t Uart0.stop() { */
  /*       UCSR0A = 0; */
  /*       UCSR0B = 0; */
  /*       UCSR0C = 0; */
  /*       return SUCCESS; */
  /*   } */
  /*   async command error_t Uart1.stop() { */
  /*       UCSR0A = 0; */
  /*       UCSR0B = 0; */
  /*       UCSR0C = 0; */
  /*       return SUCCESS; */
  /*   } */

  //=== Uart Put Commands. ====================================
  async command error_t Uart0.put(uint8_t data) {
    atomic{
      UDR0 = data; 
      SET_BIT(UCSR0A, TXC);
    }
    return SUCCESS;
  }
  async command error_t Uart1.put(uint8_t data) {
    atomic{
      UDR1 = data; 
      SET_BIT(UCSR1A, TXC);
    }
    return SUCCESS;
  }
  
  //=== Uart Get Events. ======================================
  default async event void Uart0.get(uint8_t data) { return; }
  AVR_ATOMIC_HANDLER(SIG_UART0_RECV) {
    if (READ_BIT(UCSR0A, RXC))
      signal Uart0.get(UDR0);
  }
  default async event void Uart1.get(uint8_t data) { return; }
  AVR_ATOMIC_HANDLER(SIG_UART1_RECV) {
    if (READ_BIT(UCSR1A, RXC))
      signal Uart1.get(UDR1);
  }

  //=== Uart Put Done Events. =================================
  default async event void Uart0.putDone() { return; }
  AVR_NONATOMIC_HANDLER(SIG_UART0_TRANS) {
    signal Uart0.putDone();
  }
  default async event void Uart1.putDone() { return; }
  AVR_NONATOMIC_HANDLER(SIG_UART1_TRANS) {
    signal Uart1.putDone();
  }

}
