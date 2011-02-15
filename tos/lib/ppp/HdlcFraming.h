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

#ifndef PPP_HDLC_FRAMING_H
#define PPP_HDLC_FRAMING_H

/** Structure defining options that control HDLC framing.
 *
 * @note Implementation of the ACCM capability is not optional.  The
 * initial value defined in RFC1661 is to escape all control
 * characters less than 0x20.  During link negotiation, these
 * characters must be escaped or the peer is required to drop them,
 * which will result in FCS failure. */
typedef struct HdlcFramingOptions_t {
    /** If TRUE, the address and control field bytes are suppressed on
     * outgoing frames. */
    bool txSuppressAddressControl;
    /** If TRUE, the address and control field bytes are expected to
     * be absent from incoming frames. */
    bool rxSuppressAddressControl;
    /** Bit mask denoting those ASCII control characters that must be
     * escaped prior to transmission to the peer. */
    uint32_t txAsyncControlCharacterMap;
    /** Bit mask denoting those ASCII control characters that the peer
     * will escape prior to transmission.  Receipt of an unescaped
     * character in this set indicates a transmission error. */
    uint32_t rxAsyncControlCharacterMap;
} HdlcFramingOptions_t;

/** Codes indicating the cause of an HDLC-level error. */
typedef enum HdlcError_e {
  /** No error detected */
  HdlcError_None,
  /** The framing options require the address field be present, and
   * its content is not the required All-Stations address. */
  HdlcError_InvalidAddressField,
  /** The framing options require a control field, and its value is
   * not recognized. */
  HdlcError_InvalidControlField,
  /** A flag sequence was received without having sufficient data to
   * express the minimal packet content including CRC. */
  HdlcError_ShortFrame,
  /** The CRC calculated over the received frame did not match the
   * expected value. */
  HdlcError_BadCrc,
  /** We got data, but nobody's provided a buffer to store it in. */
  HdlcError_NoBufferAvailable,
  /** More data was present in the frame (including CRC) than is
   * available in the currently configured receive buffer. */
  HdlcError_BufferOverflow,
  /** The receive buffer was deconfigured while holding a partial
   * frame */
  HdlcError_ReceptionCancelled,
} HdlcError_e;

#endif /* PPP_HDLC_FRAMING_H */
