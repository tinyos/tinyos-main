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
#include "LcpAutomaton.h"

module LinkControlProtocolP {
  provides {
    interface PppProtocol;
    interface PppProtocolCodeSupport as ProtocolReject;
    interface PppProtocolOption as AddressControlFieldCompressionOption;
#if PPP_LCP_ENABLE_PCOMP
    interface PppProtocolOption as ProtocolFieldCompressionOption;
#endif /* PPP_LCP_ENABLE_PCOMP */
    interface PppProtocolOption as MaximumReceiveUnitOption;
    interface PppProtocolOption as AsyncControlCharacterMapOption;
  }
  uses {
    interface Ppp;
    interface PppProtocolCodeCoordinator;
    interface GetSetOptions<HdlcFramingOptions_t> as HdlcFramingOptions;
    interface GetSetOptions<PppOptions_t> as PppOptions;
    interface PppRejectedProtocol;
    interface LcpAutomaton;
  }
  enum {
    Protocol = PppProtocol_LinkControlProtocol,
  };
} implementation {
  
  /** Compressed booleans to identify those options for which
   * negotiation is permitted. */
  struct {
      uint8_t accomp:1;
      uint8_t pcomp:1;
      uint8_t mru:1;
      uint8_t accm:1;
  } isNegotiable = { accomp : TRUE,
                     pcomp : TRUE,
                     mru : TRUE,
                     accm : TRUE };

  event void Ppp.outputFrameTransmitted (frame_key_t key,
                                         error_t err) { }

  command unsigned int PppProtocol.getProtocol () { return Protocol; }

  command error_t PppProtocol.rejectedByPeer (const uint8_t* data,
                                              const uint8_t* data_end)
  {
    /* Not sure what to do about this, since the peer could only send
     * a Protocol-Reject message if it actually implemented the
     * Link-Control-Protocol. */
    return SUCCESS;
  }

  event void LcpAutomaton.transitionCompleted (LcpAutomatonState_e state) { }
  event void LcpAutomaton.thisLayerUp () { }
  event void LcpAutomaton.thisLayerDown () { }
  event void LcpAutomaton.thisLayerStarted () { }
  event void LcpAutomaton.thisLayerFinished () { }

  /* ============================== */
  /* AddressControlFieldCompression */

  /* ACCOMP is sent in a request to indicate that local can receive
   * frames without adddress and control fields.  Ack transmission
   * (remote) acknowledges permission to suppress ACF in transmitted
   * packets.  Ack reception (local) has no meaning, as we need to be
   * able to interpret packets with and without compression. */
  command uint8_t AddressControlFieldCompressionOption.getType () { return LCPOpt_AddressControlFieldCompression; }
  command bool AddressControlFieldCompressionOption.isNegotiable () { return isNegotiable.accomp; }
  command void AddressControlFieldCompressionOption.setNegotiable (bool is_negotiable) { isNegotiable.accomp = is_negotiable; }
  command uint8_t AddressControlFieldCompressionOption.considerRequest (const uint8_t* dp,
                                                                        const uint8_t* dpe)
  {
    return PppControlProtocolCode_ConfigureAck;
  }
  command uint8_t* AddressControlFieldCompressionOption.appendRequest (uint8_t* dp,
                                                                       const uint8_t* dpe)
  { return dp; }
  command uint8_t* AddressControlFieldCompressionOption.appendNakValue (const uint8_t* sp,
                                                                        const uint8_t* spe,
                                                                        uint8_t* dp,
                                                                        const uint8_t* dpe)
  { return dp; }
  command void AddressControlFieldCompressionOption.setRemote (const uint8_t* dp,
                                                                  const uint8_t* dpe)
  { 
    HdlcFramingOptions_t hdlcopt;
    /* We have accepted that the remote can receive frames with
     * address and control fields compressed.  Suppress them on
     * transmission. */
    hdlcopt = call HdlcFramingOptions.get();
    hdlcopt.txSuppressAddressControl = (0 != dp);
    call HdlcFramingOptions.set(&hdlcopt);
  }
  command void AddressControlFieldCompressionOption.setLocal (const uint8_t* dp,
                                                                 const uint8_t* dpe)
  {
    HdlcFramingOptions_t hdlcopt;
    /* The peer has accepted that we can receive frames with address
     * and control fields compressed.  Suppress them on reception. */
    hdlcopt = call HdlcFramingOptions.get();
    hdlcopt.rxSuppressAddressControl = (0 != dp);
    call HdlcFramingOptions.set(&hdlcopt);
  }
  command void AddressControlFieldCompressionOption.processNakValue (const uint8_t* dp,
                                                                     const uint8_t* dpe)
  {
    call AddressControlFieldCompressionOption.setNegotiable(FALSE);
  }
  command void AddressControlFieldCompressionOption.reset ()
  {
    call AddressControlFieldCompressionOption.setNegotiable(TRUE);
  }

#if PPP_LCP_ENABLE_PCOMP
  /* ======================== */
  /* ProtocolFieldCompression */

  /* PCOMP is sent in a request to indicate that local can receive
   * frames without adddress and control fields.  Ack transmission
   * (remote) acknowledges permission to compress protocols in
   * transmitted packets.  Ack reception (local) has no meaning, as we
   * need to be able to interpret packets with and without
   * compression. */
  command uint8_t ProtocolFieldCompressionOption.getType () { return LCPOpt_ProtocolFieldCompression; }
  command bool ProtocolFieldCompressionOption.isNegotiable () { return isNegotiable.pcomp; }
  command void ProtocolFieldCompressionOption.setNegotiable (bool is_negotiable) { isNegotiable.pcomp = is_negotiable; }
  command uint8_t ProtocolFieldCompressionOption.considerRequest (const uint8_t* dp,
                                                                        const uint8_t* dpe)
  {
    return PppControlProtocolCode_ConfigureAck;
  }
  command uint8_t* ProtocolFieldCompressionOption.appendRequest (uint8_t* dp,
                                                                       const uint8_t* dpe)
  { return dp; }
  command uint8_t* ProtocolFieldCompressionOption.appendNakValue (const uint8_t* sp,
                                                                  const uint8_t* spe,
                                                                  uint8_t* dp,
                                                                  const uint8_t* dpe)
  { return dp; }
  command void ProtocolFieldCompressionOption.setRemote (const uint8_t* dp,
                                                            const uint8_t* dpe)
  { 
    PppOptions_t opt;
    /* We have accepted that the remote can receive frames with the
     * protocol field compressed.  Compress it on transmission. */
    opt = call PppOptions.get();
    opt.txProtocolFieldCompression = (0 != dp);
    call PppOptions.set(&opt);
  }
  command void ProtocolFieldCompressionOption.setLocal (const uint8_t* dp,
                                                           const uint8_t* dpe)
  {
    PppOptions_t opt;
    /* The peer has accepted that we can receive frames with the
     * protocol field compressed.  Try reading them that way on
     * reception. */
    opt = call PppOptions.get();
    opt.rxProtocolFieldCompression = (0 != dp);
    call PppOptions.set(&opt);
  }
  command void ProtocolFieldCompressionOption.processNakValue (const uint8_t* dp,
                                                               const uint8_t* dpe)
  {
    call ProtocolFieldCompressionOption.setNegotiable(FALSE);
  }
  command void ProtocolFieldCompressionOption.reset ()
  {
    call ProtocolFieldCompressionOption.setNegotiable(TRUE);
  }
#endif /* PPP_LCP_ENABLE_PCOMP */

  /* ================== */
  /* MaximumReceiveUnit */

  enum {
    PPP_DefaultMRU = 1500,
  };
  uint16_t proposedMRU_ = PPP_PREFERRED_MRU;

  /* MRU is sent in a request to indicate that local can receive
   * frames with information fields that exceed the PPP default, or to
   * request that the remote transmit shorter frames.  Ack
   * transmission (remote) indicates a promise to transmit no more
   * than the MRU in each frame.  Ack reception (local) indicates we
   * might not receive messages larger than the MRU. */
  command uint8_t MaximumReceiveUnitOption.getType () { return LCPOpt_MaximumReceiveUnit; }
  command bool MaximumReceiveUnitOption.isNegotiable ()
  {
    PppOptions_t opt = call PppOptions.get();
    return isNegotiable.mru && (PPP_DefaultMRU != opt.rxMaximumReceiveUnit);
  }
  command void MaximumReceiveUnitOption.setNegotiable (bool is_negotiable) { isNegotiable.mru = is_negotiable; }
  command uint8_t MaximumReceiveUnitOption.considerRequest (const uint8_t* dp,
                                                            const uint8_t* dpe)
  {
    /* Although we may not be able to support the default MRU on
     * reception, there's no facility to force the remote to negotiate
     * the MRU option.  Best we can do is, if they sent it, make sure
     * it's acceptable: i.e., doesn't exceed the maximum, or is what
     * we proposed. */
    uint16_t tx_mru = (dp[0] << 8) | dp[1];
    if ((tx_mru > PPP_MAXIMUM_MRU) && (proposedMRU_ != tx_mru)) {
      return PppControlProtocolCode_ConfigureNak;
    }
    return PppControlProtocolCode_ConfigureAck;
  }
  command uint8_t* MaximumReceiveUnitOption.appendRequest (uint8_t* dp,
                                                           const uint8_t* dpe)
  {
    if (dpe < (dp+2)) {
      return 0;
    }
    *dp++ = (proposedMRU_ >> 8);
    *dp++ = (proposedMRU_ & 0x0FF);
    return dp;
  }
  command uint8_t* MaximumReceiveUnitOption.appendNakValue (const uint8_t* sp,
                                                            const uint8_t* spe,
                                                            uint8_t* dp,
                                                            const uint8_t* dpe)
  {
    if (dpe < (dp+2)) {
      return 0;
    }
    *dp++ = (PPP_PREFERRED_MRU >> 8);
    *dp++ = (PPP_PREFERRED_MRU & 0x0FF);
    return dp;
  }
  command void MaximumReceiveUnitOption.setRemote (const uint8_t* dp,
                                                      const uint8_t* dpe)
  { 
    PppOptions_t opt;
    uint16_t value;

    /* We have accepted the size requested by the remote.  Limit
     * transmissions to that size. */
    opt = call PppOptions.get();
    if (dp) {
      value = (dp[0] << 8) | dp[1];
    } else {
      value = PPP_PREFERRED_MRU;
    }
    opt.txMaximumReceiveUnit = value;
    call PppOptions.set(&opt);
  }
  command void MaximumReceiveUnitOption.setLocal (const uint8_t* dp,
                                                     const uint8_t* dpe)
  {
    PppOptions_t opt;
    uint16_t value;

    /* The peer has accepted our preferred size.  Configure receptions
     * to expect it. */
    opt = call PppOptions.get();
    if (dp) {
      value = (dp[0] << 8) | dp[1];
    } else {
      value = PPP_PREFERRED_MRU;
    }
    opt.rxMaximumReceiveUnit = value;
    call PppOptions.set(&opt);
  }
  command void MaximumReceiveUnitOption.processNakValue (const uint8_t* dp,
                                                         const uint8_t* dpe)
  {
    proposedMRU_ = (dp[0] << 8) | dp[1];
  }
  command void MaximumReceiveUnitOption.reset ()
  {
    call MaximumReceiveUnitOption.setNegotiable(TRUE);
    proposedMRU_ = PPP_PREFERRED_MRU;
  }

  /* ================== */
  /* AsyncControlCharacterMap */

  enum {
    HDLC_DefaultACCM = ~0UL,
    HDLC_PreferredACCM = 0UL,
  };
  uint32_t proposedACCM_;

  /* ACCM is sent in a request to indicate that local does not require
   * certain control characters to be mapped for transparency.  Ack
   * transmission (remote) indicates a promise to escape the characters
   * specified in the ACCM.  Ack reception (local) indicates that we
   * can expect the characters not marked in the map to be received
   * unescaped.
   *
   * Local is reset prior to SCR.  On local reset, restore both rxSCCM
   * and txSCCM to defaults.
   *
   * Local is set on CA reception.  On local set, set rxACCM.
   *
   * Remote is set after CA transmission.  On remote set, set txACCM.
   *
   * When is remote reset?
   */
  command uint8_t AsyncControlCharacterMapOption.getType () { return LCPOpt_AsyncControlCharacterMap; }
  command bool AsyncControlCharacterMapOption.isNegotiable ()
  {
    return isNegotiable.accm;
  }
  command void AsyncControlCharacterMapOption.setNegotiable (bool is_negotiable) { isNegotiable.accm = is_negotiable; }
  command uint8_t AsyncControlCharacterMapOption.considerRequest (const uint8_t* dp,
                                                                  const uint8_t* dpe)
  {
    return PppControlProtocolCode_ConfigureAck;
  }
  command uint8_t* AsyncControlCharacterMapOption.appendRequest (uint8_t* dp,
                                                           const uint8_t* dpe)
  {
    nx_uint32_t* np = (nx_uint32_t*)dp;
    if (dpe < (dp+1)) {
      return 0;
    }
    *np = proposedACCM_;
    return (uint8_t*)(np+1);
  }
  command uint8_t* AsyncControlCharacterMapOption.appendNakValue (const uint8_t* sp,
                                                                  const uint8_t* spe,
                                                                  uint8_t* dp,
                                                                  const uint8_t* dpe)
  {
    nx_uint32_t* np = (nx_uint32_t*)dp;
    if (dpe < (dp+1)) {
      return 0;
    }
    *np = HDLC_PreferredACCM;
    return (uint8_t*)(np+1);
  }
  command void AsyncControlCharacterMapOption.setRemote (const uint8_t* dp,
                                                         const uint8_t* dpe)
  { 
    HdlcFramingOptions_t opt;
    uint32_t value;

    /* We have accepted the map requested by the remote.  Perform
     * transparency operations on characters in that map. */
    opt = call HdlcFramingOptions.get();
    if (dp) {
      value = *(nx_uint32_t*)dp;
    } else {
      value = HDLC_DefaultACCM;
    }
    opt.txAsyncControlCharacterMap = value;
    call HdlcFramingOptions.set(&opt);
  }
  command void AsyncControlCharacterMapOption.setLocal (const uint8_t* dp,
                                                        const uint8_t* dpe)
  {
    HdlcFramingOptions_t opt;
    uint32_t value;

    /* The peer has accepted our proposed map.  This has no effect on
     * our behavior. */
    opt = call HdlcFramingOptions.get();
    if (dp) {
      value = *(nx_uint32_t*)dp;
    } else {
      value = HDLC_DefaultACCM;
    }
    opt.rxAsyncControlCharacterMap = value;
    call HdlcFramingOptions.set(&opt);
  }
  command void AsyncControlCharacterMapOption.processNakValue (const uint8_t* dp,
                                                               const uint8_t* dpe)
  {
    proposedACCM_ = *(nx_uint32_t*)dp;
  }
  command void AsyncControlCharacterMapOption.reset ()
  {
    call AsyncControlCharacterMapOption.setNegotiable(TRUE);
    proposedACCM_ = HDLC_PreferredACCM;
  }

  /* ======================================== */

  command uint8_t ProtocolReject.getCode () { return PppControlProtocolCode_ProtocolReject; }
  command error_t ProtocolReject.process (uint8_t identifier,
                                          const uint8_t* data,
                                          const uint8_t* data_end)
  {
    uint16_t protocol = 0;
    protocol = (data[0] << 8) + data[1];
    return call PppRejectedProtocol.rejected(protocol, data, data_end);
  }

  /** Invoke some code-specific operation */
  command error_t ProtocolReject.invoke (void* param_,
                                         frame_key_t* keyp)
  {
    error_t rc = EINVAL;
    protocolReject_param_t* param = (protocolReject_param_t*)param_;

    if (LAS_Opened == call LcpAutomaton.getState()) {
      /* Due to implementation choice, we can't reject a protocol value
       * of zero, which is fine since that's an illegal protocol value.
       * Just drop those on the floor. */
      if (0 != param->protocol) {
        rc = call PppProtocolCodeCoordinator.rejectPacket(param->protocol, param->information, param->information + param->information_length, keyp);
      }
    }
    return rc;
  }

  command error_t PppProtocol.process (const uint8_t* information,
                                       unsigned int information_length)
  {
    return call PppProtocolCodeCoordinator.dispatch(information, information_length);
  }

}
