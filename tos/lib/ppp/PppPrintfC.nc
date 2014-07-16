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
#include "PppPrintf.h"

/** Support printf(3) within applications that use PPP.
 *
 * printf is too useful as a debugging capability to be lost simply
 * because the serial interface is shuttling packets back and forth.
 * Wiring this protocol allows console output to be passed to the peer
 * in a special protocol message, where it can be displayed.
 *
 * Applications that do this should use the following wiring:
 
  components PppPrintfC;
  PppC.PppProtocol[PppPrintfC.Protocol] -> PppPrintfC;
  PppPrintfC.Ppp -> PppC;

 * where PppC is alternatively PppDaemonC.  Simply using this
 * component without wiring in its protocol will work, in that the
 * messages will be sent to the peer, but standard PPP implementations
 * that do not recognize the TinyOS-specific PPP protocol will send a
 * Protocol-Reject message, which the TinyOS PPP implementation will be
 * unable to process.  Wiring in the protocol allows TinyOS PPP to
 * disable it when the peer is unable to process the messages,
 * avoiding log clutter.
 *
 * A variant PPP implementation that recognizes TinyOS packets can be
 * obtained by reading the instructions in the patch file in
 * ${TINYOS_OS_DIR}/lib/ppp/tos-pppd.patch.
 *
 * @note For cross-platform compatibility, this module uses the PutcharP
 * component from ${TINYOS_OS_DIR}/lib/printf.  That directory must be in
 * your component search path.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
configuration PppPrintfC {
  provides {
    interface PppProtocol;
  }
  uses {
    interface Ppp;
  }
  enum {
    Protocol = PppProtocol_Printf,
  };
} implementation {
  components PppPrintfP;

  PppProtocol = PppPrintfP;
  Ppp = PppPrintfP;

  components PutcharC;
  PutcharC.Putchar -> PppPrintfP;
}
