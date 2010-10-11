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

#include "I2C.h"

/**
 * This module implements a software I2CPacket with 7-bit addressing.
 * The SDA and SCL pins must have pull-up resistors.
 *
 * This code was written with help from the I2C Wikipedia page:
 * http://en.wikipedia.org/wiki/I%C2%B2C
 * 
 * @param speed The number of micro seconds 
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */
generic module SoftwareI2CPacketC(int speed)
{
  provides interface I2CPacket<TI2CBasicAddr>;

  uses interface GeneralIO as SDA;
  uses interface GeneralIO as SCL;
  uses interface BusyWait<TMicro, uint16_t>;
}
implementation
{
  enum
  {
    S_IDLE,
    S_BUSY,      
  };

  uint8_t m_state = S_IDLE;
  uint16_t m_addr;
  uint8_t m_length;
  uint8_t* m_data;
  error_t m_error;
  bool m_read;

  uint8_t READSDA()
  {
    call SDA.makeInput();
    return call SDA.get();
  }

  uint8_t READSCL()
  {
    call SCL.makeInput();
    return call SCL.get();
  }

  void CLRSCL()
  {
    call SCL.clr();
    call SCL.makeOutput();
  }

  void CLRSDA()
  {
    call SDA.clr();
    call SDA.makeOutput();
  }

  void i2cDelay(uint16_t u) {
    call BusyWait.wait(u);
  }

  uint8_t i2cReadBit(void)
  {
    uint8_t bit;

    /* lets the slave drive data */
    READSDA();
    i2cDelay(speed/2);
    /* Clock stretching */
    while (READSCL() == 0);
    /* SCL is high, now data is valid */
    bit = READSDA();
    i2cDelay(speed/2);
    CLRSCL();
    return bit;
  }

  error_t i2cWriteBit(bool bit)
  {
    if (bit) 
      READSDA();
    else 
      CLRSDA();
    i2cDelay(speed/2);
    /* Clock stretching */
    while (READSCL() == 0);
    /* SCL is high, now data is valid */
    /* check that nobody is driving SDA */
    if (bit && READSDA() == 0)
      return FAIL;
    i2cDelay(speed/2);
    CLRSCL();
    return SUCCESS;
  }

  error_t i2cStartCond(void)
  {
    READSCL();
    READSDA();
    i2cDelay(speed/2);
    if (READSDA() == 0)
      return FAIL;

    /* SCL is high, set SDA from 1 to 0 */
    CLRSDA();
    i2cDelay(speed/2);
    CLRSCL();
    return SUCCESS;
  }

  error_t i2cStopCond(void)
  {
    /* set SDA to 0 */
    CLRSDA();
    i2cDelay(speed/2);

    /* Clock stretching */
    while (READSCL() == 0); /* Release SCL, wait for done */

    /* SCL is high, set SDA from 0 to 1 */
    i2cDelay(speed/2);
    READSDA(); /* Release SDA */

    /* Verify, give some time to settle first */
    i2cDelay(speed/2);
    if (READSDA() == 0)
      return FAIL;
    return SUCCESS;
  }

  error_t i2cTx(uint8_t byte)
  {
    uint8_t bit;
    uint8_t ack;
    error_t error = SUCCESS;

    for (bit = 0; bit < 8; bit++) {
      error = ecombine(error, i2cWriteBit(byte & 0x80));
      byte <<= 1;
    }

    // The ack bit is 0 for success
    if (!i2cReadBit())
    {
      return ecombine(error, SUCCESS);
    }
    else 
    {
      return FAIL;
    }
  }

  uint8_t i2cRx (bool nack)
  {
    uint8_t byte = 0;
    uint8_t bit;

    for (bit = 0; bit < 8; bit++) {
      byte <<= 1;
      byte |= i2cReadBit();
    }
    i2cWriteBit(nack);
    return byte;
  }

  task void signalTask()
  {
    uint16_t addr;
    uint8_t length;
    uint8_t* data;
    error_t error;
    bool read;
    atomic
    {
      addr = m_addr;
      length = m_length;
      data = m_data;
      error = m_error;
      m_state = S_IDLE;
      read = m_read;
    }
    if (read)
    {
      signal I2CPacket.readDone(error, addr, length,  data);
    }
    else
    {
      signal I2CPacket.writeDone(error, addr, length,  data);
    }
  }

  async command error_t I2CPacket.read(i2c_flags_t flags, uint16_t addr, uint8_t length, uint8_t* data)
  {
    uint8_t i;
    error_t error = SUCCESS;

    // Both I2C_STOP and I2C_ACK_END flags are not allowed at the same time.
    if ((flags & I2C_STOP) && (flags & I2C_ACK_END))
    {
      return EINVAL;
    }

    atomic
    {
      if (m_state == S_IDLE)
      {
        m_state = S_BUSY;
      }
      else
      {
        return EBUSY;
      }
    }
    atomic
    {
      if (flags & I2C_START)
      {
        error = ecombine(error, i2cStartCond());
        error = ecombine(error, i2cTx((addr<<1)|1)); 
      }

      // Only read data from the device if length is >0.
      // TODO(henrik): Should a data length of 0 be a invalid input?
      if (length > 0)
      {
        // Read the data from the device.
        for (i = 0; i < length-1; ++i)
        {
          data[i] = i2cRx(false);
        }
        if (flags & I2C_ACK_END)
        {
          data[length-1] = i2cRx(false);
        }
        else
        {
          data[length-1] = i2cRx(true);
        }
      }
      if (flags & I2C_STOP)
      {
        error = ecombine(error, i2cStopCond());
      }

      m_error = error;
      m_addr = addr;
      m_length = length;
      m_data = data;
      m_read = true;
    }
    post signalTask();

    return SUCCESS;
  }

  async command error_t I2CPacket.write(i2c_flags_t flags, uint16_t addr, uint8_t length, uint8_t* data)
  {
    uint8_t i;
    error_t error = SUCCESS;

    atomic
    {
      if (m_state == S_IDLE)
      {
        m_state = S_BUSY;
      }
      else
      {
        return EBUSY;
      }
    }
    atomic
    {
      if (flags & I2C_START)
      {
        error = ecombine(error, i2cStartCond());
      }

      error = ecombine(error, i2cTx(addr<<1));

      // Send the data to the device (stop on error).
      for (i = 0; error == SUCCESS && i < length; ++i)
      {
        error = ecombine(error, i2cTx(data[i]));
      }

      if (flags & I2C_STOP)
      {
        error = ecombine(error, i2cStopCond());
      }

      m_error = error;
      m_addr = addr;
      m_length = length;
      m_data = data;
      m_read = false;
    }
    post signalTask();
    return SUCCESS;
  }
}
