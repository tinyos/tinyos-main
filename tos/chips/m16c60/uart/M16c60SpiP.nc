/*
 * Copyright (c) 2011 Lulea University of Technology
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
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Spi interface implementations for a M16c/60 Uart.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

generic module M16c60SpiP()
{
  provides
  {
    interface SpiPacket;
    interface SpiByte;
    interface FastSpiByte;
  }
  uses interface HplM16c60Uart as HplUart;
}
implementation
{
  enum
  {
    S_IDLE,
    S_PACKET,
  };
  
  uint8_t m_state = S_IDLE;
  uint8_t* m_tx_buf;
  int8_t* m_rx_buf;
  uint8_t m_length;
  uint8_t m_pos;

  async command error_t SpiPacket.send(uint8_t* txBuf,
                                       uint8_t* rxBuf,
                                       uint16_t len )
  {
    atomic
    {
      if (m_state != S_IDLE)
      {
        return EBUSY;
      }
      m_state = S_PACKET;
    }
    
    if (len == 0)
    {
      return EINVAL;
    }
    atomic
    {
      m_rx_buf = rxBuf;
      m_tx_buf = txBuf;
      m_length = len;
      m_pos = 0;
    }

    call HplUart.enableRxInterrupt();
    atomic call HplUart.tx(m_tx_buf[m_pos]);
    return SUCCESS;
  }

  async event void HplUart.rxDone()
  {
    atomic
    {
      if (m_state != S_PACKET)
      {
        return;
      }
      m_rx_buf[m_pos++] = call HplUart.rx();
      if (m_pos == m_length)
      {
        // Done sending and receiving.
        call HplUart.disableRxInterrupt();
        m_state = S_IDLE;
        signal SpiPacket.sendDone(m_tx_buf, m_rx_buf, m_length, SUCCESS);
      }
      else
      {
        call HplUart.tx(m_tx_buf[m_pos]);
      }
    }
  }
  async event void HplUart.txDone() {}
  
  default async event void SpiPacket.sendDone(uint8_t* txBuf,
                                              uint8_t* rxBuf,
                                              uint16_t len,
                                              error_t error ) {}

  async command uint8_t SpiByte.write( uint8_t tx )
  {
    uint8_t tmp = call HplUart.rx(); // Empty rx buf

    call HplUart.tx(tx);
    while(call HplUart.isRxEmpty());
    return call HplUart.rx();
  }

  async command void FastSpiByte.splitWrite(uint8_t data)
  {
    uint8_t tmp = call HplUart.rx(); // Empty rx buf
    call HplUart.tx(data);
  }

  async command uint8_t FastSpiByte.splitReadWrite(uint8_t data)
  {
    uint8_t tmp;

    while(call HplUart.isRxEmpty());
    tmp = call HplUart.rx();
    call HplUart.tx(data);
    return tmp;
  }

  async command uint8_t FastSpiByte.splitRead()
  {
    while(call HplUart.isRxEmpty());
    return call HplUart.rx();
  }

  async command uint8_t FastSpiByte.write(uint8_t data)
  {
    return call SpiByte.write(data);
  }
}
