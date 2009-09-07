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

/*
 * Copyright (c) 2006 Stanford University.
 * All rights reserved.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
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
 *
 * @author Philip Levis
 */

/**
 * This driver implements an software Spi Master controller.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

generic module SoftSpiMasterPacketP()
{
  provides interface AsyncStdControl;
  provides interface SpiByte;
  provides interface SpiPacket;
  
  uses interface SoftSpiBus as Spi;
}
implementation
{
  enum
  {
    SPI_OFF          = 0,
    SPI_IDLE         = 1,
    SPI_BUSY         = 2,      
  } soft_spi_state_t;

  uint8_t state = SPI_OFF;

  async command error_t AsyncStdControl.start()
  {
    atomic
    {
      if (state == SPI_OFF)
      {
	    call Spi.init();
	    state = SPI_IDLE;
	    return SUCCESS;
      }
      else
      {
	    return FAIL;
      }
    }
  }

  async command error_t AsyncStdControl.stop()
  {
    atomic
    {
      if (state == SPI_IDLE)
      {
	    call Spi.off();
	    state = SPI_OFF;
	    return SUCCESS;
      }
      else
      {
	    return FAIL;
      }
    }
  }

  async command uint8_t SpiByte.write( uint8_t tx )
  {
    uint8_t rx;
    atomic
    {
      if (state == SPI_IDLE)
      {
	    state = SPI_BUSY;
      }
      else if (state == SPI_OFF)
      {
	    return EOFF;
      }
      else
      {
	    return EBUSY;
      }
    }
    atomic
    {
      rx = call Spi.write(tx);
      state = SPI_IDLE;
    }
    return rx;
  }
  
  async command error_t SpiPacket.send( uint8_t* txBuf, uint8_t* rxBuf, uint16_t len )
  {
    uint8_t i;
    atomic
    {
      if (state == SPI_IDLE)
      {
	    state = SPI_BUSY;
      }
      else if (state == SPI_OFF)
      {
	    return EOFF;
      }
      else
      {
	    return EBUSY;
      }
    }
    atomic
    {
      for(i = 0; i < len; ++i)
      {
        rxBuf[i] = call Spi.write(txBuf[i]);
      }
      state = SPI_IDLE;
    }
    signal SpiPacket.sendDone(txBuf, rxBuf, len, SUCCESS);
    return SUCCESS;
  }

  default async event void SpiPacket.sendDone( uint8_t* txBuf,
                                               uint8_t* rxBuf,
                                               uint16_t len,
                                               error_t error ) {}
}
