//$Id: SendBytePacket.nc,v 1.5 2010-06-29 22:07:50 scipio Exp $

/* Copyright (c) 2000-2005 The Regents of the University of California.  
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
 * - Neither the name of the copyright holder nor the names of
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
 * This is an interface that a serial framing protocol provides and a serial
 * dispatcher uses. The call sequence should be as follows:
 * The dispatcher should call startSend, specifying the first byte to
 * send. The framing protocol can then signal as many nextBytes as it
 * wants/needs, to spool in the bytes. It continues to do so until it receives
 * a sendComplete call, which will almost certainly happen within a nextByte
 * signal (i.e., re-entrant to the framing protocol).

 * This allows the framing protocol to buffer as many bytes as it needs to to meet
 * timing requirements, jitter, etc. 
 *
 * @author Philip Levis
 * @author Ben Greenstein
 * @date August 7 2005
 *
 */


interface SendBytePacket {
  /**
   * The dispatcher may initiate a serial transmission by calling this function
   * and passing the first byte to be transmitted.
   * @param first_byte The first byte to be transmitted.
   * @return Returns an error_t code indicating either that the framer
   * has the resources available to transmit the frame (SUCCESS) or
   * not (EBUSY).
   */
  async command error_t startSend(uint8_t first_byte);

  /**
   * The dispatcher must indicate when the end-of-packet has been reached and does
   * so by calling completeSend. The function may be called from within the
   * implementation of a nextByte event.
   * @return Returns an error_t code indicating whether the framer accepts
   * this notification (SUCCESS) or not (FAIL).
   */
  async command error_t completeSend();

  /**
   * Used by the framer to request the next byte to transmit. The
   * framer may allocate a buffer to pre-spool some or all of a
   * packet; or it may request and transmit a byte at a time. If there
   * are no more bytes to send, the dispatcher must call completeSend
   * before returning from this function.
   * @return The dispatcher must return the next byte to transmit
   */
  async event uint8_t nextByte();

  /**
   * The framer signals sendCompleted to indicate that it is done transmitting a
   * packet on the dispatcher's behalf. A non-SUCCESS error_t code indicates that
   * there was a problem in transmission.
   * @param error The framer indicates whether it has successfully
   * accepted the entirety of the packet from the dispatcher (SUCCESS)
   * or not (FAIL).
   */
  async event void sendCompleted(error_t error);
}



