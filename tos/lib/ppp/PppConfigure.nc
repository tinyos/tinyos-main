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

/** Provide facility to set a complete set of options for a given
 * protocol.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
interface PppConfigure {
  /** Completely reset all options prior to a new negotiation sequence.
   *
   * This brings things back to their power-up default, and is
   * executed when the link goes down.  This includes default proposed
   * local and remote values, as well as resetting whether the option
   * is negotiable. */
  command void resetOptions ();

  /** Set (reset) the local value for a protocol's options.
   *
   * This is invoked to set options by passing an encoded option set
   * extracted from a received Configure-Ack; to convey proposed
   * alternatives from a Configure-Nak; and to disable negotiation
   * from a Configure-Reject.  If the code is for Configure-Ack, the
   * content of this set must match the previously transmitted
   * Configure-Request.
   *
   * This is invoked with null pointers to reset the local values
   * prior to transmission of a Configure-Request.
   *
   * @param code The message type from which the options were received.
   * @param dp Start of the encoded option sequence; null for reset
   * @param dpe End of the encoded option sequence; null for reset */
  command void setLocalOptions (uint8_t code,
                                const uint8_t* dp,
                                const uint8_t* dpe);
  
  /** Set (reset) the remote value for a protocol's options.
   *
   * This is invoked to set options by passing an encoded option set
   * extracted from a transmitted Configure-Ack (equivalently, an
   * accepted received Configure-Request).
   *
   * This is invoked with null pointers to reset the remote values
   * upon receipt of a Configure-Request.
   *
   * @param dp Start of the encoded option sequence
   * @param dpe End of the encoded option sequence */
  command void setRemoteOptions (const uint8_t* dp,
                                 const uint8_t* dpe);
}
