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

module PppIpv6P {
  provides {
    interface Init;
    interface PppIpv6;
    interface PppProtocol as PppControlProtocol;
    interface PppProtocolOption as InterfaceIdentifierOption;
    interface PppProtocol;
  }
  uses {
    interface Ppp;
    interface PppConfigure;
    interface PppProtocolCodeCoordinator;
    interface LcpAutomaton;
    interface LcpAutomaton as LowerLcpAutomaton;
  }
} implementation {
  enum {
    ControlProtocol = PppProtocol_Ipv6Cp,
    Protocol = PppProtocol_Ipv6,
  };

  /* ============================== */
  /* InterfaceIdentifier */

  bool negotiateIID_ = TRUE;
  bool linkIsUp_;
  ppp_ipv6cp_iid_t localIID_;
  ppp_ipv6cp_iid_t proposedLocalIID_;
  ppp_ipv6cp_iid_t remoteIID_;
  
  command const ppp_ipv6cp_iid_t* PppIpv6.localIid ()
  {
    return linkIsUp_ ? &localIID_ : 0;
  }

  command const ppp_ipv6cp_iid_t* PppIpv6.remoteIid ()
  {
    return linkIsUp_ ? &remoteIID_ : 0;
  }

  command bool PppIpv6.linkIsUp () { return linkIsUp_; }
  default event void PppIpv6.linkUp () { }
  default event void PppIpv6.linkDown () { }

  command error_t Init.init ()
  {
    return SUCCESS;
  }

  /* Interface-Identifier is sent in a request to indicate the IID
   * that the sender wishes to use for its link-local IPv6 address.
   * Transmission of a value of zero indicates a request that the peer
   * provide a preferred IID via a Configure-Nak response. */
  command uint8_t InterfaceIdentifierOption.getType () { return Ipv6CpOpt_InterfaceIdentifier; }
  command bool InterfaceIdentifierOption.isNegotiable () { return negotiateIID_; }
  command void InterfaceIdentifierOption.setNegotiable (bool is_negotiable) { negotiateIID_ = is_negotiable; }
  command uint8_t InterfaceIdentifierOption.considerRequest (const uint8_t* dp,
                                                             const uint8_t* dpe)
  {
    return PppControlProtocolCode_ConfigureAck;
  }
  command uint8_t* InterfaceIdentifierOption.appendRequest (uint8_t* dp,
                                                            const uint8_t* dpe)
  {
    if (dpe < (dp+sizeof(proposedLocalIID_))) {
      return 0;
    }
    memcpy(dp, &proposedLocalIID_, sizeof(proposedLocalIID_));
    dp += sizeof(proposedLocalIID_);
    return dp;
  }
  command uint8_t* InterfaceIdentifierOption.appendNakValue (const uint8_t* sp,
                                                             const uint8_t* spe,
                                                             uint8_t* dp,
                                                             const uint8_t* dpe)
  { return dp; }
  command void InterfaceIdentifierOption.setRemote (const uint8_t* dp,
                                                    const uint8_t* dpe)
  { 
    memcpy(&remoteIID_, dp, sizeof(remoteIID_));
  }
  command void InterfaceIdentifierOption.setLocal (const uint8_t* dp,
                                                   const uint8_t* dpe)
  {
    if (dp) {
      memcpy(&localIID_, dp, sizeof(localIID_));
    } else {
      memset(&localIID_, 0, sizeof(localIID_));
    }
  }
  command void InterfaceIdentifierOption.processNakValue (const uint8_t* dp,
                                                          const uint8_t* dpe)
  {
    memcpy(&proposedLocalIID_, dp, sizeof(proposedLocalIID_));
  }
  command void InterfaceIdentifierOption.reset ()
  {
    call InterfaceIdentifierOption.setNegotiable(TRUE);
    memset(&proposedLocalIID_, 0, sizeof(proposedLocalIID_));
  }
  

  event void Ppp.outputFrameTransmitted (frame_key_t key,
                                         error_t err) { }

  command unsigned int PppControlProtocol.getProtocol () { return ControlProtocol; }

  command unsigned int PppProtocol.getProtocol () { return Protocol; }

  command error_t PppControlProtocol.process (const uint8_t* information,
                                              unsigned int information_length)

  {
    return call PppProtocolCodeCoordinator.dispatch(information, information_length);
  }

  command error_t PppProtocol.process (const uint8_t* information,
                                       unsigned int information_length)
  {
    return signal PppIpv6.receive(information, information_length);
  }

  command error_t PppProtocol.rejectedByPeer (const uint8_t* data,
                                              const uint8_t* data_end)
  {
    /* Not sure what to do about this, since the peer could only send
     * a Protocol-Reject message if it actually implemented the
     * Link-Control-Protocol. */
    return SUCCESS;
  }
  command error_t PppControlProtocol.rejectedByPeer (const uint8_t* data,
                                              const uint8_t* data_end)
  {
    /* Not sure what to do about this, since the peer could only send
     * a Protocol-Reject message if it actually implemented the
     * Link-Control-Protocol. */
    return SUCCESS;
  }

  event void LcpAutomaton.transitionCompleted (LcpAutomatonState_e state) { }
  event void LcpAutomaton.thisLayerUp ()
  {
    linkIsUp_ = TRUE;
    signal PppIpv6.linkUp();
  }
  event void LcpAutomaton.thisLayerDown ()
  {
    linkIsUp_ = FALSE;
    signal PppIpv6.linkDown();
  }
  event void LcpAutomaton.thisLayerStarted () { }
  event void LcpAutomaton.thisLayerFinished () { }

  event void LowerLcpAutomaton.transitionCompleted (LcpAutomatonState_e state) { }
  event void LowerLcpAutomaton.thisLayerUp ()
  {
    call LcpAutomaton.up();
  }
  event void LowerLcpAutomaton.thisLayerDown ()
  {
    call LcpAutomaton.down();
    call PppConfigure.resetOptions();
  }
  event void LowerLcpAutomaton.thisLayerStarted () { }
  event void LowerLcpAutomaton.thisLayerFinished () { }
  
  command error_t PppIpv6.transmit (const uint8_t* message,
                                    unsigned int len)
  {
    error_t rc;
    frame_key_t key;
    const uint8_t* fpe;
    uint8_t* fp = call Ppp.getOutputFrame(PppProtocol_Ipv6, &fpe, FALSE, &key);

    if ((! fp) || ((fpe - fp) < len)) {
      if (fp) {
	call Ppp.releaseOutputFrame(key);
      }
      return ENOMEM;
    }
    memcpy(fp, message, len);
    rc = call Ppp.fixOutputFrameLength(key, fp + len);
    if (SUCCESS == rc) {
      rc = call Ppp.sendOutputFrame(key);
    }
    return rc;
  }

}
