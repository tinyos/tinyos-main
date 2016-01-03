/*
 * Copyright (c) 2014, Technische Universitaet Berlin
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
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 * @author Jasper Buesch <buesch@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TknTschConfigLog.h"
//ifndef TKN_TSCH_LOG_ENABLED_PIB
//undef TKN_TSCH_LOG_ENABLED
//endif
#include "tkntsch_log.h"

#include "tkntsch_pib.h"
#include "tkntsch_lock.h"
#include "static_config.h"

module TknTschPibP {

  provides interface TknTschMlmeGet;
  provides interface TknTschMlmeSet;

  provides interface TknTschPib;
  provides interface Init;
}
implementation {
  tkntsch_pib_t pib;
  const uint8_t m_hoppingSequenceList[] = TSCH_HOPPING_SEQUENCE;

  // TODO figure out how to ensure atomic accesses to the pib
  // TODO atomic sections are costly

  command error_t Init.init()
  {
    atomic pib.lock = TKNTSCH_LOCK_LOCKED;

    // general
    atomic {
    pib.macASN = 0;
    pib.joinPriority = 0;
    pib.macTSCHcapable = TRUE;
    pib.macTSCHenabled = FALSE;

    // CSMA
    pib.macMinBE = 1; // TSCH-CA default: 1 (range: 0 - maxBE)
    pib.macMaxBE = 3; // TSCH-CA default: 7 (range: 3 - 8), 6TiSCH default: 3
    pib.macMaxFrameRetries = 6;

    pib.macHoppingSequenceList = (uint8_t*)m_hoppingSequenceList;
    pib.macHoppingSequenceLength = (uint8_t) sizeof(m_hoppingSequenceList);
    }


    TKNTSCH_RELEASE_LOCK(pib.lock);
    return SUCCESS;
  }


  /*** MLME SET ************************************************/

  async command plain154_status_t TknTschMlmeSet.macJoinPriority( uint8_t priority )
  {
    atomic pib.joinPriority = priority;
    return PLAIN154_SUCCESS;
  }

  async command plain154_status_t TknTschMlmeSet.macASN( tkntsch_asn_t asn )
  {
    atomic pib.macASN = asn;
    return PLAIN154_SUCCESS;
  }

  async command plain154_status_t TknTschMlmeSet.macBeaconSyncRxTimestamp( uint32_t macBeaconSyncRxTimestamp )
  {
    atomic pib.macBeaconSyncRxTimestamp = macBeaconSyncRxTimestamp;
    return PLAIN154_SUCCESS;
  }

  async command plain154_status_t TknTschMlmeSet.macPanId( plain154_macPANId_t panid )
  {
    atomic pib.macPanId = panid;
    return PLAIN154_SUCCESS;
  }

  async command plain154_status_t TknTschMlmeSet.macShortAddr(uint16_t shortAddr)
  {
    atomic pib.macShortAddress = shortAddr;
    return PLAIN154_SUCCESS;
  }

  async command plain154_status_t TknTschMlmeSet.macExtAddr(plain154_extended_address_t macExtendedAddress)
  {
    atomic pib.macExtendedAddress = macExtendedAddress;
    return PLAIN154_SUCCESS;
  }

  async command plain154_status_t TknTschMlmeSet.macDSN(plain154_macDSN_t macDSN)
  {
    atomic pib.macDSN = macDSN;
    return PLAIN154_SUCCESS;
  }

  async command plain154_status_t TknTschMlmeSet.macAutoRequest(bool macAutoRequest)
  {
    atomic pib.macAutoRequest = macAutoRequest;
    return PLAIN154_SUCCESS;
  }

  async command plain154_status_t TknTschMlmeSet.isCoordinator(bool isCoordinator)
  {
    atomic pib.isCoordinator = isCoordinator;
    return PLAIN154_SUCCESS;
  }

  async command plain154_status_t TknTschMlmeSet.macTimeParent(plain154_address_t timeParentAddress)
  {
    atomic pib.timeParentAddress = timeParentAddress;
    return PLAIN154_SUCCESS;
  }

  async command plain154_status_t TknTschMlmeSet.macMinBE(uint8_t minBE)
  {
    atomic pib.macMinBE = minBE;
    return PLAIN154_SUCCESS;
  }

  async command plain154_status_t TknTschMlmeSet.macMaxBE(uint8_t maxBE)
  {
    atomic pib.macMaxBE = maxBE;
    return PLAIN154_SUCCESS;
  }

  async command plain154_status_t TknTschMlmeSet.macMaxFrameRetries(uint8_t maxFrameRetries)
  {
    atomic pib.macMaxFrameRetries = maxFrameRetries;
    return PLAIN154_SUCCESS;
  }


  /*** MLME GET ************************************************/

  async command uint8_t TknTschMlmeGet.macJoinPriority()
  {
    atomic return pib.joinPriority;
  }

  async command tkntsch_asn_t TknTschMlmeGet.macASN()
  {
    atomic return pib.macASN;
  }

  async command uint32_t TknTschMlmeGet.macBeaconSyncRxTimestamp()
  {
    atomic return pib.macBeaconSyncRxTimestamp;
  }


  async command plain154_macPANId_t TknTschMlmeGet.macPanId()
  {
    atomic return pib.macPanId;
  }

  async command uint16_t TknTschMlmeGet.macShortAddr()
  {
    atomic return pib.macShortAddress;
  }

  async command plain154_extended_address_t TknTschMlmeGet.macExtAddr()
  {
    atomic return pib.macExtendedAddress;
  }

  async command plain154_macDSN_t TknTschMlmeGet.macDSN()
  {
    atomic return pib.macDSN;
  }

  async command bool TknTschMlmeGet.macAutoRequest()
  {
    atomic return pib.macAutoRequest;
  }

  async command bool TknTschMlmeGet.isCoordinator()
  {
    atomic return pib.isCoordinator;
  }

  async command plain154_address_t TknTschMlmeGet.macTimeParent()
  {
    atomic return pib.timeParentAddress;
  }

  async command uint8_t TknTschMlmeGet.macMinBE()
  {
    atomic return pib.macMinBE;
  }

  async command uint8_t TknTschMlmeGet.macMaxBE()
  {
    atomic return pib.macMaxBE;
  }

  async command uint8_t TknTschMlmeGet.macMaxFrameRetries()
  {
    atomic return pib.macMaxFrameRetries;
  }

  async command uint8_t* TknTschMlmeGet.macHoppingSequenceList() {
    atomic return pib.macHoppingSequenceList;
  }

  async command uint8_t* TknTschMlmeGet.macHoppingSequenceLength() {
    atomic return pib.macHoppingSequenceLength;
  }


  /*************************************************************/


  async command tkntsch_pib_t* TknTschPib.getPib()
  {
    return &pib;
  }

  task void printPib()
  {
#ifdef TKN_TSCH_LOG_DEBUG
    volatile uint32_t tmp;
    tkntsch_pib_t p, *ppib;
    ppib = call TknTschPib.getPib();
    TKNTSCH_ACQUIRE_LOCK(ppib->lock, tmp);
    if (tmp == FALSE) {
      T_LOG_ERROR("printPib: Can't copy PIB, it's locked!\n"); T_LOG_FLUSH;
      return;
    }
    atomic p = *ppib; // shallow copy
    TKNTSCH_RELEASE_LOCK(ppib->lock);

    for (tmp = 0; tmp < 300000; tmp++) {}
    T_LOG_DEBUG("printPib\n  macASN_MSB: %u, macASN: %lu\n", p.macASN_MSB, p.macASN);
    T_LOG_DEBUG("  macTSCHcapable: %u\n", p.macTSCHcapable);
    T_LOG_DEBUG("  macTSCHenabled: %u\n", p.macTSCHenabled);
    T_LOG_FLUSH;
    for (tmp = 0; tmp < 300000; tmp++) {}
    T_LOG_DEBUG("  macHoppingSequenceID: %u\n", p.macHoppingSequenceID);
    T_LOG_DEBUG("  macHoppingSequenceLength: %u\n", p.macHoppingSequenceLength);
    T_LOG_DEBUG("  macHoppingSequence: N/A\n");
    T_LOG_DEBUG("  macCurrentHop: %u\n", p.macCurrentHop);
    T_LOG_DEBUG("  macMinBE: %u\n", p.macMinBE);
    T_LOG_DEBUG("  macMaxBE: %u\n", p.macMaxBE);
    T_LOG_FLUSH;
#endif
  }

  async command void TknTschPib.printPib() { post printPib(); }
}
