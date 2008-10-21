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
 * $Revision: 1.4 $
 * $Date: 2008-10-21 17:29:00 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154_PHY.h"
#include "TKN154_MAC.h"
#include "TKN154_PIB.h"
#include "TKN154_DEBUG.h"

configuration TKN154P
{
  provides
  {
    // MCPS-SAP
    interface MCPS_DATA;
    interface MCPS_PURGE;
    interface Packet;

    // MLME-SAP
    interface MLME_ASSOCIATE;
    interface MLME_BEACON_NOTIFY;
    interface MLME_COMM_STATUS;
    interface MLME_DISASSOCIATE;
    interface MLME_GET;
/*    interface MLME_GTS;*/
    interface MLME_ORPHAN;
    interface MLME_POLL;
    interface MLME_RESET;
    interface MLME_RX_ENABLE;
    interface MLME_SCAN;
    interface MLME_SET;
    interface MLME_START;
    interface MLME_SYNC;
    interface MLME_SYNC_LOSS;

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
    interface EnergyDetection;
    interface SplitControl as PhySplitControl;
    interface Set<bool> as RadioPromiscuousMode;

    interface Alarm<TSymbolIEEE802154,uint32_t> as Alarm1;
    interface Alarm<TSymbolIEEE802154,uint32_t> as Alarm2;
    interface Alarm<TSymbolIEEE802154,uint32_t> as Alarm3;
    interface Alarm<TSymbolIEEE802154,uint32_t> as Alarm4;
    interface Alarm<TSymbolIEEE802154,uint32_t> as Alarm5;
    interface Alarm<TSymbolIEEE802154,uint32_t> as Alarm6;
    interface Alarm<TSymbolIEEE802154,uint32_t> as Alarm7;
    interface Alarm<TSymbolIEEE802154,uint32_t> as Alarm8;
    interface Alarm<TSymbolIEEE802154,uint32_t> as Alarm9;
    interface Alarm<TSymbolIEEE802154,uint32_t> as Alarm10;
    interface Alarm<TSymbolIEEE802154,uint32_t> as Alarm11;
    interface Alarm<TSymbolIEEE802154,uint32_t> as Alarm12;

    interface Timer<TSymbolIEEE802154> as Timer1;
    interface Timer<TSymbolIEEE802154> as Timer2;
    interface Timer<TSymbolIEEE802154> as Timer3;
    interface Timer<TSymbolIEEE802154> as Timer4;
    interface Timer<TSymbolIEEE802154> as Timer5;

    interface Ieee802154Debug[uint8_t client];
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
             IndirectTxP,
             PollP,

#ifndef IEEE154_SCAN_DISABLED
             ScanP,
#else
             NoScanP as ScanP,
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

#ifndef IEEE154_BEACON_SYNC_DISABLED
             BeaconSynchronizeP,
             new CsmaQueueP() as DeviceCapQueue,
             new CsmaP(INCOMING_SUPERFRAME) as DeviceCap,
#else
             NoBeaconSynchronizeP as BeaconSynchronizeP,
             new NoCsmaQueueP() as DeviceCapQueue,
             new NoCsmaP() as DeviceCap,
#endif
             NoDeviceCfpP as DeviceCfp,

#ifndef IEEE154_BEACON_TX_DISABLED
             BeaconTransmitP,
             new CsmaQueueP() as CoordCapQueue,
             new CsmaP(OUTGOING_SUPERFRAME) as CoordCap,
#else
             NoBeaconTransmitP as BeaconTransmitP,
             new NoCsmaQueueP() as CoordCapQueue,
             new NoCsmaP() as CoordCap,
#endif
             NoCoordCfpP as CoordCfp,

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

#ifndef IEEE154_COORD_BROADCAST_DISABLED
             CoordBroadcastP,
#else
             NoCoordBroadcastP as CoordBroadcastP,
#endif

             new PoolC(ieee154_txframe_t, TXFRAME_POOL_SIZE) as TxFramePoolP,
             new PoolC(ieee154_txcontrol_t, TXCONTROL_POOL_SIZE) as TxControlPoolP,
             new QueueC(ieee154_txframe_t*, CAP_TX_QUEUE_SIZE) as DeviceCapQueueC,
             new QueueC(ieee154_txframe_t*, CAP_TX_QUEUE_SIZE) as CoordCapQueueC,
             new QueueC(ieee154_txframe_t*, CAP_TX_QUEUE_SIZE) as BroadcastQueueC;

  components MainC;

  // MCPS
  MCPS_DATA = DataP; 
  MCPS_PURGE = DataP; 

  //MLME
  MLME_START = BeaconTransmitP;
  MLME_ASSOCIATE = AssociateP;
  MLME_DISASSOCIATE = DisassociateP;
  MLME_BEACON_NOTIFY = BeaconSynchronizeP;
  MLME_BEACON_NOTIFY = ScanP;
  MLME_COMM_STATUS = AssociateP;
  MLME_COMM_STATUS = CoordRealignmentP;
  MLME_GET = PibP;
  MLME_ORPHAN = CoordRealignmentP;
/*  MLME_GTS = CfpTransmitP;*/
  MLME_POLL = PollP;
  MLME_RESET = PibP;
  MLME_RX_ENABLE = RxEnableP;
  MLME_SCAN = ScanP;
  MLME_SET = PibP;
  MLME_SYNC = BeaconSynchronizeP;
  MLME_SYNC_LOSS = BeaconSynchronizeP;
  IEEE154Frame = PibP;
  IEEE154BeaconFrame = PibP;
  PromiscuousMode = PromiscuousModeP;
  GetLocalExtendedAddress = PibP.GetLocalExtendedAddress;
  IEEE154TxBeaconPayload = BeaconTransmitP;
  Packet = PibP; 
  TimeCalc = PibP;
  FrameUtility = PibP;
  
/* ----------------------- Scanning (MLME-SCAN) ----------------------- */

  components new RadioClientC() as ScanRadioClient;
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
  ScanP.Token -> ScanRadioClient;
  ScanP.FrameUtility -> PibP;
  ScanP.Leds = Leds;

/* ----------------- Beacon Transmission (MLME-START) ----------------- */
  
  components new RadioClientC() as BeaconTxRadioClient;
  PibP.MacReset -> BeaconTransmitP;
  BeaconTransmitP.PIBUpdate[IEEE154_macAssociationPermit] -> PibP.PIBUpdate[IEEE154_macAssociationPermit];
  BeaconTransmitP.PIBUpdate[IEEE154_macGTSPermit] -> PibP.PIBUpdate[IEEE154_macGTSPermit];
  BeaconTransmitP.BeaconTxAlarm = Alarm1;
  BeaconTransmitP.BeaconPayloadUpdateTimer = Timer2;
  BeaconTransmitP.RadioOff -> BeaconTxRadioClient;
  BeaconTransmitP.IsBeaconEnabledPAN -> PibP.IsBeaconEnabledPAN;
  BeaconTransmitP.BeaconTx -> BeaconTxRadioClient;
  BeaconTransmitP.MLME_SET -> PibP.MLME_SET;
  BeaconTransmitP.MLME_GET -> PibP;
  BeaconTransmitP.SetMacSuperframeOrder -> PibP.SetMacSuperframeOrder;
  BeaconTransmitP.SetMacBeaconTxTime -> PibP.SetMacBeaconTxTime;
  BeaconTransmitP.SetMacPanCoordinator -> PibP.SetMacPanCoordinator;
  BeaconTransmitP.Token -> BeaconTxRadioClient;
  BeaconTransmitP.TokenTransferred -> BeaconTxRadioClient;
  BeaconTransmitP.TokenToBroadcast -> BeaconTxRadioClient;
  BeaconTransmitP.RealignmentBeaconEnabledTx -> CoordBroadcastP.RealignmentTx;
  BeaconTransmitP.RealignmentNonBeaconEnabledTx -> CoordCapQueue.FrameTx[unique(CAP_TX_CLIENT)];
  BeaconTransmitP.BeaconRequestRx -> CoordCap.FrameRx[FC1_FRAMETYPE_CMD + CMD_FRAME_BEACON_REQUEST];
  BeaconTransmitP.GtsInfoWrite -> CoordCfp.GtsInfoWrite;
  BeaconTransmitP.PendingAddrSpecUpdated -> IndirectTxP.PendingAddrSpecUpdated;
  BeaconTransmitP.PendingAddrWrite -> IndirectTxP.PendingAddrWrite;
  BeaconTransmitP.FrameUtility -> PibP.FrameUtility;
  BeaconTransmitP.IsTrackingBeacons -> BeaconSynchronizeP.IsTrackingBeacons;
  BeaconTransmitP.LastBeaconRxRefTime -> BeaconSynchronizeP.CapStartRefTime;
  BeaconTransmitP.LastBeaconRxTime -> BeaconSynchronizeP.CapStart;
  BeaconTransmitP.GetSetRealignmentFrame -> CoordRealignmentP;
  BeaconTransmitP.IsBroadcastReady -> CoordBroadcastP.IsBroadcastReady;
  BeaconTransmitP.TimeCalc -> PibP;
  BeaconTransmitP.Leds = Leds;
  BeaconTransmitP.Debug = Ieee802154Debug[START_CLIENT];
  BeaconTxRadioClient.TransferTo -> CoordBroadcastRadioClient.TransferFrom;

/* ------------------ Beacon Tracking (MLME-SYNC) ------------------ */

  components new RadioClientC() as SyncRadioClient;
  PibP.MacReset -> BeaconSynchronizeP;
  BeaconSynchronizeP.MLME_SET -> PibP.MLME_SET;
  BeaconSynchronizeP.MLME_GET -> PibP;
  BeaconSynchronizeP.TrackAlarm = Alarm2;
  BeaconSynchronizeP.FrameUtility -> PibP;
  BeaconSynchronizeP.FindBeacon -> DeviceCap.FindBeacon;
  BeaconSynchronizeP.FindBeacon -> CoordCap.FindBeacon;
  BeaconSynchronizeP.Frame -> PibP;
  BeaconSynchronizeP.BeaconFrame -> PibP;
  BeaconSynchronizeP.BeaconRx -> SyncRadioClient;
  BeaconSynchronizeP.RadioOff -> SyncRadioClient;
  BeaconSynchronizeP.IsBeaconEnabledPAN -> PibP.IsBeaconEnabledPAN;
  BeaconSynchronizeP.DataRequest -> PollP.DataRequest[SYNC_CLIENT];
  BeaconSynchronizeP.Token -> SyncRadioClient;
  BeaconSynchronizeP.TokenTransferred -> SyncRadioClient;
  BeaconSynchronizeP.TokenToCap -> SyncRadioClient;
  BeaconSynchronizeP.TimeCalc -> PibP;
  BeaconSynchronizeP.CoordRealignmentRx -> DeviceCap.FrameRx[FC1_FRAMETYPE_CMD + CMD_FRAME_COORDINATOR_REALIGNMENT];
  BeaconSynchronizeP.Leds = Leds;
  BeaconSynchronizeP.Debug = Ieee802154Debug[SYNC_CLIENT];
  SyncRadioClient.TransferTo -> DeviceCapRadioClient.TransferFrom;

/* -------------------- Association (MLME-ASSOCIATE) -------------------- */

  PibP.MacReset -> AssociateP;
  AssociateP.AssociationRequestRx -> CoordCap.FrameRx[FC1_FRAMETYPE_CMD + CMD_FRAME_ASSOCIATION_REQUEST];
  AssociateP.AssociationRequestTx -> DeviceCapQueue.FrameTx[unique(CAP_TX_CLIENT)];
  AssociateP.AssociationResponseExtracted -> DeviceCap.FrameExtracted[FC1_FRAMETYPE_CMD + CMD_FRAME_ASSOCIATION_RESPONSE];
  AssociateP.AssociationResponseTx -> IndirectTxP.FrameTx[unique(INDIRECT_TX_CLIENT)];
  AssociateP.DataRequest -> PollP.DataRequest[ASSOCIATE_CLIENT];
  AssociateP.ResponseTimeout = Timer3;
  AssociateP.TxFramePool -> TxFramePoolP;
  AssociateP.TxControlPool -> TxControlPoolP;
  AssociateP.MLME_GET -> PibP;
  AssociateP.MLME_SET -> PibP.MLME_SET;
  AssociateP.FrameUtility -> PibP;
  AssociateP.Frame -> PibP;
  AssociateP.LocalExtendedAddress -> PibP.GetLocalExtendedAddress;
  AssociateP.Debug = Ieee802154Debug[ASSOCIATE_CLIENT];

/* --------------- Disassociation (MLME-DISASSOCIATE) --------------- */

  PibP.MacReset -> DisassociateP;
  DisassociateP.DisassociationIndirectTx -> IndirectTxP.FrameTx[unique(INDIRECT_TX_CLIENT)];
  DisassociateP.DisassociationDirectTx -> CoordCapQueue.FrameTx[unique(CAP_TX_CLIENT)];
  DisassociateP.DisassociationToCoord -> DeviceCapQueue.FrameTx[unique(CAP_TX_CLIENT)];
  DisassociateP.DisassociationDirectRxFromCoord -> 
    DeviceCap.FrameRx[FC1_FRAMETYPE_CMD + CMD_FRAME_DISASSOCIATION_NOTIFICATION];
  DisassociateP.DisassociationExtractedFromCoord -> 
    DeviceCap.FrameExtracted[FC1_FRAMETYPE_CMD + CMD_FRAME_DISASSOCIATION_NOTIFICATION];
  DisassociateP.DisassociationRxFromDevice -> 
    CoordCap.FrameRx[FC1_FRAMETYPE_CMD + CMD_FRAME_DISASSOCIATION_NOTIFICATION];
  DisassociateP.TxFramePool -> TxFramePoolP;
  DisassociateP.TxControlPool -> TxControlPoolP;
  DisassociateP.MLME_GET -> PibP;
  DisassociateP.FrameUtility -> PibP;
  DisassociateP.Frame -> PibP;
  DisassociateP.LocalExtendedAddress -> PibP.GetLocalExtendedAddress;
  DisassociateP.Debug = Ieee802154Debug[DISASSOCIATE_CLIENT];

/* ------------------ Data Transmission (MCPS-DATA) ------------------- */

  PibP.MacReset -> DataP;
  DataP.IsSendingBeacons -> BeaconTransmitP.IsSendingBeacons;
  DataP.CoordCapRx -> CoordCap.FrameRx[FC1_FRAMETYPE_DATA]; 
  DataP.DeviceCapTx -> DeviceCapQueue.FrameTx[unique(CAP_TX_CLIENT)];
  DataP.CoordCapTx -> CoordCapQueue.FrameTx[unique(CAP_TX_CLIENT)];
  DataP.DeviceCapRx -> PollP.DataRx;        // indirect
  DataP.DeviceCapRx -> PromiscuousModeP.FrameRx;   // promiscuous
  DataP.DeviceCapRx -> DeviceCap.FrameRx[FC1_FRAMETYPE_DATA]; // broadcast
  DataP.TxFramePool -> TxFramePoolP;
  DataP.BroadcastTx -> CoordBroadcastP.BroadcastDataFrame;
  DataP.DeviceCfpTx -> DeviceCfp.CfpTx;
  DataP.IndirectTx -> IndirectTxP.FrameTx[unique(INDIRECT_TX_CLIENT)];
  DataP.FrameUtility -> PibP;
  DataP.Frame -> PibP;
  DataP.PurgeDirect -> DeviceCapQueue;
  DataP.PurgeIndirect -> IndirectTxP;
  DataP.PurgeGtsDevice -> DeviceCfp;
  DataP.PurgeGtsCoord -> CoordCfp;
  DataP.MLME_GET -> PibP;
  DataP.LocalExtendedAddress -> PibP.GetLocalExtendedAddress;
  DataP.Packet -> PibP;
  DataP.Leds = Leds;

/* ------------------------ Polling (MLME-POLL) ----------------------- */

  PibP.MacReset -> PollP;
  PollP.PollTx -> DeviceCapQueue.FrameTx[unique(CAP_TX_CLIENT)];
  PollP.DataExtracted -> DeviceCap.FrameExtracted[FC1_FRAMETYPE_DATA];
  PollP.FrameUtility -> PibP;
  PollP.TxFramePool -> TxFramePoolP;
  PollP.TxControlPool -> TxControlPoolP;
  PollP.Debug = Ieee802154Debug[POLL_CLIENT];
  PollP.MLME_GET -> PibP;
  PollP.LocalExtendedAddress -> PibP.GetLocalExtendedAddress;

/* ---------------------- Indirect transmission ----------------------- */

  PibP.MacReset -> IndirectTxP;
  IndirectTxP.CoordCapTx -> CoordCapQueue.FrameTx[unique(CAP_TX_CLIENT)];
  IndirectTxP.DataRequestRx -> CoordCap.FrameRx[FC1_FRAMETYPE_CMD + CMD_FRAME_DATA_REQUEST];
  IndirectTxP.MLME_GET -> PibP;
  IndirectTxP.FrameUtility -> PibP;
  IndirectTxP.IndirectTxTimeout = Timer4;
  IndirectTxP.TimeCalc -> PibP;
  IndirectTxP.Leds = Leds;
  IndirectTxP.Debug = Ieee802154Debug[INDIRECTTX_DEBUG_CLIENT];

/* ---------------------------- Realignment --------------------------- */

  PibP.MacReset -> CoordRealignmentP;
  CoordRealignmentP.CoordRealignmentTx -> CoordCapQueue.FrameTx[unique(CAP_TX_CLIENT)];
  CoordRealignmentP.OrphanNotificationRx -> CoordCap.FrameRx[FC1_FRAMETYPE_CMD + CMD_FRAME_ORPHAN_NOTIFICATION];
  CoordRealignmentP.FrameUtility -> PibP;
  CoordRealignmentP.Frame -> PibP;
  CoordRealignmentP.TxFramePool -> TxFramePoolP;
  CoordRealignmentP.TxControlPool -> TxControlPoolP;
  CoordRealignmentP.MLME_GET -> PibP;
  CoordRealignmentP.LocalExtendedAddress -> PibP.GetLocalExtendedAddress;

/* ---------------------------- Broadcasts ---------------------------- */

  components new RadioClientC() as CoordBroadcastRadioClient;
  PibP.MacReset -> CoordBroadcastP;
  CoordBroadcastP.TokenTransferred -> CoordBroadcastRadioClient;
  CoordBroadcastP.TokenToCap -> CoordBroadcastRadioClient;
  CoordBroadcastRadioClient.TransferTo -> CoordCapRadioClient.TransferFrom;
  CoordBroadcastP.BeaconFramePendingBit -> BeaconTransmitP.BeaconFramePendingBit;
  CoordBroadcastP.CapTransmitNow -> CoordCap.BroadcastTx;
  CoordBroadcastP.Queue -> BroadcastQueueC;
  CoordBroadcastP.Leds = Leds;

/* --------------------- CAP (incoming superframe) -------------------- */

  PibP.CapQueueReset -> DeviceCapQueue;
  DeviceCapQueue.Queue -> DeviceCapQueueC;
  DeviceCapQueue.FrameTxCsma -> DeviceCap;

  PibP.CapQueueReset -> CoordCapQueue;
  CoordCapQueue.Queue -> CoordCapQueueC;
  CoordCapQueue.FrameTxCsma -> CoordCap;
  
  components new RadioClientC() as DeviceCapRadioClient;
  PibP.CapReset -> DeviceCap;
  DeviceCap.Random = Random;
  DeviceCap.CapEndAlarm = Alarm3;
  DeviceCap.BLEAlarm = Alarm4;
  DeviceCap.IndirectTxWaitAlarm = Alarm5;
  DeviceCap.BroadcastAlarm = Alarm6;
  DeviceCap.Token -> DeviceCapRadioClient;
  DeviceCap.TokenToCfp -> DeviceCapRadioClient;
  DeviceCap.TokenTransferred -> DeviceCapRadioClient;
  DeviceCap.TokenRequested -> DeviceCapRadioClient;
  DeviceCap.IsTokenRequested -> DeviceCapRadioClient;
  DeviceCap.CapStart -> BeaconSynchronizeP.CapStart;
  DeviceCap.CapStartRefTime -> BeaconSynchronizeP.CapStartRefTime;
  DeviceCap.CapLen -> BeaconSynchronizeP.CapLen;
  DeviceCap.IsBLEActive -> BeaconSynchronizeP.IsBLEActive;
  DeviceCap.BLELen -> BeaconSynchronizeP.BLELen;
  DeviceCap.IsRxBroadcastPending -> BeaconSynchronizeP.IsRxBroadcastPending;
  DeviceCap.IsRxEnableActive -> RxEnableP.IsRxEnableActive;
  DeviceCap.RxEnableStateChange -> RxEnableP.RxEnableStateChange;  
  DeviceCap.IsTrackingBeacons -> BeaconSynchronizeP.IsTrackingBeacons;  
  DeviceCap.FrameUtility -> PibP;
  DeviceCap.RadioTx -> DeviceCapRadioClient;
  DeviceCap.RadioRx -> DeviceCapRadioClient;
  DeviceCap.RadioOff -> DeviceCapRadioClient;
  DeviceCap.IsBeaconEnabledPAN -> PibP.IsBeaconEnabledPAN;
  DeviceCap.MLME_GET -> PibP;
  DeviceCap.MLME_SET -> PibP.MLME_SET;
  DeviceCap.Debug = Ieee802154Debug[DEVICE_CAP_CLIENT];
  DeviceCap.TimeCalc -> PibP;
  DeviceCap.Leds = Leds;
  DeviceCapRadioClient.TransferTo -> DeviceCfpRadioClient.TransferFrom;

/* ---------------------- CAP (outgoing superframe) ------------------- */

  components new RadioClientC() as CoordCapRadioClient, 
             new BackupP(ieee154_cap_frame_backup_t);
  PibP.CapReset -> CoordCap;
  CoordCap.Random = Random;
  CoordCap.CapEndAlarm = Alarm7;
  CoordCap.BLEAlarm = Alarm8;
  CoordCap.Token -> CoordCapRadioClient;
  CoordCap.TokenToCfp -> CoordCapRadioClient;
  CoordCap.TokenTransferred -> CoordCapRadioClient;
  CoordCap.TokenRequested -> CoordCapRadioClient;
  CoordCap.IsTokenRequested -> CoordCapRadioClient;
  CoordCap.CapStart -> BeaconTransmitP.CapStart;
  CoordCap.CapStartRefTime -> BeaconTransmitP.CapStartRefTime;
  CoordCap.CapLen -> BeaconTransmitP.CapLen;
  CoordCap.IsBLEActive -> BeaconTransmitP.IsBLEActive;
  CoordCap.BLELen -> BeaconTransmitP.BLELen;
  CoordCap.IsRxEnableActive -> RxEnableP.IsRxEnableActive;
  CoordCap.RxEnableStateChange -> RxEnableP.RxEnableStateChange;  
  CoordCap.IsTrackingBeacons -> BeaconSynchronizeP.IsTrackingBeacons;  
  CoordCap.FrameUtility -> PibP;
  CoordCap.RadioTx -> CoordCapRadioClient;
  CoordCap.RadioRx -> CoordCapRadioClient;
  CoordCap.RadioOff -> CoordCapRadioClient;
  CoordCap.IsBeaconEnabledPAN -> PibP.IsBeaconEnabledPAN;
  CoordCap.MLME_GET -> PibP;
  CoordCap.MLME_SET -> PibP.MLME_SET;
  CoordCap.Debug = Ieee802154Debug[COORD_CAP_CLIENT];
  CoordCap.TimeCalc -> PibP;
  CoordCap.Leds = Leds;
  CoordCapRadioClient.TransferTo -> CoordCfpRadioClient.TransferFrom;
  CoordCap.FrameBackup -> BackupP;
  CoordCap.FrameRestore -> BackupP;

/* -------------------- GTS (incoming superframe) --------------------- */

  components new RadioClientC() as DeviceCfpRadioClient;
  PibP.MacReset -> DeviceCfp;
  DeviceCfp.Token -> DeviceCfpRadioClient;
  DeviceCfp.TokenTransferred -> DeviceCfpRadioClient;
  DeviceCfp.TokenRequested -> DeviceCfpRadioClient;
  DeviceCfp.TokenToBeaconSync -> DeviceCfpRadioClient;
  DeviceCfp.CapStartRefTime -> BeaconSynchronizeP.CapStartRefTime; 
  DeviceCfp.IsSendingBeacons -> BeaconTransmitP.IsSendingBeacons;
  DeviceCfp.CfpEnd -> BeaconSynchronizeP.CfpEnd; 
  DeviceCfp.GtsField -> BeaconSynchronizeP.GtsField; 
  DeviceCfp.SfSlotDuration -> BeaconSynchronizeP.SfSlotDuration; 
  DeviceCfp.FinalCapSlot -> BeaconSynchronizeP.FinalCapSlot; 
  DeviceCfp.CfpSlotAlarm = Alarm9;
  DeviceCfp.CfpEndAlarm = Alarm10;
  DeviceCfp.RadioTx -> DeviceCfpRadioClient;
  DeviceCfp.RadioRx -> DeviceCfpRadioClient;
  DeviceCfp.RadioOff -> DeviceCfpRadioClient;
  DeviceCfp.MLME_GET -> PibP;
  DeviceCfp.MLME_SET -> PibP.MLME_SET; 
  DeviceCfpRadioClient.TransferTo -> SyncRadioClient.TransferFrom;

/* -------------------- GTS (outgoing superframe) --------------------- */

  components new RadioClientC() as CoordCfpRadioClient;
  PibP.MacReset -> CoordCfp;
  CoordCfp.Token -> CoordCfpRadioClient;
  CoordCfp.TokenTransferred -> CoordCfpRadioClient;
  CoordCfp.TokenRequested -> CoordCfpRadioClient;
  CoordCfp.TokenToBeaconTransmit -> CoordCfpRadioClient;
  CoordCfp.IsTrackingBeacons -> BeaconSynchronizeP.IsTrackingBeacons;
  CoordCfp.CfpEnd -> BeaconTransmitP.CfpEnd; 
  CoordCfp.GtsField -> BeaconTransmitP.GtsField; 
  CoordCfp.SfSlotDuration -> BeaconTransmitP.SfSlotDuration; 
  CoordCfp.FinalCapSlot -> BeaconTransmitP.FinalCapSlot; 
  CoordCfp.CfpSlotAlarm = Alarm11;
  CoordCfp.CfpEndAlarm = Alarm12;
  CoordCfp.RadioTx -> CoordCfpRadioClient;
  CoordCfp.RadioRx -> CoordCfpRadioClient;
  CoordCfp.RadioOff -> CoordCfpRadioClient;
  CoordCfp.MLME_GET -> PibP;
  CoordCfp.MLME_SET -> PibP.MLME_SET;
  CoordCfpRadioClient.TransferTo -> BeaconTxRadioClient.TransferFrom;

/* -------------------------- promiscuous mode ------------------------ */

  components new RadioClientC() as PromiscuousModeRadioClient;
  PibP.MacReset -> PromiscuousModeP;
  PromiscuousModeP.Token -> PromiscuousModeRadioClient;
  PromiscuousModeP.PromiscuousRx -> PromiscuousModeRadioClient;
  PromiscuousModeP.RadioOff -> PromiscuousModeRadioClient;
  PromiscuousModeP.RadioPromiscuousMode = RadioPromiscuousMode;
  PromiscuousModeP.Debug = Ieee802154Debug[PROMISCUOUS_MODE_CLIENT];

/* --------------------------- MLME-RX-ENABLE  ------------------------ */

  PibP.MacReset -> RxEnableP;
  RxEnableP.IncomingSfStart -> BeaconSynchronizeP.CapStart;
  RxEnableP.OutgoingSfStart -> BeaconTransmitP.CapStart;
  RxEnableP.IncomingBeaconInterval -> BeaconSynchronizeP.BeaconInterval;
  RxEnableP.OutgoingBeaconInterval -> BeaconTransmitP.BeaconInterval;
  RxEnableP.IsTrackingBeacons -> BeaconSynchronizeP.IsTrackingBeacons;
  RxEnableP.IsSendingBeacons-> BeaconTransmitP.IsSendingBeacons;
  RxEnableP.IsMacPanCoordinator -> PibP.IsMacPanCoordinator;
  RxEnableP.IsBeaconEnabledPAN -> PibP.IsBeaconEnabledPAN;
  RxEnableP.TimeCalc -> PibP.TimeCalc;
  RxEnableP.WasRxEnabled -> DeviceCap.WasRxEnabled;
  RxEnableP.WasRxEnabled -> CoordCap.WasRxEnabled;
  RxEnableP.RxEnableTimer = Timer5;
  RxEnableP.Debug = Ieee802154Debug[RXENABLE_CLIENT];

/* ------------------------------- PIB -------------------------------- */

  components new RadioClientC() as PibRadioClient;
  PIBUpdate = PibP;
  MainC.SoftwareInit -> PibP.LocalInit;
  PibP.RadioControl = PhySplitControl;
  PibP.Random = Random; 
  PibP.PromiscuousModeGet -> PromiscuousModeP; 
  PibP.LocalTime = LocalTime;
  PibP.Token -> PibRadioClient;
  PibP.RadioOff -> PibRadioClient;

/* ------------------------- Radio Control ---------------------------- */

  RadioControlP.PhyTx = RadioTx;
  RadioControlP.PhyRx = RadioRx;
  RadioControlP.PhyRadioOff = RadioOff;
  RadioControlP.RadioPromiscuousMode -> PromiscuousModeP;
  RadioControlP.Leds = Leds;
  RadioControlP.Debug = Ieee802154Debug[RADIORXTX_CLIENT];
}
