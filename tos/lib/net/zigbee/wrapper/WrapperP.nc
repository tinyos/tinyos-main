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
 * $Date: 2009-09-18 16:41:20 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author: Ricardo Severino <rars@isep.ipp.pt>
 * ========================================================================
 */

module WrapperP
{
  uses {
    interface MLME_START;
    interface MLME_SET;
    interface MLME_GET;

    interface MLME_ASSOCIATE;
    interface MLME_DISASSOCIATE;

    interface MLME_BEACON_NOTIFY;
    interface MLME_GTS;

    interface MLME_ORPHAN;

    interface MLME_SYNC;
    interface MLME_SYNC_LOSS;

    interface MLME_RESET;

    interface MLME_SCAN;

    //MCPS
    interface MCPS_DATA;
    interface MCPS_PURGE;

    interface IEEE154Frame;
    interface IEEE154BeaconFrame;
    interface Pool<message_t> as MessagePool;
    interface Packet;
  }

  provides
  {
    interface OPENZB_MLME_RESET;
    interface OPENZB_MLME_START;

    interface OPENZB_MLME_GET;
    interface OPENZB_MLME_SET;

    interface OPENZB_MLME_BEACON_NOTIFY;
    interface OPENZB_MLME_GTS;

    interface OPENZB_MLME_ASSOCIATE;
    interface OPENZB_MLME_DISASSOCIATE;

    interface OPENZB_MLME_ORPHAN;
    interface OPENZB_MLME_SYNC;
    interface OPENZB_MLME_SYNC_LOSS;
    interface OPENZB_MLME_SCAN;

    interface OPENZB_MCPS_DATA;
  }

}
implementation
{

  /* ----------------------- MLME-RESET ----------------------- */

  command error_t OPENZB_MLME_RESET.request(uint8_t set_default_PIB)
  {
    return call MLME_RESET.request(set_default_PIB != 0);
  }

  event void MLME_RESET.confirm(ieee154_status_t status)
  {
    signal OPENZB_MLME_RESET.confirm(status);
  }

  /* ----------------------- MLME-ASSOCIATE ----------------------- */

  command error_t OPENZB_MLME_ASSOCIATE.request(uint8_t LogicalChannel,uint8_t CoordAddrMode,
      uint16_t CoordPANId,uint32_t CoordAddress[],uint8_t CapabilityInformation,bool securityenable)
  {
    ieee154_CapabilityInformation_t capabilityInformation;
    ieee154_address_t coordAddress;

    if (securityenable)
      return IEEE154_UNSUPPORTED_SECURITY;
    memcpy(&coordAddress, CoordAddress, 8);
    *((uint8_t*) &capabilityInformation) = CapabilityInformation; // TODO: check
    return call MLME_ASSOCIATE.request  (
                          LogicalChannel,
                          0, // ChannelPage
                          CoordAddrMode,
                          CoordPANId,
                          coordAddress,
                          capabilityInformation,
                          NULL //security
                        );
  }

  event void MLME_ASSOCIATE.confirm    (
      uint16_t AssocShortAddress,
      uint8_t status,
      ieee154_security_t *security
      )
  {
    signal OPENZB_MLME_ASSOCIATE.confirm(AssocShortAddress, status);
  }

  command error_t OPENZB_MLME_ASSOCIATE.response(uint32_t DeviceAddress[], 
      uint16_t AssocShortAddress, uint8_t status, bool securityenable)
  {
    uint64_t deviceAddress;

    if (securityenable)
      return IEEE154_UNSUPPORTED_SECURITY;
    memcpy(&deviceAddress, DeviceAddress, 8);
    return call MLME_ASSOCIATE.response  (
                          deviceAddress,
                          AssocShortAddress,
                          status,
                          NULL //security
                        );
  }

  event void MLME_ASSOCIATE.indication (
      uint64_t DeviceAddress,
      ieee154_CapabilityInformation_t CapabilityInformation,
      ieee154_security_t *security
      )
  {
    uint32_t deviceAddress[2];
    uint8_t capabilityInformation = *((uint8_t*) &CapabilityInformation);
    memcpy(&DeviceAddress, deviceAddress, 8);
    signal OPENZB_MLME_ASSOCIATE.indication(
                          deviceAddress,
                          capabilityInformation,
                          FALSE, // SecurityUse
                          0 //ACLEntry
        );
  }

  /* ----------------------- MLME-DISASSOCIATE ----------------------- */

  command error_t OPENZB_MLME_DISASSOCIATE.request(uint32_t DeviceAddress[], 
      uint8_t disassociate_reason, bool securityenable)
  {
    // DeviceAddress is an extended address, c.f. Tab. 37 in 802.15.4-2003 
    uint16_t panID = call MLME_GET.macPANId();
    ieee154_address_t deviceAddress;
    memcpy(&deviceAddress, DeviceAddress, 8);
    return call MLME_DISASSOCIATE.request(
                          ADDR_MODE_EXTENDED_ADDRESS, // DeviceAddrMode,
                          panID,
                          deviceAddress,
                          disassociate_reason,
                          FALSE, // TxIndirect,
                          NULL // security
                        );

  }

  event void MLME_DISASSOCIATE.indication (
      uint64_t DeviceAddress,
      ieee154_disassociation_reason_t DisassociateReason,
      ieee154_security_t *security
      )
  {
    uint32_t deviceAddress[2];
    memcpy(&DeviceAddress, deviceAddress, 8);
    signal OPENZB_MLME_DISASSOCIATE.indication(
        deviceAddress, DisassociateReason, 0, 0);
  }


  event void MLME_DISASSOCIATE.confirm    (
      ieee154_status_t status,
      uint8_t DeviceAddrMode,
      uint16_t DevicePANID,
      ieee154_address_t DeviceAddress
      )
  {
    signal OPENZB_MLME_DISASSOCIATE.confirm(status);
  }

  /* ----------------------- MLME-START ----------------------- */

  command error_t OPENZB_MLME_START.request(uint32_t PANId, uint8_t LogicalChannel, 
      uint8_t beacon_order, uint8_t superframe_order,bool pan_coodinator,
      bool BatteryLifeExtension,bool CoordRealignment,bool securityenable,
      uint32_t StartTime)
  {
    if (securityenable)
      return IEEE154_UNSUPPORTED_SECURITY;
    return call MLME_START.request (
                          PANId,
                          LogicalChannel,
                          0, // ChannelPage,
                          StartTime,
                          beacon_order,
                          superframe_order,
                          pan_coodinator,
                          BatteryLifeExtension,
                          CoordRealignment,
                          NULL, // coordRealignSecurity
                          NULL  // beaconSecurity
        );
  }

  event void MLME_START.confirm    (
      ieee154_status_t status)
  {
    signal OPENZB_MLME_START.confirm(status);
  }

  /* ----------------------- MLME-SYNC ----------------------- */

  command error_t OPENZB_MLME_SYNC.request(uint8_t logical_channel,uint8_t track_beacon)
  {
    return call MLME_SYNC.request(logical_channel, 0, // ChannelPage
                               track_beacon);
  }


  event void MLME_SYNC_LOSS.indication (
      ieee154_status_t lossReason,
      uint16_t PANId,
      uint8_t LogicalChannel,
      uint8_t ChannelPage,
      ieee154_security_t *security
      )
  {
    signal OPENZB_MLME_SYNC_LOSS.indication(lossReason);
  }

  /* ----------------------- MLME-SCAN ----------------------- */

  enum {
    NUM_ENERGY_DETECT_LIST_ENTRIES = 16,
    NUM_PANDESCRIPTOR_LIST_ENTRIES = 16,
  };

  bool isScanBusy = FALSE;
  int8_t m_EnergyDetectList[NUM_ENERGY_DETECT_LIST_ENTRIES];
  ieee154_PANDescriptor_t m_PANDescriptorList[NUM_PANDESCRIPTOR_LIST_ENTRIES];

  command error_t OPENZB_MLME_SCAN.request(uint8_t ScanType, uint32_t ScanChannels, uint8_t ScanDuration)
  {
    if (isScanBusy)
      return IEEE154_TRANSACTION_OVERFLOW;
    isScanBusy = TRUE;
    return call MLME_SCAN.request  (
                          ScanType,
                          ScanChannels,
                          ScanDuration,
                          0, // ChannelPage,
                          NUM_ENERGY_DETECT_LIST_ENTRIES, // EnergyDetectListNumEntries,
                          m_EnergyDetectList, // EnergyDetectList,
                          NUM_PANDESCRIPTOR_LIST_ENTRIES, // PANDescriptorListNumEntries,
                          m_PANDescriptorList, // PANDescriptorList,
                          NULL //security
                        );
  }

  event void MLME_SCAN.confirm    (
      ieee154_status_t status,
      uint8_t ScanType,
      uint8_t ChannelPage,
      uint32_t UnscannedChannels,
      uint8_t EnergyDetectNumResults,
      int8_t* EnergyDetectList,
      uint8_t PANDescriptorListNumResults,
      ieee154_PANDescriptor_t* PANDescriptorList
      )
  {
    uint8_t i;
    uint8_t numResults = (ScanType == ED_SCAN) ? EnergyDetectNumResults : PANDescriptorListNumResults;
    SCAN_PANDescriptor pDescriptor[PANDescriptorListNumResults];
    
    isScanBusy = FALSE;
    for (i=0; i<PANDescriptorListNumResults; i++) {
      pDescriptor[i].CoordPANId = PANDescriptorList[i].CoordPANId;
      pDescriptor[i].CoordAddress = PANDescriptorList[i].CoordAddress.shortAddress;
      pDescriptor[i].LogicalChannel = PANDescriptorList[i].LogicalChannel;
      memcpy(&pDescriptor[i].SuperframeSpec, &PANDescriptorList[i].SuperframeSpec, 2);
      pDescriptor[i].lqi = PANDescriptorList[i].LinkQuality;
    }
    signal OPENZB_MLME_SCAN.confirm(status, ScanType, 
         UnscannedChannels, numResults, (uint8_t*) EnergyDetectList, pDescriptor);
  }

  /* ----------------------- MLME-BEACON-NOTIFY ----------------------- */

  enum {
    MAX_NUM_PENDING_ADDRESSES = 10,
  };

  void convertPANDescriptor(ieee154_PANDescriptor_t* PANDescriptorTKN154, PANDescriptor *PANDescriptorOPENZB)
  {
    PANDescriptorOPENZB->CoordAddrMode = PANDescriptorTKN154->CoordAddrMode;
    PANDescriptorOPENZB->CoordPANId = PANDescriptorTKN154->CoordPANId;
    memcpy(&PANDescriptorOPENZB->CoordAddress0, &PANDescriptorTKN154->CoordAddress, 4);
    memcpy(&PANDescriptorOPENZB->CoordAddress1, ((uint8_t*) &PANDescriptorTKN154->CoordAddress) + 4, 4);
    PANDescriptorOPENZB->LogicalChannel = PANDescriptorTKN154->LogicalChannel;
    memcpy(&PANDescriptorOPENZB->SuperframeSpec, &PANDescriptorTKN154->SuperframeSpec, 2);
    PANDescriptorOPENZB->GTSPermit = PANDescriptorTKN154->GTSPermit;
    PANDescriptorOPENZB->LinkQuality = PANDescriptorTKN154->LinkQuality;
    PANDescriptorOPENZB->TimeStamp = PANDescriptorTKN154->TimeStamp;
    PANDescriptorOPENZB->SecurityUse = 0;
    PANDescriptorOPENZB->ACLEntry = 0;
    PANDescriptorOPENZB->SecurityFailure = FALSE;
  }

  event message_t* MLME_BEACON_NOTIFY.indication ( message_t *beaconFrame )
  {
    uint8_t sdu[call IEEE154BeaconFrame.getBeaconPayloadLength(beaconFrame)];
    uint8_t sduLength = call IEEE154BeaconFrame.getBeaconPayloadLength(beaconFrame);
    uint8_t BSN = call IEEE154BeaconFrame.getBSN(beaconFrame);
    ieee154_PANDescriptor_t PANDescriptorTKN154;
    PANDescriptor PANDescriptorOPENZB; 
    uint8_t PenAddrSpec;
    ieee154_address_t buffer[MAX_NUM_PENDING_ADDRESSES];

    call IEEE154BeaconFrame.getPendAddr(beaconFrame, ADDR_MODE_SHORT_ADDRESS, buffer, MAX_NUM_PENDING_ADDRESSES);
    call IEEE154BeaconFrame.getPendAddrSpec(beaconFrame, &PenAddrSpec);
    memcpy(sdu, call IEEE154BeaconFrame.getBeaconPayload(beaconFrame), sduLength);
    call IEEE154BeaconFrame.parsePANDescriptor(beaconFrame, call MLME_GET.phyCurrentChannel(), 0, &PANDescriptorTKN154);
    convertPANDescriptor(&PANDescriptorTKN154, &PANDescriptorOPENZB);
    signal OPENZB_MLME_BEACON_NOTIFY.indication(
      BSN, PANDescriptorOPENZB, PenAddrSpec, 
      0, //TODO: this should be a list of device addresses -> wrong data type in the OpenZB interfaces 
      sduLength, sdu);
    return beaconFrame;
  }

  /* ----------------------- MLME-ORPHAN ----------------------- */

  event void MLME_ORPHAN.indication (
      uint64_t OrphanAddress,
      ieee154_security_t *security
      )
  {
    uint32_t orphanAddress[1]; // TODO: this should be 64 bit
    memcpy(orphanAddress, &OrphanAddress, 4);
    signal OPENZB_MLME_ORPHAN.indication(orphanAddress, 
        0, // SecurityUse, 
        0 // ACLEntry
        );
  }
  
  command error_t OPENZB_MLME_ORPHAN.response(uint32_t OrphanAddress[1],
      uint16_t ShortAddress,uint8_t AssociatedMember, uint8_t security_enabled)
  {
    uint64_t orphanAddress;
    if (security_enabled)
      return IEEE154_UNSUPPORTED_SECURITY;
    memcpy(&orphanAddress, OrphanAddress, 4); // see comment above
    return call MLME_ORPHAN.response (
                          orphanAddress,
                          ShortAddress,
                          AssociatedMember,
                          0 // security
                        );
  }

  /* ----------------------- MLME-GTS ----------------------- */

  command error_t OPENZB_MLME_GTS.request(uint8_t GTSCharacteristics, bool security_enable)
  {
    if (security_enable)
      return IEEE154_UNSUPPORTED_SECURITY;
    return call MLME_GTS.request( GTSCharacteristics, 
                          NULL //security
                        );
  }

  event void MLME_GTS.confirm    (
      uint8_t GtsCharacteristics,
      ieee154_status_t status
      )
  {
    signal OPENZB_MLME_GTS.confirm( GtsCharacteristics, status);
  }

  event void MLME_GTS.indication (
      uint16_t DeviceAddress,
      uint8_t GtsCharacteristics,
      ieee154_security_t *security
      )
  {
    signal OPENZB_MLME_GTS.indication(DeviceAddress, 
        GtsCharacteristics, 
        0, // SecurityUse
        0 // ACLEntry
        );
  }

  /* ----------------------- MCPS-DATA ----------------------- */

  command error_t OPENZB_MCPS_DATA.request(uint8_t SrcAddrMode, uint16_t SrcPANId, 
      uint32_t SrcAddr[], uint8_t DstAddrMode, uint16_t DestPANId, uint32_t DstAddr[], 
      uint8_t msduLength, uint8_t msdu[],uint8_t msduHandle, uint8_t TxOptions)
  {
    // note: in 802.15.4-2006 SrcAddr/SrcPANId is not explicitly passed anymore
    // (they are read by the MAC from the Pib)
    ieee154_status_t status;
    message_t *frame = call MessagePool.get();
    ieee154_address_t dstAddr;
    uint8_t *payload;

    if (frame == NULL)
      return IEEE154_TRANSACTION_OVERFLOW;
    payload = call Packet.getPayload(frame, msduLength);
    if (payload == NULL || msduLength > call Packet.maxPayloadLength()){
      call MessagePool.put(frame);
      return IEEE154_FRAME_TOO_LONG;
    }
    memcpy(payload, msdu, msduLength);
    memcpy(&dstAddr, DstAddr, 8);
    call IEEE154Frame.setAddressingFields(frame,
                          SrcAddrMode,
                          DstAddrMode,
                          DestPANId,
                          &dstAddr,
                          NULL //security
                          );
    status = call MCPS_DATA.request (
                          frame,
                          msduLength,
                          msduHandle,
                          TxOptions
                        ); 
    if (status != IEEE154_SUCCESS)
      call MessagePool.put(frame);
    return status;   
  }

  event void MCPS_DATA.confirm    (  
      message_t *frame,
      uint8_t msduHandle,
      ieee154_status_t status,
      uint32_t Timestamp
      )
  {
    signal OPENZB_MCPS_DATA.confirm(msduHandle, status);
  }

  event message_t* MCPS_DATA.indication ( message_t* frame )
  {
    uint16_t SrcAddrMode = call IEEE154Frame.getSrcAddrMode(frame);
    uint16_t SrcPANId;
    uint16_t DstAddrMode = call IEEE154Frame.getDstAddrMode(frame);
    uint16_t DestPANId;
    uint16_t msduLength = call IEEE154Frame.getPayloadLength(frame);
    uint16_t mpduLinkQuality = call IEEE154Frame.getLinkQuality(frame);
    uint16_t SecurityUse = 0;
    uint16_t ACLEntry = 0;
    uint8_t *payload = call IEEE154Frame.getPayload(frame);

    ieee154_address_t srcAddr;
    ieee154_address_t dstAddr;
    uint32_t SrcAddr[2];
    uint32_t DstAddr[2];
    uint8_t msdu[100];

    if (msduLength > 100)
      return frame; // TODO: msdu should probably not an array
    call IEEE154Frame.getSrcPANId(frame, &SrcPANId);
    call IEEE154Frame.getDstPANId(frame, &DestPANId);
    call IEEE154Frame.getSrcAddr(frame, &srcAddr);   
    call IEEE154Frame.getDstAddr(frame, &dstAddr);
    memcpy(msdu, payload, msduLength);
    memcpy(SrcAddr, &srcAddr, 8);
    memcpy(DstAddr, &dstAddr, 8);
    signal OPENZB_MCPS_DATA.indication(SrcAddrMode, SrcPANId, SrcAddr, 
        DstAddrMode, DestPANId, DstAddr, msduLength, 
        msdu, mpduLinkQuality,  SecurityUse,  ACLEntry);
    return frame;
  }

  /* ----------------------- MLME-SET/GET ----------------------- */

  command error_t OPENZB_MLME_GET.request(uint8_t PIBAttribute)
  {
    uint8_t v[8];
    switch (PIBAttribute)
    {
      case 0x41: { ieee154_macAssociationPermit_t x = call MLME_GET.macAssociationPermit(); memcpy(v, &x, sizeof(ieee154_macAssociationPermit_t)); break;}
      case 0x42: { ieee154_macAutoRequest_t x = call MLME_GET.macAutoRequest(); memcpy(v, &x, sizeof(ieee154_macAutoRequest_t)); break;}
      case 0x43: { ieee154_macBattLifeExt_t x = call MLME_GET.macBattLifeExt(); memcpy(v, &x, sizeof(ieee154_macBattLifeExt_t)); break;}
      case 0x4D: { ieee154_macGTSPermit_t x = call MLME_GET.macGTSPermit(); memcpy(v, &x, sizeof(ieee154_macGTSPermit_t)); break;}
      case 0x51: { ieee154_macPromiscuousMode_t x = call MLME_GET.macPromiscuousMode(); memcpy(v, &x, sizeof(ieee154_macPromiscuousMode_t)); break;}
      case 0x52: { ieee154_macRxOnWhenIdle_t x = call MLME_GET.macRxOnWhenIdle(); memcpy(v, &x, sizeof(ieee154_macRxOnWhenIdle_t)); break;}
      case 0x56: { ieee154_macAssociatedPANCoord_t x = call MLME_GET.macAssociatedPANCoord(); memcpy(v, &x, sizeof(ieee154_macAssociatedPANCoord_t)); break;}
      case 0x5D: { ieee154_macSecurityEnabled_t x = call MLME_GET.macSecurityEnabled(); memcpy(v, &x, sizeof(ieee154_macSecurityEnabled_t)); break;}
      case 0x00: { ieee154_phyCurrentChannel_t x = call MLME_GET.phyCurrentChannel(); memcpy(v, &x, sizeof(ieee154_phyCurrentChannel_t)); break;}
      case 0x02: { ieee154_phyTransmitPower_t x = call MLME_GET.phyTransmitPower(); memcpy(v, &x, sizeof(ieee154_phyTransmitPower_t)); break;}
      case 0x03: { ieee154_phyCCAMode_t x = call MLME_GET.phyCCAMode(); memcpy(v, &x, sizeof(ieee154_phyCCAMode_t)); break;}
      case 0x04: { ieee154_phyCurrentPage_t x = call MLME_GET.phyCurrentPage(); memcpy(v, &x, sizeof(ieee154_phyCurrentPage_t)); break;}
      case 0x44: { ieee154_macBattLifeExtPeriods_t x = call MLME_GET.macBattLifeExtPeriods(); memcpy(v, &x, sizeof(ieee154_macBattLifeExtPeriods_t)); break;}
      case 0x47: { ieee154_macBeaconOrder_t x = call MLME_GET.macBeaconOrder(); memcpy(v, &x, sizeof(ieee154_macBeaconOrder_t)); break;}
      case 0x49: { ieee154_macBSN_t x = call MLME_GET.macBSN(); memcpy(v, &x, sizeof(ieee154_macBSN_t)); break;}
      case 0x4C: { ieee154_macDSN_t x = call MLME_GET.macDSN(); memcpy(v, &x, sizeof(ieee154_macDSN_t)); break;}
      case 0x4E: { ieee154_macMaxCSMABackoffs_t x = call MLME_GET.macMaxCSMABackoffs(); memcpy(v, &x, sizeof(ieee154_macMaxCSMABackoffs_t)); break;}
      case 0x4F: { ieee154_macMinBE_t x = call MLME_GET.macMinBE(); memcpy(v, &x, sizeof(ieee154_macMinBE_t)); break;}
      case 0x54: { ieee154_macSuperframeOrder_t x = call MLME_GET.macSuperframeOrder(); memcpy(v, &x, sizeof(ieee154_macSuperframeOrder_t)); break;}
      case 0x57: { ieee154_macMaxBE_t x = call MLME_GET.macMaxBE(); memcpy(v, &x, sizeof(ieee154_macMaxBE_t)); break;}
      case 0x59: { ieee154_macMaxFrameRetries_t x = call MLME_GET.macMaxFrameRetries(); memcpy(v, &x, sizeof(ieee154_macMaxFrameRetries_t)); break;}
      case 0x5a: { ieee154_macResponseWaitTime_t x = call MLME_GET.macResponseWaitTime(); memcpy(v, &x, sizeof(ieee154_macResponseWaitTime_t)); break;}
      case 0x4B: { ieee154_macCoordShortAddress_t x = call MLME_GET.macCoordShortAddress(); memcpy(v, &x, sizeof(ieee154_macCoordShortAddress_t)); break;}
      case 0x50: { ieee154_macPANId_t x = call MLME_GET.macPANId(); memcpy(v, &x, sizeof(ieee154_macPANId_t)); break;}
      case 0x53: { ieee154_macShortAddress_t x = call MLME_GET.macShortAddress(); memcpy(v, &x, sizeof(ieee154_macShortAddress_t)); break;}
      case 0x55: { ieee154_macTransactionPersistenceTime_t x = call MLME_GET.macTransactionPersistenceTime(); memcpy(v, &x, sizeof(ieee154_macTransactionPersistenceTime_t)); break;}
      case 0x58: { ieee154_macMaxFrameTotalWaitTime_t x = call MLME_GET.macMaxFrameTotalWaitTime(); memcpy(v, &x, sizeof(ieee154_macMaxFrameTotalWaitTime_t)); break;}
      case 0x48: { ieee154_macBeaconTxTime_t x = call MLME_GET.macBeaconTxTime(); memcpy(v, &x, sizeof(ieee154_macBeaconTxTime_t)); break;}
      case 0x4A: { ieee154_macCoordExtendedAddress_t x = call MLME_GET.macCoordExtendedAddress(); memcpy(v, &x, sizeof(ieee154_macCoordExtendedAddress_t)); break;}
      case 0x46: // macBeaconPayloadLength is set through the IEEE154TxBeaconPayload interface
                 // fall through
      default: return IEEE154_UNSUPPORTED_ATTRIBUTE;
    }
    signal OPENZB_MLME_GET.confirm(IEEE154_SUCCESS, PIBAttribute, v);
    return IEEE154_SUCCESS;
  }

  command error_t OPENZB_MLME_SET.request(uint8_t PIBAttribute,uint8_t PIBAttributeValue[])
  {
    ieee154_status_t status;
    switch (PIBAttribute)
    {
      case 0x41: status = call MLME_SET.macAssociationPermit(*((ieee154_macAssociationPermit_t*) PIBAttributeValue)); break;
      case 0x42: status = call MLME_SET.macAutoRequest(*((ieee154_macAutoRequest_t*) PIBAttributeValue)); break;
      case 0x43: status = call MLME_SET.macBattLifeExt(*((ieee154_macBattLifeExt_t*) PIBAttributeValue)); break;
      case 0x4D: status = call MLME_SET.macGTSPermit(*((ieee154_macGTSPermit_t*) PIBAttributeValue)); break;
      case 0x52: status = call MLME_SET.macRxOnWhenIdle(*((ieee154_macRxOnWhenIdle_t*) PIBAttributeValue)); break;
      case 0x56: status = call MLME_SET.macAssociatedPANCoord(*((ieee154_macAssociatedPANCoord_t*) PIBAttributeValue)); break;
      case 0x5D: status = call MLME_SET.macSecurityEnabled(*((ieee154_macSecurityEnabled_t*) PIBAttributeValue)); break;
      case 0x00: status = call MLME_SET.phyCurrentChannel(*((ieee154_phyCurrentChannel_t*) PIBAttributeValue)); break;
      case 0x02: status = call MLME_SET.phyTransmitPower(*((ieee154_phyTransmitPower_t*) PIBAttributeValue)); break;
      case 0x03: status = call MLME_SET.phyCCAMode(*((ieee154_phyCCAMode_t*) PIBAttributeValue)); break;
      case 0x04: status = call MLME_SET.phyCurrentPage(*((ieee154_phyCurrentPage_t*) PIBAttributeValue)); break;
      case 0x44: status = call MLME_SET.macBattLifeExtPeriods(*((ieee154_macBattLifeExtPeriods_t*) PIBAttributeValue)); break;
      case 0x47: status = call MLME_SET.macBeaconOrder(*((ieee154_macBeaconOrder_t*) PIBAttributeValue)); break;
      case 0x49: status = call MLME_SET.macBSN(*((ieee154_macBSN_t*) PIBAttributeValue)); break;
      case 0x4C: status = call MLME_SET.macDSN(*((ieee154_macDSN_t*) PIBAttributeValue)); break;
      case 0x4E: status = call MLME_SET.macMaxCSMABackoffs(*((ieee154_macMaxCSMABackoffs_t*) PIBAttributeValue)); break;
      case 0x4F: status = call MLME_SET.macMinBE(*((ieee154_macMinBE_t*) PIBAttributeValue)); break;
      case 0x57: status = call MLME_SET.macMaxBE(*((ieee154_macMaxBE_t*) PIBAttributeValue)); break;
      case 0x59: status = call MLME_SET.macMaxFrameRetries(*((ieee154_macMaxFrameRetries_t*) PIBAttributeValue)); break;
      case 0x5a: status = call MLME_SET.macResponseWaitTime(*((ieee154_macResponseWaitTime_t*) PIBAttributeValue)); break;
      case 0x4B: status = call MLME_SET.macCoordShortAddress(*((ieee154_macCoordShortAddress_t*) PIBAttributeValue)); break;
      case 0x50: status = call MLME_SET.macPANId(*((ieee154_macPANId_t*) PIBAttributeValue)); break;
      case 0x53: status = call MLME_SET.macShortAddress(*((ieee154_macShortAddress_t*) PIBAttributeValue)); break;
      case 0x55: status = call MLME_SET.macTransactionPersistenceTime(*((ieee154_macTransactionPersistenceTime_t*) PIBAttributeValue)); break;
      case 0x58: status = call MLME_SET.macMaxFrameTotalWaitTime(*((ieee154_macMaxFrameTotalWaitTime_t*) PIBAttributeValue)); break;
      case 0x4A: status = call MLME_SET.macCoordExtendedAddress(*((ieee154_macCoordExtendedAddress_t*) PIBAttributeValue)); break;
      case 0x48: // macBeaconTxTime  is read-only
                 // fall through
      case 0x54: // macSuperframeOrder is read-only
                 // fall through
      case 0x46: // macBeaconPayloadLength is set through the IEEE154TxBeaconPayload interface
                 // fall through
      case 0x51: // macPromiscousMode is set through a SplitControl
                 // fall through
      default: status = IEEE154_UNSUPPORTED_ATTRIBUTE; break;
    }   
    if (status == IEEE154_SUCCESS)
      signal OPENZB_MLME_SET.confirm(status, PIBAttribute);
    return status;
  }
}




