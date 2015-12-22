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
 */

#include "plain154_phy.h"
#include "plain154_types.h"
#include "tkntsch_types.h"

/**
 * MLME-SET
 */

interface TknTschMlmeSet
{

  async command plain154_status_t macJoinPriority(
      uint8_t priority
    );

  async command plain154_status_t macASN(
      tkntsch_asn_t asn
    );

  async command plain154_status_t macBeaconSyncRxTimestamp(
      uint32_t macBeaconSyncRxTimestamp
  );

  async command plain154_status_t macPanId(
      plain154_macPANId_t panid
    );

  async command plain154_status_t macShortAddr(
      uint16_t shortAddr
    );

  async command plain154_status_t macExtAddr(
      plain154_extended_address_t extendedAddr
    );

  async command plain154_status_t macDSN(
  	  plain154_macDSN_t macDSN
    );

  async command plain154_status_t macAutoRequest(
      bool macAutoRequest
    );

  async command plain154_status_t isCoordinator(
      bool isCoordinator
    );

  async command plain154_status_t macTimeParent(
      plain154_address_t timeParentAddress
    );

  async command plain154_status_t macMinBE(
      uint8_t minBE
    );

  async command plain154_status_t macMaxBE(
      uint8_t maxBE
    );

  async command plain154_status_t macMaxFrameRetries(
      uint8_t maxFrameRetries
    );

}
