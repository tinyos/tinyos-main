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
#include "pppipv6.h"

/** TinyOS PPP Network Control Protocol for IPv6 per RFC5072.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
configuration PppIpv6C {
  provides {
    interface PppIpv6;
    interface PppProtocol as PppControlProtocol;
    interface PppProtocol;
    interface LcpAutomaton;
  }
  uses {
    interface Ppp;
    interface LcpAutomaton as LowerLcpAutomaton;
  }
  enum {
    ControlProtocol = PppProtocol_Ipv6Cp,
    Protocol = PppProtocol_Ipv6,
  };
} implementation {

  components PppIpv6P as ProtocolC;
  PppIpv6 = ProtocolC.PppIpv6;
  PppControlProtocol = ProtocolC.PppControlProtocol;
  PppProtocol = ProtocolC.PppProtocol;
  LowerLcpAutomaton = ProtocolC.LowerLcpAutomaton;

  components MainC;
  MainC.SoftwareInit -> ProtocolC;

  /* The configuration engine allows compression, and supports one option */
  components new PppConfigureEngineC(ControlProtocol, FALSE, 1);
  PppConfigureEngineC.PppProtocolOption[Ipv6CpOpt_InterfaceIdentifier] -> ProtocolC.InterfaceIdentifierOption;
  ProtocolC.PppConfigure -> PppConfigureEngineC;

  /* Allocate a coordinator and link in the supported codes */
  components new PppProtocolCodeCoordinatorC(ControlProtocol) as CoordinatorC;
  ProtocolC.PppProtocolCodeCoordinator -> CoordinatorC;
  CoordinatorC.CodeHandler[PppConfigureEngineC.Code_ConfigureRequest] -> PppConfigureEngineC.ConfigureRequest;
  CoordinatorC.CodeHandler[PppConfigureEngineC.Code_ConfigureAck] -> PppConfigureEngineC.ConfigureAck;
  CoordinatorC.CodeHandler[PppConfigureEngineC.Code_ConfigureNak] -> PppConfigureEngineC.ConfigureNak;
  CoordinatorC.CodeHandler[PppConfigureEngineC.Code_ConfigureReject] -> PppConfigureEngineC.ConfigureReject;
  CoordinatorC.CodeHandler[PppConfigureEngineC.Code_TerminateRequest] -> PppConfigureEngineC.TerminateRequest;
  CoordinatorC.CodeHandler[PppConfigureEngineC.Code_TerminateAck] -> PppConfigureEngineC.TerminateAck;

  /* Hook in the LCP automaton. */
  components new LcpAutomatonC(ControlProtocol, FALSE);
  LcpAutomaton = LcpAutomatonC;
  PppConfigureEngineC.LcpAutomaton -> LcpAutomatonC;
  LcpAutomatonC.ConfigureRequest -> PppConfigureEngineC.ConfigureRequest;
  LcpAutomatonC.TerminateAck -> PppConfigureEngineC.TerminateAck;
  LcpAutomatonC.PppConfigure -> PppConfigureEngineC;
  ProtocolC.LcpAutomaton -> LcpAutomatonC;

  /* Whatever provides Ppp needs to go to all these components */
  Ppp = ProtocolC;
  Ppp = CoordinatorC;
  Ppp = PppConfigureEngineC;
  Ppp = LcpAutomatonC;
}
