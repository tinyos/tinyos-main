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

module PppP {
  uses {
    interface HdlcFraming;
    interface FragmentPool as TransmitFramePool;
    interface PppProtocol[ uint16_t protocol ];
    interface PppProtocolCodeSupport as ProtocolReject;
    interface PppProtocolReject;
    interface StdControl as HdlcControl;
    interface MultiLed;
  }
  provides {
    interface SplitControl;
    interface GetSetOptions<PppOptions_t> as PppOptions;
    interface Ppp;
    interface PppRejectedProtocol;
  }
} implementation {

  /* Options that control how Ppp manages things */
  PppOptions_t options = { txProtocolFieldCompression: FALSE,
                           rxProtocolFieldCompression: FALSE,
                           txMaximumReceiveUnit: PPP_MAXIMUM_MRU,
                           rxMaximumReceiveUnit: PPP_MAXIMUM_MRU };

  command error_t PppOptions.set (const PppOptions_t* new_options)
  {
    if (new_options) {
      options = *new_options;
    } else {
      options.txProtocolFieldCompression = options.rxProtocolFieldCompression = FALSE;
      options.txMaximumReceiveUnit = options.rxMaximumReceiveUnit = PPP_MAXIMUM_MRU;
    }
#if 0
    printf("PPP Opt: PCOMP tx=%d rx=%d; MRU tx=%u rx=%u\r\n",
           options.txProtocolFieldCompression, options.rxProtocolFieldCompression,
           options.txMaximumReceiveUnit, options.rxMaximumReceiveUnit);
#endif
    return SUCCESS;
  }

  command PppOptions_t PppOptions.get () { return options; }

  command error_t PppRejectedProtocol.rejected (uint16_t protocol,
                                                const uint8_t* data,
                                                const uint8_t* data_end)
  {
    return call PppProtocol.rejectedByPeer[protocol](data, data_end);
  }


  enum {
    CS_stopped,
    CS_starting,
    CS_started,
    CS_stopping,
  };
  error_t controlResult_;
  uint8_t controlState_;

  task void controlEngine_task ()
  {
    if (CS_started == controlState_) {
      signal SplitControl.startDone(controlResult_);
    } else if (CS_stopped == controlState_) {
      /* @TODO@ Notify upper levels of shutdown, await their signal */
      call HdlcControl.stop();
      signal SplitControl.stopDone(controlResult_);
    }
  }

  enum {
    /** Frame is unused */
    TFS_unused,
    /** A fragment has been allocated and somebody's filling it with
     * data.  TFS_INHIBIT_COMPRESSION may be set. */
    TFS_filling,
    /** The fragment has been frozen at its maximum length.  The
     * content may or may not be complete, but cannot extend beyond
     * the recorded end.  TFS_INHIBIT_COMPRESSION may be set. */
    TFS_fixed,
    /** Ppp.sendOutputFrame() has been invoked.  The fragment has been
     * frozen to its final length and placed on the transmission
     * queue.  TFS_INHIBIT_COMPRESSION may be set. */
    TFS_queued,
    /** The frame has been given to HdlcFraming.sendFrame for
     * processing. */
    TFS_transmitting,
    /** The frame has been transmitted, or the user cancelled it.  The
     * fragment will be released and the frame marked unused by
     * transmitEngine_task. */
    TFS_releasable,
    /** A mask used to extract the bits that represent a frame state */
    TFS_STATE_MASK = 0x0f,
    /** Auxiliary state indicating that the system indicated on
     * allocation that compression of frame protocol/address fields
     * should be suppressed. */
    TFS_INHIBIT_COMPRESSION = 0x80,
  };
  typedef struct HdlcTxFrame_t {
      uint8_t* start;
      uint8_t* end;
      uint8_t frame_state;
  } HdlcTxFrame_t;
  
  /** A set of transmission frames permitting queued transmission of
   * multiple PPP frame and processing in order. */
  HdlcTxFrame_t txFrames_[PPP_HDLC_TX_FRAME_LIMIT];
  static const HdlcTxFrame_t* txFramesEnd_ = txFrames_ + PPP_HDLC_TX_FRAME_LIMIT;
  HdlcTxFrame_t* queuedTxFrame_[PPP_HDLC_TX_FRAME_LIMIT];
  uint8_t queuedTxFrameIdx_;

  HdlcTxFrame_t* activeTxFrame_;

  /** Buffer used to communicate frame errors from the task that
   * discovered them to one that can safely deal with them. */
  HdlcError_e inFrameError__;

  /** The number of frames that were dropped by the lower level */
  unsigned int inFrameDropped__;

#if 0
  void dumpFrame (const uint8_t* fp,
                  const uint8_t* fpe)
  {
    while (fp < fpe) {
      printf(" %02x", *fp++);
    }
    printf("\r\n");
  }
#endif

  async event void TransmitFramePool.available (unsigned int length) { }

  default event void Ppp.outputFrameTransmitted (frame_key_t key,
                                                 error_t result) { }

  default command error_t PppProtocolReject.process (unsigned int protocol,
                                                     const uint8_t* information,
                                                     unsigned int length) { return SUCCESS; }

  task void transmitEngine_task ();

  void releaseTxFrame_ (HdlcTxFrame_t* fp,
                        error_t rc,
                        bool post_done)
  {
    if (post_done) {
      signal Ppp.outputFrameTransmitted(fp->start, rc);
    }
    rc = call TransmitFramePool.release(fp->start);
    if (SUCCESS != rc) {
      // @INSTRUMENT@
    }
    fp->frame_state = TFS_unused;
    fp->start = fp->end = 0;
  }

  task void transmitEngine_task ()
  {
    HdlcTxFrame_t* tfp;
    error_t rc;

    /* If there's nothing to transmit, or we're already transmitting,
     * done. */
    if ((0 == queuedTxFrameIdx_) || activeTxFrame_) {
      return;
    }

    tfp = queuedTxFrame_[0];
    if (0 < --queuedTxFrameIdx_) {
      memmove(queuedTxFrame_, queuedTxFrame_ + 1, queuedTxFrameIdx_ * sizeof(*queuedTxFrame_));
    }

    rc = call HdlcFraming.sendFrame(tfp->start,
                                    tfp->end- tfp->start,
                                    !!(tfp->frame_state & TFS_INHIBIT_COMPRESSION));

    if (SUCCESS == rc) {
      tfp->frame_state = TFS_transmitting;
      activeTxFrame_ = tfp;
    } else {
      releaseTxFrame_(tfp, rc, TRUE);
    }
  }


  command uint8_t* Ppp.getOutputFrame (unsigned int protocol,
                                       const uint8_t** frame_endp,
                                       bool inhibit_compression,
                                       frame_key_t* keyp)
  {
    error_t rc;
    uint8_t* fp;
    bool pcomp;
    HdlcTxFrame_t* tfp = txFrames_;

    while (tfp < txFramesEnd_) {
      if (TFS_unused == tfp->frame_state) {
        break;
      }
      ++tfp;
    }
    if (txFramesEnd_ <= tfp) {
      // @INSTRUMENT@
      return 0;
    }
    
    rc = call TransmitFramePool.request(&tfp->start, &tfp->end, PPP_MINIMUM_TX_FRAME_SIZE);
    if (SUCCESS != rc) {
      // @INSTRUMENT@
      return 0;
    }
    tfp->frame_state = TFS_filling;
    if (inhibit_compression) {
      tfp->frame_state |= TFS_INHIBIT_COMPRESSION;
    }
    pcomp = options.txProtocolFieldCompression && (! inhibit_compression);

    if (keyp) {
      *keyp = tfp->start;
    }
    fp = tfp->start;
    if (frame_endp) {
      *frame_endp = tfp->end;
    }

    if ((0x100 > protocol)
        && pcomp) {
      *fp++ = protocol;
    } else {
      *fp++ = (protocol >> 8);
      *fp++ = (protocol & 0x0FF);
    }

    return fp;
  }

  HdlcTxFrame_t* findTxFrame_ (frame_key_t key)
  {
    HdlcTxFrame_t* tfp = txFrames_;

    while (tfp < txFramesEnd_) {
      if (tfp->start == key) {
        return tfp;
      }
      ++tfp;
    }
    return 0;
  }

  command error_t Ppp.fixOutputFrameLength (frame_key_t key,
                                            const uint8_t* frame_end)
  {
    HdlcTxFrame_t* tfp = findTxFrame_(key);
    error_t rc;
    
    if (! tfp) {
      // @INSTRUMENT@
      return EINVAL;
    }
    if (frame_end == tfp->end) {
      // @INSTRUMENT@
    }
    rc = call TransmitFramePool.freeze(tfp->start, frame_end);
    if (SUCCESS == rc) {
      tfp->end = (uint8_t*)frame_end;
      tfp->frame_state = TFS_fixed | (tfp->frame_state & ~TFS_STATE_MASK);
    } else {
      releaseTxFrame_(tfp, rc, FALSE);
    }
    return rc;
  }

  command error_t Ppp.sendOutputFrame (frame_key_t key)
  {
    HdlcTxFrame_t* tfp = findTxFrame_(key);

    if (! tfp) {
      // @INSTRUMENT@
      return EINVAL;
    }
    if (TFS_fixed != (tfp->frame_state & TFS_STATE_MASK)) {
      // @INSTRUMENT@
    }
    tfp->frame_state = TFS_queued | (tfp->frame_state & ~TFS_STATE_MASK);
    queuedTxFrame_[queuedTxFrameIdx_++] = tfp;
    post transmitEngine_task();
    return SUCCESS;
  }

  command error_t Ppp.releaseOutputFrame (frame_key_t key)
  {
    HdlcTxFrame_t* tfp = findTxFrame_(key);

    if (! tfp) {
      // @INSTRUMENT@
      return EINVAL;
    }
    releaseTxFrame_(tfp, SUCCESS, FALSE);
    return SUCCESS;
  }

  event void HdlcFraming.sendDone (const uint8_t* data,
                                   unsigned int len,
                                   error_t err)
  {
    if (activeTxFrame_) {
      releaseTxFrame_(activeTxFrame_, err, TRUE);
      activeTxFrame_ = 0;
      post transmitEngine_task();
    }
  }

  typedef struct Frame_t {
    const uint8_t* start;
    const uint8_t* end;
  } Frame_t;
  Frame_t readyFrame__[PPP_HDLC_RX_FRAME_LIMIT];
  uint8_t readyFrameIdx__;

  task void processFrame_task ()
  {
    unsigned int protocol;
    error_t rc;
    Frame_t* apf;
    const uint8_t* dp;

    atomic {
      if (0 == readyFrameIdx__) {
        return;
      }
      apf = readyFrame__;
    }
    dp = apf->start;
    
#if 0
    {
      printf("Got frame length %u:", apf->end - apf->start);
      dumpFrame(apf->start, apf->end);
    }
#endif

    /* Decode the protocol */
    protocol = *dp++;
    if (! (protocol & 1)) {
      protocol = (protocol << 8) + *dp++;
    }

    /* If the protocol is registered, process the message; otherwise,
     * tell LCP to bounce it. */
    if (0 != call PppProtocol.getProtocol[protocol]()) {
      //printf("Good protocol %04x\r\n", protocol);
      rc = call PppProtocol.process[protocol](dp, apf->end - dp);
    } else {
      rc = call PppProtocolReject.process(protocol, dp, apf->end - dp);
    }

    if (ERETRY == rc) {
      /* Put the frame back into received mode and leave it at the
       * head of the ready queue.  Reprocess the ready queue. */
      // @INSTRUMENT@
      post processFrame_task();
    } else {
      call HdlcFraming.releaseReceivedFrame(apf->start);
      atomic {
        /* Consume the frame; shift any remaining ready frames down in
         * the queue. */
        if (0 < --readyFrameIdx__) {
          // @INSTRUMENT@
          memmove(readyFrame__, readyFrame__+1, readyFrameIdx__ * sizeof(*readyFrame__));
          post processFrame_task();
        }
      }
    }
  }

  task void processError_task ()
  {
    HdlcError_e in_frame_error;
    unsigned int ifd;
    atomic {
      in_frame_error = inFrameError__;
      ifd = inFrameDropped__;
      inFrameError__ = 0;
      inFrameDropped__ = 0;
    }
    //printf("Frame error %d\r\n", in_frame_error);
  }

  void initializeOptions_ ()
  {
    options.txProtocolFieldCompression = FALSE;
    options.rxProtocolFieldCompression = FALSE;
    options.txMaximumReceiveUnit = PPP_MAXIMUM_MRU;
    options.rxMaximumReceiveUnit = PPP_MAXIMUM_MRU;
  }

  command error_t SplitControl.start ()
  {
    error_t rc;

    rc = call HdlcControl.start();
    if (SUCCESS != rc) {
      return rc;
    }
    
    initializeOptions_();
    controlState_ = CS_started;
    controlResult_ = SUCCESS;
    post controlEngine_task();
    return rc;
  }

  command error_t SplitControl.stop ()
  {
    controlState_ = CS_stopping;
    post controlEngine_task();
    return SUCCESS;
  }
  
  async event void HdlcFraming.receivedDelimiter () { }

  event void HdlcFraming.receivedFrame (const uint8_t* data,
                                        unsigned int len)
  {
    atomic {
      Frame_t* fp = readyFrame__ + readyFrameIdx__++;
      fp->start = data;
      fp->end = data + len;
    }
    post processFrame_task();
  }

  async event void HdlcFraming.receptionError (HdlcError_e code)
  {
    atomic {
      inFrameError__ = code;
      ++inFrameDropped__;
    }
    post processError_task();
  }

  /* Code a default implementation that returns an invalid protocol
   * code, so we can detect unrecognized protocols. */
  default command unsigned int PppProtocol.getProtocol[ uint16_t protocol ] () { return 0; }
  
  /* Default implementation of unrecognized protocols should never be
   * invoked. */
  default command error_t PppProtocol.process[ uint16_t protocol ] (const uint8_t* information,
                                                                    unsigned int information_length) { return FAIL; }

  default command error_t PppProtocol.rejectedByPeer[ uint16_t protocol ] (const uint8_t* data,
                                                                           const uint8_t* data_end)
  {
    return SUCCESS;
  }

}
