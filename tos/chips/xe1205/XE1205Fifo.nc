/* 
 * Copyright (c) 2006, Ecole Polytechnique Federale de Lausanne (EPFL),
 * Switzerland.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ========================================================================
 */

/**
 * Interface for access to the XE1205 radio Fifo. 
 *
 * @author Henri Dubois-Ferriere
 */

interface XE1205Fifo {

  /**
   * Write a sequence of data bytes to the output FIFO.
   * Care must be taken not to overflow the FIFO (16 bytes).
   * If call returns SUCCESS, writeDone will be signalled upon completion.
   *
   * @param data a pointer to the send buffer.
   * @param length number of bytes written.
   * @return SUCCESS if the request was accepted for transfer
   */
  async command error_t write(uint8_t* data, uint8_t length);

  /**
   * Signals the completion of the previous write operation.
   *
   * @param error  SUCCESS if the operation completed successfully, FAIL
   *               otherwise
   */
  async event void writeDone(error_t error);

  /**
   * Read a sequence of data bytes from the input FIFO.
   * The FIFO level is not checked, and care must be taken not to underflow
   * the FIFO (16 bytes).
   *
   * @param data a pointer to the receive buffer.
   * @param length number of bytes to read.
   * @return SUCCESS if the request was accepted for transfer
   */
  async command error_t read(uint8_t* data, uint8_t length);



  /**
   * Signals the completion of the previous write operation.
   *
   * @param error  SUCCESS if the operation completed successfully, FAIL
   *               otherwise
   */
  async event void readDone(error_t error );
}
