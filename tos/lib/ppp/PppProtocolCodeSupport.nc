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

/** Most PPP control protocols are modeled on RFC1661's Link Control
 * Protocol, and use a packet format comprising:
 * - A one-octet Code field
 * - A one-octet Identifier field
 * - A two-octet Length field
 * - A data field of varying length.
 *
 * The code determines the specific format of the data field and how
 * it should be interpreted.  This interface allows an application to
 * determine which codes will be supported by only wiring in the ones
 * that are necessary.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
interface PppProtocolCodeSupport {
  /** Return the code for this handler.
   *
   * This is primarily used to detect unrecognized codes: a default
   * implementation is defined that returns code 0, which is an
   * illegal code value.  Upon detection of this situation, the
   * control protocol will generate a Code-Reject message. */
  command uint8_t getCode ();

  /** Process an incoming packet with the given identifer and data
   * region. */
  command error_t process (uint8_t identifier,
                           const uint8_t* data,
                           const uint8_t* data_end);

  /** Invoke some code-specific operation.
   *
   * Generally it involves building and transmitting a message.  If
   * so, the key for detection completion of that message should be
   * returned.
   *
   * @param param A code-specific structure, if needed to pass external information
   *
   * @param keyp A destination into which the output frame key should
   * be provided if invocation of this handler results in the
   * transmission of a message. */
  command error_t invoke (void* param,
                          frame_key_t* keyp);
}
