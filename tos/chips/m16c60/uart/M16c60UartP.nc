/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
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
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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
 *
 */

/**
 * Generic HAL uart for M16c/60.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 * @author Alec Woo <awoo@archrock.com>
 * @author Jonathan Hui <jhui@archrock.com>
 * @author Philip Levis <pal@cs.stanford.edu>
 */

#include <Timer.h>
#include "M16c60Uart.h"

generic module M16c60UartP()
{  
  provides interface UartByte;
  provides interface UartStream;
  provides interface UartControl;
  
  uses interface HplM16c60Uart as HplUart;
  uses interface Counter<TMicro, uint16_t>;
  
}
implementation
{ 
#define SPEED_F1_2(baud) (uint8_t)(((MAIN_CRYSTAL_SPEED * 1000000.0 / (16.0 * (float)baud))+ 0.5) - 1.0)
#define SPEED_F8(baud) (uint8_t)(((MAIN_CRYSTAL_SPEED * 1000000.0 / (128.0 * (float)baud))+ 0.5) - 1.0)
  norace uint16_t m_tx_len, m_rx_len;
  norace uint8_t *m_tx_buf, *m_rx_buf;
  norace uint16_t m_tx_pos, m_rx_pos;
  norace uint16_t m_byte_time;
  norace uint8_t m_rx_intr;
  norace uint8_t m_tx_intr;
  norace uart_duplex_t mode = TOS_UART_OFF;
  norace uart_speed_t speed;

  async command error_t UartStream.enableReceiveInterrupt()
  {
    if (mode == TOS_UART_TONLY || mode == TOS_UART_OFF)
    {
      return FAIL;
    }
    
    atomic
    {
      m_rx_intr = 3;
      call HplUart.enableRxInterrupt();
    }
    return SUCCESS;
  }

  async command error_t UartStream.disableReceiveInterrupt()
  {
    if (mode == TOS_UART_TONLY || mode == TOS_UART_OFF)
    {
      return FAIL;
    }
    atomic
    {
      call HplUart.disableRxInterrupt();
      m_rx_intr = 0;
    }
    return SUCCESS;
  }

  async command error_t UartStream.receive( uint8_t* buf, uint16_t len )
  {
    if (mode == TOS_UART_TONLY || mode == TOS_UART_OFF)
    {
      return FAIL;
    }
    
    if ( len == 0 )
    {
      return FAIL;
    }
    atomic
    {
      if ( m_rx_buf )
      {
        return EBUSY;
      }
      m_rx_buf = buf;
      m_rx_len = len;
      m_rx_pos = 0;
      m_rx_intr |= 1;
      call HplUart.enableRxInterrupt();
    }
    
    return SUCCESS;
    
  }

  async event void HplUart.rxDone() 
  {
    if ( m_rx_buf ) 
    {
      m_rx_buf[ m_rx_pos++ ] = call HplUart.rx();
      if ( m_rx_pos >= m_rx_len ) 
      {
        uint8_t* buf = m_rx_buf;
        atomic
        {
          m_rx_buf = NULL;
          if(m_rx_intr != 3)
          {
            call HplUart.disableRxInterrupt();
            m_rx_intr = 0;
          }
        }  
        signal UartStream.receiveDone( buf, m_rx_len, SUCCESS );
      }
    }
    else 
    {
      signal UartStream.receivedByte( call HplUart.rx() );
    }    
  }

  async command error_t UartStream.send( uint8_t *buf, uint16_t len)
  {
    if (mode == TOS_UART_RONLY || mode == TOS_UART_OFF)
    {
      return FAIL;
    }
    if ( len == 0 )
      return FAIL;
    else if ( m_tx_buf )
      return EBUSY;
    
    m_tx_len = len;
    m_tx_buf = buf;
    m_tx_pos = 0;
    m_tx_intr = 1;
    call HplUart.enableTxInterrupt();
    call HplUart.tx( buf[ m_tx_pos++ ] );
    
    return SUCCESS;
  }

  async event void HplUart.txDone() 
  {
    if (!m_tx_intr)
    {
      return;
    }
    if ( m_tx_pos < m_tx_len ) 
    {
      call HplUart.tx( m_tx_buf[ m_tx_pos++ ] );
    }
    else 
    {
      uint8_t* buf = m_tx_buf;
      m_tx_buf = NULL;
      m_tx_intr = 0;
      call HplUart.disableTxInterrupt();
      signal UartStream.sendDone( buf, m_tx_len, SUCCESS );
    }
  }

  async command error_t UartByte.send( uint8_t byte )
  {
    if (mode == TOS_UART_RONLY || mode == TOS_UART_OFF)
    {
      return FAIL;
    }
    if(m_tx_intr)
      return FAIL;

    call HplUart.tx( byte );
    while ( !call HplUart.isTxEmpty() );
    return SUCCESS;
  }
  
  /*
   * Check to see if space is available for another transmit byte to go out.
   */
  async command bool UartByte.sendAvail() {
    return call HplUart.isTxEmpty();
  }


  async command error_t UartByte.receive( uint8_t * byte, uint8_t timeout)
  {
    uint32_t timeout_micro32 = m_byte_time * timeout + 1;
    uint16_t timeout_micro;
    uint16_t start;
    
    if (mode == TOS_UART_TONLY || mode == TOS_UART_OFF)
    {
      return FAIL;
    }
    
    if(m_rx_intr)
    {
      return FAIL;
    }
    
    // The timeout clock is 16 bits and counts in TMicro. So a check to test that
    // the total timeout value is smaller than 0xffff - <safty margin> is needed.
    // TODO(henrik) Resolve this by lovering the clock speed used by the uart module
    //              or make it 32 bits.
    if(timeout_micro32 > 0xFFF0)
    {
      timeout_micro = 0xFFF0;
    }
    else
    {
      timeout_micro = (uint16_t) timeout_micro32;
    }

    start = call Counter.get();
    while ( call HplUart.isRxEmpty() ) 
    {
      if ( ( (uint16_t)call Counter.get() - start ) >= timeout_micro )
        return FAIL;
    }
    *byte = call HplUart.rx();
    
    return SUCCESS;
    
  }
  
  /*
   * Check to see if another Rx byte is available.
   */
  async command bool UartByte.receiveAvail() {
    return !call HplUart.isRxEmpty();
  }


  async command error_t UartControl.setSpeed(uart_speed_t s)
  {
    if (mode != TOS_UART_OFF)
    {
      return FAIL;
    }
    speed = s;
    switch (speed)
    {
      // 138us/byte @ 57600
      case TOS_UART_300:
        call HplUart.setCountSource(M16C60_UART_COUNT_SOURCE_F8);
        call HplUart.setSpeed(SPEED_F8(300)); 
        m_byte_time = 138 * 192;
        break;
      case TOS_UART_600:
        call HplUart.setCountSource(M16C60_UART_COUNT_SOURCE_F8);
        call HplUart.setSpeed(SPEED_F8(600)); 
        m_byte_time = 138 * 96;
        break;
      case TOS_UART_1200:
        call HplUart.setCountSource(M16C60_UART_COUNT_SOURCE_F8);
        call HplUart.setSpeed(SPEED_F8(1200)); 
        m_byte_time = 138 * 48;
        break;
      case TOS_UART_2400:
        call HplUart.setCountSource(M16C60_UART_COUNT_SOURCE_F8);
        call HplUart.setSpeed(SPEED_F8(2400)); 
        m_byte_time = 138 * 24;
        break;
      case TOS_UART_4800:
        call HplUart.setCountSource(M16C60_UART_COUNT_SOURCE_F8);
        call HplUart.setSpeed(SPEED_F8(4800)); 
        m_byte_time = 138 * 12;
        break;
      case TOS_UART_9600:
        call HplUart.setCountSource(M16C60_UART_COUNT_SOURCE_F1_2);
        call HplUart.setSpeed(SPEED_F1_2(9600)); 
        m_byte_time = 138 * 6;
        break;
      case TOS_UART_19200:
        call HplUart.setCountSource(M16C60_UART_COUNT_SOURCE_F1_2);
        call HplUart.setSpeed(SPEED_F1_2(19200)); 
        m_byte_time = 138 * 3;
        break;
      case TOS_UART_38400:
        call HplUart.setCountSource(M16C60_UART_COUNT_SOURCE_F1_2);
        call HplUart.setSpeed(SPEED_F1_2(38400u)); 
        m_byte_time = 138 * 1.5;
        break;
      case TOS_UART_57600:
        call HplUart.setCountSource(M16C60_UART_COUNT_SOURCE_F1_2);
        call HplUart.setSpeed(SPEED_F1_2(57600u)); 
        m_byte_time = 138;
        break;
      default:
        m_byte_time = 0xFFFF; // Set maximum value as default.
        break;
    }
    return SUCCESS;
  }

  async command uart_speed_t UartControl.speed()
  {
    return speed;
  }
  
  void uartOn()
  {
    call HplUart.setMode(M16C60_UART_MODE_UART_8BITS);
    call HplUart.disableCTSRTS();
  }

  async command error_t UartControl.setDuplexMode(uart_duplex_t duplex)
  {
    // Turn everything off
    call HplUart.disableTxInterrupt();
    call HplUart.disableTx();
    call HplUart.disableRxInterrupt();
    call HplUart.disableRx();
    m_rx_intr = 0;
    m_tx_intr = 0;

    mode = duplex;
    switch (duplex)
    {
      case TOS_UART_OFF:
        call HplUart.setMode(M16C60_UART_MODE_OFF);
        break;
      case TOS_UART_RONLY:
        uartOn();
        call HplUart.enableRx();
        break;
      case TOS_UART_TONLY:
        uartOn();
        call HplUart.enableTx();
        break;
      case TOS_UART_DUPLEX:
        uartOn();
        call HplUart.enableTx();
        call HplUart.enableRx();
        break;
      default:
        break;
    }
    
    return SUCCESS;
  }

  async command uart_duplex_t UartControl.duplexMode()
  {
    atomic return mode;
  }
  
  async command error_t UartControl.setParity(uart_parity_t parity)
  {
    if (mode != TOS_UART_OFF)
    {
      return FAIL;
    }
    call HplUart.setParity(parity);
    return SUCCESS;
  }

  async command uart_parity_t UartControl.parity()
  {
    return call HplUart.getParity();
  }
  
  async command error_t UartControl.setStop()
  {
    if (mode != TOS_UART_OFF)
    {
      return FAIL;
    }
    call HplUart.setStopBits(TOS_UART_STOP_BITS_2);
    return SUCCESS;
  }

  async command error_t UartControl.setNoStop()
  {
    if (mode != TOS_UART_OFF)
    {
      return FAIL;
    }
    call HplUart.setStopBits(TOS_UART_STOP_BITS_1);
    return SUCCESS;
  }

  async command bool UartControl.stopBits()
  {
    return (call HplUart.getStopBits() == TOS_UART_STOP_BITS_2);
  }
  
  async event void Counter.overflow() {}

  default async event void UartStream.sendDone( uint8_t* buf, uint16_t len, error_t error ){}
  default async event void UartStream.receivedByte( uint8_t byte ){}
  default  async event void UartStream.receiveDone( uint8_t* buf, uint16_t len, error_t error ){}

}
