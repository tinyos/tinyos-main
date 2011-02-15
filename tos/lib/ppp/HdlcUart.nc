/* Copyright (c) 2011 People Power Co.
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
 * - Neither the name of the People Power Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * PEOPLE POWER CO. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 */

/** Provide basic UART-related functions required for the HdlcFramingC
 * infrastructure.
 *
 * The HDLC framing infrastructure needs the ability to send blocks of
 * characters, and to receive characters one-by-one as soon as they
 * arrive.  The processing done on each received character is fairly
 * complex.
 *
 * The UartStream interface's send command and receiveByte interface
 * technically meet these needs.  However, both are async operations.
 * At high serial data rates and when serving as a bridge for a
 * high-data-rate radio interface, interrupt-driven reception causes
 * dropped packets.  DMA-based reception can work around this, but the
 * lack of an a-priori length for received messages makes the
 * translation to a per-byte reception event complex.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
interface HdlcUart {

  /** Send len bytes from the given address over the UART.
   *
   * This command is essentially forwarded to UartStream.send. */
  command error_t send (uint8_t* buf,
			uint16_t len);

  /** Notification of the result of the most recent send that returned
   * SUCCESS. */
  async event void sendDone (error_t error);

  /** Notification of an error detected in serial processing.
   *
   * The event is raised once for each detected character drop, with
   * an error value of ENOMEM.  It is raised with the error value
   * SUCCESS when the infrastructure recovers from dropped characters
   * and subsequent data is known to be good.
   */
  async event void uartError (error_t error);

  /** Notification of a newly received byte.
   */
  event void receivedByte (uint8_t byte);
}
