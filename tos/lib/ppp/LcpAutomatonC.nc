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

/** Configuration to manage the state associated with a PPP Link
 * Control Protocol automaton as defined in RFC1661.
 *
 * Note that there is generally instance of this automaton for each
 * control protocol: the LCP instance associated with the PppDaemonC
 * configuration has one, but so will every other network protocol
 * that leverages LCP's option negotiation sequence for configuration.
 * Which is most of the interesting ones.
 *
 * @param Protocol The protocol type encoded in PPP packets
 *
 * @param InhibitCompression If TRUE, any options like PCOMP and
 * ACCOMP that might result in non-default encodings are to be
 * inhibited for this protocol.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com> */
generic configuration LcpAutomatonC (uint16_t Protocol,
                                     bool InhibitCompression) {
  provides {
    interface LcpAutomaton;
    interface GetSetOptions<LcpAutomatonOptions_t> as LcpOptions;
  }
  uses {
    interface Ppp;
    interface PppConfigure;
    interface PppProtocolCodeSupport as ConfigureRequest;
    interface PppProtocolCodeSupport as TerminateAck;
  }
} implementation {
  components new LcpAutomatonP(Protocol, InhibitCompression);
  LcpAutomaton = LcpAutomatonP;
  LcpOptions = LcpAutomatonP;
  Ppp = LcpAutomatonP;
  PppConfigure = LcpAutomatonP;
  ConfigureRequest = LcpAutomatonP.ConfigureRequest;
  TerminateAck = LcpAutomatonP.TerminateAck;
  
  components MainC;
  MainC.SoftwareInit -> LcpAutomatonP;

  components new MuxAlarmMilli32C();
  LcpAutomatonP.RestartTimer -> MuxAlarmMilli32C;
}
