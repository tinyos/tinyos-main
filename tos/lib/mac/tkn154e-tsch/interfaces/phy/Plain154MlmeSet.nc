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
 * $Revision: 1.3 $
 * $Date: 2009-03-04 18:31:42 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 * ========================================================================
 */


/** 
 * This interface allows to set attribute values in the PHY/MAC PIB.
 * Instead of passing the PIB attribute identifier, there is a separate
 * command per attribute (and there are no confirm events). 
 */

#include "plain154_phy.h"
#include "plain154_phy_pib.h"

interface Plain154MlmeSet {

  /** @param value new PIB attribute value for phyCurrentChannel (0x00)
   *  @returns PLAIN154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command plain154_status_t phyCurrentChannel(plain154_phyCurrentChannel_t value);

  /** @param value new PIB attribute value for phyTransmitPower (0x02)
   *              (2 MSBs are ignored) 
   *  @returns PLAIN154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
  command plain154_status_t phyTransmitPower(plain154_phyTransmitPower_t value);

  /** @param value new PIB attribute value for phyCCAMode (0x03) 
   *  @returns PLAIN154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
//  command plain154_status_t phyCCAMode(plain154_phyCCAMode_t value);

  /** @param value new PIB attribute value for phyCurrentPage (0x04) 
   *  @returns PLAIN154_SUCCESS if PIB attribute was updated, INVALID_PARAMETER if 
   *           parameter value is out of valid range and PIB was not updated */
//  command plain154_status_t phyCurrentPage(plain154_phyCurrentPage_t value);
}

