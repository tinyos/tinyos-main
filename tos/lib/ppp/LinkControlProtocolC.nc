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
#include "lcp.h"
#include "HdlcFraming.h"

/** The component that supports the Link Control Protocol of RFC1661.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
configuration LinkControlProtocolC {
  provides {
    interface PppProtocol;
    interface LcpAutomaton;
    interface PppProtocolCodeSupport as ProtocolReject;
    interface PppProtocolCodeSupport as ConfigureRequest;
  }
  uses {
    interface Ppp;
    interface PppRejectedProtocol;
    interface GetSetOptions<HdlcFramingOptions_t> as HdlcFramingOptions;
    interface GetSetOptions<PppOptions_t> as PppOptions;
  }
  enum {
    /** Publish the protocol number to which this component should be
     * wired in the PppC component */
    Protocol = PppProtocol_LinkControlProtocol,
  };

} implementation {
  components LinkControlProtocolP as ProtocolC;
  PppProtocol = ProtocolC;
  ProtocolReject = ProtocolC;
  PppRejectedProtocol = ProtocolC;
  HdlcFramingOptions = ProtocolC;
  PppOptions = ProtocolC;

  /* LCP inhibits compression, and has four supported options */
  components new PppConfigureEngineC(Protocol, TRUE, 4) as PppConfigureEngineC;
  ConfigureRequest = PppConfigureEngineC.ConfigureRequest;
  PppConfigureEngineC.PppProtocolOption[LCPOpt_AddressControlFieldCompression] -> ProtocolC.AddressControlFieldCompressionOption;
#if PPP_LCP_ENABLE_PCOMP
  PppConfigureEngineC.PppProtocolOption[LCPOpt_ProtocolFieldCompression] -> ProtocolC.ProtocolFieldCompressionOption;
#endif /* PPP_LCP_ENABLE_PCOMP */
  PppConfigureEngineC.PppProtocolOption[LCPOpt_MaximumReceiveUnit] -> ProtocolC.MaximumReceiveUnitOption;
  PppConfigureEngineC.PppProtocolOption[LCPOpt_AsyncControlCharacterMap] -> ProtocolC.AsyncControlCharacterMapOption;

  /* Allocate a coordinator, and link in the supported codes */
  components new PppProtocolCodeCoordinatorC(Protocol) as CoordinatorC;
  ProtocolC.PppProtocolCodeCoordinator -> CoordinatorC;
  CoordinatorC.CodeHandler[PppConfigureEngineC.Code_ConfigureRequest] -> PppConfigureEngineC.ConfigureRequest;
  CoordinatorC.CodeHandler[PppConfigureEngineC.Code_ConfigureAck] -> PppConfigureEngineC.ConfigureAck;
  CoordinatorC.CodeHandler[PppConfigureEngineC.Code_ConfigureNak] -> PppConfigureEngineC.ConfigureNak;
  CoordinatorC.CodeHandler[PppConfigureEngineC.Code_ConfigureReject] -> PppConfigureEngineC.ConfigureReject;
  CoordinatorC.CodeHandler[PppConfigureEngineC.Code_TerminateRequest] -> PppConfigureEngineC.TerminateRequest;
  CoordinatorC.CodeHandler[PppConfigureEngineC.Code_TerminateAck] -> PppConfigureEngineC.TerminateAck;
  CoordinatorC.CodeHandler[PppControlProtocolCode_ProtocolReject] -> ProtocolC.ProtocolReject;

  /* Hook in the LCP automaton.  Inhibit protocol compression. */
  components new LcpAutomatonC(Protocol, TRUE);
  ProtocolC.LcpAutomaton -> LcpAutomatonC;
  PppConfigureEngineC.LcpAutomaton -> LcpAutomatonC;
  LcpAutomatonC.ConfigureRequest -> PppConfigureEngineC.ConfigureRequest;
  LcpAutomatonC.TerminateAck -> PppConfigureEngineC.TerminateAck;
  LcpAutomatonC.PppConfigure -> PppConfigureEngineC;
  LcpAutomaton = LcpAutomatonC;
        
  /* Whatever provides Ppp needs to go to all these components */
  Ppp = ProtocolC;
  Ppp = CoordinatorC;
  Ppp = PppConfigureEngineC;
  Ppp = LcpAutomatonC;
}
