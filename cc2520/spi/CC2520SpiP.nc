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
// The actual Spi files are located in Msp430SpiNoDmaBP.nc & HplMsp430UsciB0P.nc--- Lijo
/**
 * @author Jonathan Hui <jhui@archrock.com>
 * @author David Moss
 * @author Roman Lim
 * @author Razvan Musaloie-E.
 * @author Jeonggil Ko
 * @version $Revision: 1.4 $ $Date: 2008/06/23 20:25:15 $
 */


#define HI_UINT16(a) (((int)(a) >> 8) & 0xFF)
#define LO_UINT16(a) ((int)(a) & 0xFF)

module CC2520SpiP @safe() {

  provides {
    interface ChipSpiResource;
    interface Resource[ uint8_t id ];
    interface CC2520Fifo as Fifo[ uint8_t id ];
    interface CC2520Ram as Ram[ uint16_t id ];
    interface CC2520Register as Reg[ uint8_t id ];
    interface CC2520Strobe as Strobe[ uint8_t id ];
  }
  
  uses {
    interface Resource as SpiResource;
    interface SpiByte;
    interface SpiPacket;
    interface State as WorkingState;
    
    interface Leds;
  }
}

implementation {

  enum {
    RESOURCE_COUNT = uniqueCount( "CC2520Spi.Resource" ),
    NO_HOLDER = 0xFF,
  };

  /** WorkingStates */
  enum {
    S_IDLE,
    S_BUSY,
  };

  /** Address to read/write on the CC2420, also maintains caller's client id */
  norace uint16_t m_addr;
  
  /** Each bit represents a client ID that is requesting SPI bus access */
  uint8_t m_requests = 0;
  
  /** The current client that owns the SPI bus */
  uint8_t m_holder = NO_HOLDER;
  
  /** TRUE if it is safe to release the SPI bus after all users say ok */
  bool release;
  
  /***************** Prototypes ****************/
  error_t attemptRelease();
  task void grant();
  
  /***************** ChipSpiResource Commands ****************/
  /**
   * Abort the release of the SPI bus.  This must be called only with the
   * releasing() event
   */
  async command void ChipSpiResource.abortRelease() {
    atomic release = FALSE;
  }
  
  /**
   * Release the SPI bus if there are no objections
   */
  async command error_t ChipSpiResource.attemptRelease() {
    return attemptRelease();
  }
  
  /***************** Resource Commands *****************/
  async command error_t Resource.request[ uint8_t id ]() {
        
    atomic {
      if ( call WorkingState.requestState(S_BUSY) == SUCCESS ) {
        m_holder = id;
        if(call SpiResource.isOwner()) {
          post grant();
          
        } else {
          call SpiResource.request();
        }
        
      } else {
        m_requests |= 1 << id;
      }
    }
    return SUCCESS;
  }
  
  async command error_t Resource.immediateRequest[ uint8_t id ]() {
    error_t error;
        
    atomic {
      if ( call WorkingState.requestState(S_BUSY) != SUCCESS ) {
        return EBUSY;
      }
      
      
      if(call SpiResource.isOwner()) {
        m_holder = id;
        error = SUCCESS;
      
      } else if ((error = call SpiResource.immediateRequest()) == SUCCESS ) {
        m_holder = id;
        
      } else {
        call WorkingState.toIdle();
      }
    }
    return error;
  }

  async command error_t Resource.release[ uint8_t id ]() {
    uint8_t i;
    atomic {
      if ( m_holder != id ) {
        return FAIL;
      }

      m_holder = NO_HOLDER;
      if ( !m_requests ) {
        call WorkingState.toIdle();
        attemptRelease();
        
      } else {
        for ( i = m_holder + 1; ; i++ ) {
          i %= RESOURCE_COUNT;
          
          if ( m_requests & ( 1 << i ) ) {
            m_holder = i;
            m_requests &= ~( 1 << i );
            post grant();
            return SUCCESS;
          }
        }
      }
    }
    
    return SUCCESS;
  }
  
  async command uint8_t Resource.isOwner[ uint8_t id ]() {
    atomic return (m_holder == id);
  }


  /***************** SpiResource Events ****************/
  event void SpiResource.granted() {
    
	
	post grant();

  }
  
  /***************** Fifo Commands ****************/
  async command cc2520_status_t Fifo.beginRead[ uint8_t addr ]( uint8_t* data, 
                                                                uint8_t len ) {
    
    cc2520_status_t status = 0;

    atomic {
      if(call WorkingState.isIdle()) {
        return status;
      }
    }
    
   // m_addr = addr | 0x40;
    //printf("\n Fifo Read");
    //m_addr = addr;
        
    m_addr = 	CC2520_CMD_RXBUF;
    status = call SpiByte.write( m_addr );
    m_addr = addr | 0x40; // For Reading ...used in SpiPacket.sendDone
    call Fifo.continueRead[ addr ]( data, len );
    
    return status;
    
  }

  async command error_t Fifo.continueRead[ uint8_t addr ]( uint8_t* data,
                                                           uint8_t len ) {
    return call SpiPacket.send( NULL, data, len );
  }

  async command cc2520_status_t Fifo.write[ uint8_t addr ]( uint8_t* data, 
                                                            uint8_t len ) {

    uint8_t status = 0;
    
    atomic {
      if(call WorkingState.isIdle()) {
        return status;
      }
    }
    
    m_addr = CC2520_CMD_TXBUF ; //addr; // CC2520_CMD_TXBUF

    status = call SpiByte.write( m_addr );
    call SpiPacket.send( data, NULL, len );

    return status;

  }

  /***************** RAM Commands ****************/
  async command cc2520_status_t Ram.read[ uint16_t addr ]( uint8_t offset,
                                                           uint8_t* data, 
                                                           uint8_t len ) {

    cc2520_status_t status = 0;
   
    atomic {
      if(call WorkingState.isIdle()) {
        return status;
      }
    }
   
    call SpiByte.write(CC2520_CMD_MEMORY_READ | (HI_UINT16(addr))); 
    addr = LO_UINT16(addr);
    status = call SpiByte.write( addr );      // Edited by Lijo 
    for ( ; len; len-- ) {
      *data++ = call SpiByte.write( 0 );
    }
	
    return status;

  }


  async command cc2520_status_t Ram.write[ uint16_t addr ]( uint8_t offset,
                                                            uint8_t* data, 
                                                            uint8_t len ) {

    cc2520_status_t status = 0;
    uint8_t tmpLen = len;
    uint8_t * COUNT(tmpLen) tmpData = (uint8_t * COUNT(tmpLen))data;

    atomic {
      if(call WorkingState.isIdle()) {
        return status;
      }
    }
   call SpiByte.write(CC2520_CMD_MEMORY_WRITE | (HI_UINT16(addr)));
   addr = LO_UINT16(addr);
   status = call SpiByte.write( addr );      // Edited by Lijo 
    for ( ; len; len-- ) {
	   call SpiByte.write( tmpData[tmpLen-len] );
	// call SpiByte.write( tmpData[len-1] );	//Jamal:Writing in reverse order
    }

    return status;

  }

  /***************** Register Commands ****************/
  async command cc2520_status_t Reg.read[ uint8_t addr ]( uint16_t* data ) {

    cc2520_status_t status = 0;
    
    atomic {
      if(call WorkingState.isIdle()) {
        return status;
      }
    }
    
    //call SpiByte.write( CC2520_CMD_MEMORY_READ | (HI_UINT16(addr)) );
   //call SpiByte.write( LO_UINT16(addr) );
    //status = call SpiByte.write( addr | 0x40 );
    //printf("Memory Read: %x , Register Address : %x \n", CC2520_CMD_MEMORY_WRITE,addr);
    call SpiByte.write( CC2520_CMD_MEMORY_READ );
    call SpiByte.write(addr);
    //printf("Value: %x \n",  call SpiByte.write( 0x00 ));
    //call SpiByte.write( 0x00 );
    
    //printf("CC2520 Status: %x \n",  call SpiByte.write( 0x00 ));
    
    *data = (uint16_t)call SpiByte.write( 0 ) << 8;
    *data |= call SpiByte.write( 0 );
    
    //*data =0;
    
    
    return status;

  }

  async command cc2520_status_t Reg.write[ uint8_t addr ]( uint16_t data ) {
    
	 atomic {
      if(call WorkingState.isIdle()) {
        return 0;
      }
    }
	
    	if(addr <= CC2520_FREG_MASK)
        {
            // we can use 1 byte less to write this register using the
            // register write command
	    
            //ASSERT( addr == (addr & CC2520_FREG_MASK) );
            addr = (addr & CC2520_FREG_MASK);
	    //printf(" Register Address : %x ,  Data : %x\n", (CC2520_CMD_MEMORY_WRITE ),addr);
            
            //status.value = call SpiByte.write(CC2520_CMD_REGISTER_WRITE | reg);
	    //call SpiByte.write(CC2520_CMD_REGISTER_WRITE | addr);
            call SpiByte.write(CC2520_CMD_MEMORY_WRITE);
            call SpiByte.write(addr);

        }
        else
        {
            // we have to use the memory write command as the register is in
            // SREG
	    
            //ASSERT( addr == (addr & CC2520_SREG_MASK) );
	     addr = (addr & CC2520_SREG_MASK);
	   // printf(" Register Address : %x ,  Data : %x\n", (addr),data);
            // the register has to be below the 0x100 memory address. Thus, we
            // don't have to add anything to the MEMORY_WRITE command.
             call SpiByte.write(CC2520_CMD_MEMORY_WRITE);
             call SpiByte.write(addr);

        }
     
    
    //call SpiByte.write( addr );
    //call SpiByte.write( data >> 8 );
    //return call SpiByte.write( data & 0xff );
    //call SpiByte.write( CC2520_CMD_MEMORY_WRITE );
   //call SpiByte.write(addr);
   // call SpiByte.write( data );
     
   // printf("Memory Write: %x , Register Address : %x ,  Data : %x\n", CC2520_CMD_MEMORY_WRITE,addr,data);
    //printf("Value 0: %x  Value1: %x \n", *(data+0),*(data+1));
    //call SpiByte.write( CC2520_CMD_MEMORY_WRITE | (HI_UINT16(addr)) );
    //call SpiByte.write( LO_UINT16(addr) );
    //return call SpiByte.write( 0x32 );
     
     return call SpiByte.write((data & 0xFF)); // Edited by Lijo
  }


   
  
  /***************** Strobe Commands ****************/
  async command cc2520_status_t Strobe.strobe[ uint8_t addr ]() {
    atomic {
      if(call WorkingState.isIdle()) {
        return 0;
      }
    }
    
    return call SpiByte.write( addr );
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
  
  /***************** Functions ****************/
  error_t attemptRelease() {
    if(m_requests > 0 
        || m_holder != NO_HOLDER 
        || !call WorkingState.isIdle()) {
      return FAIL;
    }
    
    atomic release = TRUE;
    signal ChipSpiResource.releasing();
    atomic {
      if(release) {
        call SpiResource.release();
        return SUCCESS;
      }
    }
    
    return EBUSY;
  }
  
  task void grant() {
    uint8_t holder;
    atomic { 
      holder = m_holder;
    }
    signal Resource.granted[ holder ]();
  }

  /***************** Defaults ****************/
  default event void Resource.granted[ uint8_t id ]() {
  }

  default async event void Fifo.readDone[ uint8_t addr ]( uint8_t* rx_buf, uint8_t rx_len, error_t error ) {
  }
  
  default async event void Fifo.writeDone[ uint8_t addr ]( uint8_t* tx_buf, uint8_t tx_len, error_t error ) {
  }

  default async event void ChipSpiResource.releasing() {
  }
  
}
