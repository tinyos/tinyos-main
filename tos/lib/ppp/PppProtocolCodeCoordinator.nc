/* Copyright (c) 2010 People Power Co.
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

/** Common support for all protocols that use code-based handlers.
 *
 * The set of codes recognized by each protocol is different, but the
 * process of identifying the code and dispatching to the appropriate
 * handler is the same.  Similarly, most such protocols produce an
 * error response via a Code-Reject packet when an unrecognized code
 * is encountered.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
interface PppProtocolCodeCoordinator {

  /** Extract the code information from an information field and
   * dispatch it to the appropriate handler.
   *
   * If the code is not recognized, this produces a Code-Reject packet
   * in the given protocol.
   *
   * @param information the information section of a PPP packet
   *
   * @param information_length the number of octets in the information section
   *
   * @return The result of invoking the
   * PppProtocolCodeSupport.process() command for the appropriate
   * handler (or of submitting the Code-Reject packet)
   */
  command error_t dispatch (const uint8_t* information,
                            unsigned int information_length);

  /** Generate the appropriate reject packet for an unrecognized input.
   *
   * @param rejected_protocol Normally zero, indicating a Code-Reject
   * packet should be produced.  If non-zero, represents an
   * unrecognized protocol, and generates a Protocol-Reject packet.
   * This should only be non-zero when invoked from
   * LinkControlProtocol.
   *
   * @param ip pointer to the start of the rejected packet information field
   *
   * @param ipe pointer to the first octet following the rejected
   * packet's information field
   *
   * @param keyp where to store the HDLC transmission frame key for
   * the transmitted packet.  Passing a null pointer indicates the
   * frame key is not saved (meaning nobody needs to know when the
   * transmission completes).
   */
  command error_t rejectPacket (unsigned int rejected_protocol,
                                const uint8_t* ip,
                                const uint8_t* ipe,
                                frame_key_t* keyp);
}
