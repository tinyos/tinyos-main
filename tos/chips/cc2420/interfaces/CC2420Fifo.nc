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
 * HAL abstraction for accessing the FIFO registers of a ChipCon
 * CC2420 radio.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.1 $ $Date: 2007-07-04 00:37:14 $
 */

interface CC2420Fifo {

  /**
   * Start reading from the FIFO. The <code>readDone</code> event will
   * be signalled upon completion.
   *
   * @param data a pointer to the receive buffer.
   * @param length number of bytes to read.
   * @return status byte returned when sending the last address byte
   * of the SPI transaction.
   */
  async command cc2420_status_t beginRead( uint8_t* data, uint8_t length );

  /**
   * Continue reading from the FIFO without having to send the address
   * byte again. The <code>readDone</code> event will be signalled
   * upon completion.
   *
   * @param data a pointer to the receive buffer.
   * @param length number of bytes to read.
   * @return SUCCESS always.
   */
  async command error_t continueRead( uint8_t* data, uint8_t length );

  /**
   * Signals the completion of a read operation.
   *
   * @param data a pointer to the receive buffer.
   * @param length number of bytes read.
   * @param error notification of how the operation went
   */
  async event void readDone( uint8_t* data, uint8_t length, error_t error );

  /**
   * Start writing the FIFO. The <code>writeDone</code> event will be
   * signalled upon completion.
   *
   * @param data a pointer to the send buffer.
   * @param length number of bytes to write.
   * @return status byte returned when sending the last address byte
   * of the SPI transaction.
   */
  async command cc2420_status_t write( uint8_t* data, uint8_t length );

  /**
   * Signals the completion of a write operation.
   *
   * @param data a pointer to the send buffer.
   * @param length number of bytes written.
   * @param error notification of how the operation went
   */
  async event void writeDone( uint8_t* data, uint8_t length, error_t error );

}
