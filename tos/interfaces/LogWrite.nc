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
 * Write interface for the log storage abstraction described in
 * TEP103.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.4 $ $Date: 2006-12-12 18:23:14 $
 */

#include "Storage.h"

interface LogWrite {
  /**
   * Append data to a given volume. On SUCCESS, the <code>appendDone</code> 
   * event will signal completion of the operation.
   * 
   * @param buf buffer to write data from.
   * @param len number of bytes to write.
   * @return 
   *   <li>SUCCESS if the request was accepted, 
   *   <li>EINVAL if the request is invalid (len too large).
   *   <li>EBUSY if a request is already being processed.
   */
  command error_t append(void* buf, storage_len_t len);

  /**
   * Signals the completion of an append operation. However, data is not
   * guaranteed to survive a power-cycle unless a commit operation has
   * been completed.
   *
   * @param buf buffer that written data was read from.
   * @param len number of bytes actually written (valid even in case of error)
   * @param records_lost TRUE if this append destroyed some old records from
   *   the beginning of the log (only possible for circular logs).
   * @param error SUCCESS if append was possible, ESIZE if the (linear) log
   *    is full and FAIL for other errors.
   */
  event void appendDone(void* buf, storage_len_t len, bool recordsLost,
			error_t error);
  
  /**
   * Return a "cookie" representing the current append offset within the
   * log. This cookie can be used in a subsequent seek operation (see
   * <code>LogRead</code> to start reading from this place in the log (if
   * it hasn't been overwritten).
   *
   * The current write position is not known before the first read, append,
   * seek, erase or sync.
   *
   * @return Cookie representing current offset. 
   */
  command storage_cookie_t currentOffset();

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
   * @param error SUCCESS if the log was erased, FAIL otherwise.
   */
  event void eraseDone(error_t error);

  /**
   * Ensure all writes are present on flash, and that failure in subsequent
   * writes cannot cause loss of earlier writes. On SUCCES, the 
   * <code>commitDone</code> event will signal completion of the operation.
   *
   * @return 
   *   <li>SUCCESS if the request was accepted, 
   *   <li>EBUSY if a request is already being processed.
   */
  command error_t sync();

  /**
   * Signals the successful or unsuccessful completion of a sync operation. 
   *
   * @param error SUCCESS if the log was synchronised, FAIL otherwise.
   */
  event void syncDone(error_t error);
}
