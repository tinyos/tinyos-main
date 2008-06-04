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
 *
 * Copyright (c) 2002-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Read interface for the log storage abstraction described in
 * TEP103.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @author David Gay
 * @version $Revision: 1.5 $ $Date: 2008-06-04 03:00:25 $
 */

#include "Storage.h"

interface ConfigStorage {
  /**
   * Initiate a read operation within a given volume. On SUCCESS, the
   * <code>readDone</code> event will signal completion of the
   * operation. The data read is the contents of the config volume
   * as of the last commit operation.
   * 
   * @param addr starting address to begin reading.
   * @param 'void* COUNT(len) buf' buffer to place read data.
   * @param len number of bytes to read.
   * @return 
   *   <li>SUCCESS if the request was accepted, 
   *   <li>EINVAL if the parameters are invalid
   *   <li>EOFF if the volume has not been mounted
   *   <li>EBUSY if a request is already being processed.
   *   <li>FAIL if the volume does not contain valid data 
   *       (see <code>valid</code>)
   */
  command error_t read(storage_addr_t addr, void* buf, storage_len_t len);

  /**
   * Signals the completion of a read operation.
   *
   * @param addr starting address of read.
   * @param 'void* COUNT(len) buf' buffer where read data was placed.
   * @param len number of bytes read.
   * @param error SUCCESS if the operation was successful, FAIL if
   *   it failed
   */
  event void readDone(storage_addr_t addr, void* buf, storage_len_t len, 
		      error_t error);
  
  /**
   * Initiate a write operation within a given volume. On SUCCESS, the
   * <code>writeDone</code> event will signal completion of the
   * operation.
   * 
   * @param addr starting address to begin write.
   * @param 'void* COUNT(len) buf' buffer to write data from.
   * @param len number of bytes to write.
   * @return 
   *   <li>SUCCESS if the request was accepted, 
   *   <li>EINVAL if the parameters are invalid
   *   <li>EOFF if the volume has not been mounted
   *   <li>EBUSY if a request is already being processed.
   */
  command error_t write(storage_addr_t addr, void* buf, storage_len_t len);

  /**
   * Signals the completion of a write operation. However, data is not
   * guaranteed to survive a power-cycle unless a commit operation has
   * been completed.
   *
   * @param addr starting address of write.
   * @param 'void* COUNT(len) buf' buffer that written data was read from.
   * @param len number of bytes written.
   * @param error SUCCESS if the operation was successful, FAIL if
   *   it failed
   */
  event void writeDone(storage_addr_t addr, void* buf, storage_len_t len, 
		       error_t error);
  
  /**
   * Initiate a commit operation and finialize any additional writes to the
   * volume. A commit operation must be issued to ensure that data is
   * stored in non-volatile storage. On SUCCES, the <code>commitDone</code>
   * event will signal completion of the operation.
   *
   * @return 
   *   <li>SUCCESS if the request was accepted, 
   *   <li>EBUSY if a request is already being processed.
   *   <li>EOFF if the volume has not been mounted
   */
  command error_t commit();

  /**
   * Signals the completion of a commit operation. All written data is
   * flushed to non-volatile storage after this event.
   *
   * @param error SUCCESS if the operation was successful, FAIL if
   *   it failed
   */
  event void commitDone(error_t error);

  /**
   * Report the usable volume size in bytes (this may be significantly
   * different from the actual volume size, e.g., it's approximately
   * half the volume size on the AT45DB implementation).
   *
   * @return Volume size. The result is undefined if the volume hasn't
   *    been mounted.
   */
  command storage_len_t getSize();

  /**
   * Report whether this config volume contains valid data. Committing
   * a volume makes it valid.
   *
   * @return TRUE if the volume contains valid data, FALSE otherwise. The
   *    result is undefined if the volume hasn't been mounted.
   */
  command bool valid();
}
