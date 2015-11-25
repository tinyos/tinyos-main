/**
 * Copyright (c) 2015, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 * @author Jasper Büsch <buesch@tkn.tu-berlin.de>
 */

#include "tkntsch_pib.h"
#include "tssm_utils.h"
#include "TknTschConfig.h"
#include "TimerSymbol.h"

#include "TknTschConfigLog.h"
//#ifndef TKN_TSCH_LOG_ENABLED_TSSM_RX
//#undef TKN_TSCH_LOG_ENABLED
//#endif
#include "tkntsch_log.h"

// TODO record transmission count for statistics

module TknTschTssmRxP {
  uses {
//    interface Init;
    interface TknFsmStateHandler as InitSlotRx;
    interface TknFsmStateHandler as WaitRxDataPrepare;
    interface TknFsmStateHandler as RxDataPrepare;
    interface TknFsmStateHandler as RxDataHwScheduled;
    interface TknFsmStateHandler as RxDataSuccess;
    interface TknFsmStateHandler as RxDataFail;
    interface TknFsmStateHandler as CleanupSlotRx;
    interface TknFsmStateHandler as TxAckPrepare;
    interface TknFsmStateHandler as TxAckHwScheduled;
    interface TknFsmStateHandler as TxAckSuccess;
    interface TknFsmStateHandler as TxAckFail;

    interface TknTschDebugHelperTssm as DebugHelper;

    // TODO needed? -> interface TknFsm as Fsm;
    interface TknEventEmit as EventEmitter;

    interface Plain154PhyRx<TSymbol,uint32_t> as PhyRx;
    interface Plain154PhyTx<TSymbol,uint32_t> as PhyTx;
    interface Plain154PhyOff as PhyOff;
    interface Queue<message_t*> as RxDataQueue @safe();
    interface Queue<message_t*> as RxBeaconQueue @safe();
    interface Pool<message_t> as RxMsgPool @safe();

    interface Plain154Frame as Frame;
    interface Plain154Metadata as Metadata;
    interface TknTschInformationElement;
    interface TknTschFrames;
    interface Packet;
  }
  provides {
    interface TknTschSlotContext as SlotContext;
  }
} implementation {
  tkntsch_slot_context_t* context = NULL;
  message_t m_ackFrame;
  plain154_txframe_t m_ackTxFrame;
  uint32_t m_tracker;

  async command tkntsch_status_t SlotContext.passContext(tkntsch_slot_context_t* slot_context) {
    if (slot_context == NULL)
      return TKNTSCH_INVALID_PARAMETER;

    // TODO should that be done atomically? this function should be called before emitting the event...
    atomic context = slot_context;
    return TKNTSCH_SUCCESS;
  }

  async command void SlotContext.revokeContext() {
    // TODO do locking? currently a null pointer might get dereferenced...
    atomic context = NULL;
  }


  async event void PhyOff.offDone() {
    ;
  }

  async event void InitSlotRx.handle() {
    // TODO use proper logging
    //uint8_t slottype;

    //atomic {
    //  slottype = context->slottype;
    //}

    // schedule event
    call EventEmitter.scheduleEvent(TSCH_EVENT_INIT_RX_DONE, TSCH_DELAY_IMMEDIATE, 0);
    // TODO go to RxDataPrepare immediately
  }

  async event void WaitRxDataPrepare.handle() {
    // schedule event
    // TODO wait prepare delay? -> using 0.5ms for now...
    call EventEmitter.scheduleEvent(TSCH_EVENT_PREPARE_RXDATA, TSCH_DELAY_SHORT, 50);
  }

  async event void RxDataPrepare.handle() {
    int ret;
    uint8_t slottype;
    uint32_t radio_t0;
    //uint8_t queue_size;
    uint32_t macTsRxOffset;

    call DebugHelper.startOfPacketPrepare();

    atomic {
      slottype = context->slottype;
      radio_t0 = context->radio_t0;
    }

    switch (slottype) {
      case TSCH_SLOT_TYPE_RX:
        // TODO handle RX slots
        atomic {
          macTsRxOffset = context->tmpl->macTsRxOffset;
        }

        // TODO handle full RX queue here?
        /*
        if (queue_size <= 0) {
          T_LOG_SLOT_STATE("TxDataPrepare: idle TX slot\n");
          atomic {
            context->flags.inactive_slot = TRUE;
            context->frame = NULL;
          }
          call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT, TSCH_DELAY_IMMEDIATE, 0);
          call DebugHelper.endOfPacketPrepare();
          return;
        }
        */
        break;

      default:
        T_LOG_ERROR("RxDataPrepare: Unhandled slot type 0x%x\n", slottype);
        atomic context->flags.internal_error = TRUE;
        call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT, TSCH_DELAY_IMMEDIATE, 0);
        call DebugHelper.endOfPacketPrepare();
        return;
    }

    // schedule the transmission
    ret = call PhyRx.enableRx(radio_t0, TSSM_SYMBOLS_FROM_US(macTsRxOffset));
    if (ret != SUCCESS) {
      // TODO should the return value of PhyRx.enableRx be stored?
      // go to the RxDataFailed handler
      call EventEmitter.scheduleEvent(TSCH_EVENT_RX_FAILED, TSCH_DELAY_IMMEDIATE, 0);
    }
    else {
      // setting the timer to catch failures happens in RxDataHwScheduled

      // schedule event
      call EventEmitter.scheduleEvent(TSCH_EVENT_RXDATA, TSCH_DELAY_IMMEDIATE, 0);

      // allow the IRQ
      atomic context->flags.radio_irq_expected = TRUE;
    }

    call DebugHelper.endOfPacketPrepare();
  }

  async event void PhyRx.enableRxDone() {}

  async event void RxDataHwScheduled.handle() {
    uint32_t macTsTxOffset;
    uint32_t macTsMaxTx;
    uint32_t dataRxMaxDelay;

    atomic {
      macTsTxOffset = context->tmpl->macTsTxOffset;
      macTsMaxTx = context->tmpl->macTsMaxTx;
    }
    dataRxMaxDelay = macTsTxOffset + macTsMaxTx;

    // schedule event
    // TODO send the event after macTsRxWait and check whether a reception is ongoing. if this is the case loop back to RxFail
    call EventEmitter.scheduleEvent(TSCH_EVENT_RX_FAILED, TSCH_DELAY_SHORT, dataRxMaxDelay);
  }

  async event message_t* PhyRx.received(message_t *frame) {
    call DebugHelper.startOfPhyIrq();

    atomic {
      // check whether the IRQ is expected
      if (context->flags.radio_irq_expected == FALSE) {
        // TODO any debugging?
        call DebugHelper.endOfPhyIrq();
        return frame;
      }

      // store frame pointer
      context->frame = (void*)frame;
      context->radioDataEndTs = call PhyRx.getNow();

      // ensure only one frame is received
      context->flags.radio_irq_expected = FALSE;
    }

    call EventEmitter.cancelEvent();

    call EventEmitter.emit(TSCH_EVENT_RX_SUCCESS);

    call DebugHelper.endOfPhyIrq();

    // return an unused frame from the pool
    return call RxMsgPool.get();
  }

  async event void RxDataSuccess.handle() {
    uint8_t slottype;
    bool send_ack;
    plain154_header_t *header;
    plain154_metadata_t* metadata;
    //uint8_t* payload;
    //uint8_t payloadLen;
    uint32_t rxTimestamp;
    uint8_t ret;
    uint8_t type;
    bool reject = FALSE;
    plain154_address_t dstAddr;
    plain154_address_t srcAddr;
    uint8_t dstAddrMode;
    uint8_t srcAddrMode;
    uint32_t trackval;

    atomic {
      slottype = context->slottype;
      m_tracker++;
      trackval = m_tracker;
    }

    switch (slottype) {
      case TSCH_SLOT_TYPE_RX:
        atomic {
          header = call Frame.getHeader( context->frame );
          metadata = call Metadata.getMetadata(context->frame);
          send_ack = call Frame.isAckRequested(header);
          type = call Frame.getFrameType(header);
          //payloadLen = call Packet.payloadLength((message_t*) context->frame);
          //payload = call Packet.getPayload((message_t*) context->frame, payloadLen);

          context->flags.with_ack = send_ack;

          #ifndef TKN_TSCH_DISABLE_ADDRESS_FILTERING
          if (call Frame.getFrameVersion(header) < PLAIN154_FRAMEVERSION_2)
            reject = TRUE;
          if (call Frame.getDstAddr(header, &dstAddr) != SUCCESS) {
            if (type != PLAIN154_FRAMETYPE_BEACON)  // we accept ebeacons without dst addr
              reject = TRUE;
          } else {
            dstAddrMode = call Frame.getDstAddrMode(header);
            if ((dstAddrMode == PLAIN154_ADDR_EXTENDED) &&
                (memcmp( &dstAddr.extendedAddress, &context->macpib->macExtendedAddress, 8) != 0))
              reject = TRUE;
            else if ((dstAddrMode == PLAIN154_ADDR_SHORT) && (dstAddr.shortAddress != 0xffff))
              reject = TRUE;
          }
          #endif

          srcAddrMode = call Frame.getSrcAddrMode(header);
          if (!reject && ((srcAddrMode != PLAIN154_ADDR_EXTENDED) || (call Frame.getSrcAddr(header, &srcAddr) != SUCCESS))) {
            reject = TRUE;
          }
          if ((type != PLAIN154_FRAMETYPE_BEACON) && (type != PLAIN154_FRAMETYPE_DATA))
            reject = TRUE;

          if (!reject && (metadata->valid_timestamp)) {
            rxTimestamp = metadata->timestamp;
            context->time_correction = (context->radio_t0) + TSSM_SYMBOLS_FROM_US((context->tmpl->macTsTxOffset));
            context->time_correction = TSSM_SYMBOLS_TO_US(((context->time_correction) - rxTimestamp));
          } else T_LOG_ADDRESS_FILTERING("Frame rejected or radio ts invalid!\n");

          #ifdef TKN_TSCH_DISABLE_TIME_CORRECTION_BEACONS
            // TODO this does not happen as beacons are rejected above
            if (type == PLAIN154_FRAMETYPE_BEACON) {
                context->time_correction = 0;
            }
          #endif

          // Check if the received frame is from time parent, if we don't send an ACK (otherwise we check later)
          if ( !send_ack && (context->link->macLinkOptions & PLAIN154E_LINK_OPTION_TIMEKEEPING) ) {
            if (( memcmp((void *) &context->macpib->timeParentAddress, (void *) &srcAddr, sizeof(plain154_address_t)) != 0 )) {
              context->time_correction = 0;
            }
          }
        }

        if (reject) {
          atomic {
            context->flags.success = TRUE;
            context->frame = NULL;
          }
          call EventEmitter.scheduleEvent(TSCH_EVENT_CLEANUP_RX, TSCH_DELAY_IMMEDIATE, 0);
        }
        else if (send_ack == TRUE) {
          // We are still in PhyRx INT; to get out we have to schedule the next state properly
          uint32_t refTime = call EventEmitter.getReferenceTime();
          if (call RxDataQueue.full()) {
            T_LOG_RXTX_STATE("RxDataSuccess: RX w/ ACK (sending NACK)\n");
            atomic context->flags.nack = TRUE;
          } else {
            T_LOG_SLOT_STATE("RxDataSuccess: RX w/ ACK\n");
          }
          call EventEmitter.scheduleEventToReference(TSCH_EVENT_PREPARE_TXACK, TSCH_DELAY_SHORT, refTime, 100);
        } else {
          T_LOG_RXTX_STATE("RxDataSuccess: RX w/o ACK\n");
          atomic {
            ret = FAIL;
            if ((type == PLAIN154_FRAMETYPE_BEACON) && (call Frame.isIEListPresent(header)) ) {
              // TODO: Check if macAutoRequest is FALSE
              ret = call RxBeaconQueue.enqueue((message_t*) context->frame);
              context->flags.indicate_beacon = TRUE;
            } else if ((call Frame.getFrameType(header) == PLAIN154_FRAMETYPE_DATA)) {
              ret = call RxDataQueue.enqueue((message_t*) context->frame);
              context->flags.indicate_data = TRUE;
            } else {
              //TODO: ??
            }
            if (ret != SUCCESS) {
              T_LOG_WARN("RxDataSuccess: RX queue is full, DROPPING FRAME!\n");
              atomic call RxMsgPool.put(context->frame);
              context->flags.indicate_beacon = FALSE;
              context->flags.indicate_data = FALSE;
              context->flags.success = TRUE;
              context->flags.indicate_data = FALSE;
            } else {
              context->flags.success = TRUE;
            }
            context->frame = NULL;
          }
        }
        call EventEmitter.scheduleEvent(TSCH_EVENT_CLEANUP_RX, TSCH_DELAY_IMMEDIATE, 0);
        break;

      default:
        T_LOG_ERROR("RxDataSuccess: Unhandled slot type 0x%x\n", slottype);
        atomic context->flags.internal_error = TRUE;
        call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT, TSCH_DELAY_IMMEDIATE, 0);
        return;
    }
  }


  async event void TxAckPrepare.handle() {
    plain154_header_t *dataHeader;
    plain154_address_t peerAddress;
    uint8_t ret;
    int16_t timeCorrection;
    //bool success = FALSE;
    uint16_t srcPanID;
    bool extendedPeerAddress = FALSE;
    bool decodedPeerAddress = FALSE;
    bool reqAck;

    call DebugHelper.startOfPacketPrepare();

    atomic {
      dataHeader = call Frame.getHeader( (message_t*) context->frame );
      timeCorrection = context->time_correction;
      reqAck = !context->flags.nack;
    }

    if (call Frame.getSrcAddrMode(dataHeader) == PLAIN154_ADDR_EXTENDED)
      extendedPeerAddress = TRUE;
    if (TKNTSCH_SUCCESS == (call Frame.getSrcAddr(dataHeader, &peerAddress)))
      decodedPeerAddress = TRUE;

    atomic {
    #ifndef TKN_TSCH_DISABLE_TIME_CORRECTION_ACKS
      if ( decodedPeerAddress && extendedPeerAddress &&
           ( context->link->macLinkOptions & PLAIN154E_LINK_OPTION_TIMEKEEPING )) {
        if (( memcmp((void *) &context->macpib->timeParentAddress, (void *) &peerAddress, sizeof(plain154_address_t)) == 0 )) {
        // received frame is from time parent; don't include time correction into ACK
        //LOG_TIME_CORRECTION("Not including correction back to t.parent\n");
        timeCorrection = 0;
        } else {
          // sending the time correction in ACK and don't apply it ourselves
          context->time_correction = 0;
        }
      }
    #else
      context->time_correction = 0;
    #endif
    }

    if (TKNTSCH_SUCCESS == (call Frame.getSrcPANId(dataHeader, &srcPanID))) {
      // TODO ???
    } else {
      if (TKNTSCH_SUCCESS != (call Frame.getDstPANId(dataHeader, &srcPanID))) {
        T_LOG_WARN("RxFrame had no PanIDs!\n");
        //TODO: Get our panid from pib and set it in the answer.
        //TODO: Or should we neglect PANid totally?
        srcPanID = 0xffff;
      }
    }

    if (TKNTSCH_SUCCESS == (call TknTschFrames.createEnhancedAckFrame(
                                    &m_ackFrame,
                                    call Frame.getSrcAddrMode(dataHeader),
                                    &peerAddress,
                                    srcPanID,
                                    timeCorrection,
                                    reqAck)))
    {
      plain154_header_t *ackHeader;
      uint8_t ackHeaderLen;
      plain154_txframe_t *txframe;
      uint8_t rxDataFrameLen;
      plain154_metadata_t* rxDataFrameMeta;

      // prepare the frame structure
      atomic {
        context->ack = &m_ackFrame;
        txframe = &m_ackTxFrame;
        ackHeader = call Frame.getHeader( (message_t*) &m_ackFrame );
        txframe->payload = call Packet.getPayload(&m_ackFrame, txframe->payloadLen);
        txframe->metadata = call Metadata.getMetadata(&m_ackFrame);
        rxDataFrameMeta = call Metadata.getMetadata((message_t*) context->frame);
      }
      call Frame.setDSN(ackHeader, call Frame.getDSN(dataHeader));
      call Frame.getActualHeaderLength(ackHeader, &ackHeaderLen);
      txframe->header = ackHeader;
      txframe->headerLen = ackHeaderLen;
      txframe->payloadLen = 0;

      call Frame.getActualHeaderLength(dataHeader, &rxDataFrameLen);
      rxDataFrameLen += call Packet.payloadLength((message_t*) context->frame);

      ret = call PhyTx.transmit(txframe, rxDataFrameMeta->timestamp,
          // The RX timestamp refers to time when preamble starts
          // PhyTx.transmit schedules the time when preamble should start
          // 802.15.4 specifies eACKs need to be delayed for macTsTxAckDelay after
          // data reception, more precisely, the point in time after the SFD
          // rxTimestamp + (1 [PSDU len field] + PSDU + 2 [CRC]) * 2 + macTsTxAckDelay
          //  = delay until preamble needs to start
          ((1 + rxDataFrameLen + 2) * 2) + (uint16_t) TSSM_SYMBOLS_FROM_US(context->tmpl->macTsTxAckDelay)
        );
      if (ret != SUCCESS) {
        call EventEmitter.scheduleEvent(TSCH_EVENT_TX_FAILED, TSCH_DELAY_IMMEDIATE, 0);
      }
      else {
        call EventEmitter.scheduleEvent(TSCH_EVENT_TXACK, TSCH_DELAY_IMMEDIATE, 0);
      }
    }
    else {
      T_LOG_ERROR("TxAckPrepare: Preparation failed!\n");
      atomic context->flags.internal_error = TRUE;
      call EventEmitter.scheduleEvent(TSCH_EVENT_TX_FAILED, TSCH_DELAY_IMMEDIATE, 0);
    }

    call DebugHelper.endOfPacketPrepare();
  }

  async event void TxAckHwScheduled.handle() {
    uint16_t maxAckWaitDelay;

    atomic {
      maxAckWaitDelay = context->tmpl->macTsTxOffset + context->tmpl->macTsMaxTx
          + context->tmpl->macTsTxAckDelay + context->tmpl->macTsMaxAck;
      context->flags.radio_irq_expected = TRUE;
    }

    call EventEmitter.scheduleEvent(TSCH_EVENT_TX_FAILED, TSCH_DELAY_SHORT, maxAckWaitDelay);
  }

  async event void TxAckSuccess.handle() {
    uint8_t ret;

    T_LOG_SLOT_STATE("TxAckSuccess\n");
    atomic {
      context->flags.success = TRUE;
      context->flags.indicate_data = TRUE;
      ret = call RxDataQueue.enqueue((message_t*) context->frame);
      if (ret != SUCCESS) {
        T_LOG_WARN("RxDataSuccess: RX queue is full, DROPPING FRAME!\n");
        atomic call RxMsgPool.put(context->frame);
      }
      context->frame = NULL;
    }
    call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT, TSCH_DELAY_IMMEDIATE, 0);
  }

  async event void PhyTx.transmitDone(plain154_txframe_t *frame, error_t result) {
    bool radio_irq_expected;
    call DebugHelper.startOfPhyIrq();

    atomic {
      radio_irq_expected = context->flags.radio_irq_expected;
      // ensure only one frame is received
      context->flags.radio_irq_expected = FALSE;
    }

    // check whether the IRQ is expected
    if (radio_irq_expected == FALSE) {
      // TODO any debugging?
      call DebugHelper.endOfPhyIrq();
      return;
    }

    call EventEmitter.cancelEvent();

    // check result
    if (result == SUCCESS) {
      call EventEmitter.emit(TSCH_EVENT_TX_SUCCESS);
    }
    else {
      call EventEmitter.emit(TSCH_EVENT_TX_FAILED);
    }
    call DebugHelper.endOfPhyIrq();
  }

  async event void RxDataFail.handle() {
    // TODO log error

    uint8_t slottype;
    bool internal_error;

    atomic {
      slottype = context->slottype;
      internal_error = context->flags.internal_error;

      // deny the IRQ
      context->flags.radio_irq_expected = FALSE;
    }

    switch (slottype) {
      case TSCH_SLOT_TYPE_RX:
        if (internal_error) {
          T_LOG_ERROR("RxDataFail: RX error!\n");
          atomic {
            context->flags.indicate_data = TRUE;  // TODO: Does this make sense at all?
          }
        }
        else {
          T_LOG_SLOT_STATE("Idle RX link.\n");
          atomic {
            context->flags.inactive_slot = TRUE;
          }
        }
        call EventEmitter.scheduleEvent(TSCH_EVENT_CLEANUP_RX, TSCH_DELAY_IMMEDIATE, 0);
        break;

      default:
        T_LOG_ERROR("RxDataFail: Unhandled slot type 0x%x\n", slottype);
        atomic context->flags.internal_error = TRUE;
        call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT, TSCH_DELAY_IMMEDIATE, 0);
        return;
    }
  }

  async event void TxAckFail.handle() {
    call PhyOff.off();

    atomic {
      context->flags.radio_irq_expected = FALSE;

      if (context->flags.internal_error) {
        context->flags.indicate_data = FALSE;
      }
    }
    //TODO: Free the rx frame from the queue again?
    call EventEmitter.scheduleEvent(TSCH_EVENT_CLEANUP_RX, TSCH_DELAY_IMMEDIATE, 0);
  }

  async event void CleanupSlotRx.handle() {
    //LOG_SLOT_STATE("Cleaning up after RX slot.\n");

    // TODO any cleanup necessary after TX?

    // schedule event
    call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT, TSCH_DELAY_IMMEDIATE, 0);
  }

}
