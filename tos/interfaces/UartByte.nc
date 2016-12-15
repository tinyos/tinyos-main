/*
 * Copyright (c) 2013, Eric B. Decker
 * Copyright (c) 2006 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Jonathan Hui <jhui@archedrock.com>
 * @author Eric B. Decker <cire831@gmail.com>
 */

interface UartByte {

  /**
   * Send a single uart byte. The call blocks until it is ready to
   * accept another byte for sending.
   *
   * @param byte The byte to send.
   * @return SUCCESS if byte was sent, FAIL otherwise.
   */
  async command error_t send( uint8_t byte );

  /**
   * sendAvail: is space available for another TX byte.
   *
   * @return TRUE	the TX subsystem can take another byte.  ie.
   *			UartByte.send() would not block if called.
   *	     FALSE	TX pipeline is full, UartByte.send() would block.
   */
  async command bool    sendAvail();

  /**
   * Receive a single uart byte. The call blocks until a byte is
   * received or the timeout occurs.
   *
   * @param 'uint8_t* ONE byte' Where to place received byte.
   * @param timeout How long in byte times to wait.
   * @return SUCCESS if a byte was received, FAIL if timed out.
   */
  async command error_t receive( uint8_t* byte, uint8_t timeout );

  /**
   * receiveAvail: incoming has another byte available.
   *
   * @return TRUE	the RX subsystem has another byte to receive.  ie.
   *			UartByte.receive() would not block if called.
   *	     FALSE	RX pipeline is empty, UartByte.receive() would block
   *			waiting for a byte and/or the timeout.
   */
  async command bool    receiveAvail();
}
