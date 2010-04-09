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
 * Implementation of the time capture on RF230 interrupt and the
 * FastSpiBus interface.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

module HplRF230P
{
  provides
  {
    interface GpioCapture as IRQ;
    interface Init as PlatformInit;
    interface FastSpiByte;
  }

  uses
  {
    interface GeneralIO as PortIRQ;
    interface GeneralIO as PortVCC;
    interface GpioInterrupt as GIRQ;
    interface SoftSpiBus as Spi;
    interface Alarm<TRadio, uint16_t> as Alarm;
  }
}
implementation
{
  command error_t PlatformInit.init()
  {
    call PortIRQ.makeInput(); 
    call PortIRQ.clr();
    call GIRQ.disable();
    call PortVCC.makeOutput(); 
    call PortVCC.set(); 

    return SUCCESS;
  }

  async event void GIRQ.fired()
  {
    signal IRQ.captured(call Alarm.getNow());
  }
  async event void Alarm.fired() {}

  default async event void IRQ.captured(uint16_t time) {}

  async command error_t IRQ.captureRisingEdge()
  {
    call GIRQ.enableRisingEdge();
    return SUCCESS;
  }

  async command error_t IRQ.captureFallingEdge()
  {
    // falling edge comes when the IRQ_STATUS register of the RF230 is read
    return FAIL;	
  }

  async command void IRQ.disable()
  {
    call GIRQ.disable();
  }

  /**
   * Faster software implementation of the SPI bus for communication
   * with the RF230 chip.
   */
  uint8_t fastWrite(uint8_t byte)
  {
#define fwMOSIset() P1.BIT.P1_1 = 1
#define fwMOSIclr() P1.BIT.P1_1 = 0
#define fwSCLKset() P3.BIT.P3_3 = 1
#define fwSCLKclr() P3.BIT.P3_3 = 0
#define fwMISOget() P1.BIT.P1_0
    uint8_t data = 0;
    uint8_t mask = 0x80;
    atomic {
      if (byte & mask)
      {
        fwMOSIset();
      }
      else
      {
        fwMOSIclr();
      }
      fwSCLKclr();
      if( fwMISOget() )
        data |= mask;
      fwSCLKset();
      mask >>= 1;

      if (byte & mask)
      {
        fwMOSIset();
      }
      else
      {
        fwMOSIclr();
      }
      fwSCLKclr();
      if( fwMISOget() )
        data |= mask;
      fwSCLKset();
      mask >>= 1;

      if (byte & mask)
      {
        fwMOSIset();
      }
      else
      {
        fwMOSIclr();
      }
      fwSCLKclr();
      if( fwMISOget() )
        data |= mask;
      fwSCLKset();
      mask >>= 1;

      if (byte & mask)
      {
        fwMOSIset();
      }
      else
      {
        fwMOSIclr();
      }
      fwSCLKclr();
      if( fwMISOget() )
        data |= mask;
      fwSCLKset();
      mask >>= 1;

      if (byte & mask)
      {
        fwMOSIset();
      }
      else
      {
        fwMOSIclr();
      }
      fwSCLKclr();
      if( fwMISOget() )
        data |= mask;
      fwSCLKset();
      mask >>= 1;

      if (byte & mask)
      {
        fwMOSIset();
      }
      else
      {
        fwMOSIclr();
      }
      fwSCLKclr();
      if( fwMISOget() )
        data |= mask;
      fwSCLKset();
      mask >>= 1;

      if (byte & mask)
      {
        fwMOSIset();
      }
      else
      {
        fwMOSIclr();
      }
      fwSCLKclr();
      if( fwMISOget() )
        data |= mask;
      fwSCLKset();
      mask >>= 1;

      if (byte & mask)
      {
        fwMOSIset();
      }
      else
      {
        fwMOSIclr();
      }
      fwSCLKclr();
      if( fwMISOget() )
        data |= mask;
      fwSCLKset();
      mask >>= 1;
    }
    return data;
  }

  uint8_t tmp_data;
  inline async command void FastSpiByte.splitWrite(uint8_t data)
  {
    atomic tmp_data = fastWrite(data);
  }

  inline async command uint8_t FastSpiByte.splitRead()
  {
    atomic return tmp_data;
  }

  inline async command uint8_t FastSpiByte.splitReadWrite(uint8_t data)
  {
    uint8_t b;
    atomic
    {
      b = tmp_data;
      tmp_data = fastWrite(data);
    }
    return b;
  }

  inline async command uint8_t FastSpiByte.write(uint8_t data)
  {
    return fastWrite(data);
  }
}
