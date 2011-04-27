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
 * Implementation of a Read interface for the HplMAX116xx<T> chips A/D channels.
 * The read setup and configuration settings must be initialized via
 * SetSetup and SetConfiguration before a call to Read.read() should be made.
 * Note that only SCAN[1:0] = 01 and SCAN[1:0] = 11 makes sense.
 * Channel select bits will be overwritten by the Read interface.
 * This module works good to be used with ArbitratedReadC.
 *
 * @param T The type that is needed to store a A/D value.
 *          ex: uint8_t for MAX11600-MAX11605 and
 *              uint16_t for MAX11612-MAX11617.
 * @param p_num_channels Number of A/D channels available on the device.
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#include "HplMAX116xx.h"

generic module HalMAX116xxReaderP(typedef T, uint8_t p_num_channels)
{
  provides interface Read<T>[uint8_t ain_id];
  provides interface Set<max116xx_setup_t> as SetSetup;
  provides interface Set<max116xx_configuration_t> as SetConfiguration;

  uses interface HplMAX116xx<T>;
}
implementation
{
  enum
  {
    S_IDLE,
    S_READ,
    S_READ_DONE
  };

  uint8_t m_state = S_IDLE;
  T m_value;
  error_t m_error;
  uint8_t m_read_adc_channel;
  max116xx_setup_t m_read_setup;
  max116xx_configuration_t m_read_configuration;

  command void SetSetup.set(max116xx_setup_t setup)
  {
    m_read_setup = setup;
    m_read_setup.reg = 1;
  }

  command void SetConfiguration.set(max116xx_configuration_t conf)
  {
    m_read_configuration = conf;
    m_read_configuration.reg = 0;
  }

  task void signalTask()
  {
    m_state = S_IDLE;
    signal Read.readDone[m_read_adc_channel](m_error, m_value);
  }

  command error_t Read.read[uint8_t ain_id]()
  {
    if (m_state != S_IDLE)
    {
      return EBUSY;
    }
    
    if (ain_id > (p_num_channels - 1))
    {
      return EINVAL;
    }

    m_read_configuration.cs = ain_id;
    m_read_adc_channel = ain_id;

    if (call HplMAX116xx.setSetupAndConfiguration(m_read_setup, m_read_configuration) == SUCCESS)
    {
      m_state = S_READ;
      return SUCCESS;
    }
    else
    {
      return FAIL;
    }
  }

  event void HplMAX116xx.setDone(error_t)
  {
    if (m_state != S_READ && m_state != S_READ_DONE)
    {
      return;
    }
    if (m_state == S_READ)
    {
      if (call HplMAX116xx.measureChannels(1, &m_value) != SUCCESS)
      {
        m_error = FAIL;
        post signalTask();
      }
    }
    else if (m_state == S_READ_DONE)
    {
      post signalTask();
    }
  }

  event void HplMAX116xx.measureChannelsDone(error_t e, uint8_t numChannels, T *buf)
  {
    if (m_state != S_READ)
    {
      return;
    }
    m_state = S_READ_DONE;
    m_error = e;
    if (m_error != SUCCESS)
    {
      post signalTask();
    }
    else
    {
      max116xx_setup_t setup;

      setup.rst = 0;
      setup.bip_uni = 0;
      setup.clk = 0;
      setup.sel = 0;
      
      if (call HplMAX116xx.setSetup(setup) != SUCCESS)
      {
        m_error = FAIL;
        post signalTask();
      }
    }
  }

  default event void Read.readDone[uint8_t id](error_t e, T val) {}
}
