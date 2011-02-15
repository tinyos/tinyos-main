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

#include "ppp.h"

/** Core functions provided by the PPP infrastructure: specifically,
 * management of the internal buffers used for outgoing and incoming
 * messages.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
interface Ppp {
  /** Obtain storage for an outbound message.
   *
   * The frame is initialized to hold a message associated with the
   * given protocol.  It is the callers responsibility to fill in the
   * remainder of the message, then to invoke either sendOutputFrame
   * if the message is to be transmitted or releaseOutputFrame if the
   * message is to be dropped.
   *
   * It is implementation-defined whether multiple output frames are
   * available for use.  If no output frames are available, this
   * command will return a null pointer.
   *
   * @return A pointer to the information field of the output message,
   * or a null pointer if no output buffers are available.
   * 
   * @param protocol The protocol to which the message will belong.
   *
   * @param frame_endp Secondary output value specyfing the address at
   * which the frame ends.  Attempts to store at or beyond this
   * address result in undefined behavior.
   *
   * @param inhibit_compression Indicate that, for this protocol, all
   * non-default compression should be inhibited: in particular this
   * means the protocol will always require two octets, and the
   * address and control fields will be present.  Required for LCP.
   *
   * @param keyp Where to store the key that must be used to identify
   * this output frame to the other output-related commands.  Assigned
   * only if this command returns a non-null pointer.
   */
  command uint8_t* getOutputFrame (unsigned int protocol,
                                   const uint8_t** frame_endp,
                                   bool inhibit_compression,
                                   frame_key_t* keyp);

  /** Mark the maximum length of the frame.
   *
   * frame_end must lie within the frame identified by the given key.
   *
   * This may release memory for use in other output frames. */
  command error_t fixOutputFrameLength (frame_key_t, const uint8_t* frame_end);

  /** Transmit an output frame.
   *
   * @TODO@ Auto-fix length of buffer
   *
   * The frame will be submitted for transmission.  If this command
   * returns SUCCESS, transmission will continue in the background and
   * its completion will be indicated by the outputFrameTransmitted
   * event.  With any other return value the transmission failed.
   *
   * The caller is not permitted to modify the memory of this frame
   * after invoking this command.  If this command returns SUCCESS,
   * the caller may hold on to the frame_end value until the
   * subsequent outputFrameTransmitted event is signalled.
   */
  command error_t sendOutputFrame (frame_key_t key);

  /** Cancel transmission of an output frame.
   *
   * The caller is not permitted to access the memory of this frame
   * after invoking this command.
   */
  command error_t releaseOutputFrame (frame_key_t key);
  
  /** Indication that transmission of an output message has been
   * resolved.  The caller may read the message contents until the
   * event returns.
   *
   * @param key The key that identifies the frame that was transmitted
   * @param result The disposition of the transmission */
  event void outputFrameTransmitted (frame_key_t key,
                                     error_t result);
}
