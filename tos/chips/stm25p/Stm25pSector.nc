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
 * HAL for the ST M25P family of serial code flash chips. This
 * provides a sector level abstraction to perform basic
 * operations. Upon completion of a write/erase operation, all data is
 * committed to non-volatile storage.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.4 $ $Date: 2006-12-12 18:23:13 $
 */

#include "Stm25p.h"

interface Stm25pSector {

  /**
   * Get the physical address of a volume address.
   *
   * @return The physical address corresponding to the volume address.
   */
  command stm25p_addr_t getPhysicalAddress( stm25p_addr_t addr );

  /**
   * Get the number of sectors in the volume.
   */
  command uint8_t getNumSectors();

  /**
   * Read data from the flash chip. On SUCCESS, the
   * <code>readDone</code> event will be signalled when the operation
   * is complete.
   *
   * @param addr within volume to read data from.
   * @param buf pointer to read buffer.
   * @param len number of bytes to read.
   * @return SUCCESS if request was accepted, FAIL otherwise.
   */
  command error_t read( stm25p_addr_t addr, uint8_t* buf, stm25p_len_t len );

  /**
   * Signals when the read operation is complete.
   *
   * @param addr within the volume that data was read from.
   * @param buf pointer to buffer that data was placed.
   * @param len number of bytes read.
   * @param error notification of how the operation went.
   */
  event void readDone( stm25p_addr_t addr, uint8_t* buf, stm25p_len_t len, 
		       error_t error );
  
  /**
   * Write data to the flash chip. On SUCCESS, the
   * <code>writeDone</code> event will be signalled when the operation
   * is complete.
   *
   * @param addr within volume to write data to.
   * @param buf pointer to data buffer.
   * @param len number of bytes to write.
   * @return SUCCESS if request was accepted, FAIL otherwise.
   */
  command error_t write( stm25p_addr_t addr, uint8_t* buf, stm25p_len_t len );

  /**
   * Signals when the write operation is complete.
   *
   * @param addr within the volume that data was written to.
   * @param buf pointer to data buffer.
   * @param len number of bytes written.
   * @param error notification of how the operation went.
   */
  event void writeDone( stm25p_addr_t addr, uint8_t* buf, stm25p_len_t len, 
			error_t error );
  
  /**
   * Erase a number of sectors. On SUCCESS, the <code>eraseDone</code>
   * event will be signalled when the operation completes.
   *
   * @param sector within volume to begin erasing.
   * @param num_sectors number of sectors to erase.
   * @return SUCCESS if request was accepted, FAIL otherwise.
   */
  command error_t erase( uint8_t sector, uint8_t num_sectors );

  /**
   * Signals when the erase operation is complete.
   *
   * @param sector within volume that erasing begain.
   * @param num_sectors number of sectors erased.
   * @param error notification of how the operation went.
   */
  event void eraseDone( uint8_t sector, uint8_t num_sectors, error_t error );
  
  /**
   * Compute CRC for some contiguous data. On SUCCESS, the
   * <code>computeCrcDone</code> event will be signalled when the
   * operation completes.
   *
   * @param crc the crc value to start with.
   * @param addr within the volume to begin crc computation.
   * @param len number of bytes to compute crc over.
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  command error_t computeCrc( uint16_t crc, stm25p_addr_t addr, 
			      stm25p_len_t len );
  
  /**
   * Signals when the crc computation is complete.
   *
   * @param addr within the volume that the crc computation began at.
   * @param len number of bytes that the crc was computed over.
   * @param crc the resulting crc value
   * @param error notification of how the operation went.
   */
  event void computeCrcDone( stm25p_addr_t addr, stm25p_len_t len, 
			     uint16_t crc, error_t error );

}

