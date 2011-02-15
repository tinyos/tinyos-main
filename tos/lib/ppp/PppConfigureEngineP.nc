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

generic module PppConfigureEngineP (uint16_t Protocol,
                                    bool InhibitCompression,
                                    uint8_t NumOptions) {
  uses {
    interface Ppp;
    interface PppProtocolOption[ uint8_t type ];
    interface LcpAutomaton;
  }
  provides {
    interface Init;
    interface PppConfigure;
    interface PppProtocolCodeSupport as ConfigureRequest;
    interface PppProtocolCodeSupport as ConfigureAck;
    interface PppProtocolCodeSupport as ConfigureNak;
    interface PppProtocolCodeSupport as ConfigureReject;
    interface PppProtocolCodeSupport as TerminateRequest;
    interface PppProtocolCodeSupport as TerminateAck;
  }
} implementation {
  
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

  event void Ppp.outputFrameTransmitted (frame_key_t key,
                                         error_t err) { }

  event void LcpAutomaton.transitionCompleted (LcpAutomatonState_e state) { }
  event void LcpAutomaton.thisLayerUp () { }
  event void LcpAutomaton.thisLayerDown () { }
  event void LcpAutomaton.thisLayerStarted () { }
  event void LcpAutomaton.thisLayerFinished ()
  {
    call PppConfigure.resetOptions();
  }

  /** List of linked option types, as determined on startup.  Reserve
   * one space for 0 which marks end of list. */
  uint8_t optionTypes_[NumOptions+1];

  command error_t Init.init ()
  {
    uint8_t* otp = optionTypes_;
    uint8_t* otpe = otp + sizeof(optionTypes_) / sizeof(*otp) - 1;
    uint8_t type = 0;

    while ((0 != ++type) && (otp < otpe)) {
      if (0 != call PppProtocolOption.getType[type]()) {
        *otp++ = type;
      }
    }
    *otp = 0;
    return SUCCESS;
  }

  void setOptions (const uint8_t* sp,
                   const uint8_t* spe,
                   uint8_t code,
                   bool use_local)
  {
    //printf("OPTIONS %s %s\r\n", (sp ? "set" : "reset"), (use_local ? "local" : "remote"));
    if (! sp) {
      uint8_t* otp = optionTypes_;
      while (*otp) {
        uint8_t type = *otp++;
        if (use_local) {
          call PppProtocolOption.setLocal[type](0, 0);
        } else {
          call PppProtocolOption.setRemote[type](0, 0);
        }
      }
    } else {
      while ((sp+2) <= spe) {
        uint8_t type = *sp++;
        uint8_t length = *sp++ - 2; /* Subtract to account for type and length */
        if (0 == call PppProtocolOption.getType[type]()) {
          /* This shouldn't happen: the options should have been
           * validated. */
        } else {
          if (use_local) {
            switch (code) {
              case Code_ConfigureAck:
                (void)call PppProtocolOption.setLocal[type](sp, sp + length);
                break;
              case Code_ConfigureNak:
                (void)call PppProtocolOption.processNakValue[type](sp, sp + length);
                break;
              case Code_ConfigureReject:
                (void)call PppProtocolOption.setNegotiable[type](FALSE);
                break;
              default:
                break;
            }
          } else {
            (void)call PppProtocolOption.setRemote[type](sp, sp + length);
          }
          //printf("OPT %d set %d len %u rc %d\r\n", type, use_local, length, rc);
        }
        sp += length;
      }
    }
  }

  command void PppConfigure.resetOptions ()
  {
    uint8_t* otp = optionTypes_;
    while (*otp) {
      uint8_t type = *otp++;
      call PppProtocolOption.reset[type]();
    }
  }

  command void PppConfigure.setLocalOptions (uint8_t code,
                                             const uint8_t* dp,
                                             const uint8_t* dpe)
  {
    setOptions(dp, dpe, code, TRUE);
  }

  command void PppConfigure.setRemoteOptions (const uint8_t* dp,
                                              const uint8_t* dpe)
  {
    setOptions(dp, dpe, Code_ConfigureAck, FALSE);
  }

  error_t completeInvoke_ (frame_key_t key,
                           const uint8_t* frame_end,
                           frame_key_t* keyp)
  {
    error_t rc = call Ppp.fixOutputFrameLength(key, frame_end);
    if (SUCCESS == rc) {
      rc = call Ppp.sendOutputFrame(key);
    }
    if (SUCCESS != rc) {
      (void) call Ppp.releaseOutputFrame(key);
    } else {
      if (keyp) {
        *keyp = key;
      }
    }
    return rc;
  }

  uint8_t idConfigureRequest;

  command uint8_t ConfigureRequest.getCode () { return Code_ConfigureRequest; }

  command error_t ConfigureRequest.invoke (void* param,
                                           frame_key_t* keyp)
  {
    const uint8_t* fpe;
    frame_key_t key;
    uint8_t* fp = call Ppp.getOutputFrame(Protocol, &fpe, InhibitCompression, &key);
    const uint8_t* frame_start = fp;
    uint8_t* flp;
    uint8_t type = 1;
    uint8_t* otp = optionTypes_;

    if (0 == fp) {
      return EBUSY;
    }
    *fp++ = Code_ConfigureRequest;
    *fp++ = ++idConfigureRequest;
    flp = fp;
    fp += 2;

    /* Walk all the types in order */
    while (*otp) {
      type = *otp++;
      if (call PppProtocolOption.isNegotiable[type]()) {
        uint8_t* ofp = fp;
        uint8_t* lfp;
        /* Store the option type, reserve space for then length,
         * then store the proposed value.  If something goes wrong,
         * drop the option, otherwise record the length and move
         * on. */
        *fp++ = type;
        lfp = fp++;
        fp = call PppProtocolOption.appendRequest[type](fp, fpe);
        if (0 == fp) {
          fp = ofp;
        } else {
          *lfp = (fp - ofp);
        }
      }
    }
    {
      uint16_t frame_len = (fp - frame_start);
      *flp++ = (frame_len >> 8);
      *flp++ = (frame_len & 0x0FF);
    }
    return completeInvoke_(key, fp, keyp);
  }

  command error_t ConfigureRequest.process (uint8_t identifier,
                                            const uint8_t* sp,
                                            const uint8_t* spe)
  {
    error_t rc;
    uint8_t overall_disposition = Code_ConfigureRequest; // initial value forces reset in loop
    const uint8_t* fpe;
    frame_key_t key;
    uint8_t* fp = call Ppp.getOutputFrame(Protocol, &fpe, InhibitCompression, &key);
    uint8_t* dp = 0;
    LcpEventParams_rcr_t evt_params;

    if (0 == fp) {
      return EBUSY;
    }
    rc = SUCCESS;
    while ((SUCCESS == rc) && ((sp+2) <= spe)) {
      uint8_t type = *sp++;
      uint8_t length = *sp++ - 2; /* Subtract to account for type and length */
      uint8_t disposition;

      if (0 == call PppProtocolOption.getType[type]()) {
        disposition = Code_ConfigureReject;
      } else {
        disposition = call PppProtocolOption.considerRequest[type](sp, sp + length);
      }
      /* If we've downgraded to a new disposition, reset the pointers
       * to start constructing a new message. */
      if (disposition > overall_disposition) {
        evt_params.options = dp = fp + 4;            /* Offset by code, identifier, and length (to be written before transmission) */
        overall_disposition = disposition;
      }
      /* If the disposition of the option matches the disposition of
       * the message we're building, tack the option value onto the
       * message. */
      if (disposition == overall_disposition) {
        if (fpe < (dp+2)) {
          rc = ENOMEM;
        } else {
          /* @TODO@ Verify there is enough room to store the option */
          *dp++ = type;
          if (Code_ConfigureNak == disposition) {
            uint8_t* lp = dp++;
            /* Paste on the proposed alternative. */
            dp = call PppProtocolOption.appendNakValue[type](sp, sp + length, dp, fpe);
            if (0 == dp) {
              /* @TODO@ Now what?  This might occur if there is a
               * proposed alternative option, but the outgoing frame
               * doesn't have room to hold it.  Couldn't have checked
               * above, because we didn't know the option length. */
              rc = ENOMEM;
            }
            /* Length is type byte plus distance from length field to end of option */
            *lp = (dp - lp) + 1;
          } else {
            /* Copy from the incoming message */
            *dp++ = length + 2;     /* Add to account for type and length */
            if (fpe < (dp + length)) {
              rc = ENOMEM;
            } else {
              memmove(dp, sp, length);
              dp += length;
            }
          }
        }
      }
      sp += length;
    }

    if (SUCCESS == rc) {
      unsigned int frame_len = dp - fp;
      *fp++ = overall_disposition;
      *fp++ = identifier;
      *fp++ = (frame_len >> 8);
      *fp++ = (frame_len & 0x0ff);

      rc = call Ppp.fixOutputFrameLength(key, dp);
    }
    if (SUCCESS == rc) {
      evt_params.good = (Code_ConfigureAck == overall_disposition);
      evt_params.disposition = overall_disposition;
      evt_params.options_end = dp;
      evt_params.scx_key = key;

      /* Signal the event.  If the automaton is busy, release the output
       * frame and try again later.  For success and all other errors,
       * the automaton is responsible for releasing the frame */
      rc = call LcpAutomaton.signalEvent(LAE_ReceiveConfigureRequest, &evt_params);
      if (ERETRY == rc) {
        call Ppp.releaseOutputFrame(key);
      }
    } else {
      (void) call Ppp.releaseOutputFrame(key);
    }
    return rc;
  }
  
  command uint8_t ConfigureAck.getCode () { return Code_ConfigureAck; }
  command error_t ConfigureAck.process (uint8_t identifier,
                                        const uint8_t* data,
                                        const uint8_t* data_end)
  {
    LcpEventParams_opts_t evt_params;
    /* Silently drop responses to outdated requests */
    if (idConfigureRequest != identifier) {
      return SUCCESS;
    }
    evt_params.code = Code_ConfigureAck;
    evt_params.options = data;
    evt_params.options_end = data_end;
    return call LcpAutomaton.signalEvent(LAE_ReceiveConfigureAck, &evt_params);
  }

  command error_t ConfigureAck.invoke (void* param, frame_key_t* keyp) { return FAIL; }
  
  error_t processNakReject (uint8_t code,
                            uint8_t identifier,
                            const uint8_t* data,
                            const uint8_t* data_end)
  {
    LcpEventParams_opts_t evt_params;
    /* Silently drop responses to outdated requests */
    if (idConfigureRequest != identifier) {
      return SUCCESS;
    }
    evt_params.code = code;
    evt_params.options = data;
    evt_params.options_end = data_end;
    return call LcpAutomaton.signalEvent(LAE_ReceiveConfigureNakRej, &evt_params);
  }    

  command uint8_t ConfigureNak.getCode () { return Code_ConfigureNak; }
  command error_t ConfigureNak.process (uint8_t identifier,
                                        const uint8_t* data,
                                        const uint8_t* data_end)
  {
    return processNakReject(Code_ConfigureNak, identifier, data, data_end);
  }
  command error_t ConfigureNak.invoke (void* param, frame_key_t* keyp) { return FAIL; }
  
  command uint8_t ConfigureReject.getCode () { return Code_ConfigureReject; }
  command error_t ConfigureReject.process (uint8_t identifier,
                                           const uint8_t* data,
                                           const uint8_t* data_end)
  {
    return processNakReject(Code_ConfigureReject, identifier, data, data_end);
  }
  command error_t ConfigureReject.invoke (void* param, frame_key_t* keyp) { return FAIL; }
  

  error_t processTerminate_ (uint8_t code,
                             const uint8_t* data,
                             const uint8_t* data_end,
                             frame_key_t sta_key)
  {
    LcpEventParams_term_t evt_params;
    evt_params.code = Code_TerminateRequest;
    evt_params.data = data;
    evt_params.data_end = data_end;
    evt_params.sta_key = sta_key;
    return call LcpAutomaton.signalEvent(LAE_ReceiveTerminateRequest, &evt_params);
  }
                          
  uint8_t idTerminateRequest;
  
  command uint8_t TerminateRequest.getCode () { return Code_TerminateRequest; }
  command error_t TerminateRequest.process (uint8_t identifier,
                                            const uint8_t* data,
                                            const uint8_t* data_end)
  {
    frame_key_t key;
    const uint8_t* fpe;
    uint8_t* fp = call Ppp.getOutputFrame(Protocol, &fpe, InhibitCompression, &key);
    unsigned int frame_len;
    error_t rc;

    if (0 == fp) {
      return EBUSY;
    }
    fp[0] = Code_TerminateAck;
    fp[1] = identifier;
    frame_len = 4 + (data_end - data);
    if ((fp + frame_len) > fpe) {
      frame_len = (fpe - fp);
    }
    memcpy(fp+4, data, frame_len - 4);
    fp[2] = (frame_len >> 8);
    fp[3] = (frame_len & 0x0ff);
    
    rc = call Ppp.fixOutputFrameLength(key, fp+frame_len);
    if (SUCCESS != rc) {
      return rc;
    }
    rc = processTerminate_(Code_TerminateRequest, data, data_end, key);
    if (ERETRY == rc) {
      call Ppp.releaseOutputFrame(key);
    }
    return rc;
  }
  command error_t TerminateRequest.invoke (void* param, frame_key_t* keyp) { return FAIL; }

  command uint8_t TerminateAck.getCode () { return Code_TerminateAck; }
  command error_t TerminateAck.process (uint8_t identifier,
                                           const uint8_t* data,
                                           const uint8_t* data_end)
  {
    /* Silently drop responses to outdated requests */
    if (idTerminateRequest != identifier) {
      return SUCCESS;
    }
    return processTerminate_(Code_TerminateAck, data, data_end, 0);
  }

  uint8_t idTerminateAck;
  command error_t TerminateAck.invoke (void* param, frame_key_t* keyp)
  {
    const uint8_t* fpe;
    frame_key_t key;
    uint8_t* fp = call Ppp.getOutputFrame(Protocol, &fpe, InhibitCompression, &key);

    if (0 == fp) {
      return EBUSY;
    }
    *fp++ = Code_TerminateAck;
    *fp++ = ++idTerminateAck;
    *fp++ = 0;
    *fp++ = 2;
    return completeInvoke_(key, fp, keyp);
  }

  default command uint8_t PppProtocolOption.getType[ uint8_t type ] (){ return 0; }
  default command bool PppProtocolOption.isNegotiable[ uint8_t type ] (){ return FALSE; }
  default command uint8_t PppProtocolOption.considerRequest[ uint8_t type ] (const uint8_t* dp,
                                                                     const uint8_t* dpe) { return Code_ConfigureReject; }
  default command void PppProtocolOption.setNegotiable[ uint8_t type ] (bool is_negotiable) { }
  default command void PppProtocolOption.reset[ uint8_t type ] () { }
  default command void PppProtocolOption.setLocal[ uint8_t type ] (const uint8_t* dp,
                                                                   const uint8_t* dpe) { }
  default command void PppProtocolOption.setRemote[ uint8_t type ] (const uint8_t* dp,
                                                                    const uint8_t* dpe) { }
  default command void PppProtocolOption.processNakValue[ uint8_t type ] (const uint8_t* dp,
                                                                          const uint8_t* dpe) { }
  default command uint8_t* PppProtocolOption.appendRequest[ uint8_t type ] (uint8_t* dp,
                                                                            const uint8_t* dpe) { return 0; }
  default command uint8_t* PppProtocolOption.appendNakValue[ uint8_t type ] (const uint8_t* sp,
                                                                             const uint8_t* spe,
                                                                             uint8_t* dp,
                                                                             const uint8_t* dpe) { return 0; }

}
