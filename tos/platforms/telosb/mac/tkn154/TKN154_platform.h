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
 * $Revision: 1.4 $
 * $Date: 2009-03-26 17:50:44 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#ifndef __TKN154_platform_H
#define __TKN154_platform_H

/**************************************************** 
 * The following constants define guard times on Tmote Sky / TelosB. 
 * All values are in symbol time (1 symbol = 16 us) and assume the 
 * default system configuration (MCLK running at 4 MHz)
 */

enum {
  // the expected maximum time between calling a transmit() operation and
  // the radio putting the first byte on the channel assuming no CSMA-CA
  IEEE154_RADIO_TX_DELAY = 400,

  // the expected maximum time between calling a receive() operation and the 
  // the radio actually being put in receive mode
  IEEE154_RADIO_RX_DELAY = 400,

  // defines at what time the MAC payload for a beacon frame is assembled before
  // the next scheduled beacon transmission time; the value must be smaller than
  // the beacon interval plus the time for preparing the Tx operation
  BEACON_PAYLOAD_UPDATE_INTERVAL = 2500, 
};

// Defines the time to power the CC2420 radio from "Power Down" mode to "Idle"
// mode. The actual start up time of the oscillator is 860 us (with default
// capacitor, see CC2420 datasheet), but our constant must also include
// software latency (task posting, etc.) + shutting the radio down
// -> we keep it conservative, otherwise we may lose beacons
// NOTE: if this constant is not defined, the radio will never be powered down
// during inactive period, but always stay in idle (which consumes more energy).
#ifndef IEEE154_INACTIVE_PERIOD_POWERDOWN_DISABLED
  #ifndef IEEE154_RADIO_POWERUP_TIME
  #define IEEE154_RADIO_POWERUP_TIME 200
  #endif
#endif

#endif

