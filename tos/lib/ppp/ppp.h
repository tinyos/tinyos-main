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
#ifndef PPP_PPP_H
#define PPP_PPP_H

#ifndef PPP_PREFERRED_MRU
/** The preferred MRU for packets.  This is negotiated, unless it is
 * the PPP default of 1500 octets.  The value reflects the size of the
 * information field of a PPP packet.  Also note that RFC1661 mandates
 * the implemention must support frames with information fields up to
 * 1500 octets regardless of the negotiated MRU.  We don't necessarily
 * do that; see PPP_MAXIMUM_MRU.
 *
 * It is the developers responsibility to ensure PPP_PREFERRED_MRU <=
 * PPP_MAXIMUM_MRU, or to intentionally violate this requirement.
 *
 * @note Linux PPP requires that the negotiated MRU be at least 1280
 * bytes, or it will fail to assign an IPV6 address to the link.
 * Since the whole point of doing PPP is to enable IPv6, by default
 * we'll lie during negotation and pretend we can handle 1280 bytes.
 */
#define PPP_PREFERRED_MRU 1280
#endif /* PPP_PREFERRED_MRU */

#ifndef PPP_MAXIMUM_MRU
/** The hard maximum on the length of an information field for a
 * received PPP frame.  Frames that exceed this limit will be dropped
 * at the HDLC layer.
 *
 * It is the developers responsibility to ensure PPP_PREFERRED_MRU <=
 * PPP_MAXIMUM_MRU, or to intentionally violate this requirement. */
#define PPP_MAXIMUM_MRU PPP_PREFERRED_MRU
#endif /* PPP_MAXIMUM_MRU */

#ifndef PPP_HDLC_RX_FRAME_LIMIT
/** The maximum number of frames supported by the fragment pool used
 * for HDLC reception buffers. */
#define PPP_HDLC_RX_FRAME_LIMIT 4
#endif /* PPP_HDLC_RX_FRAME_LIMIT */

#ifndef PPP_HDLC_TX_FRAME_LIMIT
/** The maximum number of frames supported by the fragment pool used
 * for HDLC transmission buffers. */
#define PPP_HDLC_TX_FRAME_LIMIT 4
#endif /* PPP_HDLC_TX_FRAME_LIMIT */

#ifndef PPP_MINIMUM_TX_FRAME_SIZE
/** The minimum size, in octets, for an acceptable transmission buffer
 * to be returned by Ppp.getOutputFrame(). */
#define PPP_MINIMUM_TX_FRAME_SIZE 16
#endif /* PPP_MINIMUM_TX_FRAME_SIZE */

enum {
  /** The Link Control Protocol is defined in RFC 1661. */
  PppProtocol_LinkControlProtocol = 0xc021,
  /** The IPv6 Protocol is defined in RFC 5072. */
  PppProtocol_Ipv6 = 0x57,
  /** The IPv6 Control Protocol is defined in RFC 5072. */
  PppProtocol_Ipv6Cp = 0x8057,
};

/** Type holding a key that identifies a particular message frame.
 * For output frames, the key is the pointer value passed to
 * Ppp.sendOutputFrame.  This key is provided in the subsequent
 * outputFrameTransmitted event.
 *
 * For input frames, the key is the value returned by
 * Ppp.holdInputFrame.  This key must be provided to the subsequent
 * releaseInputFrame command.
 *
 * @note Although the key should be opaque to callers, various parts
 * of the implementation do rely on its value. */
typedef const uint8_t* frame_key_t;

/** Enumerations for control protocol code values.  Nominally defined
 * for the Link-Control-Protocol, in fact these codes are generally
 * re-used for network control protocols as well. */
enum {
  /** RFC 1661 section 5.1.  Data field contains a sequence of options. */
  PppControlProtocolCode_ConfigureRequest = 1,
  /** RFC 1661 section 5.2.  Data field contains a sequence of options. */
  PppControlProtocolCode_ConfigureAck = 2,
  /** RFC 1661 section 5.3.  Data field contains a sequence of options. */
  PppControlProtocolCode_ConfigureNak = 3,
  /** RFC 1661 section 5.4.  Data field contains a sequence of options. */
  PppControlProtocolCode_ConfigureReject = 4,
  /** RFC 1661 section 5.5.  Data field contains uninterpreted data
   * for use by sender. */
  PppControlProtocolCode_TerminateRequest = 5,
  /** RFC 1661 section 5.5.  Data field contains uninterpreted data
   * for use by sender. */
  PppControlProtocolCode_TerminateAck = 6,
  /** RFC 1661 section 5.6.  Data field contains rejected packet,
   * beginning with information field, truncated to peer's MRU. */
  PppControlProtocolCode_CodeReject = 7,
  /** RFC 1661 section 5.7.  Data field contains rejected protocol as
   * a uint16_t, followed by a copy of the rejected packet, beginning
   * with the information field, truncated to peer's MRU. */
  PppControlProtocolCode_ProtocolReject = 8,
  /** RFC 1661 section 5.8.  Data field contains the magic number
   * followed by uninterpreted data for use by sender. */
  PppControlProtocolCode_EchoRequest = 9,
  /** RFC 1661 section 5.8.  Data field contains the replier's magic
   * number, with the remainder matching the EchoRequest payload. */
  PppControlProtocolCode_EchoReply = 10,
  /** RFC 1661 section 5.9. Data field contains the magic number
   * followed by uninterpreted data for use by sender. */
  PppControlProtocolCode_DiscardRequest = 11,
};

typedef struct PppOptions_t {
    /** If TRUE, a PPP protocol value that fits in one octet may be
     * stored that way when messages are transmitted. */
    bool txProtocolFieldCompression;
    /** If TRUE, a PPP protocol value that fits in one octet may be
     * extracted that way when messages are received. */
    bool rxProtocolFieldCompression;
    /** Records the information field size that the remote has
     * indicated it prefers to receive. */
    uint16_t txMaximumReceiveUnit;
    /** Records the information field size that the remote has agreed
     * not to exceed */
    uint16_t rxMaximumReceiveUnit;
} PppOptions_t;

#endif /* PPP_PPP_H */
