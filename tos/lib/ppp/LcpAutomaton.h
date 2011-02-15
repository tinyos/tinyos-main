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

#ifndef PPP_LCP_AUTOMATON_H
#define PPP_LCP_AUTOMATON_H

#include "ppp.h"

/** States of the LCP automaton as defined in RFC1661. */
typedef enum LcpAutomatonState_e {
  LAS_Initial = 0,
  LAS_Starting,
  LAS_Closed,
  LAS_Stopped,
  LAS_Closing,
  LAS_Stopping,
  LAS_RequestSent,
  LAS_AckReceived,
  LAS_AckSent,
  LAS_Opened,
  /** Special non-RFC state required when the actions taken during a
   * transition are split-phase. */
  LAS_TRANSIENT = 0x0f
} LcpAutomatonState_e ;

/** Events that induce transitions among the states of the LCP
 * automaton. */
typedef enum LcpAutomatonEvent_e {
  LAE_Up,
  LAE_Down,
  LAE_Open,
  LAE_Close,
  LAE_Timeout,
  LAE_ReceiveConfigureRequest,
  LAE_ReceiveConfigureAck,
  LAE_ReceiveConfigureNakRej,
  LAE_ReceiveTerminateRequest,
  LAE_ReceiveTerminateAck,
  LAE_ReceveUnknownCode,
  LAE_ReceiveCodeProtocolReject,
  LAE_ReceiveEchoDiscardRequestReply,
} LcpAutomatonEvent_e ;

/** Options that control the behavior of the LCP automaton.
 * Generally, these have RFC-defined default values.  Check the
 * automaton source to determine whether these are actually used.  See
 * section 4.6 of RFC1661 for details. */
typedef struct LcpAutomatonOptions_t {
  uint32_t restartTimer_bms;
  uint16_t maxTerminate;
  uint16_t maxConfigure;
  uint16_t maxFailure;
  bool restartOption;
} LcpAutomatonOptions_t;

/** Structure holding parameters referenced by the LCP automaton when
 * processing a ConfigureRequest message. */
typedef struct LcpEventParams_rcr_t {
  /** The generic summary of the request: good (should be
   * acknowledged), or not (should be rejected or nak'd) */
  bool good;
  /** The specific disposition of the request: one of
   * PppControlProtocolCode_{ConfigureAck,ConfigureNak,ConfigureReject}. */
  uint8_t disposition;
  /** The start of the encoded block of options in the response
   * message. */
  const uint8_t* options;
  /** Just past the end of the encoded block of options. */
  const uint8_t* options_end;
  /** The key to be used when transmitting the message. */
  frame_key_t scx_key;
} LcpEventParams_rcr_t;

/** Structure holding parameters referenced by the LCP automaton when
 * processing a message that contains a sequence of options, such as a
 * Configure-Ack, Configure-Nak, or Configure-Reject message. */
typedef struct LcpEventParams_opts_t {
  /** The start of the encoded block of options that were accepted by
   * the remote. */
  const uint8_t* options;
  /** Just past the end of the encoded block of options. */
  const uint8_t* options_end;
  /** Code for the type of message that was received */
  uint8_t code;
} LcpEventParams_opts_t;

/** Structure holding parameters referenced by the LCP automaton when
 * processing a TerminateRequest or TerminateAck message */
typedef struct LcpEventParams_term_t {
  /** The start of the payload in the received message */
  const uint8_t* data;
  /** The end of the payload in the received message */
  const uint8_t* data_end;
  /** Code for the type of message that was received */
  uint8_t code;
  /** The key for a prepared Terminate-Ack message to be transmitted */
  frame_key_t sta_key;
} LcpEventParams_term_t;

#endif /* PPP_LCP_AUTOMATON_H */
