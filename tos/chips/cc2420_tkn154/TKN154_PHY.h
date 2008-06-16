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
 * $Revision: 1.1 $
 * $Date: 2008-06-16 18:02:40 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

// PHY constants for the CC2420
#ifndef __TKN154_PHY_H
#define __TKN154_PHY_H

#include "TKN154_MAC.h"

enum {

  IEEE154_SUPPORTED_CHANNELS  = 0x07FFF800,
  IEEE154_SYMBOLS_PER_OCTET   = 2,
  IEEE154_TXPOWER_TOLERANCE   = 0x80,
  IEEE154_SHR_DURATION        = (5 * IEEE154_SYMBOLS_PER_OCTET),
  IEEE154_MAX_FRAME_DURATION  = (IEEE154_SHR_DURATION + ((IEEE154_aMaxPHYPacketSize + 1) * IEEE154_SYMBOLS_PER_OCTET)),
  IEEE154_PREAMBLE_LENGTH     = (4*IEEE154_SYMBOLS_PER_OCTET),
  IEEE154_SYNC_SYMBOL_OFFSET  = (1 * IEEE154_SYMBOLS_PER_OCTET),
  IEEE154_MIN_LIFS_PERIOD     = 40,
  IEEE154_MIN_SIFS_PERIOD     = 12,
  IEEE154_ACK_WAIT_DURATION   = (20 + 12 + IEEE154_SHR_DURATION + 6 * IEEE154_SYMBOLS_PER_OCTET),
  // TODO: check BATT_LIFE_EXT
  IEEE154_BATT_LIFE_EXT_PERIODS      = 1,
  IEEE154_BATT_LIFE_EXT_PERIOD_TERM3 = 1,
  IEEE154_TIMESTAMP_SUPPORTED        = TRUE,

};

#include "Timer62500hz.h"
#define TSymbolIEEE802154 T62500hz

#endif

