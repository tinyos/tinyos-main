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

#ifndef PPP_LCP_H
#define PPP_LCP_H

/** Link Control Protocol constants and structures */

#ifndef PPP_LCP_ENABLE_PCOMP
/** Control whether protocol compression is supported.
 *
 * By default, we disable this option.  When enabled, it allows the
 * protocol field to be represented in a single octet, which cuts down
 * on transmitted data, but leaves the information field of the packet
 * aligned on an odd byte boundary, which is really inconvenient when
 * decoding network packets. */
#define PPP_LCP_ENABLE_PCOMP (0)
#endif /* PPP_LCP_ENABLE_PCOMP */


enum {
  /** RFC 1661 section 6.1.  Payload is a uint16_t.  @note The MRU
   * comprises the length of the PPP packet information field
   * including padding.  The protocol field, and any space for HDLC
   * address/control/FCS data is not accounted for by the MRU.  @TODO
   * support */
  LCPOpt_MaximumReceiveUnit = 1,
  /** RFC 1662 section 7.1.  Payload is a uint32_t representing a set
   * of ASCII control characters.  @note Not currently supported */
  LCPOpt_AsyncControlCharacterMap = 2,
  /** RFC 1661 section 6.2.  Payload is a uint16_t denoting an
   * authentication protocol, followed by protocol-specific data.
   * @note Not currently supported. */
  LCPOpt_AuthenticationProtocol = 3,
  /** RFC 1661 section 6.3.  Payload is a uint16_t denoting a quality
   * protocol, followed by protocol-specific data.  @note Not
   * currently supported. */
  LCPOpt_QualityProtocol = 4,
  /** RFC 1661 section 6.4.  Payload is a uint32_t.  @TODO support */
  LCPOpt_MagicNumber = 5,
  // 6 deprecated
  /** RFC  1661  section  6.5.   No  payload; presence  of  option  is
   * sufficient.  @TODO support */
  LCPOpt_ProtocolFieldCompression = 7,
  /** RFC 1661 section 6.6.  No payload; presence of option is
   * sufficient.  @TODO support */
  LCPOpt_AddressControlFieldCompression = 8,
  /* No other LCP options are currently proposed for support */
};

/** Information required by the Protocol-Reject.invoke() method
 * provided by the LCP component. */
typedef struct protocolReject_param_t {
  unsigned int protocol;
  const uint8_t* information;
  unsigned int information_length;
} protocolReject_param_t;

#endif /* PPP_LCP_H */
