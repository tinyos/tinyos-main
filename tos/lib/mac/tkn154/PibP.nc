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
 * $Date: 2008-10-21 17:29:00 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/* This component maintains the PIB (PAN Information Base) attributes and
 * provides interfaces for accessing fields in a MAC frame. */

#include "TKN154.h"
#include "TKN154_PIB.h"
#include "TKN154_PHY.h"

module PibP {
  provides 
  {
    interface Init as LocalInit;
    interface MLME_RESET;
    interface MLME_GET;
    interface MLME_SET;
    interface Set<ieee154_macSuperframeOrder_t> as SetMacSuperframeOrder;
    interface Set<ieee154_macBeaconTxTime_t> as SetMacBeaconTxTime;
    interface Set<ieee154_macPanCoordinator_t> as SetMacPanCoordinator;
    interface Get<ieee154_macPanCoordinator_t> as IsMacPanCoordinator;
    interface Get<bool> as IsBeaconEnabledPAN;
    interface FrameUtility;
    interface IEEE154Frame as Frame;
    interface IEEE154BeaconFrame as BeaconFrame;
    interface Get<uint64_t> as GetLocalExtendedAddress;
    interface Notify<const void*> as PIBUpdate[uint8_t PIBAttributeID];
    interface Packet;
    interface TimeCalc;
  }
  uses
  {
    interface Get<bool> as PromiscuousModeGet;
    interface Init as CapReset;
    interface Init as CapQueueReset;
    interface Init as MacReset;
    interface SplitControl as RadioControl;
    interface Random;
    interface Resource as Token;
    interface RadioOff;
    interface LocalTime<TSymbolIEEE802154>;
  }
}
implementation
{
  ieee154_PIB_t m_pib;
  uint8_t m_numResetClientPending;
  bool m_setDefaultPIB;
  uint8_t m_panType;
  uint8_t m_resetSpin;

#ifdef IEEE154_EXTENDED_ADDRESS
  const uint64_t m_aExtendedAddressLE = IEEE154_EXTENDED_ADDRESS;
#else
  norace uint64_t m_aExtendedAddressLE;
#endif
  task void radioControlStopTask();
  void updateMacMaxFrameTotalWaitTime();
  void resetAttributesToDefault();
  bool isLocalExtendedAddress(uint8_t *addrLE);
  bool isCoordExtendedAddress(uint8_t *addrLE); 
  uint8_t getPendAddrSpecOffset(uint8_t *macPayloadField);
  task void resetSpinTask();
  
  command error_t LocalInit.init()
  {
#ifndef IEEE154_EXTENDED_ADDRESS
    uint32_t *p = (uint32_t*) &m_aExtendedAddressLE;
    *p++ = call Random.rand32();
    *p = call Random.rand32();
#endif
    resetAttributesToDefault();
    return SUCCESS;
  }

  void resetAttributesToDefault() {
    m_pib.phyCurrentChannel = IEEE154_DEFAULT_CURRENTCHANNEL;
    m_pib.phyTransmitPower = (IEEE154_TXPOWER_TOLERANCE | (IEEE154_DEFAULT_TRANSMITPOWER_dBm & 0x3F));
    m_pib.phyCCAMode = IEEE154_DEFAULT_CCAMODE;
    m_pib.phyCurrentPage = IEEE154_DEFAULT_CURRENTPAGE;

    m_pib.macAssociatedPANCoord = IEEE154_DEFAULT_ASSOCIATEDPANCOORD;
    m_pib.macAssociationPermit = IEEE154_DEFAULT_ASSOCIATIONPERMIT;
    m_pib.macAutoRequest = IEEE154_DEFAULT_AUTOREQUEST;
    m_pib.macBattLifeExt = IEEE154_DEFAULT_BATTLIFEEXT;
    m_pib.macBeaconPayloadLength = IEEE154_DEFAULT_BEACONPAYLOADLENGTH;
    m_pib.macBeaconOrder = IEEE154_DEFAULT_BEACONORDER;
    m_pib.macBeaconTxTime = IEEE154_DEFAULT_BEACONTXTIME;
    m_pib.macBSN = 0xFF & (call Random.rand16());
    //  macCoordExtendedAddress: default is undefined
    m_pib.macCoordShortAddress = IEEE154_DEFAULT_COORDSHORTADDRESS;
    m_pib.macDSN = 0xFF & (call Random.rand16());
    m_pib.macGTSPermit = IEEE154_DEFAULT_GTSPERMIT;
    m_pib.macMaxBE = IEEE154_DEFAULT_MAXBE;
    m_pib.macMaxCSMABackoffs = IEEE154_DEFAULT_MAXCSMABACKOFFS;
    m_pib.macMaxFrameRetries = IEEE154_DEFAULT_MAXFRAMERETRIES;
    m_pib.macMinBE = IEEE154_DEFAULT_MINBE;
    m_pib.macPANId = IEEE154_DEFAULT_PANID;
    m_pib.macPromiscuousMode = IEEE154_DEFAULT_PROMISCUOUSMODE;
    m_pib.macResponseWaitTime = IEEE154_DEFAULT_RESPONSEWAITTIME;
    m_pib.macRxOnWhenIdle = IEEE154_DEFAULT_RXONWHENIDLE;
    m_pib.macSecurityEnabled = IEEE154_DEFAULT_SECURITYENABLED;
    m_pib.macShortAddress = IEEE154_DEFAULT_SHORTADDRESS;
    m_pib.macSuperframeOrder = IEEE154_DEFAULT_SUPERFRAMEORDER;
    m_pib.macTransactionPersistenceTime = IEEE154_DEFAULT_TRANSACTIONPERSISTENCETIME;
    updateMacMaxFrameTotalWaitTime();
  }

  void updateMacMaxFrameTotalWaitTime()
  {
    // using equation 14 on page 160
    ieee154_macMinBE_t macMinBE = m_pib.macMinBE; 
    ieee154_macMaxBE_t macMaxBE = m_pib.macMaxBE; 
    ieee154_macMaxCSMABackoffs_t macMaxCSMABackoffs = m_pib.macMaxCSMABackoffs;
    uint8_t m = macMaxBE - macMinBE, k;
    uint32_t waitTime = 0;

    if (macMaxCSMABackoffs < m)
      m = macMaxCSMABackoffs;
    waitTime = (((uint16_t) 1 << macMaxBE) - 1) * (macMaxCSMABackoffs - m);
    if (m) {
      k = 0;
      while (k != m){
        waitTime += ((uint16_t) 1 << (macMaxBE+k));
        k += 1;
      }
    }
    waitTime *= IEEE154_aUnitBackoffPeriod;
    waitTime += IEEE154_SHR_DURATION;
    m_pib.macMaxFrameTotalWaitTime = waitTime;
  }

  command ieee154_status_t MLME_RESET.request(bool SetDefaultPIB, uint8_t PANType) 
  {
    // resetting the complete stack is not so easy...
    // first we acquire the Token (get exclusive radio access), then we switch off 
    // the radio and reset all MAC components, starting from the ones that might 
    // still have any frames queued / allocated to get them flushed out. While we 
    // own the Token all other components are "inactive" (and there are no pending
    // Alarms!), but there can still be pending Timers/tasks -> we stop all Timers
    // through MacReset.init() and then spin a few tasks in between to get 
    // everything "flushed out"
    if (PANType != BEACON_ENABLED_PAN && PANType != NONBEACON_ENABLED_PAN)
      return IEEE154_INVALID_PARAMETER;
    if (call PromiscuousModeGet.get())
      return IEEE154_TRANSACTION_OVERFLOW; // must first cancel promiscuous mode!
    m_setDefaultPIB = SetDefaultPIB;
    m_panType = PANType; 
    if (!call Token.isOwner())
      call Token.request();
    return IEEE154_SUCCESS;
  }

  event void Token.granted()
  {
    error_t error = call RadioOff.off();
    if (error != SUCCESS) // either it is already off or driver has not been started
      signal RadioOff.offDone();
  }

  async event void RadioOff.offDone()
  {
    post radioControlStopTask();
  }

  task void radioControlStopTask()
  {
    if (call RadioControl.stop() == EALREADY)
      signal RadioControl.stopDone(SUCCESS);
  }

  event void RadioControl.stopDone(error_t error)
  {
    call CapReset.init();       // resets the CAP component(s)
    call CapQueueReset.init();  // resets the CAP queue component(s)
    call MacReset.init();       // resets the remaining components
    m_resetSpin = 5;
    post resetSpinTask();
  }

  task void resetSpinTask()
  {
    if (m_resetSpin == 2){
      // just to be safe...
      call CapReset.init();       
      call CapQueueReset.init();  
      call MacReset.init();       
    }
    if (m_resetSpin--){
      post resetSpinTask();
      return;
    }
    if (call RadioControl.start() == EALREADY)
      signal RadioControl.startDone(SUCCESS);
  }

  event void RadioControl.startDone(error_t error)
  {
    if (m_setDefaultPIB)
      resetAttributesToDefault();
    else {
      // restore previous PHY attributes
      signal PIBUpdate.notify[IEEE154_phyCurrentChannel](&m_pib.phyCurrentChannel);
      signal PIBUpdate.notify[IEEE154_phyTransmitPower](&m_pib.phyTransmitPower);
      signal PIBUpdate.notify[IEEE154_phyCCAMode](&m_pib.phyCCAMode);
      signal PIBUpdate.notify[IEEE154_phyCurrentPage](&m_pib.phyCurrentPage);
      signal PIBUpdate.notify[IEEE154_macPANId](&m_pib.macPANId);
      signal PIBUpdate.notify[IEEE154_macShortAddress](&m_pib.macShortAddress);
      signal PIBUpdate.notify[IEEE154_macPanCoordinator](&m_pib.macPanCoordinator);
    }
    call Token.release();
    signal MLME_RESET.confirm(IEEE154_SUCCESS);
  }
  
/* ----------------------- MLME-GET ----------------------- */

  command ieee154_phyCurrentChannel_t MLME_GET.phyCurrentChannel(){ return m_pib.phyCurrentChannel;}

  command ieee154_phyChannelsSupported_t MLME_GET.phyChannelsSupported(){ return IEEE154_SUPPORTED_CHANNELS;}

  command ieee154_phyTransmitPower_t MLME_GET.phyTransmitPower(){ return m_pib.phyTransmitPower;}

  command ieee154_phyCCAMode_t MLME_GET.phyCCAMode(){ return m_pib.phyCCAMode;}

  command ieee154_phyCurrentPage_t MLME_GET.phyCurrentPage(){ return m_pib.phyCurrentPage;}

  command ieee154_phyMaxFrameDuration_t MLME_GET.phyMaxFrameDuration(){ return IEEE154_MAX_FRAME_DURATION;}

  command ieee154_phySHRDuration_t MLME_GET.phySHRDuration(){ return IEEE154_SHR_DURATION;}

  command ieee154_phySymbolsPerOctet_t MLME_GET.phySymbolsPerOctet(){ return IEEE154_SYMBOLS_PER_OCTET;}

  command ieee154_macAckWaitDuration_t MLME_GET.macAckWaitDuration(){ return IEEE154_ACK_WAIT_DURATION;}

  command ieee154_macAssociationPermit_t MLME_GET.macAssociationPermit(){ return m_pib.macAssociationPermit;}

  command ieee154_macAutoRequest_t MLME_GET.macAutoRequest(){ return m_pib.macAutoRequest;}

  command ieee154_macBattLifeExt_t MLME_GET.macBattLifeExt(){ return m_pib.macBattLifeExt;}

  command ieee154_macBattLifeExtPeriods_t MLME_GET.macBattLifeExtPeriods(){ return IEEE154_BATT_LIFE_EXT_PERIODS;}

  command ieee154_macBeaconOrder_t MLME_GET.macBeaconOrder(){ return m_pib.macBeaconOrder;}

  command ieee154_macBeaconTxTime_t MLME_GET.macBeaconTxTime(){ return m_pib.macBeaconTxTime;}

  command ieee154_macBSN_t MLME_GET.macBSN(){ return m_pib.macBSN;}

  command ieee154_macCoordExtendedAddress_t MLME_GET.macCoordExtendedAddress(){ return m_pib.macCoordExtendedAddress;}

  command ieee154_macCoordShortAddress_t MLME_GET.macCoordShortAddress(){ return m_pib.macCoordShortAddress;}

  command ieee154_macDSN_t MLME_GET.macDSN(){ return m_pib.macDSN;}

  command ieee154_macGTSPermit_t MLME_GET.macGTSPermit(){ return m_pib.macGTSPermit;}

  command ieee154_macMaxCSMABackoffs_t MLME_GET.macMaxCSMABackoffs(){ return m_pib.macMaxCSMABackoffs;}

  command ieee154_macMinBE_t MLME_GET.macMinBE(){ return m_pib.macMinBE;}

  command ieee154_macPANId_t MLME_GET.macPANId(){ return m_pib.macPANId;}

  command ieee154_macPromiscuousMode_t MLME_GET.macPromiscuousMode(){ return call PromiscuousModeGet.get();}

  command ieee154_macRxOnWhenIdle_t MLME_GET.macRxOnWhenIdle(){ return m_pib.macRxOnWhenIdle;}

  command ieee154_macShortAddress_t MLME_GET.macShortAddress(){ return m_pib.macShortAddress;}

  command ieee154_macSuperframeOrder_t MLME_GET.macSuperframeOrder(){ return m_pib.macSuperframeOrder;}

  command ieee154_macTransactionPersistenceTime_t MLME_GET.macTransactionPersistenceTime(){ return m_pib.macTransactionPersistenceTime;}

  command ieee154_macAssociatedPANCoord_t MLME_GET.macAssociatedPANCoord(){ return m_pib.macAssociatedPANCoord;}

  command ieee154_macMaxBE_t MLME_GET.macMaxBE(){ return m_pib.macMaxBE;}

  command ieee154_macMaxFrameTotalWaitTime_t MLME_GET.macMaxFrameTotalWaitTime(){ return m_pib.macMaxFrameTotalWaitTime;}

  command ieee154_macMaxFrameRetries_t MLME_GET.macMaxFrameRetries(){ return m_pib.macMaxFrameRetries;}

  command ieee154_macResponseWaitTime_t MLME_GET.macResponseWaitTime(){ return m_pib.macResponseWaitTime;}

  command ieee154_macSyncSymbolOffset_t MLME_GET.macSyncSymbolOffset(){ return IEEE154_SYNC_SYMBOL_OFFSET;}

  command ieee154_macTimestampSupported_t MLME_GET.macTimestampSupported(){ return IEEE154_TIMESTAMP_SUPPORTED;}

  command ieee154_macSecurityEnabled_t MLME_GET.macSecurityEnabled(){ return m_pib.macSecurityEnabled;}

  command ieee154_macMinLIFSPeriod_t MLME_GET.macMinLIFSPeriod(){ return IEEE154_MIN_LIFS_PERIOD;}

  command ieee154_macMinSIFSPeriod_t MLME_GET.macMinSIFSPeriod(){ return IEEE154_MIN_SIFS_PERIOD;}

/* ----------------------- MLME-SET ----------------------- */

  command ieee154_status_t MLME_SET.phyCurrentChannel(ieee154_phyCurrentChannel_t value){
    uint32_t i = 1;
    uint8_t k = value;
    while (i && k){
      i <<= 1;
      k -= 1;
    }
    if (!(IEEE154_SUPPORTED_CHANNELS & i))
      return IEEE154_INVALID_PARAMETER;
    m_pib.phyCurrentChannel = value;
    signal PIBUpdate.notify[IEEE154_phyCurrentChannel](&m_pib.phyCurrentChannel);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.phyTransmitPower(ieee154_phyTransmitPower_t value){
    m_pib.phyTransmitPower = (value & 0x3F);
    signal PIBUpdate.notify[IEEE154_phyTransmitPower](&m_pib.phyTransmitPower);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.phyCCAMode(ieee154_phyCCAMode_t value){
    if (value < 1 || value > 3)
      return IEEE154_INVALID_PARAMETER;
    m_pib.phyCCAMode = value;
    signal PIBUpdate.notify[IEEE154_phyCCAMode](&m_pib.phyCCAMode);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.phyCurrentPage(ieee154_phyCurrentPage_t value){
    if (value > 31)
      return IEEE154_INVALID_PARAMETER;
    m_pib.phyCurrentPage = value;
    signal PIBUpdate.notify[IEEE154_phyCurrentPage](&m_pib.phyCurrentPage);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macAssociationPermit(ieee154_macAssociationPermit_t value){
    m_pib.macAssociationPermit = value;
    signal PIBUpdate.notify[IEEE154_macAssociationPermit](&m_pib.macAssociationPermit);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macAutoRequest(ieee154_macAutoRequest_t value){
    m_pib.macAutoRequest = value;
    signal PIBUpdate.notify[IEEE154_macAutoRequest](&m_pib.macAutoRequest);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macBattLifeExt(ieee154_macBattLifeExt_t value){
    m_pib.macBattLifeExt = value;
    signal PIBUpdate.notify[IEEE154_macBattLifeExt](&m_pib.macBattLifeExt);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macBattLifeExtPeriods(ieee154_macBattLifeExtPeriods_t value){
    if (value < 6 || value > 41)
      return IEEE154_INVALID_PARAMETER;
    m_pib.macBattLifeExtPeriods = value;
    signal PIBUpdate.notify[IEEE154_macBattLifeExtPeriods](&m_pib.macBattLifeExtPeriods);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macBeaconOrder(ieee154_macBeaconOrder_t value){
    if (value > 15)
      return IEEE154_INVALID_PARAMETER;
    m_pib.macBeaconOrder = value;
    signal PIBUpdate.notify[IEEE154_macBeaconOrder](&m_pib.macBeaconOrder);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macBSN(ieee154_macBSN_t value){
    m_pib.macBSN = value;
    signal PIBUpdate.notify[IEEE154_macBSN](&m_pib.macBSN);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macCoordExtendedAddress(ieee154_macCoordExtendedAddress_t value){
    m_pib.macCoordExtendedAddress = value;
    signal PIBUpdate.notify[IEEE154_macCoordExtendedAddress](&m_pib.macCoordExtendedAddress);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macCoordShortAddress(ieee154_macCoordShortAddress_t value){
    m_pib.macCoordShortAddress = value;
    signal PIBUpdate.notify[IEEE154_macCoordShortAddress](&m_pib.macCoordShortAddress);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macDSN(ieee154_macDSN_t value){
    m_pib.macDSN = value;
    signal PIBUpdate.notify[IEEE154_macDSN](&m_pib.macDSN);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macGTSPermit(ieee154_macGTSPermit_t value){
    m_pib.macGTSPermit = value;
    signal PIBUpdate.notify[IEEE154_macGTSPermit](&m_pib.macGTSPermit);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macMaxCSMABackoffs(ieee154_macMaxCSMABackoffs_t value){
    if (value > 5)
      return IEEE154_INVALID_PARAMETER;
    m_pib.macMaxCSMABackoffs = value;
    updateMacMaxFrameTotalWaitTime();
    signal PIBUpdate.notify[IEEE154_macMaxCSMABackoffs](&m_pib.macMaxCSMABackoffs);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macMinBE(ieee154_macMinBE_t value){
    if (value > m_pib.macMaxBE)
      return IEEE154_INVALID_PARAMETER;
    m_pib.macMinBE = value;
    updateMacMaxFrameTotalWaitTime();
    signal PIBUpdate.notify[IEEE154_macMinBE](&m_pib.macMinBE);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macPANId(ieee154_macPANId_t value){
    m_pib.macPANId = value;
    signal PIBUpdate.notify[IEEE154_macPANId](&m_pib.macPANId);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macRxOnWhenIdle(ieee154_macRxOnWhenIdle_t value){
    m_pib.macRxOnWhenIdle = value;
    signal PIBUpdate.notify[IEEE154_macRxOnWhenIdle](&m_pib.macRxOnWhenIdle);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macShortAddress(ieee154_macShortAddress_t value){
    m_pib.macShortAddress = value;
    signal PIBUpdate.notify[IEEE154_macShortAddress](&m_pib.macShortAddress);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macTransactionPersistenceTime(ieee154_macTransactionPersistenceTime_t value){
    m_pib.macTransactionPersistenceTime = value;
    signal PIBUpdate.notify[IEEE154_macTransactionPersistenceTime](&m_pib.macTransactionPersistenceTime);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macAssociatedPANCoord(ieee154_macAssociatedPANCoord_t value){
    m_pib.macAssociatedPANCoord = value;
    signal PIBUpdate.notify[IEEE154_macAssociatedPANCoord](&m_pib.macAssociatedPANCoord);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macMaxBE(ieee154_macMaxBE_t value){
    if (value < 3 || value > 8)
      return IEEE154_INVALID_PARAMETER;
    m_pib.macMaxBE = value;
    updateMacMaxFrameTotalWaitTime();
    signal PIBUpdate.notify[IEEE154_macMaxBE](&m_pib.macMaxBE);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macMaxFrameTotalWaitTime(ieee154_macMaxFrameTotalWaitTime_t value){
    // equation 14 on page 160 defines how macMaxFrameTotalWaitTime is calculated;
    // its value depends only on other PIB attributes and constants - why does the standard 
    // allow setting it by the next higher layer ??
    m_pib.macMaxFrameTotalWaitTime = value;
    signal PIBUpdate.notify[IEEE154_macMaxFrameTotalWaitTime](&m_pib.macMaxFrameTotalWaitTime);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macMaxFrameRetries(ieee154_macMaxFrameRetries_t value){
    if (value > 7)
      return IEEE154_INVALID_PARAMETER;
    m_pib.macMaxFrameRetries = value;
    signal PIBUpdate.notify[IEEE154_macMaxFrameRetries](&m_pib.macMaxFrameRetries);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macResponseWaitTime(ieee154_macResponseWaitTime_t value){
    if (value < 2 || value > 64)
      return IEEE154_INVALID_PARAMETER;
    m_pib.macResponseWaitTime = value;
    signal PIBUpdate.notify[IEEE154_macResponseWaitTime](&m_pib.macResponseWaitTime);
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t MLME_SET.macSecurityEnabled(ieee154_macSecurityEnabled_t value){
    return IEEE154_UNSUPPORTED_ATTRIBUTE;
  }
  
  // Read-only attributes (writable only by MAC components)
  command void SetMacSuperframeOrder.set( ieee154_macSuperframeOrder_t value ){
    m_pib.macSuperframeOrder = value;
    signal PIBUpdate.notify[IEEE154_macSuperframeOrder](&m_pib.macSuperframeOrder);
  }

  command void SetMacBeaconTxTime.set( ieee154_macBeaconTxTime_t value ){
    m_pib.macBeaconTxTime = value;
    signal PIBUpdate.notify[IEEE154_macBeaconTxTime](&m_pib.macBeaconTxTime);
  }

  command void SetMacPanCoordinator.set( ieee154_macPanCoordinator_t value ){
    m_pib.macPanCoordinator = value;
    signal PIBUpdate.notify[IEEE154_macPanCoordinator](&m_pib.macPanCoordinator);
  }

  command ieee154_macPanCoordinator_t IsMacPanCoordinator.get(){
    return m_pib.macPanCoordinator;
  }

/* ----------------------- TimeCalc ----------------------- */

  async command uint32_t TimeCalc.timeElapsed(uint32_t t0, uint32_t t1)
  {
    // t0 occured before t1, what is the delta?
    if (t0 <= t1)
      return t1 - t0;
    else
      return ~(t0 - t1) + 1;
  }
  
  async command bool TimeCalc.hasExpired(uint32_t t0, uint32_t dt)
  {
    // t0 is in the past, what about t0+dt?
    uint32_t now = call LocalTime.get(), elapsed;
    if (now >= t0)
      elapsed = now - t0;
    else
      elapsed = ~(t0 - now) + 1;
    return (elapsed >= dt);
  }

/* ----------------------- Frame Access ----------------------- */

  command void Packet.clear(message_t* msg)
  {
    memset(msg->header, 0, sizeof(message_header_t));
    memset(msg->metadata, 0, sizeof(message_metadata_t));
  }

  command uint8_t Packet.payloadLength(message_t* msg)
  {
    return ((message_header_t*) msg->header)->ieee154.length;
  }

  command void Packet.setPayloadLength(message_t* msg, uint8_t len)
  {
    ((message_header_t*) msg->header)->ieee154.length = len;
  }

  command uint8_t Packet.maxPayloadLength()
  {
#if TOSH_DATA_LENGTH < 118
#warning Payload portion in message_t is smaller than required (TOSH_DATA_LENGTH < IEEE154_aMaxMACPayloadSize). This means that larger packets cannot be sent/received.
#endif
    return TOSH_DATA_LENGTH;
  }

  command void* Packet.getPayload(message_t* msg, uint8_t len)
  {
    return msg->data;
  }

  async command uint8_t FrameUtility.writeHeader(
      uint8_t* mhr,
      uint8_t DstAddrMode,
      uint16_t DstPANId,
      ieee154_address_t* DstAddr,
      uint8_t SrcAddrMode,
      uint16_t SrcPANId,
      const ieee154_address_t* SrcAddr,
      bool PANIDCompression)      
  {
    uint8_t offset = MHR_INDEX_ADDRESS;
    if (DstAddrMode == ADDR_MODE_SHORT_ADDRESS || DstAddrMode == ADDR_MODE_EXTENDED_ADDRESS){
      *((nxle_uint16_t*) &mhr[offset]) = DstPANId;
      offset += 2;
      if (DstAddrMode == ADDR_MODE_SHORT_ADDRESS){
        *((nxle_uint16_t*) &mhr[offset]) = DstAddr->shortAddress;
        offset += 2;
      } else {
        call FrameUtility.convertToLE(&mhr[offset], &DstAddr->extendedAddress);
        offset += 8; 
      }
    }
    if (SrcAddrMode == ADDR_MODE_SHORT_ADDRESS || SrcAddrMode == ADDR_MODE_EXTENDED_ADDRESS){
      if (DstPANId != SrcPANId || !PANIDCompression){
        *((nxle_uint16_t*) &mhr[offset]) = SrcPANId;
        offset += 2;
      }
      if (SrcAddrMode == ADDR_MODE_SHORT_ADDRESS){
        *((nxle_uint16_t*) &mhr[offset]) = SrcAddr->shortAddress;
        offset += 2;
      } else {
        call FrameUtility.convertToLE(&mhr[offset], &SrcAddr->extendedAddress);
        offset += 8; 
      }
    }
    return offset;
  }

  command bool FrameUtility.isBeaconFromCoord(message_t *frame)
  {
    uint8_t offset = MHR_INDEX_ADDRESS;
    uint8_t *mhr = MHR(frame);
 
    if ((mhr[MHR_INDEX_FC1] & FC1_FRAMETYPE_MASK) != FC1_FRAMETYPE_BEACON) 
      return FALSE; // not a beacon frame
    if (!(mhr[MHR_INDEX_FC2] & FC2_SRC_MODE_MASK))
      return FALSE; // source address information missing
    if (mhr[MHR_INDEX_FC2] & FC2_DEST_MODE_MASK)
      return FALSE; // beacons don't include dest address
    if ((*(nxle_uint16_t*) (&mhr[offset])) != m_pib.macPANId)
      return FALSE; // wrong PAN ID
    offset += 2;         
    if ((mhr[MHR_INDEX_FC2] & FC2_SRC_MODE_MASK) == FC2_SRC_MODE_SHORT){
      if ((*(nxle_uint16_t*) (&mhr[offset])) != m_pib.macCoordShortAddress)
        return FALSE;
    } else if ((mhr[MHR_INDEX_FC2] & FC2_SRC_MODE_MASK) == FC2_SRC_MODE_EXTENDED){
      if (!isCoordExtendedAddress(mhr + offset))
        return FALSE;
    }
    return TRUE;
  }

  async command error_t FrameUtility.getMHRLength(uint8_t fcf1, uint8_t fcf2, uint8_t *len)
  {
    uint8_t idCompression;
    uint8_t offset = MHR_INDEX_ADDRESS;
 
    if (fcf1 & FC1_SECURITY_ENABLED)
      return FAIL; // not supported 
    idCompression = (fcf1 & FC1_PAN_ID_COMPRESSION);
    if (fcf2 & 0x08){ // short or ext. address
      offset += 4; // pan id + short address
      if (fcf2 & 0x04) // ext. address
        offset += 6; // diff to short address
    }
    if (fcf2 & 0x80){ // short or ext. address
      offset += 2;
      if (!idCompression)
        offset += 2;
      if (fcf2 & 0x40) // ext. address
        offset += 6; // diff to short address
    }
    *len = offset;
    return SUCCESS;
  }
    

  command error_t Frame.setAddressingFields(message_t* frame,
                          uint8_t srcAddrMode,
                          uint8_t dstAddrMode,
                          uint16_t dstPANId,
                          ieee154_address_t *dstAddr,
                          ieee154_security_t *security)
  {
    uint8_t *mhr = MHR(frame);
    ieee154_address_t srcAddress;
    ieee154_macPANId_t srcPANId = call MLME_GET.macPANId();

    if (security && security->SecurityLevel)
      return FAIL; // not implemented
    mhr[MHR_INDEX_FC2] &= (FC2_DEST_MODE_MASK | FC2_SRC_MODE_MASK);
    mhr[MHR_INDEX_FC2] |= dstAddrMode << FC2_DEST_MODE_OFFSET;
    mhr[MHR_INDEX_FC2] |= srcAddrMode << FC2_SRC_MODE_OFFSET;
    if (srcAddrMode == ADDR_MODE_SHORT_ADDRESS)
      srcAddress.shortAddress = call MLME_GET.macShortAddress();
    else  
      srcAddress.extendedAddress = call GetLocalExtendedAddress.get();
    if (dstAddrMode >= ADDR_MODE_SHORT_ADDRESS && 
        srcAddrMode >= ADDR_MODE_SHORT_ADDRESS && 
        dstPANId == srcPANId)
      mhr[MHR_INDEX_FC1] |= FC1_PAN_ID_COMPRESSION;
    else
      mhr[MHR_INDEX_FC1] &= ~FC1_PAN_ID_COMPRESSION;
    call FrameUtility.writeHeader(
            mhr,
            dstAddrMode,
            dstPANId,
            dstAddr,
            srcAddrMode,
            srcPANId,
            &srcAddress,
            (mhr[MHR_INDEX_FC1] & FC1_PAN_ID_COMPRESSION) ? TRUE: FALSE);
    return SUCCESS;
  }

  command uint8_t Frame.getFrameType(message_t* frame)
  {
    uint8_t *mhr = MHR(frame);
    return (mhr[MHR_INDEX_FC1] & FC1_FRAMETYPE_MASK);
  }

  command void* Frame.getHeader(message_t* frame)
  {
    uint8_t *mhr = MHR(frame);
    return (void*) &(mhr[MHR_INDEX_FC1]);
  }

  command uint8_t Frame.getHeaderLength(message_t* frame)
  {
    uint8_t len;
    uint8_t *mhr = MHR(frame);
    call FrameUtility.getMHRLength(mhr[0], mhr[1], &len);
    return len;
  }

  command void* Frame.getPayload(message_t* frame)
  {
    uint8_t *payload = (uint8_t *) frame->data;
    return payload;
  }

  command uint8_t Frame.getPayloadLength(message_t* frame)
  {
    uint8_t len = ((ieee154_header_t*) frame->header)->length & FRAMECTL_LENGTH_MASK;
    return len;
  }

  command uint32_t Frame.getTimestamp(message_t* frame)
  {
    ieee154_metadata_t *metadata = (ieee154_metadata_t*) frame->metadata;
    return metadata->timestamp;
  }

  command bool Frame.isTimestampValid(message_t* frame)
  {
    ieee154_metadata_t *metadata = (ieee154_metadata_t*) frame->metadata;
    if (metadata->timestamp == IEEE154_INVALID_TIMESTAMP)
      return FALSE;
    else
      return TRUE;
  }

  command uint8_t Frame.getDSN(message_t* frame)
  {
    uint8_t *mhr = MHR(frame);
    return mhr[MHR_INDEX_SEQNO];
  }

  command uint8_t Frame.getLinkQuality(message_t* frame)
  {
    ieee154_metadata_t *metadata = (ieee154_metadata_t*) frame->metadata;
    return metadata->linkQuality;
  }

  command uint8_t Frame.getSrcAddrMode(message_t* frame)
  {
    uint8_t *mhr = MHR(frame);
    return (mhr[MHR_INDEX_FC2] & FC2_SRC_MODE_MASK) >> FC2_SRC_MODE_OFFSET;
  }

  command error_t Frame.getSrcAddr(message_t* frame, ieee154_address_t *address)
  {
    uint8_t *mhr = MHR(frame);
    uint8_t offset = MHR_INDEX_ADDRESS;
    uint8_t destMode = (mhr[MHR_INDEX_FC2] & FC2_DEST_MODE_MASK);
    if (!(mhr[MHR_INDEX_FC2] & FC2_SRC_MODE_SHORT))
      return FAIL;
    if (destMode == FC2_DEST_MODE_SHORT)
      offset += 4;
    else if (destMode == FC2_DEST_MODE_EXTENDED)
      offset += 10;
    if (!((mhr[MHR_INDEX_FC1] & FC1_PAN_ID_COMPRESSION) && (mhr[MHR_INDEX_FC2] & FC2_DEST_MODE_SHORT)))
      offset += 2;
    if ((mhr[MHR_INDEX_FC2] & FC2_SRC_MODE_MASK) == FC2_SRC_MODE_SHORT)
      address->shortAddress = *((nxle_uint16_t*) (&(mhr[offset])));
    else
      call FrameUtility.convertToNative(&address->extendedAddress, (&(mhr[offset]) ));
    return SUCCESS;
  }

  command error_t Frame.getSrcPANId(message_t* frame, uint16_t *PANID)
  {
    uint8_t *mhr = MHR(frame);
    uint8_t offset = MHR_INDEX_ADDRESS;
    uint8_t destMode = (mhr[1] & FC2_DEST_MODE_MASK);
    if (!(mhr[MHR_INDEX_FC2] & FC2_SRC_MODE_SHORT))
      return FAIL;
    if (destMode == FC2_DEST_MODE_SHORT)
      offset += 4;
    else if (destMode == FC2_DEST_MODE_EXTENDED)
      offset += 10;
    if ((mhr[MHR_INDEX_FC1] & FC1_PAN_ID_COMPRESSION) && (mhr[MHR_INDEX_FC2] & FC2_DEST_MODE_SHORT))
      *PANID = *((nxle_uint16_t*) (&(mhr[MHR_INDEX_ADDRESS])));
    else if ((mhr[MHR_INDEX_FC2] & FC2_SRC_MODE_MASK) == FC2_SRC_MODE_SHORT)
      *PANID = *((nxle_uint16_t*) (&(mhr[offset])));
    else
      *PANID = *((nxle_uint16_t*) (&(mhr[offset])));
    return SUCCESS;
  }

  command uint8_t Frame.getDstAddrMode(message_t* frame)
  {
    uint8_t *mhr = MHR(frame);
    return (mhr[MHR_INDEX_FC2] & FC2_DEST_MODE_MASK) >> FC2_DEST_MODE_OFFSET;
  }

  command error_t Frame.getDstAddr(message_t* frame, ieee154_address_t *address)
  { 
    uint8_t *mhr = MHR(frame);
    if (!(mhr[MHR_INDEX_FC2] & FC2_DEST_MODE_SHORT))
      return FAIL;
    if ((mhr[MHR_INDEX_FC2] & FC2_DEST_MODE_MASK) == FC2_DEST_MODE_SHORT)
      address->shortAddress = *((nxle_uint16_t*) (&(mhr[MHR_INDEX_ADDRESS]) + 2));
    else
      call FrameUtility.convertToNative(&address->extendedAddress, (&(mhr[MHR_INDEX_ADDRESS]) + 2));
    return SUCCESS;
  }

  command error_t Frame.getDstPANId(message_t* frame, uint16_t *PANID)
  {
    uint8_t *mhr = MHR(frame);
    if (!(mhr[MHR_INDEX_FC2] & FC2_DEST_MODE_SHORT))
      return FAIL;
    *PANID = *((nxle_uint16_t*) (&(mhr[MHR_INDEX_ADDRESS])));
    return SUCCESS;
  }

  command bool Frame.wasPromiscuousModeEnabled(message_t* frame)
  {
    return (((ieee154_header_t*) frame->header)->length & FRAMECTL_PROMISCUOUS) ? TRUE : FALSE;
  }

  command bool Frame.hasStandardCompliantHeader(message_t* frame)
  {
    uint8_t *mhr = MHR(frame);
    if ( ((mhr[0] & FC1_FRAMETYPE_MASK) > 0x03) ||
         ((mhr[MHR_INDEX_FC2] & FC2_DEST_MODE_MASK) == 0x04) || 
         ((mhr[MHR_INDEX_FC2] & FC2_SRC_MODE_MASK) == 0x40) || 
#ifndef IEEE154_SECURITY_ENABLED
         ((mhr[0] & FC1_SECURITY_ENABLED)) || 
#endif
         (mhr[MHR_INDEX_FC2] & FC2_FRAME_VERSION_2)
        )
      return FALSE;
    else
      return TRUE;
  }

/* ----------------------- Beacon Frame Access ----------------------- */

  uint8_t getPendAddrSpecOffset(uint8_t *macPayloadField)
  {
    uint8_t gtsDescriptorCount = macPayloadField[BEACON_INDEX_GTS_SPEC] & GTS_DESCRIPTOR_COUNT_MASK;
    return BEACON_INDEX_GTS_SPEC + 1 + ((gtsDescriptorCount > 0) ? 1 + gtsDescriptorCount * 3: 0);
  }    

  command error_t BeaconFrame.getPendAddrSpec(message_t* frame, uint8_t* pendAddrSpec)
  {
    uint8_t *mhr = MHR(frame);
    if (((mhr[MHR_INDEX_FC1] & FC1_FRAMETYPE_MASK) != FC1_FRAMETYPE_BEACON))
      return FAIL;
    else {
      uint8_t *payload = (uint8_t *) frame->data;
      uint8_t pendAddrSpecOffset = getPendAddrSpecOffset(payload);      
      *pendAddrSpec = payload[pendAddrSpecOffset];
      return SUCCESS;
    }
  }

  command error_t BeaconFrame.getPendAddr(message_t* frame, uint8_t addrMode, 
      ieee154_address_t buffer[], uint8_t bufferSize)
  {
    uint8_t *mhr = MHR(frame);
    uint8_t *payload = (uint8_t *) frame->data;
    uint8_t pendAddrSpecOffset = getPendAddrSpecOffset(payload);      
    uint8_t pendAddrSpec = payload[pendAddrSpecOffset], i;
    if (((mhr[MHR_INDEX_FC1] & FC1_FRAMETYPE_MASK) != FC1_FRAMETYPE_BEACON))
      return FAIL;
    if (addrMode == ADDR_MODE_SHORT_ADDRESS){
      for (i=0; i<(pendAddrSpec & PENDING_ADDRESS_SHORT_MASK) && i<bufferSize; i++)
        buffer[i].shortAddress = *((nxle_uint16_t*) (payload + pendAddrSpecOffset + 1 + 2*i));
      return SUCCESS;
    } else if (addrMode == ADDR_MODE_EXTENDED_ADDRESS){
      for (i=0; i<((pendAddrSpec & PENDING_ADDRESS_EXT_MASK) >> 4) && i<bufferSize; i++)
        call FrameUtility.convertToNative(&(buffer[i].extendedAddress),
            ((payload + pendAddrSpecOffset +
              1 + (pendAddrSpec & PENDING_ADDRESS_SHORT_MASK)*2 + 8*i)));
      return SUCCESS;
    }
    return EINVAL;
  }

  command uint8_t BeaconFrame.isLocalAddrPending(message_t* frame)
  {
    uint8_t *mhr = MHR(frame);
    uint8_t *payload = (uint8_t *) frame->data;
    uint8_t pendAddrSpecOffset = getPendAddrSpecOffset(payload);      
    uint8_t pendAddrSpec = payload[pendAddrSpecOffset], i;
    ieee154_macShortAddress_t shortAddress = call MLME_GET.macShortAddress();
    if (((mhr[MHR_INDEX_FC1] & FC1_FRAMETYPE_MASK) != FC1_FRAMETYPE_BEACON))
      return ADDR_MODE_NOT_PRESENT;
    for (i=0; i<(pendAddrSpec & PENDING_ADDRESS_SHORT_MASK); i++)
      if (*((nxle_uint16_t*) (payload + pendAddrSpecOffset + 1 + 2*i)) == shortAddress)
        return ADDR_MODE_SHORT_ADDRESS;
    for (i=0; i<((pendAddrSpec & PENDING_ADDRESS_EXT_MASK) >> 4); i++)
      if (isLocalExtendedAddress(((payload + pendAddrSpecOffset + 
              1 + (pendAddrSpec & PENDING_ADDRESS_SHORT_MASK)*2 + 8*i))))
        return ADDR_MODE_EXTENDED_ADDRESS;
    return ADDR_MODE_NOT_PRESENT;
  }

  command void* BeaconFrame.getBeaconPayload(message_t* frame)
  {
    uint8_t *mhr = MHR(frame);
    uint8_t *payload = (uint8_t *) frame->data;
    if ((mhr[MHR_INDEX_FC1] & FC1_FRAMETYPE_MASK) == FC1_FRAMETYPE_BEACON){
      uint8_t pendAddrSpecOffset = getPendAddrSpecOffset(payload);
      uint8_t pendAddrSpec = payload[pendAddrSpecOffset];
      payload += (pendAddrSpecOffset + 1);
      if (pendAddrSpec & PENDING_ADDRESS_SHORT_MASK)
        payload += (pendAddrSpec & PENDING_ADDRESS_SHORT_MASK) * 2;
      if (pendAddrSpec & PENDING_ADDRESS_EXT_MASK)
        payload += ((pendAddrSpec & PENDING_ADDRESS_EXT_MASK) >> 4) * 8;
    }
    return payload;    
  }

  command uint8_t BeaconFrame.getBeaconPayloadLength(message_t* frame)
  {
    uint8_t *mhr = MHR(frame);
    uint8_t len = ((ieee154_header_t*) frame->header)->length & FRAMECTL_LENGTH_MASK;
    if ((mhr[MHR_INDEX_FC1] & FC1_FRAMETYPE_MASK) == FC1_FRAMETYPE_BEACON){
      uint8_t *payload = call Frame.getPayload(frame);
      len = len - (payload - (uint8_t *) frame->data);
    } 
    return len;
  }

  command uint8_t BeaconFrame.getBSN(message_t* frame)
  {
    return call Frame.getDSN(frame);
  }

  command error_t BeaconFrame.parsePANDescriptor(
      message_t *frame,
      uint8_t LogicalChannel,
      uint8_t ChannelPage,
      ieee154_PANDescriptor_t *PANDescriptor
      )
  {
    uint8_t *mhr = MHR(frame);
    uint8_t offset;
    ieee154_metadata_t *metadata = (ieee154_metadata_t*) frame->metadata;

    if ( (mhr[MHR_INDEX_FC1] & FC1_FRAMETYPE_MASK) != FC1_FRAMETYPE_BEACON ||
         (((mhr[MHR_INDEX_FC2] & FC2_SRC_MODE_MASK) != FC2_SRC_MODE_SHORT) && 
          ((mhr[MHR_INDEX_FC2] & FC2_SRC_MODE_MASK) != FC2_SRC_MODE_EXTENDED)) )
      return FAIL;
    PANDescriptor->CoordAddrMode = (mhr[MHR_INDEX_FC2] & FC2_SRC_MODE_MASK) >> FC2_SRC_MODE_OFFSET;
    offset = MHR_INDEX_ADDRESS;
    PANDescriptor->CoordPANId = *((nxle_uint16_t*) &mhr[offset]);
    offset += sizeof(ieee154_macPANId_t);
    if ((mhr[MHR_INDEX_FC2] & FC2_SRC_MODE_MASK) == FC2_SRC_MODE_SHORT)
      PANDescriptor->CoordAddress.shortAddress = *((nxle_uint16_t*) &mhr[offset]);
    else
      call FrameUtility.convertToNative(&PANDescriptor->CoordAddress.extendedAddress, &mhr[offset]);
    PANDescriptor->LogicalChannel = LogicalChannel;
    PANDescriptor->ChannelPage = ChannelPage;
    ((uint8_t*) &PANDescriptor->SuperframeSpec)[0] = frame->data[BEACON_INDEX_SF_SPEC1]; // little endian
    ((uint8_t*) &PANDescriptor->SuperframeSpec)[1] = frame->data[BEACON_INDEX_SF_SPEC2];
    PANDescriptor->GTSPermit = (frame->data[BEACON_INDEX_GTS_SPEC] & GTS_SPEC_PERMIT) ? 1 : 0;
    PANDescriptor->LinkQuality = metadata->linkQuality;
    PANDescriptor->TimeStamp = metadata->timestamp;
#ifndef IEEE154_SECURITY_ENABLED
    PANDescriptor->SecurityFailure = IEEE154_SUCCESS;
    PANDescriptor->SecurityLevel = 0;
    PANDescriptor->KeyIdMode = 0;
    PANDescriptor->KeySource = 0;
    PANDescriptor->KeyIndex = 0;    
#else
#error Implementation of BeaconFrame.parsePANDescriptor() needs adaptation !
#endif
    return SUCCESS;   
  }

/* ----------------------- FrameUtility, etc. ----------------------- */

  command uint64_t GetLocalExtendedAddress.get()
  {
    return m_aExtendedAddressLE;
  }

  async command void FrameUtility.convertToLE(uint8_t *destLE, const uint64_t *src)
  {
    uint8_t i;
    uint64_t srcCopy = *src;
    for (i=0; i<8; i++){
      destLE[i] = srcCopy;
      srcCopy >>= 8;
    }
  }

  async command void FrameUtility.convertToNative(uint64_t *dest, const uint8_t *srcLE)
  {
    // on msp430 nxle_uint64_t doesn't work, this is a workaround
    uint32_t lower = *((nxle_uint32_t*) srcLE);
    uint64_t upper = *((nxle_uint32_t*) (srcLE+4));
    *dest = (upper << 32) + lower;

  }

  async command void FrameUtility.copyLocalExtendedAddressLE(uint8_t *destLE)
  {
    call FrameUtility.convertToLE(destLE, &m_aExtendedAddressLE);
  }

  command void FrameUtility.copyCoordExtendedAddressLE(uint8_t *destLE)
  {
    call FrameUtility.convertToLE(destLE, &m_pib.macCoordExtendedAddress);
  }

  bool isLocalExtendedAddress(uint8_t *addrLE)
  {
    uint64_t dest;
    call FrameUtility.convertToNative(&dest, addrLE);
    return dest == m_aExtendedAddressLE;
  }

  bool isCoordExtendedAddress(uint8_t *addrLE)
  {
    uint64_t dest;
    call FrameUtility.convertToNative(&dest, addrLE);
    return dest == m_pib.macCoordExtendedAddress;
  }

  command bool IsBeaconEnabledPAN.get()
  {
    return (m_panType == BEACON_ENABLED_PAN);
  }

  default event void PIBUpdate.notify[uint8_t PIBAttributeID](const void* PIBAttributeValue){}
  command error_t PIBUpdate.enable[uint8_t PIBAttributeID](){return FAIL;}
  command error_t PIBUpdate.disable[uint8_t PIBAttributeID](){return FAIL;}
}
