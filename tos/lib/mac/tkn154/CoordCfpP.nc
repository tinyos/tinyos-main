/*
 * Copyright (c) 2010, CISTER/ISEP - Polytechnic Institute of Porto
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
 * 
 * 
 * 
 * @author Ricardo Severino <rars@isep.ipp.pt>
 * @author Stefano Tennina <sota@isep.ipp.pt>
 * ========================================================================
 */

#include "TKN154_MAC.h"
#include "GTS.h"

module CoordCfpP
{
  provides {
    interface Init;
    interface WriteBeaconField as GtsInfoWrite;
    interface FrameTx as CfpTx;
    interface Purge;
    interface FrameRx;
    interface Notify<bool> as GtsSpecUpdated;
    interface MLME_GTS;
  } uses {
    interface TransferableResource as RadioToken;
    interface Alarm<TSymbolIEEE802154,uint32_t> as CfpSlotAlarm;
    interface Alarm<TSymbolIEEE802154,uint32_t> as CfpEndAlarm;
    interface SuperframeStructure as OutgoingSF; 
    interface RadioTx;
    interface RadioRx;
    interface RadioOff;
    interface MLME_GET;
    interface MLME_SET;
    interface FrameRx as GtsRequestRx;
    interface IEEE154Frame as Frame;
  }
} 
implementation
{
  uint8_t m_slotNumber;
  uint8_t m_gtsStartSlot;
  uint32_t m_numGtsSlots;
  uint32_t m_numCapSlots;
  uint32_t m_cfpSlotDuration;
  uint32_t m_cfpDurationn;
  uint32_t m_capDuration;
  norace gtsInfoEntryType m_gtsDatabase[GTS_MAX_SLOTS];
  gtsInfoEntryType m_expiredDesc;
  gtsDescriptorType m_savedDescriptor;
  gtsSlotElementType m_gtsSlotList[GTS_MAX_SLOTS];    //maps messages in the GTS buffer to each gts slot
  uint8_t m_gtsDescriptorCount;
  uint8_t m_gtsDirections;
  uint8_t m_gts_schedule[IEEE154_aNumSuperframeSlots]; //the GTS schedule that relates a slot with the corresponding GTS slot number
  uint8_t m_gtsSlotNumber;
  gtsBufferType m_gtsSendBuffer;
  gtsSlotElementType *gtsTXSlotListPtr;
  uint8_t m_currentTxGts;
  uint8_t m_reqPending;
  uint8_t m_beaconCounter;
  task void startCoordGtsSend();
  task void removeGtsDescTask();
  task void gtsExpirationManagementTask();
  task void signalGtsTrasmitDoneTask();
  error_t m_txResult;
  ieee154_txframe_t *m_transmitedFrame;

  uint8_t computeExpirationTime (ieee154_macBeaconOrder_t BO) 
  {
    uint8_t expon;
    uint8_t gtsExpirationTime;
    if (BO < 9) {
      expon=8-BO;
      if (expon == 0)
        gtsExpirationTime=2;
      else {
        expon--;
        gtsExpirationTime=2 * (2<<expon);
      }
      return gtsExpirationTime;   
    }
    else {
      gtsExpirationTime=2;
      return gtsExpirationTime;
    }  
  }

  void initAvailableGtsIndex ()
  {
    int i=0;
    atomic{
      m_gtsSendBuffer.availableGtsIndexCount=GTS_SEND_BUFFER_SIZE;
      for (i=0; i<GTS_SEND_BUFFER_SIZE; i++)
        m_gtsSendBuffer.availableGtsIndex[i]=i;
    }
    return;
  }

  void initGtsSlotList ()
  {
    int i=0;
    for (i=0; i<7; i++) {
      m_gtsSlotList[i].elementCount=0x00;
      m_gtsSlotList[i].elementIn=0x00;
      m_gtsSlotList[i].elementOut=0x00;
    }
  }

  void initGtsDatabase ()
  {
    //initialization of the GTS database
    uint8_t i;
    atomic for (i=0 ; i < GTS_MAX_SLOTS ; i++) {
      m_gtsDatabase[i].gtsId=0x00;
      m_gtsDatabase[i].startingSlot=0x00;
      m_gtsDatabase[i].length=0x00;
      m_gtsDatabase[i].direction=0x00;
      m_gtsDatabase[i].devAddress=0x0000;
    }
    atomic for (i=0 ; i < IEEE154_aNumSuperframeSlots ; i++)
      m_gts_schedule[i]=0xFF;
  }

  uint8_t GtsSetSpecification(uint8_t gtsDescriptorCount, uint8_t gtsPermit)
  {
    return (  gtsDescriptorCount  | (gtsPermit << 7) );  
  }

  uint8_t GtsSetDescriptor(uint8_t GtsStartingSlot, uint8_t GtsLength)
  {
    //part of the descriptor list
    return ( GtsStartingSlot | (GtsLength << 4) );
  }

  uint8_t GtsSetCharacteristics(uint8_t gtsLength, uint8_t gtsDirection, uint8_t characteristicType)
  {
    return ( (gtsLength << 0) | (gtsDirection << 4) | (characteristicType << 5));
  }  

  uint8_t GtsGetReqType(uint8_t gtsCharacteristics)
  {
    if ( (gtsCharacteristics & 0x20) == 0x20)
      return GTS_ALOC_REQ;
    else
      return GTS_DEALOC_REQ;
  } 

  uint8_t GtsGetLength(uint8_t gtsCharacteristics)
  {
    return (gtsCharacteristics &  0xF);
  }

  bool GtsGetDirection(uint8_t gtsCharacteristics)
  {
    if ( (gtsCharacteristics & 0x10) == 0x10)
      return GTS_RX_DIRECTION;
    else
      return GTS_TX_DIRECTION;
  }  

  gts_op_status_t removeGtsFromPAN (uint8_t gtsLength,  uint8_t direction, uint16_t address)
  {
    uint8_t i;
    atomic{
      //search for the slot
      for (i=0; i<GTS_MAX_SLOTS; i++) {
        if (m_gtsDatabase[i].devAddress == address && 
            m_gtsDatabase[i].direction == direction && m_gtsDatabase[i].gtsId > 0) {
          m_gtsDatabase[i].startingSlot=0; //set starting slot to 0
          signal GtsSpecUpdated.notify(TRUE);
          return GTS_OP_SUCCESS;
        }
      }
      return GTS_OP_FAILED;
    }
  }

  gts_op_status_t removeGts (uint8_t gtsLength,  uint8_t direction, uint16_t address)
  {
    uint8_t i;
    uint8_t removedLength=0;
    uint8_t removedSSlot=0;
    uint8_t removedGtsId=0;
    uint8_t slotFound=0;
    //search for the slot
    for (i=0; i<GTS_MAX_SLOTS; i++) {
      if (m_gtsDatabase[i].devAddress == address && 
          m_gtsDatabase[i].direction == direction && m_gtsDatabase[i].gtsId > 0) {
        removedLength=m_gtsDatabase[i].length;
        removedSSlot=m_gtsDatabase[i].startingSlot;
        removedGtsId=m_gtsDatabase[i].gtsId;
        m_gtsDatabase[i].gtsId=0;
        m_gtsDatabase[i].startingSlot=0;
        m_gtsDatabase[i].length=0;
        m_gtsDatabase[i].direction=0;
        m_gtsDatabase[i].devAddress=0;
        m_gtsDatabase[i].expiration=0;
        slotFound=1;
      }
    }
    if (slotFound) { //adjust table
      if (m_gtsDescriptorCount > 1 && removedGtsId < m_gtsDescriptorCount) {
        for (i=removedGtsId-1; i<m_gtsDescriptorCount-1; i++) {
          m_gtsDatabase[i].gtsId=m_gtsDatabase[i+1].gtsId-1;
          m_gtsDatabase[i].startingSlot=m_gtsDatabase[i+1].startingSlot+removedLength;
          m_gtsDatabase[i].length=m_gtsDatabase[i+1].length;
          m_gtsDatabase[i].direction=m_gtsDatabase[i+1].direction;
          m_gtsDatabase[i].devAddress=m_gtsDatabase[i+1].devAddress;
          m_gtsDatabase[i].expiration=m_gtsDatabase[i+1].expiration;
        }
        m_gtsDatabase[m_gtsDescriptorCount-1].gtsId=0;
        m_gtsDatabase[m_gtsDescriptorCount-1].startingSlot=0;
        m_gtsDatabase[m_gtsDescriptorCount-1].length=0;
        m_gtsDatabase[m_gtsDescriptorCount-1].direction=0;
        m_gtsDatabase[m_gtsDescriptorCount-1].devAddress=0;
        m_gtsDatabase[m_gtsDescriptorCount-1].expiration=0;
      }
      m_gtsDescriptorCount--; 
      //rearrange gts schedule
      for (i=removedSSlot+removedLength; i>=m_gtsStartSlot; i--) {
        m_gts_schedule[i]=m_gts_schedule[i-removedLength]-1;
        if (m_gts_schedule[i] > 16)
          m_gts_schedule[i]=255;
      }
      m_gtsStartSlot=m_gtsStartSlot+removedLength; 
      signal GtsSpecUpdated.notify(TRUE);
      m_reqPending=0;
      return GTS_OP_SUCCESS;
    }
    else { //failed ot remove
      m_reqPending=0;
      return GTS_OP_FAILED;
    }
  }

  gts_op_status_t addGts (uint8_t gtsLength,  uint8_t direction, uint16_t address)
  {
    uint8_t i;
    if (m_gtsDescriptorCount >= GTS_MAX_SLOTS) {
      m_reqPending=0;
      return GTS_OP_FAILED;
    }
    //check if the address already exists in the GTS list
    for (i=0 ; i < GTS_MAX_SLOTS; i++) {
      if ( m_gtsDatabase[i].devAddress == address && m_gtsDatabase[i].direction == direction && m_gtsDatabase[i].gtsId > 0) {
        m_reqPending=0;
        return GTS_OP_FAILED;
      }
    }
    m_gtsStartSlot-=gtsLength;
    m_gtsDatabase[m_gtsDescriptorCount].gtsId=m_gtsDescriptorCount+1;
    m_gtsDatabase[m_gtsDescriptorCount].startingSlot=m_gtsStartSlot;
    m_gtsDatabase[m_gtsDescriptorCount].length=gtsLength;
    m_gtsDatabase[m_gtsDescriptorCount].direction=direction;
    m_gtsDatabase[m_gtsDescriptorCount].devAddress=address;
    m_gtsDatabase[m_gtsDescriptorCount].expiration=0x00;
    for (i=m_gtsStartSlot; i<m_gtsStartSlot+gtsLength; i++)    //flll in the gts schedule
      m_gts_schedule[i] = m_gtsDescriptorCount;
    m_gtsDescriptorCount++; 
    signal GtsSpecUpdated.notify(TRUE);
    return GTS_OP_SUCCESS;
  }

  command error_t Init.init()
  {
    atomic{
      m_gtsStartSlot=16;
      m_beaconCounter=0;
      m_reqPending=0;
      initAvailableGtsIndex();
      initGtsSlotList();
      initGtsDatabase();
    }
    return SUCCESS;
  }

  command ieee154_status_t CfpTx.transmit (ieee154_txframe_t *data)
  {
    uint8_t i;
    uint8_t gtsAvailableIndex;
    uint16_t dstAddr;    
    uint8_t status=0;
    atomic{
      if (!m_gtsSendBuffer.availableGtsIndexCount){
        return IEEE154_TRANSACTION_OVERFLOW; }
      // send a frame in a GTS slot (triggered by MCPS_DATA.request())
      dstAddr=((data->header->mhr[MHR_INDEX_ADDRESS+2])) | 
        ((data->header->mhr[MHR_INDEX_ADDRESS+3]) << 8);
      for (i=0 ; i < GTS_MAX_SLOTS ; i++) { //SEARCH FOR A VALID GTS
        if ( m_gtsDatabase[i].devAddress == dstAddr && m_gtsDatabase[i].direction == GTS_RX_DIRECTION
            && m_gtsDatabase[i].gtsId != 0)
        { 
          gtsAvailableIndex=m_gtsSendBuffer.availableGtsIndex[m_gtsSendBuffer.availableGtsIndexCount];
          m_gtsSendBuffer.availableGtsIndexCount --;
          m_gtsSendBuffer.frame[gtsAvailableIndex]=data;
          m_gtsSlotList[i].elementCount ++;
          m_gtsSlotList[i].gtsFrameIndex[m_gtsSlotList[i].elementIn]=gtsAvailableIndex;
          m_gtsSlotList[i].elementIn ++; 
          status=1;
        }
      }
      if (!status)
        atomic signal CfpTx.transmitDone(data, IEEE154_INVALID_GTS);
    }
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t Purge.purge (uint8_t msduHandle)
  {
    // request to purge a frame (triggered by MCPS_DATA.purge())
    return IEEE154_INVALID_HANDLE; 
  } 

  async event void RadioToken.transferredFrom (uint8_t fromClient)
  {  
    // the CFP has started, this component now owns the token -  
    atomic{
      uint16_t guardTime=call OutgoingSF.guardTime();
      m_cfpSlotDuration = (uint32_t) call OutgoingSF.sfSlotDuration();
      m_numCapSlots=(uint32_t) call OutgoingSF.numCapSlots();
      m_numGtsSlots=16-m_numCapSlots; 
      m_cfpDurationn=(uint32_t) m_numGtsSlots * m_cfpSlotDuration;
      m_capDuration=m_numCapSlots * m_cfpSlotDuration;
      m_slotNumber=(uint8_t) m_numCapSlots;
      call CfpEndAlarm.startAt(call OutgoingSF.sfStartTime(), 
          m_capDuration+m_cfpDurationn-guardTime);
      call CfpSlotAlarm.startAt(call OutgoingSF.sfStartTime(), m_capDuration);
    }
    if (m_reqPending == 2) {
      m_beaconCounter++;
      if (m_beaconCounter > IEEE154_aGTSDescPersistenceTime-1) {
        post removeGtsDescTask();
      }
    }
    post gtsExpirationManagementTask();
  } 

  async event void CfpEndAlarm.fired () 
  {
    call CfpEndAlarm.stop();
    call CfpSlotAlarm.stop();
    //Transfer token
#ifndef IEEE154_BEACON_SYNC_DISABLED
    call RadioToken.transferTo(RADIO_CLIENT_BEACONSYNCHRONIZE);
#else
    call RadioToken.transferTo(RADIO_CLIENT_BEACONTRANSMIT);
#endif
  }

  async event void CfpSlotAlarm.fired () 
  {
    m_gtsSlotNumber=m_gts_schedule[m_slotNumber]; //check schedule for the gts slot number
    if (m_gtsSlotNumber<=GTS_MAX_SLOTS ) {
      if (m_gtsDatabase[m_gtsSlotNumber].direction == GTS_RX_DIRECTION &&
          m_gtsDatabase[m_gtsSlotNumber].gtsId != 0) { 
        call RadioOff.off(); 
        atomic  if (m_gtsSlotNumber <= GTS_MAX_SLOTS )
          post startCoordGtsSend();  
      }
      else if (m_gtsDatabase[m_gtsSlotNumber].direction == GTS_TX_DIRECTION && 
          m_gtsDatabase[m_gtsSlotNumber].gtsId != 0) {
        call RadioRx.enableRx(0, 0);  
      }
    }
    if (m_slotNumber < IEEE154_aNumSuperframeSlots-1) 
      call CfpSlotAlarm.startAt(call OutgoingSF.sfStartTime(), m_cfpSlotDuration*(m_slotNumber+1));
    else {
      call CfpSlotAlarm.stop();
    }
    m_slotNumber++;
  }

  async event void RadioOff.offDone () {}


  event message_t* GtsRequestRx.received (message_t* frame)
  {
    uint8_t *payload=(uint8_t *) &frame->data;
    error_t status=0;
    ieee154_address_t srcAddress;
    uint8_t gtsCharacteristics = *(payload+1);
    atomic if (!m_reqPending) {
      m_reqPending=1;
      call Frame.getSrcAddr(frame, &srcAddress);
      if (GtsGetReqType(gtsCharacteristics) == GTS_ALOC_REQ) //allocation request
        status = addGts(GtsGetLength(gtsCharacteristics),
            GtsGetDirection(gtsCharacteristics), srcAddress.shortAddress);
      else if (GtsGetReqType(gtsCharacteristics) == GTS_DEALOC_REQ)
        status=removeGts(GtsGetLength(gtsCharacteristics),
            GtsGetDirection(gtsCharacteristics), srcAddress.shortAddress);
      if (status == 1) {
        signal MLME_GTS.indication (
            srcAddress.shortAddress,
            gtsCharacteristics,
            0);
      }
      m_reqPending=0;
    }
    return (frame);
  }

  command uint8_t GtsInfoWrite.write (uint8_t *lastBytePtr, uint8_t maxlen)
  {
    uint8_t ind=0;
    uint8_t slot;
    if (maxlen == 0)
      return 0;
    else { 
      if (m_gtsDescriptorCount) {
        m_gtsDirections=0;
        for (slot=0; slot<7;slot++) {
          if (m_gtsDatabase[slot].gtsId != 0 && m_gtsDatabase[slot].devAddress!=0x0000) {
            lastBytePtr[-ind]=GtsSetDescriptor(m_gtsDatabase[slot].startingSlot, m_gtsDatabase[slot].length);
            ind++;
            lastBytePtr[-ind]=m_gtsDatabase[slot].devAddress >> 8;
            ind++;
            lastBytePtr[-ind]=m_gtsDatabase[slot].devAddress;
            ind++;
            if ( m_gtsDatabase[slot].direction == GTS_RX_DIRECTION )
              m_gtsDirections=m_gtsDirections | (1 << slot); 
          }
        }
        lastBytePtr[-ind]=m_gtsDirections;
        ind++;
      }
      lastBytePtr[-ind]=GtsSetSpecification(m_gtsDescriptorCount, 1);      
      return ind+1;
    }
  }

  task void signalGtsTrasmitDoneTask()
  {
    atomic
    {
      signal CfpTx.transmitDone(m_transmitedFrame, m_txResult);    
      //transmitted a frame and got ack: reset slot expiration counter 
      m_gtsDatabase[m_gtsSlotNumber].expiration=0; 
    }
    //continue transmitting
    m_gtsSendBuffer.availableGtsIndexCount++;
    m_gtsSendBuffer.availableGtsIndex[m_gtsSendBuffer.availableGtsIndexCount]=
      gtsTXSlotListPtr->gtsFrameIndex[gtsTXSlotListPtr->elementOut];
    gtsTXSlotListPtr->elementCount--;
    if (gtsTXSlotListPtr->elementOut++ >= GTS_SEND_BUFFER_SIZE)
      gtsTXSlotListPtr->elementOut=0;
    if ( gtsTXSlotListPtr->elementCount > 0)
      post startCoordGtsSend();
  }

  async event void RadioTx.transmitDone (
      ieee154_txframe_t *frame, error_t result)
  {
    atomic
    {
      m_txResult=result;
      m_transmitedFrame=frame;
    }
    post signalGtsTrasmitDoneTask();
  }

  async event void RadioRx.enableRxDone(){}

  event message_t* RadioRx.received(message_t *frame)
  {
    //received a frame: reset slot expiration counter 
    atomic  m_gtsDatabase[m_gtsSlotNumber].expiration=0; 
    return signal FrameRx.received(frame);
  }

  event void RadioToken.granted()
  {
    ASSERT(0); // should never happen, because we never call RadioToken.request()
  }  

  command ieee154_status_t MLME_GTS.requestFromPAN (
      uint8_t GtsCharacteristics,
      uint16_t DeviceAddress,
      ieee154_security_t *security
      )
  { //This is used in case the Coordinator whishes to deallocate a gts
    error_t status=0;
    if (!m_reqPending) {
      m_reqPending=2;
      if (GtsGetReqType(GtsCharacteristics) == GTS_DEALOC_REQ)
        status=removeGtsFromPAN(GtsGetLength(GtsCharacteristics),
            GtsGetDirection(GtsCharacteristics), DeviceAddress);
      if (status == GTS_OP_SUCCESS) {    
        signal MLME_GTS.indication (
            DeviceAddress,
            GtsCharacteristics,
            0);  
        m_reqPending=2;
        m_savedDescriptor.gtsCharacteristics=GtsCharacteristics;
        m_savedDescriptor.devAddress=DeviceAddress;
      }
      else{
        m_reqPending=0;
      }
    }
  }

  task void startCoordGtsSend ()
  {
    atomic{
      if (m_gtsSlotNumber<=GTS_MAX_SLOTS) {
        gtsTXSlotListPtr=&m_gtsSlotList[m_gtsSlotNumber];
        m_currentTxGts=m_gtsSlotNumber;
        if (gtsTXSlotListPtr->elementCount > 0) {
          ieee154_macDSN_t dsn = call MLME_GET.macDSN();
          ieee154_txframe_t* gtsFrame = m_gtsSendBuffer.frame[gtsTXSlotListPtr->gtsFrameIndex[gtsTXSlotListPtr->elementOut]];


          gtsFrame->header->mhr[MHR_INDEX_SEQNO]=dsn;
          call MLME_SET.macDSN(dsn+1);
          call RadioTx.transmit(gtsFrame,0, 0); 
        }
      }
    }
  }

  task void removeGtsDescTask ()
  {
    atomic{
      if (removeGts(GtsGetLength(m_savedDescriptor.gtsCharacteristics),
            GtsGetDirection(m_savedDescriptor.gtsCharacteristics), m_savedDescriptor.devAddress))
      {
        m_reqPending=0;
        m_beaconCounter=0;
      }
    }
  }

  task void gtsExpirationManagementTask() {
    uint8_t desc;
    uint8_t gtsExpTime;
    //Increase expiration counters and check expiration
    gtsExpTime=computeExpirationTime(call MLME_GET.macBeaconOrder());
    for (desc=0; desc < GTS_MAX_SLOTS; desc++) {
      atomic if (m_gtsDatabase[desc].gtsId) {
        if (m_gtsDatabase[desc].expiration++ >=  gtsExpTime-1) {
          //deallocate gts
          m_reqPending=1;
          removeGts(m_gtsDatabase[desc].length,m_gtsDatabase[desc].direction,
              m_gtsDatabase[desc].devAddress);
          m_reqPending=0;
        }
      }
    }
  }

  command ieee154_status_t MLME_GTS.request (
      uint8_t GtsCharacteristics,
      ieee154_security_t *security
      ){}

  command error_t GtsSpecUpdated.enable () {return FAIL;}
  command error_t GtsSpecUpdated.disable () {return FAIL;}
  default event void GtsSpecUpdated.notify (bool val) {return;}
  default event void MLME_GTS.indication (
      uint16_t DeviceAddress,
      uint8_t GtsCharacteristics,
      ieee154_security_t *security
      ){}
  default  event void MLME_GTS.confirm (
      uint8_t GtsCharacteristics,
      ieee154_status_t  status
      ){}
}
