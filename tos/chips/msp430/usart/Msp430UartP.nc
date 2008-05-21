/**
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * @author Jonathan Hui <jhui@archrock.com>
 * @author Vlado Handziski <handzisk@tkn.tu-berlin.de>
 * @author Eric B. Decker <cire831@gmail.com>
 * @version $Revision: 1.6 $ $Date: 2008-05-21 22:11:57 $
 */

#include<Timer.h>

generic module Msp430UartP() {

  provides interface Resource[ uint8_t id ];
  provides interface ResourceConfigure[ uint8_t id ];
  provides interface UartStream[ uint8_t id ];
  provides interface UartByte[ uint8_t id ];
  
  uses interface Resource as UsartResource[ uint8_t id ];
  uses interface Msp430UartConfigure[ uint8_t id ];
  uses interface HplMsp430Usart as Usart;
  uses interface HplMsp430UsartInterrupts as UsartInterrupts[ uint8_t id ];
  uses interface Counter<T32khz,uint16_t>;
  uses interface Leds;

}

implementation {
  
  norace uint8_t *m_tx_buf, *m_rx_buf;
  norace uint16_t m_tx_len, m_rx_len;
  norace uint16_t m_tx_pos, m_rx_pos;
  norace uint8_t m_byte_time;
  norace uint8_t current_owner;
  
  async command error_t Resource.immediateRequest[ uint8_t id ]() {
    return call UsartResource.immediateRequest[ id ]();
  }

  async command error_t Resource.request[ uint8_t id ]() {
    return call UsartResource.request[ id ]();
  }

  async command uint8_t Resource.isOwner[ uint8_t id ]() {
    return call UsartResource.isOwner[ id ]();
  }

  async command error_t Resource.release[ uint8_t id ]() {
    if (call UsartResource.isOwner[id]() == FALSE)
      return FAIL;
    if ( m_rx_buf || m_tx_buf )
      return EBUSY;
    return call UsartResource.release[ id ]();
  }

  async command void ResourceConfigure.configure[ uint8_t id ]() {
    msp430_uart_union_config_t* config = call Msp430UartConfigure.getConfig[id]();
    m_byte_time = config->uartConfig.ubr / 2;
    call Usart.setModeUart(config);
    call Usart.enableIntr();
  }

  async command void ResourceConfigure.unconfigure[ uint8_t id ]() {
    call Usart.resetUsart(TRUE);
    call Usart.disableIntr();
    call Usart.disableUart();

    /* leave the usart in reset */
    //call Usart.resetUsart(FALSE); // this shouldn't be called.
  }

  event void UsartResource.granted[ uint8_t id ]() {
    signal Resource.granted[ id ]();
  }
  
  async command error_t UartStream.enableReceiveInterrupt[ uint8_t id ]() {
    if (call UsartResource.isOwner[id]() == FALSE)
      return FAIL;
    call Usart.enableRxIntr();
    return SUCCESS;
  }
  
  async command error_t UartStream.disableReceiveInterrupt[ uint8_t id ]() {
    if (call UsartResource.isOwner[id]() == FALSE)
      return FAIL;
    call Usart.disableRxIntr();
    return SUCCESS;
  }

  async command error_t UartStream.receive[ uint8_t id ]( uint8_t* buf, uint16_t len ) {
    if (call UsartResource.isOwner[id]() == FALSE)
      return FAIL;
    if ( len == 0 )
      return FAIL;
    atomic {
      if ( m_rx_buf )
	return EBUSY;
      m_rx_buf = buf;
      m_rx_len = len;
      m_rx_pos = 0;
    }
    return SUCCESS;
  }
  
  async event void UsartInterrupts.rxDone[uint8_t id]( uint8_t data ) {
    if ( m_rx_buf ) {
      m_rx_buf[ m_rx_pos++ ] = data;
      if ( m_rx_pos >= m_rx_len ) {
	uint8_t* buf = m_rx_buf;
	m_rx_buf = NULL;
	signal UartStream.receiveDone[id]( buf, m_rx_len, SUCCESS );
      }
    } else {
      signal UartStream.receivedByte[id]( data );
    }
  }
  
  async command error_t UartStream.send[ uint8_t id ]( uint8_t* buf, uint16_t len ) {
    if (call UsartResource.isOwner[id]() == FALSE)
      return FAIL;
    if ( len == 0 )
      return FAIL;
    else if ( m_tx_buf )
      return EBUSY;
    m_tx_buf = buf;
    m_tx_len = len;
    m_tx_pos = 0;
    current_owner = id;
    call Usart.tx( buf[ m_tx_pos++ ] );
    return SUCCESS;
  }
  
  async event void UsartInterrupts.txDone[uint8_t id]() {
    if(current_owner != id) {
      uint8_t* buf = m_tx_buf;
      m_tx_buf = NULL;
      signal UartStream.sendDone[id]( buf, m_tx_len, FAIL );
    }
    else if ( m_tx_pos < m_tx_len ) {
      call Usart.tx( m_tx_buf[ m_tx_pos++ ] );
    }
    else {
      uint8_t* buf = m_tx_buf;
      m_tx_buf = NULL;
      signal UartStream.sendDone[id]( buf, m_tx_len, SUCCESS );
    }
  }
  
  async command error_t UartByte.send[ uint8_t id ]( uint8_t data ) {
    if (call UsartResource.isOwner[id]() == FALSE)
      return FAIL;
    call Usart.clrTxIntr();
    call Usart.disableTxIntr ();
    call Usart.tx( data );
    while( !call Usart.isTxIntrPending() );
    call Usart.clrTxIntr();
    call Usart.enableTxIntr();
    return SUCCESS;
  }
  
  async command error_t UartByte.receive[ uint8_t id ]( uint8_t* byte, uint8_t timeout ) {
    
    uint16_t timeout_micro = m_byte_time * timeout + 1;
    uint16_t start;
    
    if (call UsartResource.isOwner[id]() == FALSE)
      return FAIL;
    start = call Counter.get();
    while( !call Usart.isRxIntrPending() ) {
      if ( ( call Counter.get() - start ) >= timeout_micro )
				return FAIL;
    }
    *byte = call Usart.rx();
    
    return SUCCESS;

  }
  
  async event void Counter.overflow() {}
  
  default async command error_t UsartResource.isOwner[ uint8_t id ]() { return FAIL; }
  default async command error_t UsartResource.request[ uint8_t id ]() { return FAIL; }
  default async command error_t UsartResource.immediateRequest[ uint8_t id ]() { return FAIL; }
  default async command error_t UsartResource.release[ uint8_t id ]() { return FAIL; }
  default async command msp430_uart_union_config_t* Msp430UartConfigure.getConfig[uint8_t id]() {
    return &msp430_uart_default_config;
  }

  default event void Resource.granted[ uint8_t id ]() {}

  default async event void UartStream.sendDone[ uint8_t id ](uint8_t* buf, uint16_t len, error_t error) {}
  default async event void UartStream.receivedByte[ uint8_t id ](uint8_t byte) {}
  default async event void UartStream.receiveDone[ uint8_t id ]( uint8_t* buf, uint16_t len, error_t error ) {}
}
