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

#include <Stm25p.h>

module Stm25pConfigP {
  
  provides interface Mount[ uint8_t client ];
  provides interface ConfigStorage as Config[ uint8_t client ];
  
  uses interface Stm25pSector as Sector[ uint8_t client ];
  uses interface Resource as ClientResource[ uint8_t client ];
  uses interface Leds;
  
}

implementation {
  
  enum {
    NUM_CLIENTS = uniqueCount( "Stm25p.Config" ),
    CONFIG_SIZE = 2048,
    CHUNK_SIZE_LOG2 = 8,
    CHUNK_SIZE = 1 << CHUNK_SIZE_LOG2,
    NUM_CHUNKS = CONFIG_SIZE / CHUNK_SIZE,
    BUF_SIZE = 16,
    INVALID_VERSION = -1,
  };
  
  enum {
    S_IDLE,
    S_MOUNT,
    S_READ,
    S_WRITE,
    S_COMMIT,
  };

  typedef struct {
    uint16_t addr;
    void* buf;
    uint16_t len;
    uint8_t req;
  } config_state_t;
  config_state_t m_config_state[ NUM_CLIENTS ];
  config_state_t m_req;
  
  typedef struct {
    uint16_t chunk_addr[ NUM_CHUNKS ];
    uint16_t write_addr;
    int16_t version;
    uint8_t cur_sector;
    bool valid : 1;
  } config_info_t;
  config_info_t m_config_info[ NUM_CLIENTS ];

  typedef struct {
    int32_t version;
    uint16_t crc;
  } config_metadata_t;
  config_metadata_t m_metadata[ 2 ];
  
  uint8_t m_buf[ BUF_SIZE ];
  uint16_t m_chunk;
  uint16_t m_offset;

  enum {
    S_COPY_BEFORE,
    S_COPY_AFTER,
  };
  uint8_t m_meta_state;
  
  error_t newRequest( uint8_t client );
  void continueMount( uint8_t id );
  void continueWrite( uint8_t id );
  void continueCommit( uint8_t id );
  void signalDone( uint8_t id, error_t error );
  
  command error_t Mount.mount[ uint8_t client ]() {
    
    if ( call Sector.getNumSectors[ client ]() != 2 )
      return ESIZE;
    m_req.req = S_MOUNT;
    return newRequest( client );
    
  }
  
  command error_t Config.read[ uint8_t client ]( storage_addr_t addr, 
						 void* buf, 
						 storage_len_t len ) {
    
    if ( !m_config_info[ client ].valid )
      return FAIL;
    m_req.req = S_READ;
    m_req.addr = addr;
    m_req.buf = buf;
    m_req.len = len;
    return newRequest( client );
    
  }
  
  command error_t Config.write[ uint8_t client ]( storage_addr_t addr,
						  void* buf,
						  storage_len_t len ) {
    
    m_req.req = S_WRITE;
    m_req.addr = addr;
    m_req.buf = buf;
    m_req.len = len;
    return newRequest( client );    
    
  }
  
  command error_t Config.commit[ uint8_t client ]() {
    
    m_req.req = S_COMMIT;
    return newRequest( client );    
    
  }
  
  command storage_len_t Config.getSize[ uint8_t client ]() {
    return CONFIG_SIZE;
  }
  
  command bool Config.valid[ uint8_t client ]() {
    return m_config_info[ client ].valid;
  }

  error_t newRequest( uint8_t client ) {

    if ( m_config_state[ client ].req != S_IDLE )
      return EBUSY;
    
    call ClientResource.request[ client ]();
    m_config_state[ client ] = m_req;
    
    return SUCCESS;
    
  }
  
  stm25p_addr_t calcAddr( uint8_t id, uint16_t addr, bool current ) {
    stm25p_addr_t result = addr;
    if ( !(current ^ m_config_info[ id ].cur_sector) )
      result += STM25P_SECTOR_SIZE;
    return result;
  }
  
  event void ClientResource.granted[ uint8_t id ]() {

    m_chunk = 0;
    m_offset = 0;
    
    switch( m_config_state[ id ].req ) {
    case S_IDLE:
      break;
    case S_MOUNT:
      continueMount( id );
      break;
    case S_READ:
      call Sector.read[ id ]( calcAddr( id, m_config_state[ id ].addr, TRUE ),
			      m_config_state[ id ].buf,
			      m_config_state[ id ].len );
      break;
    case S_WRITE:
      m_meta_state = S_COPY_BEFORE;
      m_chunk = m_config_state[ id ].addr >> CHUNK_SIZE_LOG2;
      continueWrite( id );
      break;
    case S_COMMIT:
      continueCommit( id );
      break;
    }
    
  }

  void continueMount( uint8_t id ) {

    uint32_t addr = 0;
    uint8_t cur_sector = 0;
    int i;

    switch( m_chunk ) {
    case 1:
      addr = STM25P_SECTOR_SIZE;
      // fall through
    case 0:
      addr += STM25P_SECTOR_SIZE - sizeof( config_metadata_t );
      call Sector.read[ id ]( addr, (uint8_t*)&m_metadata[ m_chunk ],
                              sizeof( config_metadata_t ) );
      break;
    case 3:
      addr = STM25P_SECTOR_SIZE;
      // fall through
    case 2:
      call Sector.computeCrc[ id ]( 0, addr, CONFIG_SIZE );
      break;
    case 4:
      if ( m_metadata[ 0 ].version != INVALID_VERSION ||
	   m_metadata[ 1 ].version != INVALID_VERSION ) {
	m_config_info[ id ].valid = TRUE;
	if ( m_metadata[ 0 ].version == INVALID_VERSION )
	  cur_sector = 1;
	else if ( m_metadata[ 1 ].version == INVALID_VERSION )
	  cur_sector = 0;
	else
	  cur_sector = (( m_metadata[1].version - m_metadata[0].version ) > 0);
      }
      m_config_info[ id ].cur_sector = cur_sector;
      m_config_info[ id ].version = m_metadata[ cur_sector ].version;
      call Sector.erase[ id ]( !cur_sector, 1 );
      break;
    case 5:
      // initialize chunk addrs
      for ( i = 0; i < NUM_CHUNKS; i++ )
	m_config_info[ id ].chunk_addr[ i ] = i << CHUNK_SIZE_LOG2;
      m_config_info[ id ].write_addr = CONFIG_SIZE;
      signalDone( id, SUCCESS );
      break;
    }
    
    m_chunk++;
    
  }
  
  event void Sector.readDone[ uint8_t id ]( stm25p_addr_t addr, uint8_t* buf, 
					    stm25p_len_t len, error_t error ) {
    switch ( m_config_state[ id ].req ) {
    case S_IDLE:
      break;
    case S_MOUNT:
      continueMount( id );
      break;
    case S_READ:
      signalDone( id, error );
      break;
    case S_WRITE:
      addr = calcAddr( id, m_config_info[ id ].write_addr, FALSE );
      call Sector.write[ id ]( addr, buf, len );
      break;
    case S_COMMIT:
      addr = ((uint16_t)m_chunk << CHUNK_SIZE_LOG2) + m_offset;
      addr = calcAddr( id, addr, FALSE );
      call Sector.write[ id ]( addr, buf, len );
      break;
    }
  }
  
  void continueWrite( uint8_t id ) {
    
    config_state_t* state = &m_config_state[ id ];
    config_info_t* info = &m_config_info[ id ];
    uint8_t chunk = m_chunk + (m_offset / CHUNK_SIZE);
    uint8_t offset = m_offset & 0xff;
    uint32_t addr;
    uint16_t len;
    
    // compute addr for copy
    addr = info->chunk_addr[ chunk ] + offset;
    addr = calcAddr( id, addr, info->chunk_addr[ chunk ] < CONFIG_SIZE );
    
    switch( m_meta_state ) {
      
    case S_COPY_BEFORE:
      // copy old data before
      if ( offset < (uint8_t)state->addr ) {
	len = (uint8_t)state->addr - offset;
	if ( len > sizeof( m_buf ) )
	  len = sizeof( m_buf );
	call Sector.read[ id ]( addr, m_buf, len );
      }
      // write new data
      else if ( offset == (uint8_t)state->addr ) {
	addr = calcAddr( id, info->write_addr, FALSE );
	len = state->len;
	call Sector.write[ id ]( addr, state->buf, len );
	m_meta_state = S_COPY_AFTER;
      }
      break;

    case S_COPY_AFTER:
      // copy old data after
      if ( offset != 0 ) {
	len = CHUNK_SIZE - offset;
	if ( len > sizeof( m_buf ) )
	  len = sizeof( m_buf );
	call Sector.read[ id ]( addr, m_buf, len );
      }
      // all done, update chunk addrs
      else {
	info->write_addr -= m_offset;
	for ( chunk = 0; chunk < m_offset / CHUNK_SIZE; chunk++ ) {
	  info->chunk_addr[ m_chunk+chunk ] = info->write_addr;
	  info->write_addr += CHUNK_SIZE;
	}
	signalDone( id, SUCCESS );
      }
      break;

    }

  }
  
  event void Sector.writeDone[ uint8_t id ]( stm25p_addr_t addr, uint8_t* buf, 
					     stm25p_len_t len, error_t error ){
    switch( m_config_state[ id ].req ) {

    case S_WRITE:
      m_config_info[ id ].write_addr += len;
      m_offset += len;
      continueWrite( id );
      break;

    case S_COMMIT:
      m_offset += len;
      continueCommit( id );
      break;
      
    }

  }
  
  event void Sector.eraseDone[ uint8_t id ]( uint8_t sector,
					     uint8_t num_sectors,
					     error_t error ) {
    if ( m_config_state[ id ].req == S_MOUNT )
      continueMount( id );
    else
      continueCommit( id );
  }
  
  void continueCommit( uint8_t id ) {
    
    config_info_t* info = &m_config_info[ id ];
    uint32_t addr;
    uint16_t len;
    int i;
    
    // check if time to copy next chunk
    if ( m_offset >= CHUNK_SIZE ) {
      m_chunk++;
      m_offset = 0;
    }
    
    // copy data
    if ( m_chunk < NUM_CHUNKS ) {
      // compute addr for copy
      addr = info->chunk_addr[ m_chunk ] + m_offset;
      addr = calcAddr( id, addr, info->chunk_addr[ m_chunk ] < CONFIG_SIZE );
      len = sizeof( m_buf );
      call Sector.read[ id ]( addr, m_buf, len );
    }
    // compute crc
    else if ( m_chunk == NUM_CHUNKS ) {
      addr = calcAddr( 0, 0, FALSE );
      call Sector.computeCrc[ id ]( 0, addr, CONFIG_SIZE );
      m_chunk++;
    }
    // swap and erase other sector
    else if ( m_chunk == NUM_CHUNKS + 1 ) {
      info->cur_sector ^= 1;
      info->write_addr = CONFIG_SIZE;
      // initialize chunks
      for ( i = 0; i < NUM_CHUNKS; i++ )
	info->chunk_addr[ i ] = (uint16_t)i << CHUNK_SIZE_LOG2;
      call Sector.erase[ id ]( !info->cur_sector, 1 );
      m_chunk++;
    }
    // signal done
    else {
      m_config_info[ id ].valid = TRUE;
      signalDone( id, SUCCESS );
    }
    
  }

  event void Sector.computeCrcDone[ uint8_t id ]( stm25p_addr_t addr, 
						  stm25p_len_t len,
						  uint16_t crc,
						  error_t error ) {
    
    // mount
    if ( m_config_state[ id ].req == S_MOUNT ) {
      uint8_t chunk = addr >> STM25P_SECTOR_SIZE_LOG2;
      if ( m_metadata[ chunk ].crc != crc )
	m_metadata[ chunk ].version = INVALID_VERSION;
      continueMount( id );
    }
    // commit
    else {
      bool cur_sector = m_config_info[ id ].cur_sector;
      m_config_info[ id ].version++;
      m_metadata[ !cur_sector ].version = m_config_info[ id ].version;
      m_metadata[ !cur_sector ].crc = crc;
      addr += STM25P_SECTOR_SIZE - sizeof( config_metadata_t );
      call Sector.write[ id ]( addr, (uint8_t*)&m_metadata[ !cur_sector ],
			       sizeof( config_metadata_t ) );
    }
    
  }

  void signalDone( uint8_t id, error_t error ) {
    
    uint8_t req = m_config_state[ id ].req;
    
    call ClientResource.release[ id ]();
    m_config_state[ id ].req = S_IDLE;
    
    switch( req ) {
    case S_MOUNT:
      signal Mount.mountDone[ id ]( error );
      break;
    case S_READ:
      signal Config.readDone[ id ]( m_config_state[ id ].addr,
				    m_config_state[ id ].buf,
				    m_config_state[ id ].len, error );
      break;
    case S_WRITE:
      signal Config.writeDone[ id ]( m_config_state[ id ].addr,
				     m_config_state[ id ].buf,
				     m_config_state[ id ].len, error );
      break;
    case S_COMMIT:
      signal Config.commitDone[ id ]( error );
      break;
    }
    
  }
  
  default event void Mount.mountDone[ uint8_t id ]( error_t error ) {}
  default event void Config.readDone[ uint8_t id ]( storage_addr_t addr, void* buf, storage_len_t len, error_t error ) {}
  default event void Config.writeDone[ uint8_t id ]( storage_addr_t addr, void* buf, storage_len_t len, error_t error ) {}
  default event void Config.commitDone[ uint8_t id ]( error_t error ) {}
  
  default command storage_addr_t Sector.getPhysicalAddress[ uint8_t id ]( storage_addr_t addr ) { return 0xffffffff; }
  default command uint8_t Sector.getNumSectors[ uint8_t id ]() { return 0; }
  default command error_t Sector.read[ uint8_t id ]( storage_addr_t addr, uint8_t* buf, storage_len_t len ) { return FAIL; }
  default command error_t Sector.write[ uint8_t id ]( storage_addr_t addr, uint8_t* buf, storage_len_t len ) { return FAIL; }
  default command error_t Sector.erase[ uint8_t id ]( uint8_t sector, uint8_t num_sectors ) { return FAIL; }
  default command error_t Sector.computeCrc[ uint8_t id ]( uint16_t crc, storage_addr_t addr, storage_len_t len ) { return FAIL; }
  default async command error_t ClientResource.request[ uint8_t id ]() { return FAIL; }
  default async command error_t ClientResource.release[ uint8_t id ]() { return FAIL; }
  
}
