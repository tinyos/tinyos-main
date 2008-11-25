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
 * $Revision: 1.2 $
 * $Date: 2008-11-25 09:35:09 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * This interface can be used to read attribute values from the PHY/MAC PIB.
 * Instead of passing the PIB attribute identifier, there is a separate
 * command per attribute (and there are no confirm events). 
 *
 * NOTE: for the attributes macBeaconPayload (0x45) and
 * macBeaconPayloadLength (0x46) use the <tt>IEEE154TxBeaconPayload <\tt> 
 * interface; for promiscuous mode there is a separate (SplitControl)
 * interface. 
 **/

#include "TKN154.h" 
interface MLME_GET {

  /** @return PIB attribute phyCurrentChannel (0x00) */
  command ieee154_phyCurrentChannel_t phyCurrentChannel();

  /** @return PIB attribute phyChannelsSupported (0x01) */
  command ieee154_phyChannelsSupported_t phyChannelsSupported();

  /** @return PIB attribute phyTransmitPower (0x02) */
  command ieee154_phyTransmitPower_t phyTransmitPower();

  /** @return PIB attribute phyCCAMode (0x03) */
  command ieee154_phyCCAMode_t phyCCAMode();

  /** @return PIB attribute phyCurrentPage (0x04) */
  command ieee154_phyCurrentPage_t phyCurrentPage();

  /** @return PIB attribute phyMaxFrameDuration (0x05) */
  command ieee154_phyMaxFrameDuration_t phyMaxFrameDuration();

  /** @return PIB attribute phySHRDuration (0x06) */
  command ieee154_phySHRDuration_t phySHRDuration();

  /** @return PIB attribute phySymbolsPerOctet (0x07) */
  command ieee154_phySymbolsPerOctet_t phySymbolsPerOctet();

  /** @return PIB attribute macAckWaitDuration (0x40) */
  command ieee154_macAckWaitDuration_t macAckWaitDuration();

  /** @return PIB attribute macAssociationPermit (0x41) */
  command ieee154_macAssociationPermit_t macAssociationPermit();

  /** @return PIB attribute macAutoRequest (0x42) */
  command ieee154_macAutoRequest_t macAutoRequest();

  /** @return PIB attribute macBattLifeExt (0x43) */
  command ieee154_macBattLifeExt_t macBattLifeExt();

  /** @return PIB attribute macBattLifeExtPeriods (0x44) */
  command ieee154_macBattLifeExtPeriods_t macBattLifeExtPeriods();

  /* macBeaconPayload (0x45) and macBeaconPayloadLength (0x46) are read
   * through the <tt>IEEE154TxBeaconPayload<\tt> interface. */

  /** @return PIB attribute macBeaconOrder (0x47) */
  command ieee154_macBeaconOrder_t macBeaconOrder();

  /** @return PIB attribute macBeaconTxTime (0x48) */
  command ieee154_macBeaconTxTime_t macBeaconTxTime();

  /** @return PIB attribute macBSN (0x49) */
  command ieee154_macBSN_t macBSN();

  /** @return PIB attribute macCoordExtendedAddress (0x4A) */
  command ieee154_macCoordExtendedAddress_t macCoordExtendedAddress();

  /** @return PIB attribute macCoordShortAddress (0x4B) */
  command ieee154_macCoordShortAddress_t macCoordShortAddress();

  /** @return PIB attribute macDSN (0x4C) */
  command ieee154_macDSN_t macDSN();

  /** @return PIB attribute macGTSPermit (0x4D) */
  command ieee154_macGTSPermit_t macGTSPermit();

  /** @return PIB attribute macMaxCSMABackoffs (0x4E) */
  command ieee154_macMaxCSMABackoffs_t macMaxCSMABackoffs();

  /** @return PIB attribute macMinBE (0x4F) */
  command ieee154_macMinBE_t macMinBE();

  /** @return PIB attribute macPANId (0x50) */
  command ieee154_macPANId_t macPANId();

  /** @return PIB attribute macPromiscuousMode (0x51) */
  command ieee154_macPromiscuousMode_t macPromiscuousMode();

  /** @return PIB attribute macRxOnWhenIdle (0x52) */
  command ieee154_macRxOnWhenIdle_t macRxOnWhenIdle();

  /** @return PIB attribute macShortAddress (0x53) */
  command ieee154_macShortAddress_t macShortAddress();

  /** @return PIB attribute macSuperframeOrder (0x54) */
  command ieee154_macSuperframeOrder_t macSuperframeOrder();

  /** @return PIB attribute macTransactionPersistenceTime (0x55) */
  command ieee154_macTransactionPersistenceTime_t macTransactionPersistenceTime();

  /** @return PIB attribute macAssociatedPANCoord (0x56) */
  command ieee154_macAssociatedPANCoord_t macAssociatedPANCoord();

  /** @return PIB attribute macMaxBE (0x57) */
  command ieee154_macMaxBE_t macMaxBE();

  /** @return PIB attribute macMaxFrameTotalWaitTime (0x58) */
  command ieee154_macMaxFrameTotalWaitTime_t macMaxFrameTotalWaitTime();

  /** @return PIB attribute macMaxFrameRetries (0x59) */
  command ieee154_macMaxFrameRetries_t macMaxFrameRetries();

  /** @return PIB attribute macResponseWaitTime (0x5A) */
  command ieee154_macResponseWaitTime_t macResponseWaitTime();

  /** @return PIB attribute macSyncSymbolOffset (0x5B) */
  command ieee154_macSyncSymbolOffset_t macSyncSymbolOffset();

  /** @return PIB attribute macTimestampSupported (0x5C) */
  command ieee154_macTimestampSupported_t macTimestampSupported();

  /** @return PIB attribute macSecurityEnabled (0x5D) */
  command ieee154_macSecurityEnabled_t macSecurityEnabled();

  /** @return PIB attribute macMinLIFSPeriod */
  command ieee154_macMinLIFSPeriod_t macMinLIFSPeriod();

  /** @return PIB attribute macMinSIFSPeriod */
  command ieee154_macMinSIFSPeriod_t macMinSIFSPeriod();
}
