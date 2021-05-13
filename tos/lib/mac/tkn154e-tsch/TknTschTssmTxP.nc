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
//ifndef TKN_TSCH_LOG_ENABLED_TSSM_TX
//undef TKN_TSCH_LOG_ENABLED
//endif
#include "tkntsch_log.h"

// TODO record transmission count for statistics

module TknTschTssmTxP {
  uses {
//    interface Init;
    interface TknFsmStateHandler as InitSlotAdv;
    interface TknFsmStateHandler as WaitTxDataPrepare;
    interface TknFsmStateHandler as TxDataPrepare;
    interface TknFsmStateHandler as TxDataHwScheduled;
    interface TknFsmStateHandler as TxDataSuccess;
    interface TknFsmStateHandler as TxDataFail;
    interface TknFsmStateHandler as CleanupSlotAdv;
    interface TknFsmStateHandler as InitSlotTx;
    interface TknFsmStateHandler as RxAckPrepare;
    interface TknFsmStateHandler as RxAckHwScheduled;
    interface TknFsmStateHandler as RxAckSuccess;
    interface TknFsmStateHandler as RxAckFail;
    interface TknFsmStateHandler as CleanupSlotTx;

    interface TknTschDebugHelperTssm as DebugHelper;

    // TODO needed? -> interface TknFsm as Fsm;
    interface TknEventEmit as EventEmitter;

    interface Plain154PhyTx<TSymbol,uint32_t> as PhyTx;
    interface Plain154PhyRx<TSymbol,uint32_t> as PhyRx;
    interface Plain154PhyOff as PhyOff;
    interface Queue<message_t*> as AdvQueue @safe();
    interface Queue<message_t*> as TxQueue @safe();
    interface LinkedList<message_t*> as TxLinkedList @safe();

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
  norace uint8_t m_ebsn = 0;
  norace uint8_t m_bsn = 0;
  norace uint8_t m_dsn = 0;
  norace plain154_txframe_t m_txframe;

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


  async event void InitSlotAdv.handle() {
    // TODO use proper logging
    //LOG_SLOT_STATE("Initializing advertisement slot.\n");

    // schedule event
    call EventEmitter.scheduleEvent(TSCH_EVENT_INIT_ADV_DONE, TSCH_DELAY_IMMEDIATE, 0);
  }

  async event void InitSlotTx.handle() {
    // TODO use proper logging
    //uint8_t slottype;

    atomic {
      //slottype = context->slottype;
    }

    //if (slottype == TSCH_SLOT_TYPE_SHARED) T_LOG_SLOT_STATE("Initializing shared TX slot.\n");
    //else T_LOG_SLOT_STATE("Initializing TX slot.\n");

    // schedule event
    call EventEmitter.scheduleEvent(TSCH_EVENT_INIT_TX_DONE, TSCH_DELAY_IMMEDIATE, 0);
  }

  async event void WaitTxDataPrepare.handle() {
    // schedule event
    // TODO wait prepare delay? -> using 1ms for now...
    call EventEmitter.scheduleEvent(TSCH_EVENT_PREPARE_TXDATA, TSCH_DELAY_SHORT, 1000);
  }

  async event void TxDataPrepare.handle() {
    int ret;
    uint8_t slottype;
    uint32_t radio_t0;
    uint8_t queue_size;
    message_t* msg;
    uint32_t macTsTxOffset;
    uint8_t* ptr;
    tkntsch_asn_t asn;
    uint8_t joinPriority;
    plain154_header_t *header;
    uint8_t headerLen = 0;
    plain154_metadata_t* meta;
    uint8_t num_transmissions;

    call DebugHelper.startOfPacketPrepare();

    atomic {
      slottype = context->slottype;
      radio_t0 = context->radio_t0;
    }

    switch (slottype) {
      case TSCH_SLOT_TYPE_ADVERTISEMENT:
        atomic {
          queue_size = call AdvQueue.size();
          msg = call AdvQueue.head();
          context->frame = msg;
          meta = call Metadata.getMetadata(msg);
          context->num_transmissions = meta->transmissions;
          macTsTxOffset = context->tmpl->macTsTxOffset;
          asn = context->macASN;
          joinPriority = context->joinPriority;
        }
        if (queue_size <= 0) {
          T_LOG_INFO("TxDataPrepare: idle adv. slot\n");
          atomic {
            context->flags.inactive_slot = TRUE;
            context->frame = NULL;
          }
          call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT, TSCH_DELAY_IMMEDIATE, 0);
          call DebugHelper.endOfPacketPrepare();
          return;
        }

        // TODO update IEs

        // TODO HACK !!!
        ptr = (uint8_t*) &msg->data[0];
        ptr[2 + 2] = (uint8_t) ((asn) & 0xff);
        ptr[2 + 3] = (uint8_t) ((asn >> 8) & 0xff);
        ptr[2 + 4] = (uint8_t) ((asn >> 16) & 0xff);
        ptr[2 + 5] = (uint8_t) ((asn >> 24) & 0xff);
        ptr[2 + 6] = (uint8_t) ((asn >> 32) & 0xff);
        ptr[2 + 7] = joinPriority;

        // TODO use BSN for normal beacons
        header = call Frame.getHeader(msg);
        call Frame.setDSN(header, m_ebsn++);
        break;

      case TSCH_SLOT_TYPE_SHARED:
      case TSCH_SLOT_TYPE_TX:
        atomic {
          if (call TxQueue.empty()) {
            T_LOG_INFO("TxDataPrepare: idle TX slot (empty queue)\n");
            context->flags.inactive_slot = TRUE;
            context->frame = NULL;
            call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT, TSCH_DELAY_IMMEDIATE, 0);
            call DebugHelper.endOfPacketPrepare();
            return;
          }
          queue_size = call TxQueue.size();
          if (slottype == TSCH_SLOT_TYPE_TX) {
            plain154_full_address_t* linkAddr;
            plain154_address_t addr;
            int i;
            for (i=0; i<queue_size;i++) {
              msg = call TxQueue.element(i);
              header = call Frame.getHeader(msg);
              call Frame.getDstAddr(header, &addr);
              linkAddr = &(context->link->macNodeAddress);
              if (linkAddr->mode != call Frame.getDstAddrMode(header))
                continue;
              if (linkAddr->mode == PLAIN154_ADDR_EXTENDED) {
                if (memcmp((uint8_t *)&linkAddr->addr, (uint8_t *) &addr, 8) == 0)
                  break;
              } else {
                #ifdef TKN_TSCH_DISABLE_UNICASTS_IN_SHARED_SLOTS
                if ( (slottype == TSCH_SLOT_TYPE_SHARED) && (PLAIN154_ADDR_EXTENDED == call Frame.getDstAddrMode(header)) )
                  continue;
                #endif
                if (memcmp((uint8_t *)&linkAddr->addr, (uint8_t *)&addr, 2) == 0)
                  break;
              }
            }
            if (i == queue_size) {
              T_LOG_INFO("TxDataPrepare: idle TX slot (no match found)\n");
              context->flags.inactive_slot = TRUE;
              context->frame = NULL;
              call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT, TSCH_DELAY_IMMEDIATE, 0);
              call DebugHelper.endOfPacketPrepare();
              return;
            }
          } else {  // (slottype != TSCH_SLOT_TYPE_TX)
            msg = call TxQueue.head();
            header = call Frame.getHeader(msg);
          }
          context->frame = msg;
          meta = call Metadata.getMetadata(msg);
          context->num_transmissions = meta->transmissions;
          num_transmissions = meta->transmissions;
          macTsTxOffset = context->tmpl->macTsTxOffset;
          if (context->num_transmissions == 0) {
            call Frame.setDSN(header, m_dsn++);
          }
        }
        break;

