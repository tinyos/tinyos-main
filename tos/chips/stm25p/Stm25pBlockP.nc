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
 * @version $Revision: 1.3 $ $Date: 2006-11-07 19:31:15 $
 */

module Stm25pBlockP {

  provides interface BlockRead as Read[ uint8_t id ];
  provides interface BlockWrite as Write[ uint8_t id ];
  provides interface StorageMap[ uint8_t id ];

  uses interface Stm25pSector as Sector[ uint8_t id ];
  uses interface Resource as ClientResource[ uint8_t id ];
  uses interface Leds;

}

implementation {

  enum {
    NUM_BLOCKS = uniqueCount( "Stm25p.Block" ),
  };
  
  typedef enum {
    S_IDLE,
    S_READ,
    S_CRC,
    S_WRITE,
    S_SYNC,
    S_ERASE,
  } stm25p_block_req_t;
  
  typedef struct stm25p_block_state_t {
    storage_addr_t addr;
    void* buf;
    storage_len_t len;
    stm25p_block_req_t req;
  } stm25p_block_state_t;
  
  stm25p_block_state_t m_block_state[ NUM_BLOCKS ];
  stm25p_block_state_t m_req;
  
  error_t newRequest( uint8_t client );
  void signalDone( uint8_t id, uint16_t crc, error_t error );
  
  command storage_addr_t StorageMap.getPhysicalAddress[ uint8_t id ]( storage_addr_t addr ) {
    return call Sector.getPhysicalAddress[ id ]( addr );
  }
  
  command storage_len_t Read.getSize[ uint8_t id ]() {
    return ( (storage_len_t)call Sector.getNumSectors[ id ]() 
	     << STM25P_SECTOR_SIZE_LOG2 );
  }
  
  command error_t Read.read[ uint8_t id ]( storage_addr_t addr, void* buf,
					   storage_len_t len ) {
    m_req.req = S_READ;
    m_req.addr = addr;
    m_req.buf = buf;
    m_req.len = len;
    return newRequest( id );
  }
  
  command error_t Read.computeCrc[ uint8_t id ]( storage_addr_t addr,
						 storage_len_t len,
						 uint16_t crc ) {
    m_req.req = S_CRC;
    m_req.addr = addr;
    m_req.buf = (void*)crc;
    m_req.len = len;
    return newRequest( id );
  }
  
  command error_t Write.write[ uint8_t id ]( storage_addr_t addr, void* buf, 
					     storage_len_t len ) {
    m_req.req = S_WRITE;
    m_req.addr = addr;
    m_req.buf = buf;
    m_req.len = len;
    return newRequest( id );
  }
  
  command error_t Write.sync[ uint8_t id ]() {
    m_req.req = S_SYNC;
    return newRequest( id );
  }
  
  command error_t Write.erase[ uint8_t id ]() {
    m_req.req = S_ERASE;
    return newRequest( id );
  }
  
  error_t newRequest( uint8_t client ) {
    
    if ( m_block_state[ client ].req != S_IDLE )
      return FAIL;

    call ClientResource.request[ client ]();
    m_block_state[ client ] = m_req;
    
    return SUCCESS;
    
  }
  
  event void ClientResource.granted[ uint8_t id ]() {
    
    switch( m_block_state[ id ].req ) {
    case S_READ:
      call Sector.read[ id ]( m_block_state[ id ].addr, 
			      m_block_state[ id ].buf, 
			      m_block_state[ id ].len );
      break;
    case S_CRC:
      call Sector.computeCrc[ id ]( (uint16_t)m_block_state[ id ].buf, 
				    m_block_state[ id ].addr, 
				    m_block_state[ id ].len );
      break;
    case S_WRITE:
      call Sector.write[ id ]( m_block_state[ id ].addr, 
			       m_block_state[ id ].buf, 
			       m_block_state[ id ].len );
      break;
    case S_ERASE:
      call Sector.erase[ id ]( 0, call Sector.getNumSectors[ id ]() );
      break;
    case S_SYNC:
      signalDone( id, 0, SUCCESS );
      break;
    case S_IDLE:
      break;
    }
    
  }
  
  event void Sector.readDone[ uint8_t id ]( stm25p_addr_t addr, uint8_t* buf, 
					    stm25p_len_t len, error_t error ) {
    signalDone( id, 0, error );
  }
  
  event void Sector.writeDone[ uint8_t id ]( stm25p_addr_t addr, uint8_t* buf, 
					     stm25p_len_t len, error_t error ){
    signalDone( id, 0, error );
  }
  
  event void Sector.eraseDone[ uint8_t id ]( uint8_t sector,
					     uint8_t num_sectors,
					     error_t error ) {
    signalDone( id, 0, error );
  }
  
  event void Sector.computeCrcDone[ uint8_t id ]( stm25p_addr_t addr, 
						  stm25p_len_t len,
						  uint16_t crc,
						  error_t error ) {
    signalDone( id, crc, error );
  }
  
  void signalDone( uint8_t id, uint16_t crc, error_t error ) {
    
    stm25p_block_req_t req = m_block_state[ id ].req;    
    
    call ClientResource.release[ id ]();
    m_block_state[ id ].req = S_IDLE;
    switch( req ) {
    case S_READ:
      signal Read.readDone[ id ]( m_block_state[ id ].addr, 
				  m_block_state[ id ].buf,
				  m_block_state[ id ].len, error );  
      break;
    case S_CRC:
      signal Read.computeCrcDone[ id ]( m_block_state[ id ].addr, 
					m_block_state[ id ].len, crc, error );
      break;
    case S_WRITE:
      signal Write.writeDone[ id ]( m_block_state[ id ].addr, 
				    m_block_state[ id ].buf,
				    m_block_state[ id ].len, error );
      break;
    case S_SYNC:
      signal Write.syncDone[ id ]( error );
      break;
    case S_ERASE:
      signal Write.eraseDone[ id ]( error );
      break;
    case S_IDLE:
      break;
    }
    
  }
  
  default event void Read.readDone[ uint8_t id ]( storage_addr_t addr, void* buf, storage_len_t len, error_t error ) {}
  default event void Read.computeCrcDone[ uint8_t id ]( storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error ) {}
  default event void Write.writeDone[ uint8_t id ]( storage_addr_t addr, void* buf, storage_len_t len, error_t error ) {}
  default event void Write.eraseDone[ uint8_t id ]( error_t error ) {}
  default event void Write.syncDone[ uint8_t id ]( error_t error ) {}
  
  default command storage_addr_t Sector.getPhysicalAddress[ uint8_t id ]( storage_addr_t addr ) { return 0xffffffff; }
  default command uint8_t Sector.getNumSectors[ uint8_t id ]() { return 0; }
  default command error_t Sector.read[ uint8_t id ]( stm25p_addr_t addr, uint8_t* buf, stm25p_len_t len ) { return FAIL; }
  default command error_t Sector.write[ uint8_t id ]( stm25p_addr_t addr, uint8_t* buf, stm25p_len_t len ) { return FAIL; }
  default command error_t Sector.erase[ uint8_t id ]( uint8_t sector, uint8_t num_sectors ) { return FAIL; }
  default command error_t Sector.computeCrc[ uint8_t id ]( uint16_t crc, storage_addr_t addr, storage_len_t len ) { return FAIL; }
  default async command error_t ClientResource.request[ uint8_t id ]() { return FAIL; }
  default async command error_t ClientResource.release[ uint8_t id ]() { return FAIL; }
  
}

