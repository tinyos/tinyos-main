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

module DeviceCfpP
{
  provides {
    interface Init;
    interface FrameTx as CfpTx;
    interface Purge;
    interface FrameRx;
    interface MLME_GTS;
  } uses {
    interface TransferableResource as RadioToken;
    interface Alarm<TSymbolIEEE802154,uint32_t> as CfpSlotAlarm;
    interface Alarm<TSymbolIEEE802154,uint32_t> as CfpEndAlarm;
    interface SuperframeStructure as IncomingSF; 
    interface RadioTx;
    interface RadioRx;
    interface RadioOff;
    interface MLME_GET;
    interface MLME_SET;
    interface FrameTx as GTSrequestTx;
    interface Pool<ieee154_txframe_t> as TxFramePool;
    interface Pool<ieee154_txcontrol_t> as TxControlPool;
    interface FrameUtility;
  }
}
implementation
{
  uint8_t m_gtsReqCharacteristics;
  uint8_t m_gtsCharacteristics;
  uint16_t m_gtsSlotAddress;
  uint8_t m_gtsReqPending;
  uint8_t m_gtsBeaconCounter;
  uint8_t m_gtsField[1+1+3*7];
  gtsBufferType m_gtsSendBuffer;
  uint8_t m_slotNumber;
  uint8_t m_gtsTxStartSlot;
  uint8_t m_gtsTxEndSlot;
  uint8_t m_gtsRxStartSlot;
  uint8_t m_gtsRxEndSlot;
  uint32_t m_numGtsSlots;
  uint32_t m_numCapSlots;
  uint32_t m_cfpSlotDuration;
  uint32_t m_cfpDuration;
  uint32_t m_capDuration;
  uint8_t m_gtsTXON;
  uint8_t m_gtsRXON;
  uint8_t m_gtsSlotDir;
  uint8_t m_payload_GTS_Request[2];
  uint8_t m_GtsOnTXSlot;
  ieee154_macShortAddress_t m_myAddress;
  ieee154_txframe_t *m_frameDone;
  task void startGtsSend();
  task void signalGtsConfirmSuccessTask();
  task void signalGtsConfirmDeniedTask();
  task void signalCfpTxDone();
  task void signalGtsConfirmNoAddressTask();
  task void signalGtsIndicationTask();
  task void signalGtsConfirmNoDataTask();

  void initGtsBuffer()
  {
    int i=0;
    atomic for(i=0;i<7;i++)
    {
      m_gtsSendBuffer.gtsSendBufferCount = 0x00;
      m_gtsSendBuffer.gtsSendBufferMsgIn = 0x00;
      m_gtsSendBuffer.gtsSendBufferMsgOut = 0x00;
    }
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

  command error_t Init.init()
  {
    atomic{
      m_gtsReqPending=0;
      m_gtsBeaconCounter=0;
      m_gtsTXON=0;
      m_gtsRXON=0;
      m_GtsOnTXSlot=0;
    }
    initGtsBuffer();
    return SUCCESS;
  }

  command ieee154_status_t MLME_GTS.request  (
      uint8_t GtsCharacteristics,
      ieee154_security_t *security
      )
  {

    ieee154_status_t status = IEEE154_SUCCESS;
    ieee154_txframe_t *txFrame=0;
    ieee154_txcontrol_t *txControl=0;
    ieee154_address_t srcAddress;
    ieee154_macDSN_t dsn = call MLME_GET.macDSN();
    ieee154_address_t DeviceAddress;
    atomic m_gtsCharacteristics=GtsCharacteristics;
    if (security && security->SecurityLevel)
      status = IEEE154_UNSUPPORTED_SECURITY;
    atomic {
      m_myAddress=srcAddress.shortAddress=call MLME_GET.macShortAddress(); 
      if ( srcAddress.shortAddress==0xFFFF ||  srcAddress.shortAddress==0xFFFE) { 
        post signalGtsConfirmNoAddressTask();
        status=IEEE154_NO_SHORT_ADDRESS;
      }
      else if (!(txFrame=call TxFramePool.get()))
        status=IEEE154_TRANSACTION_OVERFLOW;
      else if (!(txControl=call TxControlPool.get())) {
        call TxFramePool.put(txFrame);
        status=IEEE154_TRANSACTION_OVERFLOW;
      } 
    }
    atomic {
      if (status==IEEE154_SUCCESS) {
        // construct the  frame
        txFrame->header=&txControl->header;
        txFrame->metadata=&txControl->metadata;
        txFrame->header->mhr[MHR_INDEX_FC1]=FC1_ACK_REQUEST | FC1_FRAMETYPE_CMD;
        txFrame->header->mhr[MHR_INDEX_FC2]=FC2_SRC_MODE_SHORT;
        txFrame->header->mhr[MHR_INDEX_SEQNO]=dsn;
        call MLME_SET.macDSN(dsn+1);
        txFrame->headerLen=call FrameUtility.writeHeader(
            txFrame->header->mhr,
            ADDR_MODE_NOT_PRESENT,
            call MLME_GET.macPANId(),
            &DeviceAddress,
            ADDR_MODE_SHORT_ADDRESS,
            call MLME_GET.macPANId(),
            &srcAddress,
            0);    
        m_payload_GTS_Request[0]=CMD_FRAME_GTS_REQUEST;
        m_payload_GTS_Request[1]=GtsCharacteristics;
        txFrame->payload=m_payload_GTS_Request;
        txFrame->payloadLen=2;
        status=call GTSrequestTx.transmit(txFrame);
        m_gtsReqCharacteristics=GtsCharacteristics;
      }
      if (status != IEEE154_SUCCESS) {
        call TxFramePool.put(txFrame);
        call TxControlPool.put(txControl);
      }
      else   
        m_gtsReqPending=1;
    }
    return status;
  }

  command ieee154_status_t CfpTx.transmit(ieee154_txframe_t *data)
  {
    atomic{
      if (m_gtsTXON==1) { //if there is a TX gts and gts mechanism is on for this device 
        // request to send a frame in a GTS slot (triggered by MCPS_DATA.request())
        gtsBufferType* gtsSendBufferPtr = &m_gtsSendBuffer;
        gtsSendBufferPtr->frame[gtsSendBufferPtr->gtsSendBufferMsgIn] = data;
        gtsSendBufferPtr->gtsSendBufferMsgIn++;
        gtsSendBufferPtr->gtsSendBufferCount++;
        if (gtsSendBufferPtr->gtsSendBufferMsgIn==GTS_SEND_BUFFER_SIZE)
          gtsSendBufferPtr->gtsSendBufferMsgIn=0;
        if (m_GtsOnTXSlot)
          post startGtsSend();
        return IEEE154_SUCCESS;
      }
      else
        return IEEE154_INVALID_GTS;
    }
  }

  command ieee154_status_t Purge.purge(uint8_t msduHandle)
  {
    // request to purge a frame (triggered by MCPS_DATA.purge())
    return IEEE154_INVALID_HANDLE; 
  } 

  async event void RadioToken.transferredFrom(uint8_t fromClient)
  { 
    // the CFP has started, this component now owns the token -  
    const uint8_t* gtsFieldPtr;
    uint8_t gtsFieldLength;
    uint8_t  GTS_FIELD_INDEX=0;
    uint8_t numGts;
    uint16_t gtsSlotAddress;
    uint8_t i, DIR_MASK;
    uint16_t guardTime=call IncomingSF.guardTime();

    m_cfpSlotDuration=(uint32_t) call IncomingSF.sfSlotDuration();
    m_numCapSlots=(uint32_t) call IncomingSF.numCapSlots();
    m_numGtsSlots=16-m_numCapSlots; 
    m_cfpDuration=(uint32_t) m_numGtsSlots * m_cfpSlotDuration;
    m_capDuration=m_numCapSlots * m_cfpSlotDuration;
    m_slotNumber=(uint8_t) m_numCapSlots-1;
    call CfpEndAlarm.startAt(call IncomingSF.sfStartTime(), 
        m_capDuration+m_cfpDuration-guardTime);

    //process gts
    gtsFieldPtr=call IncomingSF.gtsFields();
    gtsFieldLength=1 + ((call IncomingSF.numGtsSlots() > 0) ? 1 + call IncomingSF.numGtsSlots() * 3: 0);
    memcpy(m_gtsField, gtsFieldPtr, gtsFieldLength);
    numGts=(m_gtsField[0] & GTS_DESCRIPTOR_COUNT_MASK);
    m_gtsSlotDir=m_gtsField[1];
    GTS_FIELD_INDEX=2;
    m_gtsTXON=0;
    m_gtsRXON=0;
    for (i=numGts; i>0; i--) {
      gtsSlotAddress= ( m_gtsField[GTS_FIELD_INDEX] | m_gtsField[GTS_FIELD_INDEX+1] << 8 );
      DIR_MASK=(0x01 << (i-1));
      if (gtsSlotAddress == m_myAddress) {
        if ((m_gtsSlotDir & DIR_MASK) == GTS_TX_DIRECTION) {//TX gts
          m_gtsTXON=1;//gts slots on 
          m_gtsTxStartSlot=m_gtsField[GTS_FIELD_INDEX+2] & 0x0f;
          m_gtsTxEndSlot=m_gtsTxStartSlot+((m_gtsField[GTS_FIELD_INDEX+2] & 0xf0) >> 4);
          m_gtsCharacteristics=GtsSetCharacteristics(m_gtsTxEndSlot-m_gtsTxStartSlot, 0, 1);
          m_gtsSlotAddress=gtsSlotAddress;
          if (m_gtsTxStartSlot == 0) {
            m_gtsTXON=0;
            if (m_gtsReqPending == 1) {
              post signalGtsConfirmDeniedTask();
              m_gtsReqPending=0;
            }
            else {
              post signalGtsIndicationTask();
            }
          }
          if (m_gtsReqPending && m_gtsCharacteristics == m_gtsReqCharacteristics) {
            post signalGtsConfirmSuccessTask();
            m_gtsReqPending=0;
            m_gtsBeaconCounter=0;
          }
        }
        else { //RX gts
          m_gtsRXON=1;
          m_gtsRxStartSlot=m_gtsField[GTS_FIELD_INDEX+2] & 0x0f ;
          m_gtsRxEndSlot=m_gtsRxStartSlot+((m_gtsField[GTS_FIELD_INDEX+2] & 0xf0) >> 4);  
          m_gtsCharacteristics=GtsSetCharacteristics(m_gtsRxEndSlot-m_gtsRxStartSlot, 1, 1);
          m_gtsSlotAddress=gtsSlotAddress;
          if (m_gtsRxStartSlot == 0) {
            m_gtsRXON=0;
            if (m_gtsReqPending == 1) {
              post signalGtsConfirmDeniedTask();
              m_gtsReqPending=0;
            }
            else {
              post signalGtsIndicationTask();
            }
          }
          if (m_gtsReqPending && m_gtsCharacteristics == m_gtsReqCharacteristics) {
            post signalGtsConfirmSuccessTask();
            m_gtsReqPending=0;
            m_gtsBeaconCounter=0;
          }
        }
      }
      GTS_FIELD_INDEX+=3;
    }
    if (m_gtsReqPending) {
      if (m_gtsBeaconCounter++ > IEEE154_aGTSDescPersistenceTime) {
        post signalGtsConfirmNoDataTask();
        m_gtsReqPending=0;
        m_gtsBeaconCounter=0;
      }
    }
    call CfpSlotAlarm.startAt(call IncomingSF.sfStartTime(), m_capDuration);
  }

  task void signalGtsConfirmNoAddressTask()
  {
    atomic signal MLME_GTS.confirm(m_gtsCharacteristics,IEEE154_NO_SHORT_ADDRESS);     
  }

  task void signalGtsConfirmSuccessTask()
  {
    atomic signal MLME_GTS.confirm(m_gtsReqCharacteristics,IEEE154_SUCCESS);     
  }

  task void signalGtsConfirmNoDataTask()
  {
    atomic signal MLME_GTS.confirm(m_gtsReqCharacteristics,IEEE154_NO_DATA);     
  }

  task void signalGtsConfirmDeniedTask()
  {;
    atomic signal MLME_GTS.confirm(m_gtsReqCharacteristics,IEEE154_DENIED);     
  }

  task void signalGtsIndicationTask()
  {
    atomic signal MLME_GTS.indication(m_gtsSlotAddress, m_gtsCharacteristics,0);     
  }

  task void startGtsSend()
  {
    ieee154_txframe_t* gtsFrame;
    ieee154_macDSN_t dsn = call MLME_GET.macDSN();
    atomic{
      if (m_slotNumber >= m_gtsTxStartSlot && m_slotNumber <m_gtsTxEndSlot)
      {
        gtsFrame = m_gtsSendBuffer.frame[m_gtsSendBuffer.gtsSendBufferMsgOut];

        gtsFrame->header->mhr[MHR_INDEX_SEQNO]=dsn;
        call MLME_SET.macDSN(dsn+1);
        call RadioTx.transmit(gtsFrame,0, 0);  
      }
    }
  }

  task void  signalCfpTxDone()
  {
    atomic signal CfpTx.transmitDone(m_frameDone, IEEE154_SUCCESS);
  }

  async event void CfpEndAlarm.fired() 
  {
    call CfpEndAlarm.stop();
    call CfpSlotAlarm.stop();
    m_GtsOnTXSlot=0;
#ifndef IEEE154_BEACON_TX_DISABLED
    call RadioToken.transferTo(RADIO_CLIENT_BEACONTRANSMIT);
#else
    call RadioToken.transferTo(RADIO_CLIENT_BEACONSYNCHRONIZE);
#endif
  }

  async event void CfpSlotAlarm.fired() 
  {
    m_slotNumber++;
    if (m_slotNumber >= m_gtsTxStartSlot && m_slotNumber <m_gtsTxEndSlot && 
        m_gtsSendBuffer.gtsSendBufferCount > 0 ) {
      call RadioOff.off();
      m_GtsOnTXSlot=1;
      post startGtsSend();
    }   
    else if (m_slotNumber >= m_gtsRxStartSlot && m_slotNumber <m_gtsRxEndSlot) { //receive slot
      call RadioRx.enableRx(0, 0); //enable receiver
      m_GtsOnTXSlot=0;
    }  
    else {
      m_GtsOnTXSlot=0;
    }
    if (m_slotNumber < IEEE154_aNumSuperframeSlots-1) {
      call CfpSlotAlarm.startAt(call IncomingSF.sfStartTime(), m_cfpSlotDuration*(m_slotNumber+1));
    }
    else {}
  }

  async event void RadioOff.offDone() {
    post startGtsSend();
  }

  async event void RadioTx.transmitDone(ieee154_txframe_t *frame, error_t result)
  {
    atomic{
      m_gtsSendBuffer.gtsSendBufferCount--;
      m_gtsSendBuffer.gtsSendBufferMsgOut++;
      if (m_gtsSendBuffer.gtsSendBufferMsgOut == GTS_SEND_BUFFER_SIZE)
        m_gtsSendBuffer.gtsSendBufferMsgOut=0;
      m_frameDone=frame;
      post signalCfpTxDone();
      if (m_gtsSendBuffer.gtsSendBufferCount > 0)
        post startGtsSend();
    }
  }

  async event void RadioRx.enableRxDone(){} 

  event message_t* RadioRx.received(message_t *frame)
  { // signal it to responsible client component 
    return signal FrameRx.received(frame);
  } 

  event void RadioToken.granted()
  {
    ASSERT(0); // should never happen, because we never call RadioToken.request()
  }   

  event void GTSrequestTx.transmitDone(ieee154_txframe_t *txFrame, ieee154_status_t status)
  {
    atomic{
      call TxControlPool.put((ieee154_txcontrol_t*) ((uint8_t*) txFrame->header - offsetof(ieee154_txcontrol_t, header)));
      call TxFramePool.put(txFrame);
      if (GtsGetReqType(m_gtsReqCharacteristics)==GTS_DEALOC_REQ) {
        post signalGtsConfirmSuccessTask();
        m_gtsReqPending=0;
      }
    }
  }

  command ieee154_status_t MLME_GTS.requestFromPAN  (
      //Only for PAN Coordinator use
      uint8_t GtsCharacteristics,
      uint16_t DeviceAddress,
      ieee154_security_t *security
      ){}

  default event void MLME_GTS.indication (
      uint16_t DeviceAddress,
      uint8_t GtsCharacteristics,
      ieee154_security_t *security
      ){}

  default event void MLME_GTS.confirm    (
      uint8_t GtsCharacteristics,
      ieee154_status_t  status
      ){}
}
