/**
 * Copyright (c) 2015, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:T
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
 * @author Jasper Buesch <buesch@tkn.tu-berlin.de>
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 */

#define PLAIN154_RADIO_RESOURCE "RadioTxRx.resource"
#define RADIO_CLIENT_SCANNING unique(PLAIN154_RADIO_RESOURCE)

// Check whether the platform supports the radio interfaces
#ifndef HAS_TKNTSCH_PLATFORM_SUPPORT
#error Using TKN-TSCH without platform support!
#endif

#include "TimerSymbol.h"
#include "TknTschConfig.h"

configuration TknTschC {
  provides {
    interface TknTschMlmeReset;
    interface TknTschMlmeTschMode;
    interface TknTschMlmeScan;
    interface TknTschMlmeSyncLoss;
    interface TknTschMlmeBeacon;
    interface TknTschMlmeBeaconNotify;
    interface TknTschMlmeBeaconRequest;
    interface TknTschMlmeAssociate;
    interface TknTschMlmeDisassociate;
    interface TknTschMlmeKeepAlive;
    interface TknTschMlmeSet;
    interface TknTschMlmeGet;
    interface TknTschMlmeSetLink;
    interface TknTschMlmeSetSlotframe;
    interface TknTschMcpsData;
    interface Init as TknTschInit;
    interface Packet;
    interface Plain154PhyTx<TSymbol,uint32_t> as PhyTx;
    interface Plain154PhyRx<TSymbol,uint32_t> as PhyRx;
	//interface Plain154PhyOff as PhyOff;
    interface Plain154PlmeGet;
    interface Plain154PlmeSet;

    interface TknTschInformationElement;
    interface TknTschFrames;
    interface TknTschEvents;
  }
  uses {
    interface Pool<message_t> as RxMsgPool @safe();
    interface Pool<message_t> as AdvMsgPool @safe();
  }


} implementation {

//components TknTschTssmP;
  components TknTschP;
  components McuSleepC;

  components Plain154_Symbol32C as RadioPhy;

  Plain154PlmeGet = RadioPhy;
  Plain154PlmeSet = RadioPhy;

  PhyTx = RadioPhy;
  PhyRx = RadioPhy;
  //PhyOff = RadioPhy;

  components Ieee154AddressC;
  TknTschP.Ieee154Address -> Ieee154AddressC;
  TknTschP.TknTschMlmeSet -> TknTschPibP;

  // TODO components TknTschQueueP;
  components TknTschPibP;

  components Plain154FrameC;

  //components new QueueC(message_t*, RX_QUEUE_SIZE) as RxQueue;
  //components new PoolC(message_t, RX_QUEUE_SIZE) as RxMessagePool;
  //components new PoolC(message_t, RX_QUEUE_SIZE) as TxMessagePool;

  // Alarm/timer system still missing

  // Radio control
  /*
  RadioPhy.Plain154PhyTx<T32khz,uint32_t> -> RadioPhy;
  RadioPhy.Plain154PhyRx<T32khz,uint32_t> -> RadioPhy;
  RadioPhy.Plain154PhyOff -> RadioPhy;
  TknTschScanP.RadioChannel -> RadioPhy;
  */

  components TknTschFramesC;
  TknTschFrames = TknTschFramesC;
  TknTschFramesC.TknTschMlmeGet -> TknTschPibP;
  TknTschFramesC.TknTschPib -> TknTschPibP;

  components TknTschInformationElementC;
  TknTschInformationElement = TknTschInformationElementC;

  components Plain154MetadataC;

  components Plain154PacketC;
  Packet = Plain154PacketC;
  TknTschInit = Plain154PacketC.LocalInit;

  components new MuxAlarm32khz32C() as ScanTimer; // virtualized 32khz alarm
  TknTschScanP.ScanTimer -> ScanTimer;


  // Beacon Scanning

  components TknTschScanP;
  components new Plain154RadioClientC(RADIO_CLIENT_SCANNING) as EBScanRadioClient;

  McuSleepC.McuPowerOverride -> TknTschScanP.McuPowerOverride;
  TknTschScanP.McuPowerState -> McuSleepC.McuPowerState;
  TknTschScanP.RadioToken -> EBScanRadioClient;
// TODO shouldn't be needed:  TknTschScanP.Plain154PhyTx -> RadioPhy;
  //TknTschScanP.TknTschMlmeBeaconNotify ->
  TknTschScanP.Plain154PlmeGet -> RadioPhy;
  TknTschScanP.Plain154PlmeSet -> RadioPhy;
  TknTschScanP.TknTschMlmeGet -> TknTschPibP;
  TknTschScanP.TknTschMlmeSet -> TknTschPibP;
  TknTschMlmeScan = TknTschScanP;
  TknTschScanP.Frame -> Plain154FrameC.Plain154Frame;
  TknTschScanP.Plain154PhyOff -> RadioPhy;
  TknTschScanP.Packet -> Plain154PacketC;
  TknTschScanP.Metadata -> Plain154MetadataC;
  TknTschScanP.TknTschInformationElement -> TknTschInformationElementC;;

  //TknTschScanP.RxQueue -> RxQueue;
  //TknTschScanP.RxMessagePool -> RxMessagePool;

  TknTschScanP.PhyRx -> RadioPhy.Plain154PhyRx;


  // TSSM

  components TknTschTssmC as Tssm;
  TknTschMlmeBeacon = Tssm.MLME_BEACON;
  TknTschMcpsData = Tssm.MCPS_DATA;
  Tssm.Pib -> TknTschPibP;
  Tssm.InitPib -> TknTschPibP;
  Tssm.MLME_SET -> TknTschPibP;
  Tssm.MLME_GET -> TknTschPibP;
  Tssm.PhyTx -> RadioPhy.Plain154PhyTx;
  Tssm.PhyRx -> RadioPhy.Plain154PhyRx;
  Tssm.PhyOff -> RadioPhy.Plain154PhyOff;
  TknTschP.TssmControl -> Tssm.SplitControl;
  Tssm.Packet -> Plain154PacketC;
  Tssm.Metadata -> Plain154MetadataC;
  Tssm.TknTschFrames -> TknTschFramesC;
  Tssm.RxMsgPool = RxMsgPool;
  Tssm.AdvMsgPool = AdvMsgPool;
  Tssm.TknTschInformationElement -> TknTschInformationElementC;
  Tssm.PLME_SET -> RadioPhy;

  components TknTschEventsC;
  TknTschEvents = TknTschEventsC;
  TknTschEventsC.TknTschEventsProxy -> Tssm.TknTschEvents;

  components new MuxAlarm32khz32C() as TssmAlarm; // TODO necessary?
  Tssm.TssmAlarm -> TssmAlarm;

  components TknTschScheduleMinP as Schedule;
  Tssm.Schedule -> Schedule;
  TknTschMlmeSetLink = Schedule.TknTschMlmeSetLink;
  Tssm.InitSchedule -> Schedule;
  components new LinkedListC(macSlotframeEntry_t*, TKNTSCH_SF_POOL_SIZE) as SFQueue;
  components new LinkedListC(macLinkEntry_t*, TKNTSCH_LINK_POOL_SIZE) as LinkQueue;
  components new PoolC(macSlotframeEntry_t,TKNTSCH_SF_POOL_SIZE) as SFPool;
  components new PoolC(macLinkEntry_t,TKNTSCH_LINK_POOL_SIZE) as LinkPool;
  Schedule.SFQueue -> SFQueue;
  Schedule.SFLinkedList -> SFQueue;
  Schedule.SFCompare <- SFQueue;
  Schedule.LinkQueue -> LinkQueue;
  Schedule.LinkLinkedList -> LinkQueue;
  Schedule.LinkCompare <- LinkQueue;
  Schedule.SFPool -> SFPool;
  Schedule.LinkPool -> LinkPool;

  components TknTschTemplateMinP as Template;
  Tssm.Template -> Template;
  Tssm.InitTemplate -> Template;


  // TSCH init and fallback stuff

  TknTschInit = TknTschP.Init;
  TknTschInit = TknTschScanP.Init;
  TknTschInit = TknTschPibP;

  // TODO TknTschQueueP.TknTschQueue -> TknTschQueueP;

  // IEEE 802.15.4e-TSCH MLME interfaces
  TknTschMlmeReset = TknTschP;
  TknTschMlmeTschMode = TknTschP;
  //TknTschMlmeScan = TknTschP;
  TknTschMlmeSyncLoss = TknTschP;
  TknTschMlmeBeaconRequest = TknTschP;
  TknTschMlmeAssociate = TknTschP;
  TknTschMlmeDisassociate = TknTschP;
  TknTschMlmeKeepAlive = TknTschP;
  TknTschMlmeSet = TknTschPibP;
  TknTschMlmeGet = TknTschPibP;
  TknTschMlmeSetSlotframe = TknTschP;


  TknTschMlmeBeaconNotify = TknTschScanP.TknTschMlmeBeaconNotify;
  TknTschMlmeBeaconNotify = Tssm.MLME_BEACON_NOTIFY;
}
