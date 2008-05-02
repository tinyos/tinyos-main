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
 * Write interface for the block storage abstraction described in
 * TEP103.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.5 $ $Date: 2008-05-02 19:50:00 $
 */

#include "Storage.h"

interface BlockWrite {
  /**
   * Initiate a write operation within a given volume. On SUCCESS, the
   * <code>writeDone</code> event will signal completion of the
   * operation.
   * <p>
   * Between two erases, no byte may be written more than once.
   * 
   * @param addr starting address to begin write.
   * @param buf buffer to write data from.
   * @param len number of bytes to write.
   * @return 
   *   <li>SUCCESS if the request was accepted, 
   *   <li>EINVAL if the parameters are invalid
   *   <li>EBUSY if a request is already being processed.
   */
  command error_t write(storage_addr_t addr, void* buf, storage_len_t len);

  /**
   * Signals the completion of a write operation. However, data is not
   * guaranteed to survive a power-cycle unless a sync operation has
   * been completed.
   *
   * @param addr starting address of write.
   * @param buf buffer that written data was read from.
   * @param len number of bytes written.
   * @param error SUCCESS if the operation was successful, FAIL if
   *   it failed
   */
  event void writeDone(storage_addr_t addr, void* buf, storage_len_t len, 
		       error_t error);
  
  /**
   * Initiate an erase operation. On SUCCESS, the
   * <code>eraseDone</code> event will signal completion of the
   * operation.
   *
   * @return 
   *   <li>SUCCESS if the request was accepted, 
   *   <li>EBUSY if a request is already being processed.
   */
  command error_t erase();
  
  /**
   * Signals the completion of an erase operation.
   *
   * @param error SUCCESS if the operation was successful, FAIL if
   *   it failed
   */
  event void eraseDone(error_t error);

  /**
   * Initiate a sync operation to finalize writes to the volume. A
   * sync operation must be issued to ensure that data is stored in
   * non-volatile storage. On SUCCES, the <code>syncDone</code> event
   * will signal completion of the operation.
   *
   * @return 
   *   <li>SUCCESS if the request was accepted, 
   *   <li>EBUSY if a request is already being processed.
   */
  command error_t sync();

  /**
   * Signals the completion of a sync operation. All written data is
   * flushed to non-volatile storage after this event.
   *
   * @param error SUCCESS if the operation was successful, FAIL if
   *   it failed
   */
  event void syncDone(error_t error);
}
