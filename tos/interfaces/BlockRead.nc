/**
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
 * Read interface for the block storage abstraction described in
 * TEP103.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.4 $ $Date: 2006-12-12 18:23:14 $
 */

#include "Storage.h"

interface BlockRead {
  /**
   * Initiate a read operation within a given volume. On SUCCESS, the
   * <code>readDone</code> event will signal completion of the
   * operation.
   * 
   * @param addr starting address to begin reading.
   * @param buf buffer to place read data.
   * @param len number of bytes to read.
   * @return 
   *   <li>SUCCESS if the request was accepted, 
   *   <li>EINVAL if the parameters are invalid
   *   <li>EBUSY if a request is already being processed.
   */
  command error_t read(storage_addr_t addr, void* buf, storage_len_t len);

  /**
   * Signals the completion of a read operation.
   *
   * @param addr starting address of read.
   * @param buf buffer where read data was placed.
   * @param len number of bytes read.
   * @param error SUCCESS if the operation was successful, FAIL if
   *   it failed
   */
  event void readDone(storage_addr_t addr, void* buf, storage_len_t len, 
		      error_t error);
  
  /**
   * Initiate a crc computation. On SUCCESS, the
   * <code>computeCrcDone</code> event will signal completion of the
   * operation.
   *
   * @param addr starting address.
   * @param len the number of bytes to compute the crc over.
   * @parm crc initial CRC value
   * @return 
   *   <li>SUCCESS if the request was accepted, 
   *   <li>EINVAL if the parameters are invalid
   *   <li>EBUSY if a request is already being processed.
   */
  command error_t computeCrc(storage_addr_t addr, storage_len_t len,
			     uint16_t crc);

  /**
   * Signals the completion of a crc computation.
   *
   * @param addr stating address.
   * @param len number of bytes the crc was computed over.
   * @param crc the resulting crc value.
   * @param error SUCCESS if the operation was successful, FAIL if
   *   it failed
   */
  event void computeCrcDone(storage_addr_t addr, storage_len_t len,
			    uint16_t crc, error_t error);

  /**
   * Report the usable volume size in bytes (this may be different than
   * the actual volume size because of metadata overheads).
   * @return Volume size.
   */
  command storage_len_t getSize();
}
