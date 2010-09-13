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
 * $Date: 2009/10/29 17:42:56 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
#include "TKN154.h"
#include "app_profile.h"
module SnifferC
{
  provides interface SerialPacketInfo;
  uses {
    interface Boot;
    interface MLME_RESET;
    interface MLME_SET;
    interface MLME_GET;
    interface MCPS_DATA;
    interface Leds;
    interface Queue<message_t*> as Queue;
    interface Pool<message_t> as Pool;
    interface IEEE154Frame as Frame;
    interface IEEE154BeaconFrame as BeaconFrame;
    interface SplitControl as PromiscuousMode;
    interface SplitControl as SerialControl;
    interface Send as SerialSend;
  }
} implementation {

  bool m_serialSendBusy;
  task void serialSendTask();

  event void Boot.booted() {
    m_serialSendBusy = FALSE;
    if (call Pool.maxSize() != call Queue.maxSize() ||
        call SerialControl.start() != SUCCESS)
      call Leds.led0On(); // error
  }

  event void SerialControl.startDone(error_t error) {
    if (error != SUCCESS)
      call Leds.led0On(); // error
    else
      call MLME_RESET.request(TRUE);
  }

  event void MLME_RESET.confirm(ieee154_status_t status)
  {
    if (status != IEEE154_SUCCESS)
      call Leds.led0On(); // error
    else {
      call MLME_SET.phyCurrentChannel(INITAL_RADIO_CHANNEL);
      if (call PromiscuousMode.start() != SUCCESS)
        call Leds.led0On(); // error
    }
  }

  event void PromiscuousMode.startDone(error_t error) 
  {
    // ready - we're now in "sniffing mode" ...
    call Leds.led2On(); 
  }

  event message_t* MCPS_DATA.indication (message_t* frame)
  {
    // -> received a frame: queue it and post a task to
    // forward it over serial
    call Leds.led1Toggle();
    if (call Queue.enqueue(frame) != SUCCESS) {
      call Leds.led0On(); // overflow
      return frame;
    } else {
      post serialSendTask();
      return call Pool.get();
    }
  }

  task void serialSendTask() 
  {
    message_t* frame;
    sniffer_metadata_t *snifferMetadata;
    uint8_t headerLen; 
    uint8_t payloadLen; 
    uint8_t serialLen; 
    ieee154_metadata_t *radioMetadata;
    uint8_t rssi, lqi;
    uint8_t *header;
    uint32_t timestamp;
    uint8_t *phyLenField;

    if (call Queue.empty() || m_serialSendBusy)
      return;
    frame = call Queue.head();
    radioMetadata = (ieee154_metadata_t*) &frame->metadata;
    rssi = radioMetadata->rssi;
    lqi = radioMetadata->linkQuality;
    timestamp = radioMetadata->timestamp;
    headerLen = call Frame.getHeaderLength(frame);
    payloadLen = call Frame.getPayloadLength(frame);
    header = call Frame.getHeader(frame);

    // update PHY length field: set it to the length of
    // MHR + payload (ignoring CRC footer)
    phyLenField = (uint8_t*) frame + call SerialPacketInfo.offset();
    *phyLenField = headerLen + payloadLen; 

    // need to move the payload to the front, because there can be a
    // gap between the end of the header and the start of the payload
    // section (-> do not touch the frame via Frame interface afterwards)
    memmove(header + headerLen, call Frame.getPayload(frame), payloadLen);

    snifferMetadata = (sniffer_metadata_t *) (header + headerLen + payloadLen);
    if ((uint8_t*) snifferMetadata + sizeof(sniffer_metadata_t) > 
        (uint8_t*) frame + sizeof(message_t)) {
      // message_t is too small to hold frame content + sniffer_metadata_t
      // (this cannot happen, unless someone messes with the header files)
      call Leds.led0On();
      return;
    }
    snifferMetadata->lqi = lqi;
    snifferMetadata->rssi = rssi - 45; // substract offset (see CC2420 datasheet)

    // IEEE 802.15.4 Std: incoming packets with incorrect CRC 
    // are discarded even in promiscuous mode (so all frames
    // we get here must have passed the CRC check already)
    snifferMetadata->crc = 1;
    snifferMetadata->mhrLen = headerLen;
    snifferMetadata->channel = call MLME_GET.phyCurrentChannel();
    snifferMetadata->timestamp = timestamp;

    serialLen = 1 + // for the PHY length field
      headerLen + payloadLen + sizeof(sniffer_metadata_t);     
    m_serialSendBusy = TRUE;
    if (call SerialSend.send(frame, serialLen) != SUCCESS)
      call Leds.led0On();
  }
  
  event void SerialSend.sendDone(message_t* frame, error_t error) {
    if (error != SUCCESS)
      call Leds.led0On();
    else {
      call Pool.put(call Queue.dequeue());
      m_serialSendBusy = FALSE;
      if (!call Queue.empty())
        post serialSendTask();
    }
  }

  async command uint8_t SerialPacketInfo.offset()
  {
    return offsetof(message_t, header) +
           offsetof(message_header_t, ieee154) +
           offsetof(ieee154_header_t, length);
  }

  async command uint8_t SerialPacketInfo.dataLinkLength(message_t* frame, uint8_t upperLen)
  {
    // returns size of the serial PDU
    uint8_t length = *((uint8_t*) frame + call SerialPacketInfo.offset());
    return 1 + length + sizeof(sniffer_metadata_t); // 1 for the length-field itself
  }

  async command uint8_t SerialPacketInfo.upperLength(message_t* msg, uint8_t dataLinkLen)
  {
    // returns size of the serial PDU minus the MAC header length
    uint8_t *phyLenField = (uint8_t*) msg + call SerialPacketInfo.offset();
    sniffer_metadata_t *snifferMetadata = 
      (sniffer_metadata_t *) (phyLenField + *phyLenField);
    return *phyLenField + sizeof(sniffer_metadata_t) - snifferMetadata->mhrLen;
  }

  event void MCPS_DATA.confirm( message_t *msg, uint8_t msduHandle, ieee154_status_t status, uint32_t Timestamp){}
  event void PromiscuousMode.stopDone(error_t error) {}
  event void SerialControl.stopDone(error_t error) {}
}
