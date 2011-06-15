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
 * Implementation of a Read interface that can be used to read a AD port
 * on Mulle. It will switch VRef on and off automatically and also set
 * the AD port as input.
 *
 * NOTE: The state of the AD port will not be changed from input on a
 *       readDone event.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

generic module AdcReadP(uint8_t channel, uint8_t precision, uint8_t prescaler)
{
  provides interface M16c60AdcConfig;
  provides interface Read<uint16_t>;

  uses interface GeneralIO as Pin;
  uses interface Read<uint16_t> as ReadAdc;
  uses interface StdControl as AVccControl;
}
implementation
{
  async command uint8_t M16c60AdcConfig.getChannel()
  {
    return channel;
  }

  async command uint8_t M16c60AdcConfig.getPrecision()
  {
    return precision;
  }

  async command uint8_t M16c60AdcConfig.getPrescaler()
  {
    return prescaler;
  }

  enum
  {
    S_IDLE,
    S_READING,
  };

  uint8_t m_state = S_IDLE;

  command error_t Read.read()
  {
    if (m_state != S_IDLE)
    {
      return EBUSY;
    }
    call AVccControl.start();
    call Pin.makeInput();

    if (call ReadAdc.read() != SUCCESS)
    {
      call AVccControl.stop();
    }
    m_state = S_READING;
    return SUCCESS;
  }

  event void ReadAdc.readDone(error_t e, uint16_t val)
  {
    m_state = S_IDLE;
    // The control of the off state for the pin should be
    // handled from somewhere else.
    call AVccControl.stop();
    signal Read.readDone(e, val);
  }

  default async command void Pin.makeInput() {}
  default event void Read.readDone(error_t e, uint16_t val) {}
}
