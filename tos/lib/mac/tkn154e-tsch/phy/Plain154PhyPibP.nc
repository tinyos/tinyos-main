/**
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

#include "plain154_phy_pib.h"
#define PLAIN154_TXPOWER_TOLERANCE 0x80
#define PLAIN154_SUPPORTED_CHANNELS 0x07FFF800

/**
 * TODO Module description
 */
module Plain154PhyPibP
{
  provides {
    interface Init;
    interface Notify<const void*> as PIBUpdate[uint8_t PIBAttributeID];
    interface Plain154PlmeGet;
    interface Plain154PlmeSet;
  }
  uses { // TODO ?
    ;
  }
}
implementation
{
  /**
   * IEEE 15.4 PHY PIB variables
   */
  plain154_phy_pib_t pib;

  /**
   * Non-interface functions
   */
  void setDefaultAttributes() {
    pib.phyCurrentChannel = PLAIN154_DEFAULT_CURRENTCHANNEL;
    pib.phyTransmitPower = (PLAIN154_TXPOWER_TOLERANCE | (PLAIN154_DEFAULT_TRANSMITPOWER_dBm & 0x3F));
//    pib.phyCCAMode = PLAIN154_DEFAULT_CCAMODE;
//    pib.phyCurrentPage = PLAIN154_DEFAULT_CURRENTPAGE;
    pib.phyChannelsSupported = PLAIN154_DEFAULT_CHANNELSSUPPORTED_PAGE0;
  }

  /**
   * Init
   */
  command error_t Init.init()
  {
    setDefaultAttributes();
	return SUCCESS;
  }

  /**
   * MLME_GET (15.4 PHY)
   */
  command plain154_phyCurrentChannel_t    Plain154PlmeGet.phyCurrentChannel()
    { return pib.phyCurrentChannel; }

  command plain154_phyChannelsSupported_t Plain154PlmeGet.phyChannelsSupported()
    { return PLAIN154_SUPPORTED_CHANNELS; }

  command plain154_phyTransmitPower_t     Plain154PlmeGet.phyTransmitPower()
    { return pib.phyTransmitPower; }

//  command plain154_phyCCAMode_t           Plain154PlmeGet.phyCCAMode()
//    { return pib.phyCCAMode; }

//  command plain154_phyCurrentPage_t       Plain154PlmeGet.phyCurrentPage()
//    { return pib.phyCurrentPage; }

//  command plain154_phyMaxFrameDuration_t  Plain154PlmeGet.phyMaxFrameDuration()
//    { return PLAIN154_MAX_FRAME_DURATION; }

//  command plain154_phySHRDuration_t       Plain154PlmeGet.phySHRDuration()
//    { return PLAIN154_SHR_DURATION; }

//  command plain154_phySymbolsPerOctet_t   Plain154PlmeGet.phySymbolsPerOctet()
//    { return PLAIN154_SYMBOLS_PER_OCTET; }

  /**
   * MLME_SET (15.4 PHY)
   */
  command plain154_status_t Plain154PlmeSet.phyCurrentChannel(plain154_phyCurrentChannel_t value) {
    uint32_t i = 1;
    uint8_t k = value;
    while (i && k) {
      i <<= 1;
      k -= 1;
    }
    if (!(PLAIN154_SUPPORTED_CHANNELS & i))
      return PLAIN154_PHY_INVALID_PARAMETER;
    pib.phyCurrentChannel = value;
    signal PIBUpdate.notify[PLAIN154_phyCurrentChannel](&pib.phyCurrentChannel);
    return PLAIN154_PHY_SUCCESS;
  }

  command plain154_status_t Plain154PlmeSet.phyTransmitPower(plain154_phyTransmitPower_t value) {
    pib.phyTransmitPower = (value & 0x3F);
    signal PIBUpdate.notify[PLAIN154_phyTransmitPower](&pib.phyTransmitPower);
    return PLAIN154_PHY_SUCCESS;
  }
/*
  command plain154_status_t Plain154PlmeSet.phyCCAMode(plain154_phyCCAMode_t value) {
    if (value < 1 || value > 3)
      return PLAIN154_PHY_INVALID_PARAMETER;
    pib.phyCCAMode = value;
    signal PIBUpdate.notify[PLAIN154_phyCCAMode](&pib.phyCCAMode);
    return PLAIN154_PHY_SUCCESS;
  }

  command plain154_status_t Plain154PlmeSet.phyCurrentPage(plain154_phyCurrentPage_t value) {
    if (value > 31)
      return PLAIN154_PHY_INVALID_PARAMETER;
    pib.phyCurrentPage = value;
    signal PIBUpdate.notify[PLAIN154_phyCurrentPage](&pib.phyCurrentPage);
    return PLAIN154_PHY_SUCCESS;
  }
*/

  /**
   * PhyPIBUpdate
   */
  default event void PIBUpdate.notify[uint8_t PIBAttributeID](const void* PIBAttributeValue) {}
  command error_t PIBUpdate.enable[uint8_t PIBAttributeID]() { return FAIL; }
  command error_t PIBUpdate.disable[uint8_t PIBAttributeID]() { return FAIL; }
}
