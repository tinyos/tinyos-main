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

#include "TimerSymbol.h"

#ifndef TKNTSCH_ADV_QUEUE_SIZE
#define TKNTSCH_ADV_QUEUE_SIZE 5
#endif

#ifndef TKNTSCH_TX_QUEUE_SIZE
#define TKNTSCH_TX_QUEUE_SIZE 10
#endif

#ifndef TKNTSCH_RX_QUEUE_SIZE
#define TKNTSCH_RX_QUEUE_SIZE 10
#endif

/**
 * TODO Configuration description
 */
configuration TknTschTssmC
{
  provides {
    interface SplitControl;
    interface TknTschMcpsData as MCPS_DATA;
    interface TknTschMlmeBeacon as MLME_BEACON;
    interface TknTschMlmeBeaconNotify as MLME_BEACON_NOTIFY;
    interface TknTschEvents;
  }
  uses {
    interface Alarm<T32khz,uint32_t> as TssmAlarm;

    // PIB, Template, Schedule
    interface TknTschPib as Pib;
    interface TknTschTemplate as Template;
    interface TknTschSchedule as Schedule;
    interface Init as InitPib;
    interface Init as InitTemplate;
    interface Init as InitSchedule;
    interface TknTschMlmeSet as MLME_SET;
    interface TknTschMlmeGet as MLME_GET;

    // Radio
    interface Plain154PhyTx<TSymbol,uint32_t> as PhyTx;
    interface Plain154PhyRx<TSymbol,uint32_t> as PhyRx;
    interface Plain154PhyOff as PhyOff;
    interface Plain154PlmeSet as PLME_SET;

    interface Packet;
    interface Plain154Metadata as Metadata;
    interface TknTschFrames;
    interface TknTschInformationElement;
    interface Pool<message_t> as RxMsgPool;
    interface Pool<message_t> as AdvMsgPool;
  }
}
implementation
{
  components McuSleepC;
  components TknTschTssmP as Tssm;

  // provided interfaces
  SplitControl = Tssm;
  MCPS_DATA = Tssm;
  MLME_BEACON = Tssm;

  // used TSCH components
  Pib = Tssm;
  Schedule = Tssm;
  Template = Tssm;
  InitPib = Tssm.InitPib;
  InitTemplate = Tssm.InitTemplate;
  InitSchedule = Tssm.InitSchedule;
  MLME_SET = Tssm;
  MLME_GET = Tssm;
  PLME_SET = Tssm;
  MLME_BEACON_NOTIFY = Tssm;
  Tssm.McuPowerOverride <- McuSleepC.McuPowerOverride;
  Tssm.McuPowerState -> McuSleepC;
  TknTschEvents = Tssm;

  components Plain154FrameC;
  Tssm.Frame -> Plain154FrameC;
  Packet = Tssm.Packet;
  Metadata = Tssm.Metadata;
  TknTschFrames = Tssm.TknTschFrames;

  // internal TSSM components
  components TknTschTssmTxP as HandlerTx;
  components TknTschTssmRxP as HandlerRx;
  components new TknFsmP("TknTschTssm") as Fsm;
  components TknTschEventEmitterP as Emitter;
  Fsm.EventReceive -> Emitter.EventReceive;
  Emitter.TssmAlarm32 = TssmAlarm;
  Tssm.fsm -> Fsm.Fsm;
  Tssm.EventEmitter -> Emitter.EventEmit;
  Tssm.SlotContextTx -> HandlerTx.SlotContext;
  Tssm.PhyTx = PhyTx;
  Tssm.PhyOff = PhyOff;
  Tssm.SlotContextRx -> HandlerRx.SlotContext;
  HandlerTx.EventEmitter -> Emitter.EventEmit;
  HandlerTx.Frame -> Plain154FrameC;
  HandlerTx.PhyTx = PhyTx;
  HandlerTx.PhyRx = PhyRx;
  HandlerTx.PhyOff = PhyOff;
  HandlerTx.TknTschInformationElement = TknTschInformationElement;
  HandlerTx.TknTschFrames = TknTschFrames;
  HandlerTx.Metadata = Metadata;
  HandlerTx.Packet = Packet;

  HandlerRx.EventEmitter -> Emitter.EventEmit;
  HandlerRx.PhyRx = PhyRx;
  HandlerRx.PhyTx = PhyTx;
  HandlerRx.PhyOff = PhyOff;
  HandlerRx.Frame -> Plain154FrameC;
  HandlerRx.TknTschInformationElement = TknTschInformationElement;
  HandlerRx.TknTschFrames = TknTschFrames;
  HandlerRx.Metadata = Metadata;
  HandlerRx.Packet = Packet;

  // Queues
  components new QueueC(message_t*, TKNTSCH_ADV_QUEUE_SIZE) as AdvQueue;
  HandlerTx.AdvQueue -> AdvQueue;
  Tssm.AdvQueue -> AdvQueue;
  //components new QueueC(message_t*, TKNTSCH_TX_QUEUE_SIZE) as TxQueue;
  components new LinkedListC(TKNTSCH_TX_QUEUE_SIZE) as TxQueue;
  HandlerTx.TxQueue -> TxQueue;
  HandlerTx.TxLinkedList -> TxQueue;
  Tssm.TxQueue -> TxQueue;
  components new QueueC(message_t*, TKNTSCH_RX_QUEUE_SIZE) as RxDataQueue;
  HandlerRx.RxDataQueue -> RxDataQueue;
  Tssm.RxDataQueue -> RxDataQueue;
  components new QueueC(message_t*, TKNTSCH_RX_QUEUE_SIZE) as RxBeaconQueue;
  HandlerRx.RxBeaconQueue -> RxBeaconQueue;
  Tssm.RxBeaconQueue -> RxBeaconQueue;

  // Pools
  HandlerRx.RxMsgPool = RxMsgPool;
  Tssm.RxMsgPool = RxMsgPool;
  Tssm.AdvMsgPool = AdvMsgPool;


  // debug
  components TknTschDebugHelperC;
  Tssm.DebugHelper -> TknTschDebugHelperC;
  Emitter.DebugHelper -> TknTschDebugHelperC;
  HandlerTx.DebugHelper -> TknTschDebugHelperC;
  HandlerRx.DebugHelper -> TknTschDebugHelperC;

  // generic handlers for all slot types
  Fsm.StateHandler[TKNTSCH_HANDLER_INIT]       <- Tssm.FsmInitHandler;
  Fsm.StateHandler[TKNTSCH_HANDLER_INIT_DONE]  <- Tssm.FsmInitDoneHandler;
  Fsm.StateHandler[TKNTSCH_HANDLER_IDLE]       <- Tssm.IdleHandler;
  Fsm.StateHandler[TKNTSCH_HANDLER_SLOT_START] <- Tssm.SlotStartHandler;
  Fsm.StateHandler[TKNTSCH_HANDLER_SLOT_END]   <- Tssm.SlotEndHandler;

  // TX slot handlers
  Fsm.StateHandler[TKNTSCH_HANDLER_ADV_INIT]            <- HandlerTx.InitSlotAdv;
  Fsm.StateHandler[TKNTSCH_HANDLER_TX_INIT]             <- HandlerTx.InitSlotTx;
  Fsm.StateHandler[TKNTSCH_HANDLER_TXDATA_WAIT_PREPARE] <- HandlerTx.WaitTxDataPrepare;
  Fsm.StateHandler[TKNTSCH_HANDLER_TXDATA_PREPARE]      <- HandlerTx.TxDataPrepare;
  Fsm.StateHandler[TKNTSCH_HANDLER_TXDATA_HW_SCHEDULED] <- HandlerTx.TxDataHwScheduled;
  Fsm.StateHandler[TKNTSCH_HANDLER_TXDATA_SUCCESS]      <- HandlerTx.TxDataSuccess;
  Fsm.StateHandler[TKNTSCH_HANDLER_RXACK_PREPARE]       <- HandlerTx.RxAckPrepare;
  Fsm.StateHandler[TKNTSCH_HANDLER_RXACK_HW_SCHEDULED]  <- HandlerTx.RxAckHwScheduled;
  Fsm.StateHandler[TKNTSCH_HANDLER_RXACK_SUCCESS]       <- HandlerTx.RxAckSuccess;
  Fsm.StateHandler[TKNTSCH_HANDLER_ADV_CLEANUP]         <- HandlerTx.CleanupSlotAdv;
  Fsm.StateHandler[TKNTSCH_HANDLER_TX_CLEANUP]          <- HandlerTx.CleanupSlotTx;
  Fsm.StateHandler[TKNTSCH_HANDLER_TXDATA_FAIL]         <- HandlerTx.TxDataFail;
  Fsm.StateHandler[TKNTSCH_HANDLER_RXACK_FAIL]          <- HandlerTx.RxAckFail;

  // RX slot handlers
  Fsm.StateHandler[TKNTSCH_HANDLER_RX_INIT]             <- HandlerRx.InitSlotRx;
  Fsm.StateHandler[TKNTSCH_HANDLER_RXDATA_WAIT_PREPARE] <- HandlerRx.WaitRxDataPrepare;
  Fsm.StateHandler[TKNTSCH_HANDLER_RXDATA_PREPARE]      <- HandlerRx.RxDataPrepare;
  Fsm.StateHandler[TKNTSCH_HANDLER_RXDATA_HW_SCHEDULED] <- HandlerRx.RxDataHwScheduled;
  Fsm.StateHandler[TKNTSCH_HANDLER_RXDATA_SUCCESS]      <- HandlerRx.RxDataSuccess;
  Fsm.StateHandler[TKNTSCH_HANDLER_TXACK_PREPARE]       <- HandlerRx.TxAckPrepare;
  Fsm.StateHandler[TKNTSCH_HANDLER_TXACK_HW_SCHEDULED]  <- HandlerRx.TxAckHwScheduled;
  Fsm.StateHandler[TKNTSCH_HANDLER_TXACK_SUCCESS]       <- HandlerRx.TxAckSuccess;
  Fsm.StateHandler[TKNTSCH_HANDLER_RX_CLEANUP]          <- HandlerRx.CleanupSlotRx;
  Fsm.StateHandler[TKNTSCH_HANDLER_RXDATA_FAIL]         <- HandlerRx.RxDataFail;
  Fsm.StateHandler[TKNTSCH_HANDLER_TXACK_FAIL]          <- HandlerRx.TxAckFail;
}
