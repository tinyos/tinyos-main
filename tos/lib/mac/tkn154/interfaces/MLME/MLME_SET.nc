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
 * This interface can be used to set attribute values in the PHY/MAC PIB.
 * Instead of passing the PIB attribute identifier, there is a separate
 * command per attribute (and there are no confirm events). 
 *
 * NOTE: for the attributes macBeaconPayload (0x45) and
 * macBeaconPayloadLength (0x46) use the <tt>IEEE154TxBeaconPayload <\tt> 
 * interface; for promiscuous mode there is a separate (SplitControl)
 * interface. 
 **/

#include "TKN154.h" 
interface MLME_SET {

  /** @param value new PIB attribute value for phyCurrentChannel (0x00)
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t phyCurrentChannel(ieee154_phyCurrentChannel_t value);

  /** @param value new PIB attribute value for phyTransmitPower (0x02)
   *              (2 MSBs are ignored) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t phyTransmitPower(ieee154_phyTransmitPower_t value);

  /** @param value new PIB attribute value for phyCCAMode (0x03) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t phyCCAMode(ieee154_phyCCAMode_t value);

  /** @param value new PIB attribute value for phyCurrentPage (0x04) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t phyCurrentPage(ieee154_phyCurrentPage_t value);

  /** @param value new PIB attribute value for macAssociationPermit (0x41) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macAssociationPermit(ieee154_macAssociationPermit_t value);

  /** @param value new PIB attribute value for macAutoRequest (0x42) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macAutoRequest(ieee154_macAutoRequest_t value);

  /** @param value new PIB attribute value for macBattLifeExt (0x43) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macBattLifeExt(ieee154_macBattLifeExt_t value);

  /** @param value new PIB attribute value for macBattLifeExtPeriods (0x44) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macBattLifeExtPeriods(ieee154_macBattLifeExtPeriods_t value);

  /* macBeaconPayload (0x45) and macBeaconPayloadLength (0x46) are set
   * through the <tt>IEEE154TxBeaconPayload<\tt> interface. */

  /** @param value new PIB attribute value for macBeaconOrder (0x47) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macBeaconOrder(ieee154_macBeaconOrder_t value);

  /** @param value new PIB attribute value for macBSN (0x49)
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macBSN(ieee154_macBSN_t value);

  /** @param value new PIB attribute value for macCoordExtendedAddress (0x4A) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macCoordExtendedAddress(ieee154_macCoordExtendedAddress_t value);

  /** @param value new PIB attribute value for macCoordShortAddress (0x4B) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macCoordShortAddress(ieee154_macCoordShortAddress_t value);

  /** @param value new PIB attribute value for macDSN (0x4C) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macDSN(ieee154_macDSN_t value);

  /** @param value new PIB attribute value for macGTSPermit (0x4D) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macGTSPermit(ieee154_macGTSPermit_t value);

  /** @param value new PIB attribute value for macMaxCSMABackoffs (0x4E) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macMaxCSMABackoffs(ieee154_macMaxCSMABackoffs_t value);

  /** @param value new PIB attribute value for macMinBE (0x4F)
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macMinBE(ieee154_macMinBE_t value);

  /** @param value new PIB attribute value for macPANId (0x50) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macPANId(ieee154_macPANId_t value);

  /* macPromiscuousMode (0x51) is (re-)set through the 
   * <tt>PromiscuousMode<\tt> (SplitControl) interface. */

  /** @param value new PIB attribute value for macRxOnWhenIdle (0x52) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macRxOnWhenIdle(ieee154_macRxOnWhenIdle_t value);

  /** @param value new PIB attribute value for macShortAddress (0x53) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macShortAddress(ieee154_macShortAddress_t value);

  /** @param value new PIB attribute value for macTransactionPersistenceTime (0x55) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macTransactionPersistenceTime(ieee154_macTransactionPersistenceTime_t value);

  /** @param value new PIB attribute value for macAssociatedPANCoord (0x56) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macAssociatedPANCoord(ieee154_macAssociatedPANCoord_t value);

  /** @param value new PIB attribute value for macMaxBE (0x57) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macMaxBE(ieee154_macMaxBE_t value);

  /** @param value new PIB attribute value for macMaxFrameTotalWaitTime (0x58) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macMaxFrameTotalWaitTime(ieee154_macMaxFrameTotalWaitTime_t value);

  /** @param value new PIB attribute value for macMaxFrameRetries (0x59) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macMaxFrameRetries(ieee154_macMaxFrameRetries_t value);

  /** @param value new PIB attribute value for macResponseWaitTime (0x5A) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macResponseWaitTime(ieee154_macResponseWaitTime_t value);

  /** @param value new PIB attribute value for macSecurityEnabled (0x5D) 
   *  @returns IEEE154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command ieee154_status_t macSecurityEnabled(ieee154_macSecurityEnabled_t value);
}
