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
 * @author David Moss
 * @author Roman Lim
 * @version $Revision: 1.6 $ $Date: 2007-04-30 17:24:26 $
 */

module CC2420SpiImplP {

  provides interface SplitControl;
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

  enum {
    S_IDLE,
    S_GRANTING,
    S_BUSY,
  };

  norace uint16_t m_addr;
  
  uint8_t m_requests = 0;
  
  uint8_t m_holder = NO_HOLDER;
  
  uint8_t m_state = S_IDLE;

  bool enabled = FALSE;
  
  /***************** Prototypes ****************/
  task void waitForIdle();
  
  /***************** SplitControl Commands ****************/
  command error_t SplitControl.start() {
    atomic enabled = TRUE;
    signal SplitControl.startDone(SUCCESS);
    return SUCCESS;
  }
  
  command error_t SplitControl.stop() {
    atomic {
      enabled = FALSE;
      m_requests = 0;
    }
    ////call Leds.led1On();
    post waitForIdle();
    return SUCCESS;
  }
  
  /***************** Resource Commands *****************/
  async command error_t Resource.request[ uint8_t id ]() {
    
    if(!enabled) {
      return EOFF;
    }
    
    atomic {
      if ( m_state != S_IDLE ) {
        m_requests |= 1 << id;
      } else {
        m_holder = id;
        m_state = S_GRANTING;
        call SpiResource.request();
      }
    }
    return SUCCESS;
  }
  
  async command error_t Resource.immediateRequest[ uint8_t id ]() {
    error_t error;
    
    if(!enabled) {
      return EOFF;
    }
    
    atomic {
      if ( m_state != S_IDLE ) {
        return EBUSY;
      }
      
      error = call SpiResource.immediateRequest();
      if ( error == SUCCESS ) {
        m_holder = id;
        m_state = S_BUSY;
      }
    }
    return error;
  }

  async command error_t Resource.release[ uint8_t id ]() {
    uint8_t i;
    atomic {
      if ( (m_holder != id) || (m_state != S_BUSY)) {
        return FAIL;
      }

      m_holder = NO_HOLDER;
      call SpiResource.release();
      if ( !m_requests ) {
        m_state = S_IDLE;
      } else {
        for ( i = m_holder + 1; ; i++ ) {
          if ( i >= RESOURCE_COUNT ) {
            i = 0;
          }
          
          if ( m_requests & ( 1 << i ) ) {
            m_holder = i;
            m_requests &= ~( 1 << i );
            call SpiResource.request();
            m_state = S_GRANTING;
            return SUCCESS;
          }
        }
      }
      return SUCCESS;
    }
  }
  
  async command uint8_t Resource.isOwner[ uint8_t id ]() {
    atomic return (m_holder == id) & (m_state == S_BUSY);
  }


  /***************** Fifo Commands ****************/
  async command cc2420_status_t Fifo.beginRead[ uint8_t addr ]( uint8_t* data, 
                                                                uint8_t len ) {
    
    cc2420_status_t status = 0;

    atomic {
      if(m_state != S_BUSY) {
        return status;
      }
    }
    
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

    uint8_t status = 0;
 
    atomic {
      if(m_state != S_BUSY) {
        return status;
      }
    }
    
    m_addr = addr;

    status = call SpiByte.write( m_addr );
    call SpiPacket.send( data, NULL, len );

    return status;

  }

  /***************** RAM Commands ****************/
  async command cc2420_status_t Ram.read[ uint16_t addr ]( uint8_t offset,
                                                           uint8_t* data, 
                                                           uint8_t len ) {

    cc2420_status_t status = 0;

    atomic {
      if(m_state != S_BUSY) {
        return status;
      }
    }
    
    addr += offset;

    call SpiByte.write( addr | 0x80 );
    status = call SpiByte.write( ( ( addr >> 1 ) & 0xc0 ) | 0x20 );
    for ( ; len; len-- )
      *data++ = call SpiByte.write( 0 );

    return status;

  }


  async command cc2420_status_t Ram.write[ uint16_t addr ]( uint8_t offset,
                                                            uint8_t* data, 
                                                            uint8_t len ) {

    cc2420_status_t status = 0;

    atomic {
      if(m_state != S_BUSY) {
        return status;
      }
    }
    
    addr += offset;

    call SpiByte.write( addr | 0x80 );
    call SpiByte.write( ( addr >> 1 ) & 0xc0 );
    for ( ; len; len-- )
      status = call SpiByte.write( *data++ );

    return status;

  }

  /***************** Register Commands ****************/
  async command cc2420_status_t Reg.read[ uint8_t addr ]( uint16_t* data ) {

    cc2420_status_t status = 0;
    
    atomic {
      if(m_state != S_BUSY) {
        return status;
      }
    }
    
    status = call SpiByte.write( addr | 0x40 );
    *data = (uint16_t)call SpiByte.write( 0 ) << 8;
    *data |= call SpiByte.write( 0 );
    
    return status;

  }

  async command cc2420_status_t Reg.write[ uint8_t addr ]( uint16_t data ) {
    atomic {
      if(m_state != S_BUSY) {
        return 0;
      }
    }
    call SpiByte.write( addr );
    call SpiByte.write( data >> 8 );
    return call SpiByte.write( data & 0xff );
  }

  
  /***************** Strobe Commands ****************/
  async command cc2420_status_t Strobe.strobe[ uint8_t addr ]() {
    atomic {
      if(m_state != S_BUSY) {
        return 0;
      }
    }
    
    return call SpiByte.write( addr );
  }

  /***************** SpiResource Events ****************/
  event void SpiResource.granted() {
    uint8_t holder;
    atomic { 
        holder = m_holder;
        m_state = S_BUSY;
    }
    signal Resource.granted[ holder ]();
  }
  
  /***************** SpiPacket Events ****************/
  async event void SpiPacket.sendDone( uint8_t* tx_buf, uint8_t* rx_buf, 
                                       uint16_t len, error_t error ) {
    if ( m_addr & 0x40 ) {
      signal Fifo.readDone[ m_addr & ~0x40 ]( rx_buf, len, error );
    } else {
      signal Fifo.writeDone[ m_addr ]( tx_buf, len, error );
    }
  }
  
  
  /***************** Tasks ****************/
  task void waitForIdle() {
    uint8_t currentState;
    atomic currentState = m_state;
    
    if(currentState != S_IDLE) {
      post waitForIdle();
    } else {
      ////call Leds.led1Off();
      signal SplitControl.stopDone(SUCCESS);
    }
  }
  

  /***************** Defaults ****************/
  default event void Resource.granted[ uint8_t id ]() {
  }

  default async event void Fifo.readDone[ uint8_t addr ]( uint8_t* rx_buf, uint8_t rx_len, error_t error ) {
  }
  
  default async event void Fifo.writeDone[ uint8_t addr ]( uint8_t* tx_buf, uint8_t tx_len, error_t error ) {
  }

}
