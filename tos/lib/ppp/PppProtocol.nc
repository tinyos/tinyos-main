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

/** Basic interface used by the PPP infrastructure to connect to an
 * arbitrary protocol.
 *
 * Components that provide this interface should generally define an
 * enumeration value named Protocol in their specification, so that
 * applications can wire the interface into the PppC Protocols
 * subsystem using the correct protocol value.  See
 * LinkControlProtocolC for a canonical example.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
interface PppProtocol {
  /** Return the protocol code for this protocol.
   *
   * This is primarily used to detect unrecognized protocols: a
   * default implementation is defined that returns protocol 0, which
   * is an illegal protocol value.  Upon detection of this situation,
   * the PppC component delegates handling to a module that implements
   * PppProtocolReject.
   *
   * @return A non-zero value for a registered protocol; zero if the
   * protocol is unknown to the system. */
  command unsigned int getProtocol ();

  /** Process an incoming packet with the given information payload.
   *
   * The packet memory is owned by the PppC component to which this
   * protocol has been wired.  Normally, that memory is released for
   * re-use upon return of this command.  There are cases where the
   * protocol requires continued access to the data after this command
   * completes (for example, to await completion of a PPP
   * transmission).  The called component must invoke the
   * Ppp.holdInputFrame() command during this command if it requires
   * continued access to the input buffer.
   *
   * @param information A pointer to the start of the information
   * field for the message.
   *
   * @param information_length The number of octets in the information
   * field.  This may incorporate padding; the protocol must determine
   * this.
   *
   * @return SUCCESS if packet was processed.  ERETRY if the system is
   * busy but the packet might be processable again later.  Other errors
   * indicate the packet should not be re-processed. */
  command error_t process (const uint8_t* information,
                           unsigned int information_length);

  /** Invoked to inform protocol that the peer rejected it.
   *
   * Poor, sad, lonely protocol.
   *
   * @param data If not null, this begins the start of the information
   * field from the message that caused the peer to reject the
   * protocol.  If null, this is being invoked by the engine after the
   * link has been reset, indicating that the protocol may re-enable
   * itself.
   *
   * @param data_end Points past the end of whatever portion of the
   * rejected message was returned by the peer.  Null if data is null.
   *
   * @return SUCCESS, please. */
  command error_t rejectedByPeer (const uint8_t* data,
                                  const uint8_t* data_end);
}
