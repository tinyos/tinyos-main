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

#include "TKN154_MAC.h"

module NoScanP
{
  provides
  {
    interface Init;
    interface MLME_SCAN;
    interface MLME_BEACON_NOTIFY;
  }
  uses
  {
    interface MLME_GET;
    interface MLME_SET;
    interface EnergyDetection;
    interface RadioOff;
    interface RadioRx;
    interface RadioTx;
    interface IEEE154Frame as Frame;
    interface IEEE154BeaconFrame as BeaconFrame;
    interface Timer<TSymbolIEEE802154> as ScanTimer;
    interface Pool<ieee154_txframe_t> as TxFramePool;
    interface Pool<ieee154_txcontrol_t> as TxControlPool;
    interface Resource as Token;
    interface FrameUtility;
    interface Leds;
  }
}
implementation
{

  command error_t Init.init() { return SUCCESS;}

  command ieee154_status_t MLME_SCAN.request  (
                          uint8_t ScanType,
                          uint32_t ScanChannels,
                          uint8_t ScanDuration,
                          uint8_t ChannelPage,
                          uint8_t EnergyDetectListNumEntries,
                          int8_t* EnergyDetectList,
                          uint8_t PANDescriptorListNumEntries,
                          ieee154_PANDescriptor_t* PANDescriptorList,
                          ieee154_security_t *security
                        )
  {
    return IEEE154_TRANSACTION_OVERFLOW;
  }

  event void Token.granted()
  {
    call Token.release();
  }

  event void EnergyDetection.done(error_t status, int8_t EnergyLevel){}

  async event void RadioRx.prepareDone() { }

  event message_t* RadioRx.received(message_t *frame, ieee154_reftime_t *time)
  {
    return frame;
  }

  async event void RadioTx.loadDone() { }

  async event void RadioTx.transmitDone(ieee154_txframe_t *frame, ieee154_reftime_t *txTime){}

  async event void RadioTx.transmitUnslottedCsmaCaDone(ieee154_txframe_t *frame,
      bool ackPendingFlag, ieee154_csma_t *csmaParameters, error_t result){}

  async event void RadioTx.transmitSlottedCsmaCaDone(ieee154_txframe_t *frame, ieee154_reftime_t *txTime, 
      bool ackPendingFlag, uint16_t remainingBackoff, ieee154_csma_t *csmaParameters, error_t result){}
 
  event void ScanTimer.fired() { }

  async event void RadioOff.offDone() { }
}
