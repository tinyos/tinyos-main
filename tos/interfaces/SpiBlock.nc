/*
 * Copyright (c) 2011 Eric B. Decker
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
 * Send/Receive (transfer) SPI data, single phase.
 *
 * Similar to SpiPacket but is not split phase.  Transfering any data
 * on the SPI requires both a transmit and a receive.  SpiBlock.write
 * can be used for transmit, receive, or both simultaneously.
 *
 * Many SPI transfers are a small number of (>1) bytes.  SpiPacket requires
 * split phase and that costs a non-zero overhead.   Potentially uses
 * interrupts (which can be expensive) or DMA (much better for large data
 * transfers).
 *
 * So we really want a more efficient small number of bytes mechanism.  That
 * is the purpose of SpiBlock.
 *
 * Often, an SPI bus must first be acquired using a Resource interface
 * before sending commands with SPIPacket. In the case of multiple
 * devices attached to a single SPI bus, chip select pins are often also
 * used.
 *
 * @author Eric B. Decker <cire831@gmail.com>
 */

interface SpiBlock {

  /**
   * Transmit/Receive a buffer over the SPI bus.   (single phase, efficient)
   *
   * @param 'uint8_t* COUNT_NOK(len) txBuf' A pointer to the buffer to send
   *		over the bus. If this parameter is NULL, then CPU will
   *		write zeros.
   * @param 'uint8_t* COUNT_NOK(len) rxBuf' A pointer to the buffer where
   *		received data should be stored. If this parameter is NULL,
   *		then incoming bytes will be discarded.
   * @param len Length of the message.  Note that non-NULL rxBuf and txBuf
   *		parameters must be AT LEAST as large as len, or buffer
   *		overflow will occur.
   *
   * @return SUCCESS
   */

  async command void transfer(uint8_t* txBuf, uint8_t* rxBuf, uint16_t len);
}
