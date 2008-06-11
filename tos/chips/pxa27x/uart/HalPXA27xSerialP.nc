/* $Id: HalPXA27xSerialP.nc,v 1.5 2008-06-11 00:42:13 razvanm Exp $ */
/*
 * Copyright (c) 2005 Arched Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arched Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/*
 *  Intel Open Source License
 *
 *  Copyright (c) 2002 Intel Corporation
 *  All rights reserved.
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 *
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 */
/**
 * Implements the UartByte, UartStream and HalPXA27xSerialPacket interface 
 * for a PXA27x UART. 
 * 
 *
 * @param defaultRate Default baud rate for the serial port. 
 *
 *
 * @author Phil Buonadonna
 */

#include "pxa27x_serial.h"

generic module HalPXA27xSerialP(uint32_t defaultRate)
{
  provides {
    interface Init;
    interface StdControl;
    interface UartByte;
    interface UartStream;
    interface HalPXA27xSerialPacket;
    interface HalPXA27xSerialCntl;
  }
  uses {
    interface Init as UARTInit;
    interface HplPXA27xUART as UART;
    interface HplPXA27xDMAChnl as RxDMA;
    interface HplPXA27xDMAChnl as TxDMA;
    interface HplPXA27xDMAInfo as UARTRxDMAInfo;
    interface HplPXA27xDMAInfo as UARTTxDMAInfo;
  }
}

