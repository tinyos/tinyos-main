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
 * Implementation of the Hpl interface for Microchips MCP4728 12bit
 * digital-to-analog converter chip with EEPROM.
 *
 * @param p_addr The I2C address of the device.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#include "HplMCP4728.h"

generic module HplMCP4728P(uint8_t p_addr)
{
  provides interface HplMCP4728;
  provides interface Init;

  uses
  {
    interface Resource as I2CResource;
    interface I2CPacket<TI2CBasicAddr> as I2C;
    interface GeneralIO as RDY;
    interface GeneralIO as LDAC;
  }
}
implementation
{
  enum
  {
    S_IDLE,
    S_SET_REF,
    S_SET_GAIN,
    S_SET_POWER_DOWN,
    S_SET_OUTPUT,
    S_SET_DAC_REGISTER_EEPROM
  };

  norace uint8_t m_state = S_IDLE;
  norace uint8_t m_buffer[15];
  norace uint8_t m_write_length;
  norace uint8_t m_dac;
  norace error_t m_error;

  task void isReady()
  {
    if (!call HplMCP4728.EEPROMisReady())
    {
      post isReady();
    }
    else
    {
      call I2C.write(I2C_START | I2C_STOP, p_addr, m_write_length, m_buffer);
    }
  }

  bool isIdle()
  {
    return m_state == S_IDLE ? true : false;
  }

  error_t requestI2C(uint8_t newState)
  {
    if (call I2CResource.request() == SUCCESS)
    {
      m_state = newState;
      return SUCCESS;
    }
    else
    {
      return FAIL;
    }
  }

  task void signalTask()
  {
    uint8_t state = m_state;
    call I2CResource.release();
    m_state = S_IDLE;
    call LDAC.clr();
    call LDAC.set();
    switch(state)
    {
      case S_SET_REF:
        signal HplMCP4728.setRefereceDone(m_error);
        break;
      case S_SET_GAIN:
        signal HplMCP4728.setGainDone(m_error);
        break;
      case S_SET_POWER_DOWN:
        signal HplMCP4728.setPowerDownDone(m_error);
        break;
      case S_SET_OUTPUT:
        signal HplMCP4728.setOutputVoltageDone(m_error);
        break;
      case S_SET_DAC_REGISTER_EEPROM:
        signal HplMCP4728.writeDACRegisterAndEEPROMDone(m_error, m_dac);
        break;
    }
  }

  command error_t Init.init()
  {
    call RDY.makeInput();
    call LDAC.makeOutput();
    call LDAC.set();
    return SUCCESS;
  }

  command bool HplMCP4728.EEPROMisReady()
  {
    return call RDY.get();
  }

  command void HplMCP4728.setLDAC(bool high)
  {
    if (high)
    {
      call LDAC.set();
    }
    else
    {
      call LDAC.clr();
    }
  }

  command error_t HplMCP4728.setReference(bool a_internal,
                                          bool b_internal,
                                          bool c_internal,
                                          bool d_internal)
  {
    if (!isIdle())
    {
      return EBUSY;
    }
    m_buffer[0] = 0x80 | a_internal << 3 | b_internal << 2
                       | c_internal << 1 | d_internal;
    m_write_length = 1;

    return requestI2C(S_SET_REF); 
  }

  command error_t HplMCP4728.setGain(bool a, bool b, bool c, bool d)
  {
    if (!isIdle())
    {
      return EBUSY;
    }
    m_buffer[0] = 0xc0 | a << 3 | b << 2 | c << 1 | d;
    m_write_length = 1;

    return requestI2C(S_SET_GAIN); 
  }

  command error_t HplMCP4728.setPowerDown(MCP4728_POWER_DOWN a,
                                          MCP4728_POWER_DOWN b,
                                          MCP4728_POWER_DOWN c,
                                          MCP4728_POWER_DOWN d)
  {
    if (!isIdle())
    {
      return EBUSY;
    }
    m_buffer[0] = 0xa0 | a << 2 | b;
    m_buffer[1] =  c << 6 | d << 4;
    m_write_length = 2;

    return requestI2C(S_SET_POWER_DOWN); 
  }

  command error_t HplMCP4728.setOutputVoltage(uint16_t a,
                                              uint16_t b,
                                              uint16_t c,
                                              uint16_t d)
  {
    if (!isIdle())
    {
      return EBUSY;
    }
    m_buffer[0] = 0x0F & (a >> 8);
    m_buffer[1] = 0xFF & a;

    m_buffer[2] = 0x0F & (b >> 8);
    m_buffer[3] = 0xFF & b;

    m_buffer[4] = 0x0F & (c >> 8);
    m_buffer[5] = 0xFF & c;

    m_buffer[6] = 0x0F & (d >> 8);
    m_buffer[7] = 0xFF & d;

    m_write_length = 8;

    return requestI2C(S_SET_OUTPUT);
  }

  command error_t HplMCP4728.writeDACRegisterAndEEPROM(MCP4728_CHANNEL channel,
      uint16_t volt, bool internal_vref, MCP4728_POWER_DOWN power_down,
      bool gain,bool upload)
  {
    if (!isIdle())
    {
      return EBUSY;
    }

    m_dac = channel;
    m_buffer[0] = 0x58 | channel << 1 | !upload;
    m_buffer[1] = internal_vref << 7 | power_down << 5
                  | gain << 4 | 0xF & (volt >> 8);
    m_buffer[2] = 0xFF & volt;
    m_write_length = 3;

    return requestI2C(S_SET_DAC_REGISTER_EEPROM);
  }

  async event void I2C.writeDone(error_t error, uint16_t addr,
      uint8_t length, uint8_t* data)
  {
    m_error = error;
    post signalTask();
  }

  event void I2CResource.granted()
  {
    post isReady();
  }
  
  async event void I2C.readDone(error_t error, uint16_t addr,
      uint8_t length, uint8_t* data) {}
}
