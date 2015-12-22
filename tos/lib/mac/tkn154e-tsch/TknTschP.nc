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

#include "plain154_values.h"

module TknTschP {
  provides {
    interface TknTschMlmeReset;
    interface TknTschMlmeTschMode;
    interface TknTschMlmeSyncLoss;
    interface TknTschMlmeBeacon;
    // TODO this provides only an event: interface TknTschMlmeBeaconNotify;
    interface TknTschMlmeBeaconRequest;
    interface TknTschMlmeAssociate;
    interface TknTschMlmeDisassociate;
    interface TknTschMlmeKeepAlive;
    interface TknTschMlmeSetLink;
    interface TknTschMlmeSetSlotframe;

    //interface TknTschMcpsData;
    interface Init;


  } uses {

    // TODO interface TknTschQueue;
    interface TknTschPib;
    interface TknTschScanControl;
    interface SplitControl as TssmControl;
    interface Ieee154Address;
    interface TknTschMlmeSet;
  }



} implementation {

  //task void initTask(bool SetDefaultPIB);
  //task void initTask();
  void init();
  bool m_scanning;
  bool m_resetting;  // only true if MLME_RESET is called

/******* Init ********************************************************/

  // task void initTask(bool SetDefaultPIB) {
  void init() {
    ieee154_laddr_t extAddr;
    plain154_extended_address_t addr = 0;
    m_scanning = FALSE;
    // TODO: Fill in the rest of necessary tasks to initialize the system
    //call SubInit.init();
    if (m_resetting) {
      signal TknTschMlmeReset.confirm(PLAIN154_SUCCESS);
    }

    // Putting node's extended address into PiB
    extAddr = call Ieee154Address.getExtAddr();
    addr += ((uint64_t)extAddr.data[0] << 0);
    addr += ((uint64_t)extAddr.data[1] << 8);
    addr += ((uint64_t)extAddr.data[2] << 16);
    addr += ((uint64_t)extAddr.data[3] << 24);
    addr += ((uint64_t)extAddr.data[4] << 32);
    addr += ((uint64_t)extAddr.data[5] << 40);
    addr += ((uint64_t)extAddr.data[6] << 48);
    addr += ((uint64_t)extAddr.data[7] << 56);
    call TknTschMlmeSet.macExtAddr(addr);
  }

  command error_t Init.init()
  {
    m_resetting = FALSE;
    init(); // TODO what about bool SetDefaultPIB ?

    return SUCCESS;
  }


  event void Ieee154Address.changed()
  {
  }

/******* TknTschMlmeReset ********************************************/

  command tkntsch_status_t TknTschMlmeReset.request  (
                          bool SetDefaultPIB
                        )
  {
    atomic {
      if (m_resetting)
        return PLAIN154_TRANSACTION_OVERFLOW;

      m_resetting = TRUE;
    }

    init(); // TODO (SetDefaultPIB);

    return PLAIN154_SUCCESS;
  }

  default event void TknTschMlmeReset.confirm(plain154_status_t status) {}


/******* TknTschMlmeTschMode *****************************************/

  command tkntsch_status_t TknTschMlmeTschMode.request  (
                          tkntsch_mode_t TSCHMode
                        )
  {
    error_t ret;
    if (TSCHMode == TKNTSCH_MODE_ON) {
      ret = call TssmControl.start();
      if (ret == SUCCESS)
        return PLAIN154_SUCCESS;
      else
        return PLAIN154_DENIED; // ?
    }
    else if (TSCHMode == TKNTSCH_MODE_OFF) {
      ret = call TssmControl.stop();
      if (ret == SUCCESS)
        return PLAIN154_SUCCESS;
      else
        return PLAIN154_DENIED; // ?
    }
    else {
      return PLAIN154_INVALID_PARAMETER;
    }
  }

  default event void TknTschMlmeTschMode.confirm( tkntsch_mode_t TSCHMode, tkntsch_status_t Status ) {}

  event void TssmControl.startDone(error_t error) {
    signal TknTschMlmeTschMode.confirm(TKNTSCH_MODE_ON, error);
  }

  event void TssmControl.stopDone(error_t error) {
    signal TknTschMlmeTschMode.confirm(TKNTSCH_MODE_OFF, error);
  }



  default event void TknTschMlmeSyncLoss.indication ( tkntsch_status_t lossReason, uint16_t PANId, uint8_t LogicalChannel, uint8_t ChannelPage, plain154_security_t *security ) {}



/******* TknTschMlmeBeacon *******************************************/

  command tkntsch_status_t TknTschMlmeBeacon.request  (
                          uint8_t BeaconType,
                          uint8_t Channel,
                          uint8_t ChannelPage,
                          plain154_security_t *beaconSecurity,
                          uint8_t DstAddrMode,
                          plain154_address_t *DstAddr,
                          bool BSNSuppression
                        )
  {
    return PLAIN154_NOT_IMPLMENTED_YET;
  }
  default event void TknTschMlmeBeacon.confirm( tkntsch_status_t Status ) {}



/******* TknTschMlmeBeaconRequest ************************************/

  command tkntsch_status_t TknTschMlmeBeaconRequest.indication  (
                          uint8_t BeaconType,
                          uint8_t SrcAddrMode,
                          plain154_address_t *SrcAddr,
                          uint16_t dstPANID,
                          uint8_t *IEList
                        )
  {
    return PLAIN154_NOT_IMPLMENTED_YET;
  }



/******* TknTschMlmeAssociate ****************************************/

  command tkntsch_status_t TknTschMlmeAssociate.request  (
                          uint8_t LogicalChannel,
                          uint8_t ChannelPage,
                          uint8_t CoordAddrMode,
                          uint16_t CoordPANID,
                          plain154_address_t CoordAddress,
                          plain154_CapabilityInformation_t CapabilityInformation,
                          plain154_security_t *security,
                          uint16_t ChannelOffset,
                          uint8_t HoppingSequenceID
                        )
  {
    return PLAIN154_NOT_IMPLMENTED_YET;
  }

  command tkntsch_status_t TknTschMlmeAssociate.response (
                          uint64_t DeviceAddress,
                          uint16_t AssocShortAddress,
                          plain154_association_status_t status,
                          plain154_security_t *security,
                          uint16_t ChannelOffset,
                          uint16_t HoppingSequenceLength,
                          uint8_t* HoppingSequence
                        )
  {
    return PLAIN154_NOT_IMPLMENTED_YET;
  }

  default event void TknTschMlmeAssociate.indication ( uint64_t DeviceAddress, plain154_CapabilityInformation_t CapabilityInformation, plain154_security_t *security, uint16_t ChannelOffset, uint8_t HoppingSequenceID ) {}

  default event void TknTschMlmeAssociate.confirm( uint16_t AssocShortAddress, uint8_t status, plain154_security_t *security, uint16_t ChannelOffset, uint16_t HoppingSequenceLength, uint8_t* HoppingSequence ) {}



/******* TknTschMlmeDisassociate *************************************/

  command tkntsch_status_t TknTschMlmeDisassociate.request  (
                          uint8_t DeviceAddrMode,
                          uint16_t DevicePANID,
                          plain154_address_t DeviceAddress,
                          plain154_disassociation_reason_t DisassociateReason,
                          bool TxIndirect,
                          plain154_security_t *security
                        )
  {
    return PLAIN154_NOT_IMPLMENTED_YET;
  }

  default event void TknTschMlmeDisassociate.indication ( uint64_t DeviceAddress, plain154_disassociation_reason_t DisassociateReason, plain154_security_t *security ) {}

  default event void TknTschMlmeDisassociate.confirm( tkntsch_status_t status, uint8_t DeviceAddrMode, uint16_t DevicePANID, plain154_address_t DeviceAddress ) {}



/******* TknTschMlmeKeepAlive ****************************************/

  command tkntsch_status_t TknTschMlmeKeepAlive.request  (
                          uint16_t DstAddr,
                          uint16_t KeepAlivePeriod
                        )
  {
    return PLAIN154_NOT_IMPLMENTED_YET;
  }

  default event void TknTschMlmeKeepAlive.confirm( tkntsch_status_t Status ) {}



/******* TknTschMlmeSet **********************************************/


/******* TknTschMlmeSetLink ******************************************/

  command tkntsch_status_t TknTschMlmeSetLink.request  (
                          tkntsch_slotframe_operation_t  Operation,
                          uint16_t LinkHandle,
                          uint8_t  sfHandle,
                          uint16_t Timeslot,
                          uint8_t  ChannelOffset,
                          uint8_t  LinkOptions,
                          tkntsch_link_type_t  LinkType,
                          uint16_t NodeAddr
                        )
  {
    return PLAIN154_NOT_IMPLMENTED_YET;
  }

  default event void TknTschMlmeSetLink.confirm( tkntsch_status_t Status, uint16_t LinkHandle, uint8_t sfHandle ) {}



/******* TknTschMlmeSetSlotframe *************************************/

  command tkntsch_status_t TknTschMlmeSetSlotframe.request  (
                          uint8_t sfHandle,
                          uint8_t Operation,  // enum.
                          uint16_t Size
                        )
  {
    return PLAIN154_NOT_IMPLMENTED_YET;
  }

  default event void TknTschMlmeSetSlotframe.confirm( uint8_t sfHandle, uint8_t Status) {}



/******* TknTschMcpsData *********************************************/
/*
  command plain154_status_t TknTschMcpsData.request(
    uint8_t SrcAddrMode,
    uint8_t DstAddrMode,
    uint16_t DstPANId,
    plain154_address_t DstAddr,
    uint8_t msduLength,
    void* msdu,
    uint8_t msduHandle,
    uint8_t AckTX,
    uint8_t SecurityLevel,
    uint8_t KeyIdMode,
    plain154_sec_keysource_t KeySource,
    uint8_t KeyIndex
  )
  {
    return PLAIN154_NOT_IMPLMENTED_YET;
    //call TknTschQueue.enqueue()
  }

  default event void TknTschMcpsData.confirm( uint8_t msduHandle, plain154_status_t status) {}

  default event void TknTschMcpsData.indication( uint8_t SrcAddrMode, uint16_t SrcPANId, plain154_address_t SrcAddr, uint8_t DstAddrMode, uint16_t DstPANId, plain154_address_t DstAddr, uint8_t msduLength, void* msdu, uint8_t mpduLinkQuality, uint8_t DSN, uint8_t SecurityLevel, uint8_t KeyIdMode, plain154_sec_keysource_t KeySource, uint8_t KeyIndex) {}
*/
}
