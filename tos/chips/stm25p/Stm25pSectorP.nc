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
 * @version $Revision: 1.5 $ $Date: 2007-12-22 08:11:51 $
 */

#include <Stm25p.h>
#include <StorageVolumes.h>

module Stm25pSectorP {

  provides interface SplitControl;
  provides interface Resource as ClientResource[ uint8_t id ];
  provides interface Stm25pSector as Sector[ uint8_t id ];
  provides interface Stm25pVolume as Volume[ uint8_t id ];

  uses interface Resource as Stm25pResource[ uint8_t id ];
  uses interface Resource as SpiResource;
  uses interface Stm25pSpi as Spi;
  uses interface Leds;

}

implementation {

  enum {
    NO_CLIENT = 0xff,
  };

  typedef enum {
    S_IDLE,
    S_READ,
    S_WRITE,
    S_ERASE,
    S_CRC,
  } stm25p_sector_state_t;
  norace stm25p_sector_state_t m_state;

  typedef enum {
    S_NONE,
    S_START,
    S_STOP,
  } stm25p_power_state_t;
  norace stm25p_power_state_t m_power_state;

  norace uint8_t m_client;
  norace stm25p_addr_t m_addr;
  norace stm25p_len_t m_len;
  norace stm25p_len_t m_cur_len;
  norace uint8_t* m_buf;
  norace error_t m_error;
  norace uint16_t m_crc;
  
  void bindVolume();
  void signalDone( error_t error );
  task void signalDone_task();

  command error_t SplitControl.start() {
    error_t error = call SpiResource.request();
    if ( error == SUCCESS )
      m_power_state = S_START;
    return error;
  }
  
  command error_t SplitControl.stop() {
    error_t error = call SpiResource.request();
    if ( error == SUCCESS )
      m_power_state = S_STOP;
    return error;
  }
  
  async command error_t ClientResource.request[ uint8_t id ]() {
    return call Stm25pResource.request[ id ]();
  }

  async command error_t ClientResource.immediateRequest[ uint8_t id ]() {
    return FAIL;
  }
  
  async command error_t ClientResource.release[ uint8_t id ]() {
    if ( m_client == id ) {
      m_state = S_IDLE;
      m_client = NO_CLIENT;
      call SpiResource.release();
      call Stm25pResource.release[ id ]();
      return SUCCESS;
    }
    return FAIL;
  }
  
  event void Stm25pResource.granted[ uint8_t id ]() {
    m_client = id;
    call SpiResource.request();
  }
  
  uint8_t getVolumeId( uint8_t client ) {
    return signal Volume.getVolumeId[ client ]();
  }  
  
  event void SpiResource.granted() {
    error_t error;
    stm25p_power_state_t power_state = m_power_state;
    m_power_state = S_NONE;
    if ( power_state == S_START ) {
      error = call Spi.powerUp();
      call SpiResource.release();
      signal SplitControl.startDone( error );
      return;
    }
    else if ( power_state == S_STOP ) {
      error = call Spi.powerDown();
      call SpiResource.release();
      signal SplitControl.stopDone( error );
      return;
    }
    signal ClientResource.granted[ m_client ]();
  }
  
  async command bool ClientResource.isOwner[ uint8_t id ]() {
    return call Stm25pResource.isOwner[id]();
  }
  
  stm25p_addr_t physicalAddr( uint8_t id, stm25p_addr_t addr ) {
    return addr + ( (stm25p_addr_t)STM25P_VMAP[ getVolumeId( id ) ].base 
		    << STM25P_SECTOR_SIZE_LOG2 );
  }
  
  stm25p_len_t calcWriteLen( stm25p_addr_t addr ) {
    stm25p_len_t len = STM25P_PAGE_SIZE - ( addr & STM25P_PAGE_MASK );
    return ( m_cur_len < len ) ? m_cur_len : len;
  }
  
  command stm25p_addr_t Sector.getPhysicalAddress[ uint8_t id ]( stm25p_addr_t addr ) {
    return physicalAddr( id, addr );
  }
  
  command uint8_t Sector.getNumSectors[ uint8_t id ]() {
    return STM25P_VMAP[ getVolumeId( id ) ].size;
  }
  
  command error_t Sector.read[ uint8_t id ]( stm25p_addr_t addr, uint8_t* buf, 
					     stm25p_len_t len ) {
    
    m_state = S_READ;
    m_addr = addr;
    m_buf = buf;
    m_len = len;
    
    return call Spi.read( physicalAddr( id, addr ), buf, len );
    
  }
  
  async event void Spi.readDone( stm25p_addr_t addr, uint8_t* buf, 
				 stm25p_len_t len, error_t error ) {
    signalDone( error );
  }
  
  command error_t Sector.write[ uint8_t id ]( stm25p_addr_t addr, 
					      uint8_t* buf, 
					      stm25p_len_t len ) {
    
    m_state = S_WRITE;
    m_addr = addr;
    m_buf = buf;
    m_len = m_cur_len = len;
    
    return call Spi.pageProgram( physicalAddr( id, addr ), buf, 
				 calcWriteLen( addr ) );
    
  }
  
  async event void Spi.pageProgramDone( stm25p_addr_t addr, uint8_t* buf, 
					stm25p_len_t len, error_t error ) {
    addr += len;
    buf += len;
    m_cur_len -= len;
    if ( !m_cur_len )
      signalDone( SUCCESS );
    else
      call Spi.pageProgram( addr, buf, calcWriteLen( addr ) );
  }
  
  command error_t Sector.erase[ uint8_t id ]( uint8_t sector,
					      uint8_t num_sectors ) {
    
    m_state = S_ERASE;
    m_addr = sector;
    m_len = num_sectors;
    m_cur_len = 0;
    
    return call Spi.sectorErase( STM25P_VMAP[ getVolumeId(id) ].base + m_addr +
				 m_cur_len );
    
  }
  
  async event void Spi.sectorEraseDone( uint8_t sector, error_t error ) {
    if ( ++m_cur_len < m_len )
      call Spi.sectorErase( STM25P_VMAP[getVolumeId(m_client)].base + m_addr +
			    m_cur_len );
    else
      signalDone( error );
  }
  
  command error_t Sector.computeCrc[ uint8_t id ]( uint16_t crc, 
						   stm25p_addr_t addr,
						   stm25p_len_t len ) {
    
    m_state = S_CRC;
    m_addr = addr;
    m_len = len;
    
    return call Spi.computeCrc( crc, physicalAddr( id, addr ), m_len );
    
  }
  
  async event void Spi.computeCrcDone( uint16_t crc, stm25p_addr_t addr, 
				       stm25p_len_t len, error_t error ) {
    m_crc = crc;
    signalDone( SUCCESS );
  }
  
  async event void Spi.bulkEraseDone( error_t error ) {
    
  }
  
  void signalDone( error_t error ) {
    m_error = error;
    post signalDone_task();
  }
  
  task void signalDone_task() {
    switch( m_state ) {
    case S_IDLE:
      signal ClientResource.granted[ m_client ]();
      break;
    case S_READ:
      signal Sector.readDone[ m_client ]( m_addr, m_buf, m_len, m_error );
      break;
    case S_CRC:
      signal Sector.computeCrcDone[ m_client ]( m_addr, m_len,
						m_crc, m_error );
      break;
    case S_WRITE:
      signal Sector.writeDone[ m_client ]( m_addr, m_buf, m_len, m_error );
      break;
    case S_ERASE:
      signal Sector.eraseDone[ m_client ]( m_addr, m_len, m_error );
      break;
    default:
      break;
    }
  }
  
  default event void ClientResource.granted[ uint8_t id ]() {}
  default event void Sector.readDone[ uint8_t id ]( stm25p_addr_t addr, uint8_t* buf, stm25p_len_t len, error_t error ) {}
  default event void Sector.writeDone[ uint8_t id ]( stm25p_addr_t addr, uint8_t* buf, stm25p_len_t len, error_t error ) {}
  default event void Sector.eraseDone[ uint8_t id ]( uint8_t sector, uint8_t num_sectors, error_t error ) {}
  default event void Sector.computeCrcDone[ uint8_t id ]( stm25p_addr_t addr, stm25p_len_t len, uint16_t crc, error_t error ) {}
  default async event volume_id_t Volume.getVolumeId[ uint8_t id ]() { return 0xff; }
  
}

