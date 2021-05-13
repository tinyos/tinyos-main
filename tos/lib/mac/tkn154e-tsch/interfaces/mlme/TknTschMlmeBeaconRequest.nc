/*
 * Copyright (c) 2015, Technische Universitaet Berlin
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
 * @author Jasper Büsch <buesch@tkn.tu-berlin.de>
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 */


#include "tkntsch_types.h"


interface TknTschMlmeBeaconRequest 
{

  /**
   * The MLME-BEACON.request primitive requests the generation of a beacon or 
   * enhanced beacon in a non- beacon-enabled PAN, either in response to a beacon 
   * request command when macBeaconAutoRespond is FALSE, or on demand, e.g., 
   * to send beacons to enable a TSCH passive scan.
   * 
   * @param BeaconType  BEACON = 0: send a beacon. ENHANCED BEACON = 1: 
                        send an enhanced beacon.
   * @param SrcAddrMode The source addressing mode for device from whom the 
                        beacon request was received. 
   * @param SrcAddr     The device who sent the beacon request, if present, 
                        otherwise the short broadcast address (0xffff)
   * @param dstPANID    The PANID contained in the beacon request, or the broadcast 
                        PAN ID (0xffff) if PAN ID not present.
   * @param IEList      If BeaconType = 0x01, the EB Filter IE and/or other IEs are 
                        contained in the beacon request. Otherwise it is empty.
   *
   * @return       IEEE154_SUCCESS if the request succeeded and a confirm event
   *               will be signalled, an appropriate error code otherwise 
   *               (no confirm event will be signalled in this case)
   * @see          confirm
  */
  command plain154_status_t indication  (
                          uint8_t BeaconType,
                          uint8_t SrcAddrMode,
                          plain154_address_t *SrcAddr,
                          uint16_t dstPANID,
                          uint8_t *IEList
                        );
}

