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
 * Generic implementation of the HplMAX116xx<T> interface.
 *
 * @param T The type that is needed to store a A/D value.
 *          ex: uint8_t for MAX11600-MAX11605 and
 *              uint16_t for MAX11612-MAX11617.
 * @param p_addr I2C address of the device.
 * @param p_num_channels Number of A/D channels available on the device.
 * @param p_bit_mask Bit mask for the significant bits.
 *                   Ex: 0xFF for a 8 bit A/D device and
 *                       0xFFF for a 12 bit A/D device.
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#include "HplMAX116xx.h"

generic module HplMAX116xxP(typedef T,
                            uint8_t p_addr,
                            uint8_t p_num_channels,
                            uint32_t p_bit_mask) // p_bit_mask is 32 bits for future compatibility
{
  provides interface HplMAX116xx<T>;

  uses
  {
    interface Resource as I2CResource;
    interface I2CPacket<TI2CBasicAddr> as I2C;
  }
}
implementation
{
  enum
  {
    S_IDLE,
    S_SET,
    S_ADC,
  };

  norace error_t m_error;

  norace uint8_t m_state = S_IDLE;
  norace uint8_t m_write_buffer[2];
  norace uint8_t m_write_length;

  norace T* m_read_buffer;
  norace uint8_t m_read_length;

  void doI2CTask();

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
    switch(state)
    {
      case S_SET:
        signal HplMAX116xx.setDone(m_error);
        break;
      case S_ADC:
        signal HplMAX116xx.measureChannelsDone(m_error, m_read_length / sizeof(T), m_read_buffer);
        break;
    }
  }

  error_t set(max116xx_setup_t *setup, max116xx_configuration_t *conf, uint8_t nextState)
  {
    m_write_length = 0;
    if (setup != 0)
    {
      m_write_buffer[m_write_length++] = *((uint8_t*)setup);
    }
    if (conf != 0)
    {
      m_write_buffer[m_write_length++] = *((uint8_t*)conf);
    }
    return requestI2C(nextState);
  }

  command error_t HplMAX116xx.setSetup(max116xx_setup_t setup)
  {
    if (!isIdle())
    {
      return EBUSY;
    }

    setup.reg = 1;
    return set(&setup, 0, S_SET);
  }

  command error_t HplMAX116xx.setConfiguration(max116xx_configuration_t conf)
  {
    if (!isIdle())
    {
      return EBUSY;
    }

    conf.reg = 0;
    return set(0, &conf, S_SET);
  }

  command error_t HplMAX116xx.setSetupAndConfiguration(max116xx_setup_t setup,
      max116xx_configuration_t conf)
  {
    if (!isIdle())
    {
      return EBUSY;
    }

    setup.reg = 1;
    conf.reg = 0;
    return set(&setup, &conf, S_SET);
  }

  command error_t HplMAX116xx.measureChannels(uint8_t numChannels, T *buf)
  {
    if (!isIdle())
    {
      return EBUSY;
    }

    m_read_length = numChannels*sizeof(T);
    m_read_buffer = buf;
    return requestI2C(S_ADC);
  }

  async event void I2C.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data)
  {
    m_error = error;
    post signalTask();
  }

  async event void I2C.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data)
  {
    m_error = error;

    if (error == SUCCESS)
    {
      uint8_t i,j;
      uint32_t tmp;
      for (i = 0; i < length/sizeof(T); ++i)
      {
        tmp = 0;
        for (j = 0; j < sizeof(T); ++j)
        {
          tmp |= ( (uint32_t)data[i*sizeof(T)+j] << (8 * (sizeof(T)-j-1))  );
        }
        tmp &= p_bit_mask;
        // A memcpy is needed because if we try to do a cast we will
        // get a "conversion to non-scalar type requested" error.
        // Maybe there is a nicer way to do this?
        memcpy(&m_read_buffer[i], &tmp, sizeof(T));
      }
    }
    
    post signalTask();
  }

  event void I2CResource.granted()
  {
    doI2CTask();
  }

  void doI2CTask()
  {
    switch (m_state)
    {
      case S_SET:
        call I2C.write(I2C_START | I2C_STOP, p_addr, m_write_length, m_write_buffer);
        break;
      case S_ADC:
        call I2C.read(I2C_START | I2C_STOP, p_addr, m_read_length, (uint8_t*)m_read_buffer);
        break;
    }
  }

  default event void HplMAX116xx.setDone(error_t) {}
  default event void HplMAX116xx.measureChannelsDone(error_t e, uint8_t numChannels, T *buf) {}
}