implementation 
{

  uint8_t *txCurrentBuf, *rxCurrentBuf;
  uint32_t txCurrentLen, rxCurrentLen, rxCurrentIdx;
  uint32_t gulFCRShadow;
  bool gbUsingUartStreamSendIF = FALSE;
  bool gbUsingUartStreamRcvIF = FALSE;
  bool gbRcvByteEvtEnabled = TRUE;

  command error_t Init.init() {
    error_t error = SUCCESS;

    atomic {
      call UARTInit.init();
      txCurrentBuf = rxCurrentBuf = NULL;
      gbUsingUartStreamSendIF = FALSE;
      gbUsingUartStreamRcvIF = FALSE;
      gbRcvByteEvtEnabled = TRUE;
      gulFCRShadow = (FCR_TRFIFOE | FCR_ITL(0)); // FIFO Mode, 1 byte Rx threshold
    }
    call TxDMA.setMap(call UARTTxDMAInfo.getMapIndex());
    call RxDMA.setMap(call UARTRxDMAInfo.getMapIndex());
    call TxDMA.setDALGNbit(TRUE);
    call RxDMA.setDALGNbit(TRUE);

    error = call HalPXA27xSerialCntl.configPort(defaultRate,8,NONE,1,FALSE);
    
    atomic {call UART.setFCR(gulFCRShadow);}
    return error;
  }

  command error_t StdControl.start() {
    atomic {
      call UART.setIER(IER_UUE | IER_RAVIE);
    }
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    atomic {
      call UART.setIER(0);
    }
    return SUCCESS;
  }

  async command error_t UartByte.send(uint8_t data) {
    atomic call UART.setTHR(data);
    while ((call UART.getLSR() & LSR_TEMT) == 0);
    return SUCCESS;
  }

  async command error_t UartByte.receive( uint8_t *data, uint8_t timeout) {
    error_t error = FAIL;
    uint8_t t;
    for (t = 0; t < timeout; t++) {
      if (call UART.getLSR() & LSR_DR) {
	*data = call UART.getRBR();
	error = SUCCESS;
	break;
      }
    }
    return error;
  }

  async command error_t UartStream.send( uint8_t* buf, uint16_t len ) {
    error_t error;
    atomic gbUsingUartStreamSendIF = TRUE;
    error = call HalPXA27xSerialPacket.send(buf,len);
    if (error) {
      atomic gbUsingUartStreamSendIF = FALSE;
    }
    return error;
  }


  async command error_t UartStream.enableReceiveInterrupt() {
    error_t error = SUCCESS;
    atomic {
      if (rxCurrentBuf == NULL) {
	call UART.setIER(call UART.getIER() | IER_RAVIE);
      }
      gbRcvByteEvtEnabled = TRUE;
    }
    return SUCCESS;
  }

  async command error_t UartStream.disableReceiveInterrupt() {
    atomic {
      // Check to make sure a short stream/packet call isn't in progress
      if ((rxCurrentBuf == NULL) || (rxCurrentLen >= 8)) {
	call UART.setIER(call UART.getIER() & ~IER_RAVIE);
      }
      gbRcvByteEvtEnabled = FALSE;
    }
    return SUCCESS;
  }

  async command error_t UartStream.receive( uint8_t* buf, uint16_t len ) {
    error_t error;
    atomic gbUsingUartStreamRcvIF = TRUE;
    error = call HalPXA27xSerialPacket.receive(buf,len,0);
    if (error) {
      atomic gbUsingUartStreamRcvIF = FALSE;
    }
    return error;
  }
  
  async command error_t HalPXA27xSerialPacket.send(uint8_t *buf, uint16_t len) {
    uint32_t txAddr;
    uint32_t DMAFlags;
    error_t error = SUCCESS;

    atomic {
      if (txCurrentBuf == NULL) {
	txCurrentBuf = buf;
	txCurrentLen = len;
      }
      else {
	error = FAIL;
      }
    }

    if (error) 
      return error;
    
    if (len < 8) {
      uint16_t i;
      // Use PIO. Invariant: FIFO is empty
      atomic {
	gulFCRShadow |= FCR_TIL;
	call UART.setFCR(gulFCRShadow); 
      }
      for (i = 0;i < len;i++) {
	call UART.setTHR(buf[i]);
      }
      atomic call UART.setIER(call UART.getIER() | IER_TIE);
    }
    else {
      // Use DMA
      DMAFlags = (DCMD_FLOWTRG | DCMD_BURST8 | DCMD_WIDTH1 | DCMD_ENDIRQEN
		  | DCMD_LEN(len) );
      
      txAddr = (uint32_t) buf;
      DMAFlags |= DCMD_INCSRCADDR;
      
      call TxDMA.setDCSR(DCSR_NODESCFETCH);
      call TxDMA.setDSADR(txAddr);
      call TxDMA.setDTADR(call UARTTxDMAInfo.getAddr());
      call TxDMA.setDCMD(DMAFlags);
      
      atomic {
	call UART.setIER(call UART.getIER() | IER_DMAE);
      }

      call TxDMA.setDCSR(DCSR_RUN | DCSR_NODESCFETCH);
    }
    return error;
  }


  async command error_t HalPXA27xSerialPacket.receive(uint8_t *buf, uint16_t len, 
						      uint16_t timeout) {
    uint32_t rxAddr;
    uint32_t DMAFlags;
    error_t error = SUCCESS;

    atomic {
      if (rxCurrentBuf == NULL) {
	rxCurrentBuf = buf;
	rxCurrentLen = len;
	rxCurrentIdx = 0;
      }
      else {
	error = FAIL;
      }
    }

    if (error) 
      return error;

    if (len < 8) {
      // Use PIO. Invariant: FIFO is empty
      atomic {
	gulFCRShadow = ((gulFCRShadow & ~(FCR_ITL(3))) | FCR_ITL(0));
	call UART.setFCR(gulFCRShadow); 
	call UART.setIER(call UART.getIER() | IER_RAVIE);
      }
    }
    else {
      // Use DMA
      DMAFlags = (DCMD_FLOWSRC | DCMD_BURST8 | DCMD_WIDTH1 | DCMD_ENDIRQEN
		  | DCMD_LEN(len) );
      
      rxAddr = (uint32_t) buf;
      DMAFlags |= DCMD_INCTRGADDR;
      
      call RxDMA.setDCSR(DCSR_NODESCFETCH);
      call RxDMA.setDTADR(rxAddr);
      call RxDMA.setDSADR(call UARTRxDMAInfo.getAddr());
      call RxDMA.setDCMD(DMAFlags);

      atomic {
	gulFCRShadow = ((gulFCRShadow & ~(FCR_ITL(3))) | FCR_ITL(1));
	call UART.setFCR(gulFCRShadow); 
	call UART.setIER((call UART.getIER() & ~IER_RAVIE) | IER_DMAE);
      }

      call RxDMA.setDCSR(DCSR_RUN | DCSR_NODESCFETCH);
    }
    return error;
  }
  
  void DispatchStreamRcvSignal() {
    uint8_t *pBuf = rxCurrentBuf;
    uint16_t len = rxCurrentLen;
    rxCurrentBuf = NULL;
    if (gbUsingUartStreamRcvIF) {
      gbUsingUartStreamRcvIF = FALSE;
      signal UartStream.receiveDone(pBuf, len, SUCCESS);
    }
    else {
      pBuf = signal HalPXA27xSerialPacket.receiveDone(pBuf, len, SUCCESS);
      if (pBuf) {
	call HalPXA27xSerialPacket.receive(pBuf,len,0);
      }
    }
    return;
  }

  void DispatchStreamSendSignal() {
    uint8_t *pBuf = txCurrentBuf;
    uint16_t len = txCurrentLen;
    txCurrentBuf = NULL;
    if (gbUsingUartStreamSendIF) {
      gbUsingUartStreamSendIF = FALSE;
      signal UartStream.sendDone(pBuf, len, SUCCESS);
    }
    else {
      pBuf = signal HalPXA27xSerialPacket.sendDone(pBuf, len, SUCCESS);
      if (pBuf) {
	call HalPXA27xSerialPacket.send(pBuf,len);
      }
    }
    return;
  }

  async event void RxDMA.interruptDMA() {
    call RxDMA.setDCMD(0);
    call RxDMA.setDCSR(DCSR_EORINT | DCSR_ENDINTR | DCSR_STARTINTR | DCSR_BUSERRINTR);
    DispatchStreamRcvSignal();
    if (gbRcvByteEvtEnabled) 
      call UART.setIER(call UART.getIER() | IER_RAVIE);
    return;
  }

  async event void TxDMA.interruptDMA() {
    call TxDMA.setDCMD(0);
    call TxDMA.setDCSR(DCSR_EORINT | DCSR_ENDINTR | DCSR_STARTINTR | DCSR_BUSERRINTR);
    DispatchStreamSendSignal();
    return;
  }


  async command error_t HalPXA27xSerialCntl.configPort(uint32_t baudrate, 
							uint8_t databits, 
							uart_parity_t parity, 
							uint8_t stopbits, 
							bool flow_cntl) {
    uint32_t uiDivisor;
    uint32_t valLCR = 0;
    uint32_t valMCR = MCR_OUT2;
      
    uiDivisor = 921600/baudrate;
    // Check for invalid baud rate divisor value.
    // XXX - Eventually could use '0' to imply auto rate detection
    if ((uiDivisor & 0xFFFF0000) || (uiDivisor == 0)) {
      return EINVAL;
    }

    if ((databits > 8 || databits < 5)) {
      return EINVAL;
    }
    valLCR |= LCR_WLS((databits-5));

    switch (parity) {
    case EVEN: 
      valLCR |= LCR_EPS;
      // Fall through to enable
    case ODD:
      valLCR |= LCR_PEN;
      break;
    case NONE:
      break;
    default:
      return EINVAL;
      break;
    }
    
    if ((stopbits > 2) || (stopbits < 1)) {
      return EINVAL;
    }
    else if (stopbits == 2) {
      valLCR |= LCR_STB;
    }

    if (flow_cntl) {
      valMCR |= MCR_AFE;
    }

    atomic {
      call UART.setDLL((uiDivisor & 0xFF));
      call UART.setDLH(((uiDivisor >> 8) & 0xFF));
      call UART.setLCR(valLCR);
      call UART.setMCR(valMCR);
    }
 
    return SUCCESS;
  }
    
  async command error_t HalPXA27xSerialCntl.flushPort() {

    atomic {
      call UART.setFCR(gulFCRShadow | FCR_RESETTF | FCR_RESETRF);
    }

    return SUCCESS;
  }
  
  async event void UART.interruptUART() {
    uint8_t error, intSource;
    uint8_t ucByte;

    intSource = call UART.getIIR();
    intSource &= IIR_IID_MASK;
    intSource = intSource >> 1;
    
    switch (intSource) {
    case 0: // MODEM STATUS
      break;
    case 1: // TRANSMIT FIFO
      call UART.setIER(call UART.getIER() & ~IER_TIE);
      DispatchStreamSendSignal();
      break;
    case 2: // RECEIVE FIFO data available
      while (call UART.getLSR() & LSR_DR) {
	ucByte = call UART.getRBR();

	if (rxCurrentBuf != NULL) {
	  rxCurrentBuf[rxCurrentIdx] = ucByte;
	  rxCurrentIdx++;
	  if (rxCurrentIdx >= rxCurrentLen) 
	    DispatchStreamRcvSignal();
	}
	else if (gbRcvByteEvtEnabled) {
	  signal UartStream.receivedByte(ucByte);
	}
      }
      break;
    case 3: // ERROR
      error = call UART.getLSR();
      break;
    default:
      break;
    }
    return;
  }

  default async event void UartStream.sendDone( uint8_t* buf, uint16_t len, error_t error ) {
    return; 
  }

  default async event void UartStream.receivedByte(uint8_t data) {
    return;
  }

  default async event void UartStream.receiveDone( uint8_t* buf, uint16_t len, error_t error ) {
    return;
  }

  default async event uint8_t* HalPXA27xSerialPacket.sendDone(uint8_t *buf, 
							      uint16_t len, 
							      uart_status_t status) {
    return NULL;
  }

  default async event uint8_t* HalPXA27xSerialPacket.receiveDone(uint8_t *buf, 
								 uint16_t len, 
								 uart_status_t status) {
    return NULL;
  }


}
