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
 * Software implementation of all the Spi interfaces.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */
generic module SoftwareSpiC()
{
  provides
  {
    interface SpiPacket;
    interface SpiByte;
    interface FastSpiByte;
  }
  uses
  {
    interface GeneralIO as SCLK;
    interface GeneralIO as MISO;
    interface GeneralIO as MOSI;
  }
}
implementation
{
  enum
  {
    S_IDLE,
    S_PACKET_SEND,
  };
  uint8_t m_state = S_IDLE;
  uint8_t* m_txBuf;
  uint8_t* m_rxBuf;
  uint16_t m_len;
  norace uint8_t m_fastByte;
  
  task void signalSendDone()
  {
    uint8_t* tmpTxBuf;
    uint8_t* tmpRxBuf;
    uint16_t tmpLen;
    atomic
    {
      m_state = S_IDLE;
      tmpTxBuf = m_txBuf;
      tmpRxBuf = m_rxBuf;
      tmpLen = m_len;
    }
    signal SpiPacket.sendDone(tmpTxBuf, tmpRxBuf, tmpLen, SUCCESS);
  }
    
  async command error_t SpiPacket.send( uint8_t* txBuf, uint8_t* rxBuf, uint16_t len )
  {
    uint16_t i;
    atomic
    {
      if (m_state != S_IDLE)
      {
        return EBUSY;
      }
      m_state = S_PACKET_SEND;
      m_txBuf = txBuf;
      m_rxBuf = rxBuf;
      m_len = len;
      for(i = 0; i < len; ++i)
      {
        rxBuf[i] = call SpiByte.write(txBuf[i]);
      }
    }
    post signalSendDone();
    return SUCCESS;
  }
  default async event void SpiPacket.sendDone(uint8_t* txBuf, uint8_t* rxBuf, uint16_t len, error_t error) {}

  async command uint8_t SpiByte.write( uint8_t byte )
  {
    uint8_t data = 0;
    uint8_t mask = 0x80;

    atomic do
    {
      if( (byte & mask) != 0 )
        call MOSI.set();
      else
        call MOSI.clr();

      call SCLK.clr();
      if( call MISO.get() )
        data |= mask;
      call SCLK.set();
    } while( (mask >>= 1) != 0 );

    return data;
  }

  async command void FastSpiByte.splitWrite(uint8_t data)
  {
    m_fastByte = call SpiByte.write(data);
  }

  async command uint8_t FastSpiByte.splitReadWrite(uint8_t data)
  {
    uint8_t tmp = m_fastByte;
    m_fastByte = call SpiByte.write(data);
    return tmp;
  }

  async command uint8_t FastSpiByte.splitRead()
  {
    return m_fastByte;
  }

  async command uint8_t FastSpiByte.write(uint8_t data)
  {
    return call SpiByte.write(data);
  }
}
