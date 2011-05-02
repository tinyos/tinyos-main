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
 * I2CPacket interface implementation for a M16c/60 Uart.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#include "I2C.h"

generic module M16c60I2CP()
{
  provides interface I2CPacket<TI2CBasicAddr>;
  provides interface AsyncStdControl;
  uses interface HplM16c60Uart as HplUart;
}
implementation
{
  enum
  {
    S_OFF,
    S_IDLE,
    S_READ_SEND_ADDR,
    S_READ,
    S_WRITE,
  };
  
  norace uint8_t m_state = S_OFF;
  norace uint8_t* m_data;
  norace uint8_t m_length;
  norace uint8_t m_data_pos;
  norace uint16_t m_addr;
  norace error_t m_error;
  norace i2c_flags_t m_flags;

  void receiveNext();
  void writeNext();

  void setIdleState()
  {
    atomic m_state = S_IDLE;
    call HplUart.disableTxInterrupt();
    call HplUart.disableRxInterrupt();
  }

  async command error_t AsyncStdControl.start()
  {
    if (m_state != S_OFF)
    {
      return EALREADY;
    }
    call HplUart.setMode(M16C60_UART_MODE_I2C);
    // TODO(henrik) Dont hardcode the speed here.
    call HplUart.setSpeed((unsigned char)((((float)MAIN_CRYSTAL_SPEED*1000000.0) / (2.0 * (100000.0))) - 0.5));
    call HplUart.enableTx();
    call HplUart.enableRx();
    m_state = S_IDLE;
    return SUCCESS;
  }

  async command error_t AsyncStdControl.stop()
  {
    if (m_state == S_OFF)
    {
      return EALREADY;
    }
    else if (m_state != S_IDLE)
    {
      return EBUSY;
    }
    call HplUart.setMode(M16C60_UART_MODE_OFF);
    m_state = S_OFF;
    return SUCCESS;
  }

  async command error_t I2CPacket.read(i2c_flags_t flags,
      uint16_t addr, uint8_t length, uint8_t* data)
  {
    if (m_state == S_OFF)
    {
      return EOFF;
    }
    else if (m_state != S_IDLE)
    {
      return EBUSY;
    }
    atomic
    {
      m_state = S_READ;
      m_addr = addr;
      m_flags = flags;
      m_length = length;
      m_data = data;
      m_data_pos = 0;
    }


    if (m_flags & I2C_START)
    {
      atomic m_state = S_READ_SEND_ADDR;
      call HplUart.i2cStart();
      call HplUart.enableRxInterrupt();
      call HplUart.enableTxInterrupt();
      call HplUart.i2cTx((addr<<1)+1);
    }
    else
    {
      call HplUart.enableRxInterrupt();
      call HplUart.enableTxInterrupt();
      receiveNext();
    }

    return SUCCESS;
  }

  void receiveNext()
  {
    bool nack = false;
    if (m_data_pos == m_length)
    {
      // Reception is done
      if (m_flags & I2C_STOP)
      {
        call HplUart.i2cStop();
      }
      setIdleState();
      signal I2CPacket.readDone(SUCCESS, m_addr, m_data_pos,  m_data);
      return;
    }
    else if (m_data_pos == m_length - 1 && !(m_flags & I2C_ACK_END))
    {
      nack = true;
    }
    
    call HplUart.i2cStartRx(nack);
  }

  async command error_t I2CPacket.write(i2c_flags_t flags,
      uint16_t addr, uint8_t length, uint8_t* data)
  {
    if (m_state == S_OFF)
    {
      return EOFF;
    }
    else if (m_state != S_IDLE)
    {
      return EBUSY;
    }
    atomic
    {
      m_state = S_WRITE;
      m_addr = addr;
      m_flags = flags;
      m_length = length;
      m_data = data;
      m_data_pos = 0;
    }
    call HplUart.enableRxInterrupt();
    call HplUart.enableTxInterrupt();
    
    if (m_flags & I2C_START)
    {
      call HplUart.i2cStart();
      call HplUart.i2cTx(addr << 1);
    }
    else
    {
      writeNext();
    }

    return SUCCESS;
  }

  void writeNext()
  {
    if (m_data_pos == m_length)
    {
      // Sending is done
      if (m_flags & I2C_STOP)
      {
        call HplUart.i2cStop();
      }
      setIdleState();
      signal I2CPacket.writeDone(SUCCESS, m_addr, m_data_pos,  m_data);
    }
    else
    {
      atomic call HplUart.i2cTx(m_data[m_data_pos++]);
    }
  }

  void interrupt(bool ack)
  {
    switch(m_state)
    {
      case S_READ_SEND_ADDR:
        if (!ack)
        {
          setIdleState();
          signal I2CPacket.readDone(ENOACK, m_addr, 0,  m_data);
        }
        else
        {
          atomic m_state = S_READ;
          receiveNext();
        }
        break;
      case S_READ:
        m_data[m_data_pos++] = call HplUart.rx();
        receiveNext();
        break;
      case S_WRITE:
        if (!ack)
        {
          setIdleState();
          signal I2CPacket.writeDone(ENOACK, m_addr, 0,  m_data);
        }
        else
        {
          writeNext();
        }
        break;
    }
  }

  async event void HplUart.txDone()
  {
    interrupt(false);
  }

  async event void HplUart.rxDone()
  {
    interrupt(true);
  }

  default async event void I2CPacket.writeDone(error_t e,
      uint16_t addr, uint8_t length, uint8_t* data) {}

  default async event void I2CPacket.readDone(error_t e,
      uint16_t addr, uint8_t length, uint8_t* data) {}

}
