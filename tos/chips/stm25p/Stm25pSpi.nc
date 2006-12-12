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
 * SPI abstraction for the ST M25P family of serial code flash chips.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.4 $ $Date: 2006-12-12 18:23:13 $
 */

interface Stm25pSpi {

  /**
   * Put chip into deep power down mode.
   *
   * @return SUCCESS if the request completed successfully, FAIL
   * otherwise.
   */
  async command error_t powerDown();

  /**
   * Release chip from power down mode.
   *
   * @return SUCCESS if the request completed successfully, FAIL
   * otherwise.
   */
  async command error_t powerUp();
  
  /**
   * Initiate a read operation. On SUCCESS, the <code>readDone</cdoe>
   * event will be signalled when the operation completes.
   *
   * @param addr the physical address to start at.
   * @param buf pointer to data buffer.
   * @param len number of bytes to read.
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  async command error_t read( stm25p_addr_t addr, uint8_t* buf, 
			      stm25p_len_t len );

  /**
   * Signals the completion of a read operation.
   *
   * @param addr the starting physical address.
   * @param buf pointer to data buffer.
   * @param len number of bytes read.
   * @param error notification of how the operation went.
   */
  async event void readDone( stm25p_addr_t addr, uint8_t* buf, 
			     stm25p_len_t len, error_t error );

  /**
   * Initiate a crc computation. On SUCCESS, the
   * <code>computeCrcDone</code> event will be signalled when the
   * operation completes.
   *
   * @param crc starting crc value.
   * @param addr the starting physical address.
   * @param len the number of bytes to do crc computation over.
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  async command error_t computeCrc( uint16_t crc, stm25p_addr_t addr,
				    stm25p_len_t len );

  /**
   * Signals the completion of a crc computation operation.
   *
   * @param crc resulting crc value.
   * @param addr the starting physical address.
   * @param len the number of bytes the crc was computed over.
   * @param error notification of how the operation went.
   */
  async event void computeCrcDone( uint16_t crc, stm25p_addr_t addr,
				   stm25p_len_t len, error_t error );

  /**
   * Initiate a page program. On SUCCESS, the
   * <code>pageProgramDone</code> event will be signalled when the
   * operation completes.
   *
   * @param addr starting physical address.
   * @param buf pointer to data buffer.
   * @param len number of bytes to write.
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  async command error_t pageProgram( stm25p_addr_t addr, uint8_t* buf, 
				     stm25p_len_t len );

  /**
   * Signal the completion of a page program operation.
   *
   * @param addr starting physical address.
   * @param buf pointer to data buffer.
   * @param len number of bytes to write.
   * @param error notification of how the operation went.
   */
  async event void pageProgramDone( stm25p_addr_t addr, uint8_t* buf, 
				    stm25p_len_t len, error_t error );

  /**
   * Initiate a sector erase. On SUCCESS, the
   * <code>sectorEraseDone</code> event will be signalled when the
   * operation completes.
   *
   * @param sector physical sector to erase.
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  async command error_t sectorErase( uint8_t sector );

  /**
   * Signals the completion of a sector erase operation.
   *
   * @param sector physical sector erased
   * @param error notification of how the operation went.
   */
  async event void sectorEraseDone( uint8_t sector, error_t error );

  /**
   * Initiate a bulk erase. On SUCCESS, the <code>bulkEraseDone</code>
   * event will be signalled when the operation completes.
   *
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  async command error_t bulkErase();

  /**
   * Signals the completion of a bulk erase operation.
   *
   * @param error notification of how the operation went.
   */
  async event void bulkEraseDone( error_t error );

}
