/*
 * Copyright (c) 2008, Technische Universitaet Berlin
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
 * - Revision -------------------------------------------------------------
 * $Revision: 1.10 $
 * $Date: 2009-10-16 12:25:46 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154_PHY.h"
#include "TKN154_MAC.h"
#include "TKN154_PIB.h"

#define IEEE154_BEACON_ENABLED_PAN FALSE

configuration TKN154NonBeaconEnabledP
{
  provides
  {
    /* MCPS-SAP */
    interface MCPS_DATA;
    interface MCPS_PURGE;
    interface Packet;

    /* MLME-SAP */
    interface MLME_ASSOCIATE;
    interface MLME_BEACON_NOTIFY;
    interface MLME_COMM_STATUS;
    interface MLME_DISASSOCIATE;
    interface MLME_GET;
    interface MLME_ORPHAN;
    interface MLME_POLL;
    interface MLME_RESET;
    interface MLME_RX_ENABLE;
    interface MLME_SCAN;
    interface MLME_SET;
    interface MLME_START;

    interface Notify<const void*> as PIBUpdate[uint8_t attributeID];
    interface IEEE154Frame;
    interface IEEE154BeaconFrame;
    interface IEEE154TxBeaconPayload;
    interface SplitControl as PromiscuousMode;
    interface Get<uint64_t> as GetLocalExtendedAddress;
    interface TimeCalc;
    interface FrameUtility;

  } uses {

    interface RadioRx;
    interface RadioTx;
    interface RadioOff;
    interface UnslottedCsmaCa;
    interface EnergyDetection;
    interface SplitControl as PhySplitControl;
    interface Set<bool> as RadioPromiscuousMode;

    interface Timer<TSymbolIEEE802154> as Timer1;
    interface Timer<TSymbolIEEE802154> as Timer2;
    interface Timer<TSymbolIEEE802154> as Timer3;
    interface Timer<TSymbolIEEE802154> as Timer4;
    interface Timer<TSymbolIEEE802154> as Timer5;

    interface LocalTime<TSymbolIEEE802154>;
    interface Random;
    interface Leds;
  }
}
implementation
{
  components DataP,
             PibP,
             RadioControlP,
             DispatchUnslottedCsmaP as DispatchP,
#if CAP_TX_QUEUE_SIZE == 1
             new NoDispatchQueueP() as DispatchQueueP,
#else
             new DispatchQueueP() as DispatchQueueP,
#endif

#ifndef IEEE154_INDIRECT_TX_DISABLED
             IndirectTxP,
             PollP,
#else
             NoIndirectTxP as IndirectTxP,
             NoPollP as PollP,
#endif

#ifndef IEEE154_SCAN_DISABLED
             ScanP,
             BeaconRequestRxP,
#else
             NoScanP as ScanP,
             NoBeaconRequestRxP as BeaconRequestRxP,
#endif

#ifndef IEEE154_ASSOCIATION_DISABLED
             AssociateP,
#else
             NoAssociateP as AssociateP,
#endif

#ifndef IEEE154_DISASSOCIATION_DISABLED
             DisassociateP,
#else
             NoDisassociateP as DisassociateP,
#endif

#ifndef IEEE154_RXENABLE_DISABLED
             RxEnableP,
#else
             NoRxEnableP as RxEnableP,
#endif


#ifndef IEEE154_PROMISCUOUS_MODE_DISABLED
             PromiscuousModeP,
#else
             NoPromiscuousModeP as PromiscuousModeP,
#endif

#ifndef IEEE154_COORD_REALIGNMENT_DISABLED
             CoordRealignmentP,
#else
             NoCoordRealignmentP as CoordRealignmentP,
#endif

             new PoolC(ieee154_txframe_t, TXFRAME_POOL_SIZE) as TxFramePoolP,
             new PoolC(ieee154_txcontrol_t, TXCONTROL_POOL_SIZE) as TxControlPoolP,
             new QueueC(ieee154_txframe_t*, CAP_TX_QUEUE_SIZE) as DispatchQueueC;

  components MainC;

  /* MCPS */
  MCPS_DATA = DataP; 
  MCPS_PURGE = DataP; 

  /* MLME */
  MLME_START = BeaconRequestRxP;
  MLME_ASSOCIATE = AssociateP;
  MLME_DISASSOCIATE = DisassociateP;
  MLME_BEACON_NOTIFY = ScanP;
  MLME_COMM_STATUS = AssociateP;
  MLME_COMM_STATUS = CoordRealignmentP;
  MLME_GET = PibP;
  MLME_ORPHAN = CoordRealignmentP;
  MLME_POLL = PollP;
  MLME_RESET = PibP;
  MLME_RX_ENABLE = RxEnableP;
  MLME_SCAN = ScanP;
  MLME_SET = PibP;
  IEEE154Frame = PibP;
  IEEE154BeaconFrame = PibP;
  IEEE154TxBeaconPayload = BeaconRequestRxP;
  PromiscuousMode = PromiscuousModeP;
  GetLocalExtendedAddress = PibP.GetLocalExtendedAddress;
  Packet = PibP; 
  TimeCalc = PibP;
  FrameUtility = PibP;

  /* ----------------------- Scanning (MLME-SCAN) ----------------------- */

  components new RadioClientC(RADIO_CLIENT_SCAN) as ScanRadioClient;
  PibP.MacReset -> ScanP;
  ScanP.MLME_GET -> PibP;
  ScanP.MLME_SET -> PibP.MLME_SET;
  ScanP.EnergyDetection = EnergyDetection;
  ScanP.RadioRx -> ScanRadioClient;
  ScanP.RadioTx -> ScanRadioClient;
  ScanP.Frame -> PibP;
  ScanP.BeaconFrame -> PibP;
  ScanP.RadioOff -> ScanRadioClient;
  ScanP.ScanTimer = Timer1;
  ScanP.TxFramePool -> TxFramePoolP;
  ScanP.TxControlPool -> TxControlPoolP;
  ScanP.RadioToken -> ScanRadioClient;
  ScanP.Leds = Leds;
  ScanP.FrameUtility -> PibP;

  /* -------------------- Responding to Active Scans  --------------------- */

  PibP.MacReset -> BeaconRequestRxP;
  BeaconRequestRxP.BeaconRequestRx -> DispatchP.FrameRx[FC1_FRAMETYPE_CMD + CMD_FRAME_BEACON_REQUEST];
  BeaconRequestRxP.BeaconRequestResponseTx -> DispatchQueueP.FrameTx[unique(CAP_TX_CLIENT)];
  BeaconRequestRxP.MLME_GET -> PibP;
  BeaconRequestRxP.MLME_SET -> PibP;
  BeaconRequestRxP.FrameUtility -> PibP;
  BeaconRequestRxP.Frame -> PibP;
  BeaconRequestRxP.SetMacPanCoordinator -> PibP.SetMacPanCoordinator;

  /* -------------------- Association (MLME-ASSOCIATE) -------------------- */

  PibP.MacReset -> AssociateP;
  AssociateP.AssociationRequestRx -> DispatchP.FrameRx[FC1_FRAMETYPE_CMD + CMD_FRAME_ASSOCIATION_REQUEST];
  AssociateP.AssociationRequestTx -> DispatchQueueP.FrameTx[unique(CAP_TX_CLIENT)];
  AssociateP.AssociationResponseExtracted -> DispatchP.FrameExtracted[FC1_FRAMETYPE_CMD + CMD_FRAME_ASSOCIATION_RESPONSE];
  AssociateP.AssociationResponseTx -> IndirectTxP.FrameTx[unique(INDIRECT_TX_CLIENT)];
  AssociateP.DataRequest -> PollP.DataRequest[ASSOCIATE_POLL_CLIENT];
  AssociateP.ResponseTimeout = Timer2;
  AssociateP.TxFramePool -> TxFramePoolP;
  AssociateP.TxControlPool -> TxControlPoolP;
  AssociateP.MLME_GET -> PibP;
  AssociateP.MLME_SET -> PibP.MLME_SET;
  AssociateP.FrameUtility -> PibP;
  AssociateP.Frame -> PibP;
  AssociateP.LocalExtendedAddress -> PibP.GetLocalExtendedAddress;

  /* --------------- Disassociation (MLME-DISASSOCIATE) --------------- */

  PibP.MacReset -> DisassociateP;
  DisassociateP.DisassociationIndirectTx -> IndirectTxP.FrameTx[unique(INDIRECT_TX_CLIENT)];
  DisassociateP.DisassociationDirectTx -> DispatchQueueP.FrameTx[unique(CAP_TX_CLIENT)];
  DisassociateP.DisassociationToCoord -> DispatchQueueP.FrameTx[unique(CAP_TX_CLIENT)];
  DisassociateP.DisassociationExtractedFromCoord -> 
    DispatchP.FrameExtracted[FC1_FRAMETYPE_CMD + CMD_FRAME_DISASSOCIATION_NOTIFICATION];
  DisassociateP.DisassociationRxFromDevice -> 
    DispatchP.FrameRx[FC1_FRAMETYPE_CMD + CMD_FRAME_DISASSOCIATION_NOTIFICATION];
  DisassociateP.TxFramePool -> TxFramePoolP;
  DisassociateP.TxControlPool -> TxControlPoolP;
  DisassociateP.MLME_GET -> PibP;
  DisassociateP.MLME_SET -> PibP;
  DisassociateP.FrameUtility -> PibP;
  DisassociateP.Frame -> PibP;
  DisassociateP.LocalExtendedAddress -> PibP.GetLocalExtendedAddress;

  /* ------------------ Data Transmission (MCPS-DATA) ------------------- */

  DataP.DeviceCapTx -> DispatchQueueP.FrameTx[unique(CAP_TX_CLIENT)];
  DataP.CoordCapTx -> DispatchQueueP.FrameTx[unique(CAP_TX_CLIENT)];
  DataP.DeviceCapRx -> PollP.DataRx;                          
  DataP.DeviceCapRx -> PromiscuousModeP.FrameRx;              
  DataP.DeviceCapRx -> DispatchP.FrameRx[FC1_FRAMETYPE_DATA]; 
  DataP.TxFramePool -> TxFramePoolP;
  DataP.IndirectTx -> IndirectTxP.FrameTx[unique(INDIRECT_TX_CLIENT)];
  DataP.FrameUtility -> PibP;
  DataP.Frame -> PibP;
  DataP.PurgeDirect -> DispatchQueueP;
  DataP.PurgeIndirect -> IndirectTxP;
  DataP.MLME_GET -> PibP;
  DataP.Packet -> PibP;
  DataP.Leds = Leds;

  /* ------------------------ Polling (MLME-POLL) ----------------------- */

  PibP.MacReset -> PollP;
  PollP.PollTx -> DispatchQueueP.FrameTx[unique(CAP_TX_CLIENT)];
  PollP.DataExtracted -> DispatchP.FrameExtracted[FC1_FRAMETYPE_DATA];
  PollP.FrameUtility -> PibP;
  PollP.TxFramePool -> TxFramePoolP;
  PollP.TxControlPool -> TxControlPoolP;
  PollP.MLME_GET -> PibP;
  PollP.LocalExtendedAddress -> PibP.GetLocalExtendedAddress;

  /* ---------------------- Indirect transmission ----------------------- */

  PibP.MacReset -> IndirectTxP;
  IndirectTxP.CoordCapTx -> DispatchQueueP.FrameTx[unique(CAP_TX_CLIENT)];
  IndirectTxP.DataRequestRx -> DispatchP.FrameRx[FC1_FRAMETYPE_CMD + CMD_FRAME_DATA_REQUEST];
  IndirectTxP.MLME_GET -> PibP;
  IndirectTxP.IEEE154Frame -> PibP;
  IndirectTxP.IndirectTxTimeout = Timer3;
  IndirectTxP.TimeCalc -> PibP;
  IndirectTxP.Leds = Leds;

  /* ---------------------------- Realignment --------------------------- */

  PibP.MacReset -> CoordRealignmentP;
  CoordRealignmentP.CoordRealignmentTx -> DispatchQueueP.FrameTx[unique(CAP_TX_CLIENT)];
  CoordRealignmentP.OrphanNotificationRx -> DispatchP.FrameRx[FC1_FRAMETYPE_CMD + CMD_FRAME_ORPHAN_NOTIFICATION];
  CoordRealignmentP.FrameUtility -> PibP;
  CoordRealignmentP.Frame -> PibP;
  CoordRealignmentP.TxFramePool -> TxFramePoolP;
  CoordRealignmentP.TxControlPool -> TxControlPoolP;
  CoordRealignmentP.MLME_GET -> PibP;
  CoordRealignmentP.LocalExtendedAddress -> PibP.GetLocalExtendedAddress;

  /* --------------------- DispatchP -------------------- */

  PibP.DispatchReset -> DispatchP;
  PibP.DispatchQueueReset -> DispatchQueueP;
  DispatchQueueP.Queue -> DispatchQueueC;
  DispatchQueueP.FrameTxCsma -> DispatchP;
  
  components new RadioClientC(unique(IEEE802154_RADIO_RESOURCE)) as DispatchRadioClient;
  PibP.DispatchReset -> DispatchP;
  DispatchP.IndirectTxWaitTimer = Timer4;
  DispatchP.RadioToken -> DispatchRadioClient;
  DispatchP.SetMacSuperframeOrder -> PibP.SetMacSuperframeOrder;
  DispatchP.IsRxEnableActive -> RxEnableP.IsRxEnableActive;
  DispatchP.RadioTokenRequested -> DispatchRadioClient;
  DispatchP.IsRadioTokenRequested -> PibP.IsRadioTokenRequested; // fan out...
  DispatchP.IsRadioTokenRequested -> PromiscuousModeP.IsRadioTokenRequested;
  DispatchP.IsRadioTokenRequested -> ScanP.IsRadioTokenRequested;
  DispatchP.GetIndirectTxFrame -> IndirectTxP;
  DispatchP.RxEnableStateChange -> RxEnableP.RxEnableStateChange;  
  DispatchP.PIBUpdateMacRxOnWhenIdle -> PibP.PIBUpdate[IEEE154_macRxOnWhenIdle];
  DispatchP.FrameUtility -> PibP;
  DispatchP.UnslottedCsmaCa -> DispatchRadioClient;
  DispatchP.RadioRx -> DispatchRadioClient;
  DispatchP.RadioOff -> DispatchRadioClient;
  DispatchP.MLME_GET -> PibP;
  DispatchP.MLME_SET -> PibP.MLME_SET;
  DispatchP.TimeCalc -> PibP;
  DispatchP.Leds = Leds;

  /* -------------------------- promiscuous mode ------------------------ */

  components new RadioClientC(RADIO_CLIENT_PROMISCUOUSMODE) as PromiscuousModeRadioClient;
  PibP.MacReset -> PromiscuousModeP;
  PromiscuousModeP.RadioToken -> PromiscuousModeRadioClient;
  PromiscuousModeP.PromiscuousRx -> PromiscuousModeRadioClient;
  PromiscuousModeP.RadioOff -> PromiscuousModeRadioClient;
  PromiscuousModeP.RadioPromiscuousMode = RadioPromiscuousMode;

  /* --------------------------- MLME-RX-ENABLE  ------------------------ */

  PibP.MacReset -> RxEnableP;
  RxEnableP.TimeCalc -> PibP.TimeCalc;
  RxEnableP.WasRxEnabled -> DispatchP.WasRxEnabled;
  RxEnableP.RxEnableTimer = Timer5;

  /* ------------------------------- PIB -------------------------------- */

  components new RadioClientC(RADIO_CLIENT_PIB) as PibRadioClient;
  PIBUpdate = PibP;
  MainC.SoftwareInit -> PibP.LocalInit;
  PibP.RadioControl = PhySplitControl;
  PibP.Random = Random; 
  PibP.PromiscuousModeGet -> PromiscuousModeP; 
  PibP.LocalTime = LocalTime;
  PibP.RadioToken -> PibRadioClient;
  PibP.RadioOff -> PibRadioClient;

  /* ------------------------- Radio Control ---------------------------- */

  RadioControlP.PhyTx = RadioTx;
  RadioControlP.PhyUnslottedCsmaCa = UnslottedCsmaCa;
  RadioControlP.PhyRx = RadioRx;
  RadioControlP.PhyRadioOff = RadioOff;
  RadioControlP.RadioPromiscuousMode -> PromiscuousModeP;
  RadioControlP.Leds = Leds;
}
