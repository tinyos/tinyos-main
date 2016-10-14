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
 * @author Sanjeet Raj Pandey <code@tkn.tu-berlin.de>
 */

#include <jendefs.h>
#include <AppHardwareApi.h>

/**
 * Private component of the Jn516
 */
module HplJn516UartP {
  provides interface Init as Uart0Init;
  provides interface StdControl as Uart0Control;
  provides interface HplJn516Uart as HplUart0;
}
implementation {

  #define MAXBUFFER 512
  #define BAUD_RATE_UART0 E_AHI_UART_RATE_115200 //E_AHI_UART_RATE_38400 for NXP Border Router//;

  /*Default set for UART0*/
  uint8_t UART0 = E_AHI_UART_0;
  uint16_t BUFFER_LEN = MAXBUFFER;
  uint8_t TX_BUFFER[MAXBUFFER];
  uint8_t RX_BUFFER[MAXBUFFER];
  bool RX_INT=FALSE;
  bool TX_INT=FALSE;
  uint8_t UDR0;


  void vUartTxIsr(uint8_t uart) {
    signal HplUart0.txDone();
  }

  void vUartRxIsr(uint8_t uart) {
    atomic {
      UDR0 = u8AHI_UartReadData(UART0);
      signal HplUart0.rxDone(UDR0);
    }
  }


  /*Interrupt handler for UART send and receive*/
  void vUartISR(uint32_t DeviceID,uint32_t ItemBitmap) {
    /*Interrupt Bitmap , check API for more Items*/
    switch (ItemBitmap) {
      case E_AHI_UART_INT_TX :      vUartTxIsr(UART0); break; //interrupt handler for TX
      case E_AHI_UART_INT_RXDATA :  vUartRxIsr(UART0); break; //interrupt handler for RX , based on E_AHI_UART_FIFO_LEVEL_x flag
    }
  }

  command error_t Uart0Init.init() {
    atomic {
      RX_INT = FALSE;
      TX_INT = FALSE;
      bAHI_UartEnable(UART0, TX_BUFFER, BUFFER_LEN, RX_BUFFER, BUFFER_LEN);
      vAHI_Uart0RegisterCallback(vUartISR);
      vAHI_UartSetBaudRate(UART0, BAUD_RATE_UART0);
      vAHI_UartReset(UART0, TRUE, TRUE);
      vAHI_UartReset(UART0, FALSE, FALSE);
    }
    return SUCCESS;
  }

  command error_t Uart0Control.start() {
    call HplUart0.enableTxIntr();
    call HplUart0.enableRxIntr();
    return SUCCESS;
  }

  command error_t Uart0Control.stop() {
    atomic {
      call HplUart0.disableTxIntr();
      call HplUart0.disableRxIntr();
      //vAHI_UartDisable(UART0);
      return SUCCESS;
    }
  }

  async command error_t HplUart0.enableTxIntr() {
    atomic {
      TX_INT=TRUE;
      vAHI_UartSetInterrupt(UART0, FALSE, FALSE, TX_INT, RX_INT, E_AHI_UART_FIFO_LEVEL_1);
    }
    return SUCCESS;
  }

  async command error_t HplUart0.disableTxIntr() {
    atomic {
      TX_INT=FALSE;
      vAHI_UartSetInterrupt(UART0, FALSE, FALSE, TX_INT, RX_INT, E_AHI_UART_FIFO_LEVEL_1);
    }
    return SUCCESS;
  }

  async command error_t HplUart0.enableRxIntr() {
    atomic {
      RX_INT=TRUE;
      vAHI_UartSetInterrupt(UART0, FALSE, FALSE, TX_INT, RX_INT, E_AHI_UART_FIFO_LEVEL_1);
    }
    return SUCCESS;
  }

  async command error_t HplUart0.disableRxIntr() {
    atomic {
      RX_INT=FALSE;
      vAHI_UartSetInterrupt(UART0, FALSE, FALSE, TX_INT, RX_INT, E_AHI_UART_FIFO_LEVEL_1);
    }
    return SUCCESS;
  }

  async command bool HplUart0.isTxEmpty() {
    if (u16AHI_UartReadTxFifoLevel(UART0) > 0)
      return FALSE;
    else
      return TRUE;
  }

  async command bool HplUart0.isRxEmpty() {
    if (u16AHI_UartReadRxFifoLevel(UART0) > 0)
      return FALSE;
    else
      return TRUE;
  }

  async command uint8_t HplUart0.rx() {
    atomic{
      UDR0=u8AHI_UartReadData(UART0);
      return UDR0;
    }
  }

  async command void HplUart0.tx(uint8_t data) {
    atomic {
      //UDW0 = data;
      vAHI_UartWriteData(UART0, data);
    }
  }


  default async event void HplUart0.txDone() {}
  default async event void HplUart0.rxDone(uint8_t data) {}
  /*default async event void HplUart1.txDone() {}
  default async event void HplUart1.rxDone(uint8_t data) {}*/

}
