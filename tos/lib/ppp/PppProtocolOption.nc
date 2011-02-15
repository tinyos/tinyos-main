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

/** Operations that should be supported for each option that can be
 * configured through an LCP-style automaton negotiation.
 *
 * @note We currently do not support options that can appear multiple
 * times in a single request.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com> */
interface PppProtocolOption {
  /** Return the option type code for this option within its protocol.
   *
   * This is primarily used to detect unrecognized options: a default
   * implementation is defined that returns option 0, which is an
   * illegal option value.  Upon detection of this situation, the
   * configuration processing implementation will generate a
   * Configure-Reject message. */
  command uint8_t getType ();

  /** Return TRUE iff the option should be added to outgoing
   * Configure-Request messages.
   *
   * If the option is negotiable, appendRequest will invoked to append
   * the proposed local value to the outgoing request message.
   *
   * @note Negotiability of remote values for options is indicated by
   * the return value of considerRequest. */
  command bool isNegotiable ();

  /** Set whether the local value of the option should be negotiated,
   * based on protocol activity.
   *
   * Option negotiation is set to FALSE upon receipt of a
   * Configure-Reject message identifying the option, and upon a
   * Reject return from considerRequest.  It is set to TRUE upon
   * receipt of a non-Reject return from considerRequest. */
  command void setNegotiable (bool is_negotiable);

  /** Determine whether the proposed remote value is acceptable to the
   * protocol.

   * @return PppControlProtocolCode_Configure{Ack,Nak,Reject},
   * depending on whether the option value specified at dp is
   * acceptable to this end of the link. */
  command uint8_t considerRequest (const uint8_t* dp,
                                   const uint8_t* dpe);

  /** Add a proposed local value to a message.  The option type and
   * length fields are already incorporated; only the data portion is
   * to be stored. */
  command uint8_t* appendRequest (uint8_t* dp,
                                  const uint8_t* dpe);

  /** Add an alternative suggestion to a Nak message.  The option type
   * and length fields are already reserved; only the data portion is
   * to be stored.
   *
   * If the option cannot express an acceptable alternative within the
   * buffer indicated by dp to dpe, the command should return a null
   * pointer.  Otherwise, the command should return a pointer just
   * past the last octet of its proposed alternative.
   *
   * @param sp The value in the Configure-Request message, in case
   * that's useful when proposing an alternative
   *
   * @param spe Indidates the end of the requested option value
   *
   * @param dp Where the proposed alternative should be stored
   *
   * @param dpe The limit up to which the proposed alternative may be
   * written. */
  command uint8_t* appendNakValue (const uint8_t* sp,
                                   const uint8_t* spe,
                                   uint8_t* dp,
                                   const uint8_t* dpe);

  /** Completely reset the option prior to a new negotiation sequence.
   *
   * This brings things back to their power-up default, and is
   * executed when the link goes down.  It re-enables options for
   * negotiation, and restores default proposed local and remote
   * values. */
  command void reset ();

  /** Set (reset) the option's local value.
   *
   * The set operation is invoked on each option present in a received
   * Configure-Ack message (i.e., this node requested the value).  The
   * reset operation is invoked prior to transmission of a
   * Configure-Request (need permission for value).
   *
   * @param dp Start of the option value.  If passed as a null
   * pointer, option is reset to its default.
   *
   * @param dpe First octet past option value. */
  command void setLocal (const uint8_t* dp,
                         const uint8_t* dpe);

  /** Process a proposed alternative local value.
   *
   * This operation is invoked when the remote sends a Configure-Nak
   * in response to local's Configure-Request.  Generally, the
   * response should be to replace the original local value with the
   * value proposed by the peer, or to mark the option non-negotiable.
   *
   * @param dp Start of the option value.
   *
   * @param dpe First octet past option value. */
  command void processNakValue (const uint8_t* dp,
                                const uint8_t* dpe);

  /** Set (reset) the option's remote value.
   *
   * The set operation is invoked on each option present in a
   * transmitted Configure-Ack message (i.e., the remote node
   * requested the value).  This is done after transmission.  The
   * reset operation is invoked upon receipt of a Configure-Request.
   *
   * @param dp Start of the option value.  If passed as a null
   * pointer, option is reset to its default.
   *
   * @param dpe First octet past option value. */
  command void setRemote (const uint8_t* dp,
                          const uint8_t* dpe);

}
