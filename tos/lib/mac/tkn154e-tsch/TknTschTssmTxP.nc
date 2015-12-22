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

#ifdef NEW_PRINTF_SEMANTICS
#include "printf.h"
#else
#define printf(...)
#define printfflush()
#endif

#include "tkntsch_pib.h"
#include "tssm_utils.h"
#include "TknTschConfig.h"

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
    //printf("Initializing advertisement slot.\n");

    // schedule event
    call EventEmitter.scheduleEvent(TSCH_EVENT_INIT_ADV_DONE, TSCH_DELAY_IMMEDIATE, 0);
  }

  async event void InitSlotTx.handle() {
    // TODO use proper logging
    uint8_t slottype;

    atomic {
      slottype = context->slottype;
    }

    //if (slottype == TSCH_SLOT_TYPE_SHARED) printf("Initializing shared TX slot.\n");
    //else printf("Initializing TX slot.\n");

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
          printf("TxDataPrepare: idle adv. slot\n");
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
        // Check if backoff is in action

      case TSCH_SLOT_TYPE_TX:
        // TODO handle TX slots. falling through switch cases...
        atomic {
          queue_size = call TxQueue.size();
          // TODO search for the right TX frame matching the link
          // HACK all slots are shared for now, remove the frame after success
          //      or final retransmission failure
          msg = call TxQueue.head();
          context->frame = msg;
          meta = call Metadata.getMetadata(msg);
          context->num_transmissions = meta->transmissions;
          macTsTxOffset = context->tmpl->macTsTxOffset;
        }

        if (queue_size <= 0) {
          printf("TxDataPrepare: idle TX slot\n");
          atomic {
            context->flags.inactive_slot = TRUE;
            context->frame = NULL;
          }
          call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT, TSCH_DELAY_IMMEDIATE, 0);
          call DebugHelper.endOfPacketPrepare();
          return;
        }

        header = call Frame.getHeader(msg);
        if (context->num_transmissions == 0)
          call Frame.setDSN(header, m_dsn++);
        break;

      default:
        printf("TxDataPrepare: Unhandled slot type 0x%x\n", slottype);
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
    meta->transmissions += 1;

    switch (slottype) {
      case TSCH_SLOT_TYPE_ADVERTISEMENT:
        printf("TxDataSuccess [ADV]!\n");

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
          printf("TxDataSuccess: TX w ACK\n");
          //call EventEmitter.scheduleEvent(TSCH_EVENT_PREPARE_RXACK, TSCH_DELAY_IMMEDIATE, 0);
        }
        else {
          call EventEmitter.scheduleEvent(TSCH_EVENT_CLEANUP_TX, TSCH_DELAY_IMMEDIATE, 0);
          printf("TxDataSuccess: TX w/o ACK\n");
          atomic {
            context->flags.success = TRUE;
            context->flags.confirm_data = TRUE;
            context->num_transmissions = 99;
            call TxQueue.dequeue();  // TODO: search for correct frame to remove! Doesn't have to be first frame!
          }
        }
        break;

      default:
        printf("TxDataSuccess: Unhandled slot type 0x%x\n", slottype);
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
    uint32_t macTsTxOffset;
    uint32_t macTsMaxTx;
    uint32_t macTsTxAckDelay;
    uint32_t macTsMaxAck;

    atomic {
      macTsTxOffset = context->tmpl->macTsTxOffset;
      macTsMaxTx = context->tmpl->macTsMaxTx;
      macTsTxAckDelay = context->tmpl->macTsTxAckDelay;
      macTsMaxAck = context->tmpl->macTsMaxAck;
      context->flags.radio_irq_expected = TRUE;
    }

    maxRxAckDelay =  macTsTxOffset + macTsMaxTx + macTsTxAckDelay + macTsMaxAck;

    call EventEmitter.scheduleEvent(TSCH_EVENT_RX_FAILED, TSCH_DELAY_SHORT, maxRxAckDelay);
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
      printf("ERROR: ACK had no IEs!\n");
      return FALSE;
    }
    if (TKNTSCH_SUCCESS != call TknTschInformationElement.presentHIEs(ackHeader, &hie)) {
      printf("ERROR: ACK HIE parsing failed!\n");
      return FALSE;
    }
    if (! hie.correctionIEpresent) {
      printf("ERROR: ACK had no time correction IE!\n");
      return FALSE;
    }
    if ( TKNTSCH_SUCCESS != call TknTschInformationElement.parseTimeCorrection( hie.correctionIEfrom, &ack, &correction)) {
      printf("ACK IE parsing failed!\n");
      return FALSE;
    }

    atomic {
    #ifndef TKN_TSCH_DISABLE_TIME_CORRECTION_ACKS
      if ( decodedPeerAddress && extendedPeerAddress &&
           (context->link->macLinkOptions & PLAIN154E_LINK_OPTION_TIMEKEEPING ) &&
           (memcmp((void *) &context->macpib->timeParentAddress, (void *) &peerAddress, sizeof(plain154_address_t)) == 0 )) {
        context->time_correction = -correction;
      } else {
        printf("Ignoring ACK HIE time correction!\n");
        context->time_correction = 0;
      }
    #else
      context->time_correction = 0;
    #endif
      context->flags.success = TRUE;
    }

    return ack;
  }
  async event void RxAckSuccess.handle() {
    plain154_header_t *ackHeader;
    bool ackSuccess = FALSE;

    printf("RxAckSuccess");

    atomic ackHeader = call Frame.getHeader(context->ack);

    // TODO: Check if this is the ACK that we are waiting for
    /*
    dstAddrMode = call Frame.getSrcAddrMode(ackHeader);
    if (dstAddrMode == PLAIN154_ADDR_EXTENDED) {

    } else if (dstAddrMode == PLAIN154_ADDR_SHORT) {

    else {
      // not present!
    }
    call Frame.getDSN(ackHeader)
    call Frame.getDSN(dataHeader)
    */

    ackSuccess = processAck(ackHeader);
    if (ackSuccess == TRUE) {  // ACK was successfully decoded and no NACK
      if (context->slottype == TSCH_SLOT_TYPE_SHARED) {
        call TxQueue.dequeue();
      } else {
        // TODO: Search for the corret frame to remove from queue

      }
      atomic {
        context->num_transmissions = 99;
        context->flags.confirm_data = TRUE;
      }
      printf("\n");
    } else {
      printf(" (NACK)\n");
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

    call EventEmitter.scheduleEvent(TSCH_EVENT_CLEANUP_TX, TSCH_DELAY_SHORT, (call EventEmitter.getReferenceToNowDt()) + 250);
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
        printf("TxDataFail: ADV!\n");

        atomic context->flags.confirm_beacon = TRUE;
        call EventEmitter.scheduleEvent(TSCH_EVENT_CLEANUP_ADV, TSCH_DELAY_IMMEDIATE, 0);
        break;

      case TSCH_SLOT_TYPE_SHARED:
        // TODO check retransmit behavior
        // TODO calculate CSMA backoff
        if ((context->num_transmissions - 1) >= max_retransmissions) {
          printf("TxDataFail: Shared TX -> final!\n");
          atomic {
            context->flags.confirm_data = TRUE;
            context->num_transmissions = 99;
            call TxQueue.dequeue();
          }
        }
        else {
          printf("TxDataFail: Shared TX!\n");
          // TODO plan retransmission
        }
        call EventEmitter.scheduleEvent(TSCH_EVENT_CLEANUP_TX, TSCH_DELAY_IMMEDIATE, 0);
        break;

      case TSCH_SLOT_TYPE_TX:
        printf("TxDataFail: TX!\n");
        if ((context->num_transmissions - 1) >= max_retransmissions) {
          printf("TxDataFail: Ded. TX -> final!\n");
          atomic {
            context->flags.confirm_data = TRUE;
            context->num_transmissions = 99;
            //TODO: FIX THIS: Find the correct frame and remove it from queue (not necessary the first frame)
            call TxQueue.dequeue();
          }
        }
        call EventEmitter.scheduleEvent(TSCH_EVENT_CLEANUP_TX, TSCH_DELAY_IMMEDIATE, 0);
        break;

      default:
        printf("TxDataFail: Unhandled slot type 0x%x\n", slottype);
        atomic context->flags.internal_error = TRUE;
        call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT, TSCH_DELAY_IMMEDIATE, 0);
        return;
    }
  }

  async event void RxAckFail.handle() {
    uint8_t maxBE;
    uint8_t slottype, max_retransmissions;
    maxBE = context->macpib->macMaxBE;

    atomic {
      context->macBE = context->macBE < maxBE ? context->macBE + 1 : maxBE;
      slottype = context->slottype;
      max_retransmissions = context->macpib->macMaxFrameRetries;
    }

    switch (slottype) {
      case TSCH_SLOT_TYPE_SHARED:
        if ((context->num_transmissions - 1) >= max_retransmissions) {
          printf("RxAckFail: Shared TX -> final!\n");
          atomic {
            context->flags.confirm_data = TRUE;
            context->num_transmissions = 99;
            call TxQueue.dequeue();
          }
        }
        else {
          printf("RxAckFail: Shared TX!\n");
          // TODO plan retransmission
        }
        call EventEmitter.scheduleEvent(TSCH_EVENT_CLEANUP_TX, TSCH_DELAY_IMMEDIATE, 0);
        break;

      case TSCH_SLOT_TYPE_TX:
        printf("ALERT: ACK for plain TX slots is not yet implemented!\n");
        /*printf("RxAckFail: TX!\n");
        if ((context->num_transmissions - 1) == max_retransmissions) {
          printf("RxAckFail: Ded. TX -> final!\n");
          atomic {
            context->flags.confirm_data = TRUE;
            context->num_transmissions = 99;
            //TODO: FIX THIS: Find the correct frame and remove it from queue (not necessary the first frame)
            call TxQueue.dequeue();
          }
        }
        call EventEmitter.scheduleEvent(TSCH_EVENT_CLEANUP_TX, TSCH_DELAY_IMMEDIATE, 0);*/
        break;

      default:
        printf("RxAckFail: Unhandled slot type 0x%x\n", slottype);
        atomic context->flags.internal_error = TRUE;
        call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT, TSCH_DELAY_IMMEDIATE, 0);
        return;
    }

    call EventEmitter.scheduleEvent(TSCH_EVENT_CLEANUP_TX, TSCH_DELAY_IMMEDIATE, 0);
  }

  async event void CleanupSlotAdv.handle() {
    //printf("Cleaning up after advertisement slot.\n");

    // TODO any cleanup necessary after advertisements?

    // schedule event
    call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT, TSCH_DELAY_IMMEDIATE, 0);
  }

  async event void CleanupSlotTx.handle() {
    //printf("Cleaning up after TX slot.\n");

    // TODO any cleanup necessary after TX?

    // schedule event
    call EventEmitter.scheduleEvent(TSCH_EVENT_END_SLOT, TSCH_DELAY_IMMEDIATE, 0);
  }

}
