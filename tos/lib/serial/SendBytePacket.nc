//$Id: SendBytePacket.nc,v 1.4 2006-12-12 18:23:31 vlahan Exp $

/* "Copyright (c) 2000-2005 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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



