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
module RV8564P
{
  provides interface RV8564 as RTC;
  // TODO(henrik) Exactly how is the RTC connected to mulle, what is the functionallity of GeneralIO?
  //              Maybe there is only a init needed because the chip is always on?
  uses interface GeneralIO as CLKOE;
  uses interface GeneralIO as CLKOUT;
  uses interface GeneralIO;
  uses interface GpioInterrupt;
  uses interface I2CPacket<TI2CBasicAddr> as I2C;
  uses interface Resource as I2CResource;
}
implementation
{

  enum
  {
    OFF,
    IDLE,
    READING,
    WRITING
  };
  norace uint8_t state = OFF;
  norace uint8_t read_register;
  uint8_t read_register_value;
  uint8_t write_buffer[2];

  command error_t RTC.on()
  {
    if (state != OFF)
    {
      return SUCCESS;
    }
    state = IDLE;
    return SUCCESS;
  }

  command error_t RTC.off()
  {
    if  (state == OFF)
    {
      return SUCCESS;
    }
    else if (state != IDLE)
    {
      return FAIL;
    }
    call CLKOE.clr();
    call CLKOUT.clr();
    return SUCCESS;
  }

  command bool RTC.isOn()
  {
    return ((state != OFF) ? true : false);
  }

  command void RTC.enableCLKOUT()
  {
  	call CLKOUT.makeInput();
  	call CLKOUT.clr();
  	call CLKOE.makeOutput();
  	call CLKOE.set();
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
    uint8_t val;
    if (state != IDLE)
    {	
      return FAIL;
    }
    state = READING;
    read_register = reg;
    call I2CResource.request();
    return SUCCESS;
  }

  command error_t RTC.writeRegister(uint8_t reg, uint8_t value)
  { 
    if (state != IDLE)
    {
      return FAIL;
    }
    state = WRITING;
    write_buffer[0] = reg;
    write_buffer[1] = value;
    call I2CResource.request();
    return SUCCESS;
  }

  event void I2CResource.granted()
  {
    atomic {
      if (state == READING)
      {
        call I2C.write(I2C_START, RV8564_ADDR, 1, &read_register);
      }
      else if (state == WRITING)
      {
        call I2C.write(I2C_START | I2C_STOP, RV8564_ADDR, 2, write_buffer);    
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
      if (state == READING && data == &read_register_value)
      {
        state = IDLE;
        call I2CResource.release();
        signal RTC.readRegisterDone(read_register_value, read_register);
      }	
    }
  }

  async event void I2C.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data)
  {
    if (state == READING)
    {
      call I2C.read(I2C_START | I2C_STOP, RV8564_ADDR, 1, &read_register_value);
    }
    else if (state == WRITING)
    {
      state = IDLE;
      call I2CResource.release();
      signal RTC.writeRegisterDone(write_buffer[0]);
    }
  }

  default async event void RTC.readRegisterDone(uint8_t val, uint8_t reg) {}
  default async event void RTC.writeRegisterDone(uint8_t reg) {}
  default async event void RTC.fired() { }
}
