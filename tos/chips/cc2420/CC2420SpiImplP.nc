/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.4 $ $Date: 2006-12-12 18:23:05 $
 */

module CC2420SpiImplP {

  provides interface Resource[ uint8_t id ];
  provides interface CC2420Fifo as Fifo[ uint8_t id ];
  provides interface CC2420Ram as Ram[ uint16_t id ];
  provides interface CC2420Register as Reg[ uint8_t id ];
  provides interface CC2420Strobe as Strobe[ uint8_t id ];

  uses interface Resource as SpiResource;
  uses interface SpiByte;
  uses interface SpiPacket;
  uses interface Leds;

}

implementation {

  enum {
    RESOURCE_COUNT = uniqueCount( "CC2420Spi.Resource" ),
    NO_HOLDER = 0xff,
  };

  norace uint16_t m_addr;
  bool m_resource_busy = FALSE;
  uint8_t m_requests = 0;
  uint8_t m_holder = NO_HOLDER;

  default event void Resource.granted[ uint8_t id ]() {
  }

  async command error_t Resource.request[ uint8_t id ]() {
    atomic {
      if ( m_resource_busy )
	m_requests |= 1 << id;
      else {
	m_holder = id;
	m_resource_busy = TRUE;
	call SpiResource.request();
      }
    }
    return SUCCESS;
  }
  
  async command error_t Resource.immediateRequest[ uint8_t id ]() {
    error_t error;
    atomic {
      if ( m_resource_busy )
	return EBUSY;
      error = call SpiResource.immediateRequest();
      if ( error == SUCCESS ) {
	m_holder = id;
	m_resource_busy = TRUE;
      }
    }
    return error;
  }

  async command error_t Resource.release[ uint8_t id ]() {
    uint8_t i;
    atomic {
      if ( m_holder != id )
	return FAIL;
      m_holder = NO_HOLDER;
      call SpiResource.release();
      if ( !m_requests ) {
	m_resource_busy = FALSE;
      }
      else {
	for ( i = m_holder + 1; ; i++ ) {
	  if ( i >= RESOURCE_COUNT )
	    i = 0;
	  if ( m_requests & ( 1 << i ) ) {
	    m_holder = i;
	    m_requests &= ~( 1 << i );
	    call SpiResource.request();
	    return SUCCESS;
	  }
	}
      }
      return SUCCESS;
    }
  }
  
  async command uint8_t Resource.isOwner[ uint8_t id ]() {
    atomic return m_holder == id;
  }

  event void SpiResource.granted() {
    uint8_t holder;
    atomic holder = m_holder;
    signal Resource.granted[ holder ]();
  }

  async command cc2420_status_t Fifo.beginRead[ uint8_t addr ]( uint8_t* data, 
								uint8_t len ) {
    
    cc2420_status_t status;
    
    m_addr = addr | 0x40;
    
    status = call SpiByte.write( m_addr );
    call Fifo.continueRead[ addr ]( data, len );
    
    return status;
    
  }

  async command error_t Fifo.continueRead[ uint8_t addr ]( uint8_t* data,
							   uint8_t len ) {
    call SpiPacket.send( NULL, data, len );
    return SUCCESS;
  }

  async command cc2420_status_t Fifo.write[ uint8_t addr ]( uint8_t* data, 
							    uint8_t len ) {

    uint8_t status;

    m_addr = addr;

    status = call SpiByte.write( m_addr );
    call SpiPacket.send( data, NULL, len );

    return status;

  }

  async command cc2420_status_t Ram.read[ uint16_t addr ]( uint8_t offset,
							   uint8_t* data, 
							   uint8_t len ) {

    cc2420_status_t status;

    addr += offset;

    call SpiByte.write( addr | 0x80 );
    status = call SpiByte.write( ( ( addr >> 1 ) & 0xc0 ) | 0x20 );
    for ( ; len; len-- )
      *data++ = call SpiByte.write( 0 );

    return status;

  }

  async event void SpiPacket.sendDone( uint8_t* tx_buf, uint8_t* rx_buf, 
				       uint16_t len, error_t error ) {
    if ( m_addr & 0x40 )
      signal Fifo.readDone[ m_addr & ~0x40 ]( rx_buf, len, error );
    else
      signal Fifo.writeDone[ m_addr ]( tx_buf, len, error );
  }

  async command cc2420_status_t Ram.write[ uint16_t addr ]( uint8_t offset,
							    uint8_t* data, 
							    uint8_t len ) {

    cc2420_status_t status = 0;

    addr += offset;

    call SpiByte.write( addr | 0x80 );
    call SpiByte.write( ( addr >> 1 ) & 0xc0 );
    for ( ; len; len-- )
      status = call SpiByte.write( *data++ );

    return status;

  }

  async command cc2420_status_t Reg.read[ uint8_t addr ]( uint16_t* data ) {

    cc2420_status_t status;
    
    status = call SpiByte.write( addr | 0x40 );
    *data = (uint16_t)call SpiByte.write( 0 ) << 8;
    *data |= call SpiByte.write( 0 );
    
    return status;

  }

  async command cc2420_status_t Reg.write[ uint8_t addr ]( uint16_t data ) {

    call SpiByte.write( addr );
    call SpiByte.write( data >> 8 );
    return call SpiByte.write( data & 0xff );

  }

  async command cc2420_status_t Strobe.strobe[ uint8_t addr ]() {
    return call SpiByte.write( addr );
  }

  default async event void Fifo.readDone[ uint8_t addr ]( uint8_t* rx_buf, uint8_t rx_len, error_t error ) {}
  default async event void Fifo.writeDone[ uint8_t addr ]( uint8_t* tx_buf, uint8_t tx_len, error_t error ) {}

}
