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
 * $Revision: 1.7 $
 * $Date: 2009-03-24 12:56:47 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
/*
 * Copyright (c) 2010, CISTER/ISEP - Polytechnic Institute of Porto
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
 * 
 * 
 * 
 * @author Ricardo Severino <rars@isep.ipp.pt>
 * @author Stefano Tennina <sota@isep.ipp.pt>
 * ========================================================================
 */

/** 
 * The contention free period (CFP) in beacon mode, a.k.a. GTS, is not yet
 * implemented - this is only an empty placeholder. In contrast to the CAP
 * component the GTS component for an incoming superframe will probably be very
 * different from the GTS for an outgoing superframe. That is why there are two
 * separate placeholder components (DeviceCfpP and CoordCfpP) instead of one
 * generic CfpP component. This component would deal with the GTS for an
 * incoming superframe, i.e. from the perspective of a device.
 */

#include "TKN154_MAC.h"
module NoDeviceCfpP
{
  provides {
    interface Init;
    interface FrameTx as CfpTx;
    interface Purge;
    interface FrameRx;
    interface MLME_GTS;
  } uses {
    interface TransferableResource as RadioToken;
    interface Alarm<TSymbolIEEE802154,uint32_t> as CfpSlotAlarm;
    interface Alarm<TSymbolIEEE802154,uint32_t> as CfpEndAlarm;
    interface SuperframeStructure as IncomingSF; 
    interface RadioTx;
    interface RadioRx;
    interface RadioOff;
    interface MLME_GET;
    interface MLME_SET;
    interface FrameTx as GTSrequestTx;
    interface Pool<ieee154_txframe_t> as TxFramePool;
    interface Pool<ieee154_txcontrol_t> as TxControlPool;
    interface FrameUtility;
  }
}
implementation
{
  command error_t Init.init()
  {
    return SUCCESS;
  }

  command ieee154_status_t MLME_GTS.requestFromPAN  (
      uint8_t GtsCharacteristics,
      uint16_t DeviceAddress,
      ieee154_security_t *security
      )
  {
    return IEEE154_INVALID_GTS;
  }
  command ieee154_status_t MLME_GTS.request  (
      uint8_t GtsCharacteristics,
      ieee154_security_t *security
      )
  {
    return IEEE154_INVALID_GTS;
  }

  command ieee154_status_t CfpTx.transmit(ieee154_txframe_t *data)
  {
    return IEEE154_INVALID_GTS;
  }

  command ieee154_status_t Purge.purge(uint8_t msduHandle)
  {
    // request to purge a frame (triggered by MCPS_DATA.purge())
    return IEEE154_INVALID_HANDLE; 
  } 

  async event void RadioToken.transferredFrom(uint8_t fromClient)
  { 
#ifndef IEEE154_BEACON_TX_DISABLED
    call RadioToken.transferTo(RADIO_CLIENT_BEACONTRANSMIT);
#else
    call RadioToken.transferTo(RADIO_CLIENT_BEACONSYNCHRONIZE);
#endif
  }

  async event void CfpEndAlarm.fired() {}

  async event void CfpSlotAlarm.fired()  {}

  async event void RadioOff.offDone() {}

  async event void RadioTx.transmitDone(
      ieee154_txframe_t *frame, error_t result)
  {}

  async event void RadioRx.enableRxDone(){} 

  event message_t* RadioRx.received(message_t *frame)
  { // signal it to responsible client component 
    return signal FrameRx.received(frame);
  } 

  event void RadioToken.granted()
  {
    ASSERT(0); // should never happen, because we never call RadioToken.request()
  }   

  event void GTSrequestTx.transmitDone(ieee154_txframe_t *txFrame, ieee154_status_t status)
  {}

  default event void MLME_GTS.indication (
      uint16_t DeviceAddress,
      uint8_t GtsCharacteristics,
      ieee154_security_t *security
      ){}

  default event void MLME_GTS.confirm    (
      uint8_t GtsCharacteristics,
      ieee154_status_t  status
      ){}
}
