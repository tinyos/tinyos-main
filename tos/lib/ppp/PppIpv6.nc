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

#include "pppipv6.h"

/** Interface supporting RFC5072 IPv6-over-PPP using the OSIAN/TinyOS
 * PPP daemon.
 *
 * This interface is intended as a bridge between the PPP daemon and a
 * specific implementation of IPv6, such as blip or OIP.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
interface PppIpv6 {
  /** Return the negotiated IID for the local (TinyOS) end of the PPP
   * link.
   *
   * @return Pointer to configured IID; null pointer if the link is
   * not up. */
  command const ppp_ipv6cp_iid_t* localIid ();

  /** Return the negotiated IID for the remote (PC) end of the PPP
   * link.
   *
   * @return Pointer to configured remote IID; null pointer if the
   * link is not up. */
  command const ppp_ipv6cp_iid_t* remoteIid ();

  /** Transmit data to the remote end.
   *
   * @param message Pointer to a sequence of octets to be transmitted.
   *
   * @param len The number of bytes to transmit.
   *
   * @return SUCCESS iff a frame could be allocated and the message
   * transmitted. */
  command error_t transmit (const uint8_t* message,
                            unsigned int len);

  /** @return TRUE iff the LCP automaton is in a link-up state. */
  command bool linkIsUp ();

  /** Signal that the PPP link has come up */
  event void linkUp ();

  /** Signal that the PPP link has gone down */
  event void linkDown ();

  /** Signal that a message has been received over the PPP link.
   *
   * @param message Sequence of octets received, after all
   * PPP-relevant framing has been removed.
   *
   * @param len Number of octets received.
   *
   * @return SUCCESS if the recipient has successfully processed the
   * message.  Non-SUCCESS values may be used for purposes as defined
   * by PppProtocol.process(). */
  event error_t receive (const uint8_t* message,
                         unsigned int len);
}
