/**
 * Copyright (c) 2015, Technische Universitaet Berlin
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
 * - Neither the name of the Technische Universitaet Berlin nor the names
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
 *
 * @author Tim Bormann <code@tkn.tu-berlin.de>
 * @author Moksha Birk <code@tkn.tu-berlin.de>
 */

#include <jendefs.h>
#include <AppHardwareApi.h>

generic module Jn516SerialP(uint8_t uart,uint8_t baud,uint16_t buf_len) {
  provides interface StdControl;
  provides interface UartByte;
  provides interface UartStream;
  uses interface Boot;
}
implementation {

//#define uart 		E_AHI_UART_0
//#define baud		E_AHI_UART_RATE_38400
//#define baud		E_AHI_UART_RATE_115200
//#define buf_len 	256

  uint8_t tx_buffer[buf_len];
  uint8_t rx_buffer[buf_len];

  uint8_t* txbuf;
  uint16_t txlen;

  volatile bool locked = FALSE;

  event void Boot.booted() {
    call StdControl.start();
  }

  void SerialCallback(uint32_t DeviceId, uint32_t ItemBitmap) {
    if (E_AHI_UART_INT_TX && ItemBitmap) {
      atomic {
        locked = FALSE;
        signal UartStream.sendDone(txbuf, txlen, SUCCESS);
      }
    }
  }

  command error_t StdControl.start() {
    bool init_success = bAHI_UartEnable(uart, tx_buffer, buf_len, tx_buffer,buf_len);
    vAHI_UartSetBaudRate(uart, baud);
    vAHI_UartSetInterrupt(uart, FALSE, FALSE, TRUE, FALSE, E_AHI_UART_FIFO_LEVEL_1);
    switch (uart) {
      case E_AHI_UART_0: vAHI_Uart0RegisterCallback(SerialCallback); break;
      case E_AHI_UART_1: vAHI_Uart1RegisterCallback(SerialCallback); break;
      default: return FAIL;
    }

    if (init_success)
      return SUCCESS;
    else
      return FAIL;
  }

  command error_t StdControl.stop() {
    vAHI_UartDisable(uart);
    return SUCCESS;
  }

  async command error_t UartByte.send(uint8_t byte) {
    vAHI_UartWriteData(uart, byte);
    return SUCCESS;
  }

  /*
   * Check to see if space is available for another transmit byte to go out.
   */
  async command bool UartByte.sendAvail() {
    return FALSE;
  }


  async command error_t UartByte.receive(uint8_t* byte, uint8_t timeout) {
    return FAIL;
  }


  /*
   * Check to see if another Rx byte is available.
   */
  async command bool UartByte.receiveAvail() {
    return FALSE;
  }


/*
  extern int lowlevel_putc(int c) {
    vAHI_UartWriteData(uart, (uint8_t)c);
  }
*/
  task void blockWriteData() {
    uint8_t* buf;
    uint16_t len;
    atomic {
      buf = txbuf;
      len = txlen;
    }
    u16AHI_UartBlockWriteData(uart, buf, len);
  }

  async command error_t UartStream.send(uint8_t* buf, uint16_t len) {
    if (len > buf_len) {
      signal UartStream.sendDone(buf, len, FAIL);
      return FAIL;
    }
    atomic {
      if (!locked) {
        locked = TRUE;
        txbuf = buf;
        txlen = len;
        //u16AHI_UartBlockWriteData(uart, txbuf, txlen);
        post blockWriteData();
        return SUCCESS;
      }
      else {
        return EBUSY;
      }
    }
  }

  async command error_t UartStream.enableReceiveInterrupt() { return FAIL; }
  async command error_t UartStream.disableReceiveInterrupt() { return FAIL; }
  async command error_t UartStream.receive(uint8_t* buf, uint16_t len) { return FAIL; }
  async default event void UartStream.sendDone(uint8_t* buf, uint16_t len, error_t error) {}
  async default event void UartStream.receivedByte(uint8_t byte) {}
  async default event void UartStream.receiveDone(uint8_t* buf, uint16_t len, error_t error) {}
}
