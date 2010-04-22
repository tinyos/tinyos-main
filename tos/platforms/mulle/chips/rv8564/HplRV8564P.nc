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

/**
 * Implementation of the RV-8564-C2 real time clock.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#include "rv8564.h"
#include "I2C.h"
module HplRV8564P
{
  provides interface HplRV8564 as RTC;
  provides interface Init;
  provides interface Init as Startup;

  uses interface GeneralIO as CLKOE;
  uses interface GeneralIO as CLKOUT;
  uses interface GeneralIO;
  uses interface GpioInterrupt;
  uses interface I2CPacket<TI2CBasicAddr> as I2C;
  uses interface Resource as I2CResource;
  uses interface BusyWait<TMicro, uint16_t>;
}
implementation
{

  enum
  {
    S_IDLE,
    S_READING,
    S_WRITING
  };
  norace uint8_t m_state = S_IDLE;
  norace uint8_t m_buf[2];

  command error_t Init.init()
  {
    call CLKOUT.makeInput();
    call CLKOE.clr();
    call CLKOE.makeOutput();
    return SUCCESS;
  }

  command error_t Startup.init()
  {
    int i;
    // The RTC needs a maximum of 500ms to startup
    for (i = 0; i < 10; ++i)
    {
      call BusyWait.wait(50000);
    }
    return SUCCESS;
  }

  command void RTC.enableCLKOUT()
  {
    call CLKOE.set();
  }

  command void RTC.disableCLKOUT()
  {
    call CLKOE.clr();
  }

  command void RTC.enableInterrupt()
  {
    call GpioInterrupt.enableFallingEdge();
  }

  command void RTC.disableInterrupt()
  {
    call GpioInterrupt.disable();
  }

  command error_t RTC.readRegister(uint8_t reg)
  {
    if (m_state != S_IDLE)
    {	
      return EBUSY;
    }
    m_state = S_READING;
    m_buf[0] = reg;
    if (call I2CResource.request() == SUCCESS)
    {
      return SUCCESS;
    }
    else
    {
      m_state = S_IDLE;
      return FAIL;
    }
    return SUCCESS;
  }

  command error_t RTC.writeRegister(uint8_t reg, uint8_t value)
  { 
    if (m_state != S_IDLE)
    {
      return FAIL;
    }
    m_state = S_WRITING;
    atomic m_buf[0] = reg;
    atomic m_buf[1] = value;
    if (call I2CResource.request() == SUCCESS)
    {
      return SUCCESS;
    }
    else
    {
      m_state = S_IDLE;
      return FAIL;
    }
  }

  event void I2CResource.granted()
  {
    atomic
    {
      if (m_state == S_READING)
      {
        call I2C.write(I2C_START | I2C_STOP, RV8564_ADDR, 1, m_buf);
      }
      else if (m_state == S_WRITING)
      {
        call I2C.write(I2C_START | I2C_STOP, RV8564_ADDR, 2, m_buf);    
      }
    }
  }

  async event void GpioInterrupt.fired()
  {
    signal RTC.fired();
  }

  async event void I2C.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data)
  {
    atomic
    {
      if (m_state == S_READING)
      {
        call I2CResource.release();
        m_state = S_IDLE;
        signal RTC.readRegisterDone(error, m_buf[0], m_buf[1]);
      }
    }
  }

  async event void I2C.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data)
  {
    if (m_state == S_READING)
    {
      if (error != SUCCESS)
      {
        call I2CResource.release();
        m_state = S_IDLE;
        signal RTC.readRegisterDone(error, m_buf[0], 0);
        return;
      }
      else
      {
        call I2C.read(I2C_START | I2C_STOP, RV8564_ADDR, 1, m_buf + 1);
      }
    }
    else if (m_state == S_WRITING)
    {
      call I2CResource.release();
      m_state = S_IDLE;
      signal RTC.writeRegisterDone(error, m_buf[0]);
    }
  }
}
