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

/** Implement the four messages used by the Link Control Protocol to
 * negotiate mutually acceptable options for a PPP session.
 *
 * @param Protocol_ the 16-bit protocol value
 *
 * @param InhibitCompression If true, this protocol requires that
 * optional frame compression be inhibited for its packets.
 *
 * @param NumOptions An upper bound on the number of options that will
 * be linked into this engine.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com> */
generic configuration PppConfigureEngineC (uint16_t Protocol,
                                           bool InhibitCompression,
                                           uint8_t NumOptions) {
  uses {
    interface Ppp;
    interface PppProtocolOption[ uint8_t type ];
    interface LcpAutomaton;
  }
  provides {
    interface PppConfigure;
    interface PppProtocolCodeSupport as ConfigureRequest;
    interface PppProtocolCodeSupport as ConfigureAck;
    interface PppProtocolCodeSupport as ConfigureNak;
    interface PppProtocolCodeSupport as ConfigureReject;
    interface PppProtocolCodeSupport as TerminateRequest;
    interface PppProtocolCodeSupport as TerminateAck;
  }
  enum {
    /** RFC 1661 section 5.1.  Data field contains a sequence of options. */
    Code_ConfigureRequest = PppControlProtocolCode_ConfigureRequest,
    /** RFC 1661 section 5.2.  Data field contains a sequence of options. */
    Code_ConfigureAck = PppControlProtocolCode_ConfigureAck,
    /** RFC 1661 section 5.3.  Data field contains a sequence of options. */
    Code_ConfigureNak = PppControlProtocolCode_ConfigureNak,
    /** RFC 1661 section 5.4.  Data field contains a sequence of options. */
    Code_ConfigureReject = PppControlProtocolCode_ConfigureReject,
    /** RFC 1661 section 5.5.  Data field contains a sequence of options. */
    Code_TerminateRequest = PppControlProtocolCode_TerminateRequest,
    /** RFC 1661 section 5.5.  Data field contains a sequence of options. */
    Code_TerminateAck = PppControlProtocolCode_TerminateAck,
  };
} implementation {
  components new PppConfigureEngineP(Protocol, InhibitCompression, NumOptions);
  Ppp = PppConfigureEngineP;
  PppProtocolOption = PppConfigureEngineP;
  LcpAutomaton = PppConfigureEngineP;
  PppConfigure = PppConfigureEngineP;
  ConfigureRequest = PppConfigureEngineP.ConfigureRequest;
  ConfigureAck = PppConfigureEngineP.ConfigureAck;
  ConfigureNak = PppConfigureEngineP.ConfigureNak;
  ConfigureReject = PppConfigureEngineP.ConfigureReject;
  TerminateRequest = PppConfigureEngineP.TerminateRequest;
  TerminateAck = PppConfigureEngineP.TerminateAck;

  components MainC;
  MainC.SoftwareInit -> PppConfigureEngineP;
}
