/*                                                                      
 * Copyright (c) 2016 Eric B. Decker
 * Copyright (c) 2000-2005 The Regents of the University  of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
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
 * SPI Packet/buffer interface for sending data over an SPI bus.  This
 * interface provides a split-phase send command which can be used for
 * sending, receiving or both.
 *
 * The SPI bus both sends and receives at the same time.  So this interface
 * can be used to send, receive, or both.  The send call allows NULL
 * parameters for receive or send only operations. This interface is
 * for buffer based transfers where the microcontroller is the master
 * (clocking) device.
 *
 * This is split phase and typically is implemented using interrupts.  However
 * as the SPI clock is increased the interrupt overhead become more onerous
 * wrt each byte time being transfered.  See SpiBLock for a single phase
 * transfer mechanism that doesn't have interrupt overhead issues.
 *
 * Often, an SPI bus must first be acquired using a Resource interface
 * before sending commands with SPIPacket. In the case of multiple
 * devices attached to a single SPI bus, chip select pins are often also
 * used.
 *
 * @author Philip Levis
 * @author Jonathan Hui
 * @author Joe Polastre
 * @author Eric B. Decker
 */
interface SpiPacket {

  /**
   * Send a message over the SPI bus.
   *
   * @param 'uint8_t* COUNT_NOK(len) txBuf' A pointer to the buffer to send over the bus. If this
   *              parameter is NULL, then the SPI will send zeroes.
   * @param 'uint8_t* COUNT_NOK(len) rxBuf' A pointer to the buffer where received data should
   *              be stored. If this parameter is NULL, then the SPI will
   *              discard incoming bytes.
   * @param len   Length of the message.  Note that non-NULL rxBuf and txBuf
   *              parameters must be AT LEAST as large as len, or the SPI
   *              will overflow a buffer.
   *
   * @return SUCCESS if the request was accepted for transfer
   */
  async command error_t send( uint8_t* txBuf, uint8_t* rxBuf, uint16_t len );

  /**
   * Notification that the send command has completed.
   *
   * @param 'uint8_t* COUNT_NOK(len) txBuf' The buffer used for transmission
   * @param 'uint8_t* COUNT_NOK(len) rxBuf' The buffer used for reception
   * @param len    The request length of the transfer, but not necessarily
   *               the number of bytes that were actually transferred
   * @param error  SUCCESS if the operation completed successfully, FAIL
   *               otherwise
   */
  async event void sendDone( uint8_t* txBuf, uint8_t* rxBuf, uint16_t len,
                             error_t error );

}