      default:
        T_LOG_ERROR("TxDataPrepare: Unhandled slot type 0x%x\n", slottype);
        atomic context->flags.internal_error = TRUE;
        call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT, TSCH_DELAY_IMMEDIATE, 0);
        call DebugHelper.endOfPacketPrepare();
        return;
    }

    // prepare the frame structure
    m_txframe.header = header;
    call Frame.getActualHeaderLength(header, &headerLen);
    m_txframe.headerLen = headerLen;
    m_txframe.payloadLen = call Packet.payloadLength(msg);
    m_txframe.payload = call Packet.getPayload(msg, m_txframe.payloadLen);
    m_txframe.metadata = meta;

    // schedule the transmission
    ret = call PhyTx.transmit(&m_txframe, radio_t0, TSSM_SYMBOLS_FROM_US(macTsTxOffset));
    if (ret != SUCCESS) {
      // TODO should the return value of PhyTx.transmit be stored?
      // go to the TxDataFailed handler
      call EventEmitter.scheduleEvent(TSCH_EVENT_TX_FAILED, TSCH_DELAY_IMMEDIATE, 0);
    }
    else {
      // setting the timer to catch failures happens in TxDataHwScheduled

      // schedule event
      call EventEmitter.scheduleEvent(TSCH_EVENT_TXDATA, TSCH_DELAY_IMMEDIATE, 0);

      // allow the IRQ
      atomic context->flags.radio_irq_expected = TRUE;
    }

    call DebugHelper.endOfPacketPrepare();
  }

  async event void TxDataHwScheduled.handle() {
    // schedule event
    // TODO what should be the exact tx data time out? -> 8ms after slot start for now
    call EventEmitter.scheduleEvent(TSCH_EVENT_TX_FAILED, TSCH_DELAY_SHORT, 8000);
  }

  async event void PhyTx.transmitDone(plain154_txframe_t *frame, error_t result) {
    bool radio_irq_expected;
    call DebugHelper.startOfPhyIrq();

    atomic {
      radio_irq_expected = context->flags.radio_irq_expected;
      // ensure only one frame is received
      context->flags.radio_irq_expected = FALSE;
      context->radioDataEndTs = call PhyRx.getNow();
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

  async event void TxDataSuccess.handle() {
    uint8_t slottype;
    bool send_ack;
    message_t* msg;
    plain154_metadata_t* meta;

    atomic {
      slottype = context->slottype;
      context->num_transmissions += 1;
      msg = context->frame;
    }
    meta = call Metadata.getMetadata(msg);
    meta->transmissions = context->num_transmissions;

    switch (slottype) {
      case TSCH_SLOT_TYPE_ADVERTISEMENT:
        T_LOG_SLOT_STATE("TxDataSuccess [ADV]!\n");

        // NOTE no ACKs for advertisements
        call AdvQueue.dequeue();  // remove successfully transmitted frame from queue
        atomic {
          context->flags.success = TRUE;
          context->flags.confirm_beacon = TRUE;
        }
        call EventEmitter.scheduleEvent(TSCH_EVENT_CLEANUP_ADV, TSCH_DELAY_IMMEDIATE, 0);
        break;

      case TSCH_SLOT_TYPE_SHARED:
      case TSCH_SLOT_TYPE_TX:
        // TODO should a timestamp be recorded?
        atomic send_ack = call Frame.isAckRequested( call Frame.getHeader(context->frame) );

        if (send_ack == TRUE) {
          // We are still in PhyRx INT; to get out we have to schedule the next state properly
          call EventEmitter.scheduleEvent(TSCH_EVENT_PREPARE_RXACK, TSCH_DELAY_SHORT, (call EventEmitter.getReferenceToNowDt()) + 150);
          T_LOG_SLOT_STATE("TxDataSuccess: TX w ACK\n");
          //call EventEmitter.scheduleEvent(TSCH_EVENT_PREPARE_RXACK, TSCH_DELAY_IMMEDIATE, 0);
        }
        else {
          call EventEmitter.scheduleEvent(TSCH_EVENT_CLEANUP_TX, TSCH_DELAY_IMMEDIATE, 0);
          T_LOG_SLOT_STATE("TxDataSuccess: TX w/o ACK\n");
          atomic {
            context->flags.success = TRUE;
            context->flags.confirm_data = TRUE;
            context->num_transmissions = 99;
            //call TxQueue.dequeue();  // TODO: search for correct frame to remove! Doesn't have to be first frame!
            if (call TxLinkedList.remove(context->frame) == FALSE)
              T_LOG_ERROR("Msg not found in queue for removing!\n");
          }
        }
        break;

      default:
        T_LOG_ERROR("TxDataSuccess: Unhandled slot type 0x%x\n", slottype);
        atomic context->flags.internal_error = TRUE;
        call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT, TSCH_DELAY_IMMEDIATE, 0);
        return;
    }
  }

  async event void RxAckPrepare.handle() {
    uint32_t macTsRxAckDelay;
    uint32_t radioDataEndTs;
    int ret;

    atomic {
      radioDataEndTs = context->radioDataEndTs;
      macTsRxAckDelay = context->tmpl->macTsRxAckDelay;
    }

    ret = call PhyRx.enableRx(radioDataEndTs, TSSM_SYMBOLS_FROM_US(macTsRxAckDelay));

    if (ret != SUCCESS)
      call EventEmitter.scheduleEvent(TSCH_EVENT_RX_FAILED, TSCH_DELAY_IMMEDIATE, 0);
    else
      call EventEmitter.scheduleEvent(TSCH_EVENT_RXACK, TSCH_DELAY_IMMEDIATE, 0);

  }

  async event void PhyRx.enableRxDone() {
    ;
  }


  async event void PhyOff.offDone() {
    ;
  }

  async event void RxAckHwScheduled.handle() {
    uint32_t maxRxAckDelay;
    //uint32_t macTsTxOffset;
    //uint32_t macTsMaxTx;
    uint32_t macTsTxAckDelay;
    //uint32_t macTsAckWait;
    uint32_t macTsMaxAck;
    atomic {
      //macTsTxOffset = context->tmpl->macTsTxOffset;
      //macTsMaxTx = context->tmpl->macTsMaxTx;
      macTsTxAckDelay = context->tmpl->macTsTxAckDelay;
      //macTsAckWait = context->tmpl->macTsAckWait;
      macTsMaxAck = context->tmpl->macTsMaxAck;
      context->flags.radio_irq_expected = TRUE;
    }

    //maxRxAckDelay =  macTsTxOffset + macTsMaxTx + macTsTxAckDelay + macTsMaxAck;
    maxRxAckDelay =  macTsTxAckDelay + macTsMaxAck;

    //call EventEmitter.scheduleEvent(TSCH_EVENT_RX_FAILED, TSCH_DELAY_SHORT, maxRxAckDelay);
    call EventEmitter.scheduleEvent(TSCH_EVENT_RX_FAILED, TSCH_DELAY_SHORT,
                                   (call EventEmitter.getReferenceToNowDt()) + maxRxAckDelay);
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
      context->ack = frame;

      // ensure only one frame is received
      context->flags.radio_irq_expected = FALSE;
    }

    call EventEmitter.cancelEvent();

    call EventEmitter.emit(TSCH_EVENT_RX_SUCCESS);

    call DebugHelper.endOfPhyIrq();

    // TODO: Frame is returned although it is later still processed. Should be changed in future
    return frame;

  }

  bool processAck(plain154_header_t *ackHeader) {
    typeHIE_t hie;
    plain154_address_t peerAddress;
    bool extendedPeerAddress = FALSE;
    bool decodedPeerAddress = FALSE;
    //uint8_t dstAddrMode;
    int16_t correction;
    bool ack;

    if (call Frame.getSrcAddrMode(ackHeader) == PLAIN154_ADDR_EXTENDED)
      extendedPeerAddress = TRUE;
    if (TKNTSCH_SUCCESS == (call Frame.getSrcAddr(ackHeader, &peerAddress)))
      decodedPeerAddress = TRUE;

    if (! call Frame.isIEListPresent(ackHeader)) {
      T_LOG_WARN("ERROR: ACK had no IEs!\n");
      return FALSE;
    }
    if (TKNTSCH_SUCCESS != call TknTschInformationElement.presentHIEs(ackHeader, &hie)) {
      T_LOG_ERROR("ERROR: ACK HIE parsing failed!\n");
      return FALSE;
    }
    if (! hie.correctionIEpresent) {
      T_LOG_WARN("ERROR: ACK had no time correction IE!\n");
      return FALSE;
    }
    if ( TKNTSCH_SUCCESS != call TknTschInformationElement.parseTimeCorrection( hie.correctionIEfrom, &ack, &correction)) {
      T_LOG_ERROR("ACK IE parsing failed!\n");
      return FALSE;
    }

    atomic {
    #ifndef TKN_TSCH_DISABLE_TIME_CORRECTION_ACKS
      if ( decodedPeerAddress && extendedPeerAddress &&
           (context->link->macLinkOptions & PLAIN154E_LINK_OPTION_TIMEKEEPING ) &&
           (memcmp((void *) &context->macpib->timeParentAddress, (void *) &peerAddress, sizeof(plain154_address_t)) == 0 )) {
        context->time_correction = -correction;
      } else {
        T_LOG_INFO("Ignoring ACK HIE time correction!\n");
        context->time_correction = 0;
      }
    #else
      context->time_correction = 0;
    #endif
    }
    return ack;
  }

  async event void RxAckSuccess.handle() {
    plain154_header_t *ackHeader;
    plain154_header_t *frameHeader;
    plain154_address_t ackAddress;
    plain154_address_t frameAddress;
    bool ackSuccess = TRUE;

    T_LOG_SLOT_STATE("RxAckSuccess");

    atomic {
      ackHeader = call Frame.getHeader(context->ack);
      frameHeader = call Frame.getHeader(context->frame);
    }

    // Check if this is the ACK that we are waiting for

    // not the same addressing modes
    if ( (call Frame.getSrcAddrMode(frameHeader)) != (call Frame.getDstAddrMode(ackHeader)) )
      ackSuccess = FALSE;

    // same addr mode, check addr themselves
    if (ackSuccess && (call Frame.getSrcAddr(frameHeader, &frameAddress) != TKNTSCH_SUCCESS))
      ackSuccess = FALSE;

    if (ackSuccess && (call Frame.getDstAddr(ackHeader, &ackAddress) != TKNTSCH_SUCCESS))
      ackSuccess = FALSE;

    if (ackSuccess) {
      uint8_t addrMode = call Frame.getDstAddrMode(ackHeader);
      if (PLAIN154_ADDR_EXTENDED == addrMode) {
        if (memcmp((uint8_t *) &frameAddress, (uint8_t *) &ackAddress, 8) != 0)
          ackSuccess = FALSE;
      } else if (PLAIN154_ADDR_SHORT == addrMode) {
        if (memcmp((uint8_t *) &frameAddress, (uint8_t *) &ackAddress, 2) != 0)
          ackSuccess = FALSE;
      } else {
        ackSuccess = FALSE;
      }
    }

    if (ackSuccess && (call Frame.getDSN(ackHeader) != call Frame.getDSN(frameHeader))) {
      ackSuccess = FALSE;
    }

    if (ackSuccess)
      ackSuccess = processAck(ackHeader);
    atomic {
      if (ackSuccess == TRUE) {  // ACK was successfully decoded and no NACK
        context->flags.success = TRUE;
        if (context->slottype == TSCH_SLOT_TYPE_SHARED) {
          if (call TxLinkedList.remove(context->frame) == FALSE)
            T_LOG_ERROR("Msg not found in queue for removing!\n");
        } else {
          if (call TxLinkedList.remove(context->frame) == FALSE)
            T_LOG_ERROR("Msg not found in queue for removing!\n");
        }
        context->num_transmissions = 99;
        context->flags.confirm_data = TRUE;
        T_LOG_SLOT_STATE("\n");
      } else {
        T_LOG_INFO(" (NACK)\n");
      }
    }

    // Reset backoff scheme
    // either if one shared slot transmission is successful or the queues emtpy
    if (ackSuccess) {
      atomic {
        if ((context->slottype == TSCH_SLOT_TYPE_SHARED) ||
           ((context->slottype != TSCH_SLOT_TYPE_SHARED) && ((call TxQueue.size() == 0) && (call AdvQueue.size() == 0)))) {
          context->macBE = context->macpib->macMinBE;
          context->numBackoffSlots = INVALID_BACKOFF;
        }
      }
    }

    call EventEmitter.scheduleEvent(TSCH_EVENT_CLEANUP_TX, TSCH_DELAY_SHORT, (call EventEmitter.getReferenceToNowDt()) + 150);
  }

  async event void TxDataFail.handle() {
    // TODO log error

    uint8_t slottype, max_retransmissions;

    atomic {
      slottype = context->slottype;
      max_retransmissions = context->macpib->macMaxFrameRetries;

      // deny the IRQ
      context->flags.radio_irq_expected = FALSE;
    }
    switch (slottype) {
      case TSCH_SLOT_TYPE_ADVERTISEMENT:
        T_LOG_RXTX_STATE("TxDataFail: ADV!\n");

        atomic context->flags.confirm_beacon = TRUE;
        call EventEmitter.scheduleEvent(TSCH_EVENT_CLEANUP_ADV, TSCH_DELAY_IMMEDIATE, 0);
        break;

      case TSCH_SLOT_TYPE_SHARED:
        // TODO check retransmit behavior
        // TODO calculate CSMA backoff
        atomic {
          if ((context->num_transmissions - 1) >= max_retransmissions) {
            T_LOG_RXTX_STATE("TxDataFail: Shared TX -> final!\n");
            context->flags.confirm_data = TRUE;
            context->num_transmissions = 99;
            if (call TxLinkedList.remove(context->frame) == FALSE)
              T_LOG_ERROR("Msg not found in queue for removing!\n");
          }
          else {
            T_LOG_RXTX_STATE("TxDataFail: Shared TX!\n");
            // TODO plan retransmission
          }
        }
        call EventEmitter.scheduleEvent(TSCH_EVENT_CLEANUP_TX, TSCH_DELAY_IMMEDIATE, 0);
        break;

      case TSCH_SLOT_TYPE_TX:
        T_LOG_RXTX_STATE("TxDataFail: TX!\n");
        atomic {
          if ((context->num_transmissions - 1) >= max_retransmissions) {
            T_LOG_RXTX_STATE("TxDataFail: Ded. TX -> final!\n");
            context->flags.confirm_data = TRUE;
            context->num_transmissions = 99;
            // Find the correct frame and remove it from queue (not necessary the first frame)
            if (call TxLinkedList.remove(context->frame) == FALSE)
              T_LOG_ERROR("Msg not found in queue for removing!\n");
          }
        }
        call EventEmitter.scheduleEvent(TSCH_EVENT_CLEANUP_TX, TSCH_DELAY_IMMEDIATE, 0);
        break;

      default:
        T_LOG_ERROR("TxDataFail: Unhandled slot type 0x%x\n", slottype);
        atomic context->flags.internal_error = TRUE;
        call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT, TSCH_DELAY_IMMEDIATE, 0);
        return;
    }
  }

  async event void RxAckFail.handle() {
    uint8_t maxBE;
    uint8_t slottype, max_retransmissions;

    atomic {
      maxBE = context->macpib->macMaxBE;
      context->macBE = context->macBE < maxBE ? context->macBE + 1 : maxBE;
      slottype = context->slottype;
      max_retransmissions = context->macpib->macMaxFrameRetries;
    }

    switch (slottype) {
      case TSCH_SLOT_TYPE_SHARED:
        atomic {
          if ((context->num_transmissions - 1) >= max_retransmissions) {
            T_LOG_RXTX_STATE("RxAckFail: Shared TX -> final!\n");
            context->flags.confirm_data = TRUE;
            context->num_transmissions = 99;
            //call TxQueue.dequeue();
            if (call TxLinkedList.remove(context->frame) == FALSE)
              T_LOG_ERROR("Msg not found in queue for removing!\n");
          }
          else {
            T_LOG_RXTX_STATE("RxAckFail: Shared TX!\n");
            // TODO plan retransmission
          }
        }
        call EventEmitter.scheduleEvent(TSCH_EVENT_CLEANUP_TX, TSCH_DELAY_IMMEDIATE, 0);
        break;

      case TSCH_SLOT_TYPE_TX:
        //T_LOG_ERROR("ALERT: ACK for plain TX slots is not yet implemented!\n");
        T_LOG_RXTX_STATE("RxAckFail: TX!\n");
        if ((context->num_transmissions - 1) == max_retransmissions) {
          T_LOG_RXTX_STATE("RxAckFail: Ded. TX -> final!\n");
          atomic {
            context->flags.confirm_data = TRUE;
            context->num_transmissions = 99;
            //call TxQueue.dequeue();
            if (call TxLinkedList.remove(context->frame) == FALSE)
              T_LOG_ERROR("Msg not found in queue for removing!\n");
          }
        }
        call EventEmitter.scheduleEvent(TSCH_EVENT_CLEANUP_TX, TSCH_DELAY_IMMEDIATE, 0);
        break;

      default:
        T_LOG_ERROR("RxAckFail: Unhandled slot type 0x%x\n", slottype);
        atomic context->flags.internal_error = TRUE;
        call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT, TSCH_DELAY_IMMEDIATE, 0);
        return;
    }

    call EventEmitter.scheduleEvent(TSCH_EVENT_CLEANUP_TX, TSCH_DELAY_IMMEDIATE, 0);
  }

  async event void CleanupSlotAdv.handle() {
    //LOG_SLOT_STATE("Cleaning up after advertisement slot.\n");

    // TODO any cleanup necessary after advertisements?

    // schedule event
    call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT, TSCH_DELAY_IMMEDIATE, 0);
  }

  async event void CleanupSlotTx.handle() {
    //LOG_SLOT_STATE("Cleaning up after TX slot.\n");

    // TODO any cleanup necessary after TX?

    // schedule event
    call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT, TSCH_DELAY_IMMEDIATE, 0);
  }

}
