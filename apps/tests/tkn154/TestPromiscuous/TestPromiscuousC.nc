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
 * $Date: 2008-07-21 15:18:16 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
#include "TKN154.h"
module TestPromiscuousC
{
  uses {
    interface Boot;
    interface MLME_RESET;
    interface MLME_SET;
    interface MLME_GET;
    interface MCPS_DATA;
    interface Leds;
    interface IEEE154Frame as Frame;
    interface IEEE154BeaconFrame as BeaconFrame;
    interface SplitControl as PromiscuousMode;
  }
} implementation {

  const char *m_frametype[] = {"Beacon", "Data","Acknowledgement","MAC command", "Unknown"};
  const char *m_cmdframetype[] = {"unknown command", "Association request","Association response",
    "Disassociation notification","Data request","PAN ID conflict notification",
    "Orphan notification", "Beacon request", "Coordinator realignment", "GTS request"};

  enum {
    RADIO_CHANNEL = 26,
  };

  event void Boot.booted() {
    call MLME_RESET.request(TRUE, BEACON_ENABLED_PAN);
  }

  event void MLME_RESET.confirm(ieee154_status_t status)
  {
    call MLME_SET.phyCurrentChannel(RADIO_CHANNEL);
    call PromiscuousMode.start();
  }

  event message_t* MCPS_DATA.indication (message_t* frame)
  {
    uint8_t i;
    uint8_t *payload = call Frame.getPayload(frame);
    uint8_t payloadLen = call Frame.getPayloadLength(frame);
    uint8_t *header = call Frame.getHeader(frame);
    uint8_t headerLen = call Frame.getHeaderLength(frame);
    uint8_t SrcAddrMode, DstAddrMode;
    uint8_t frameType, cmdFrameType;
    ieee154_address_t SrcAddress, DstAddress;
    uint16_t SrcPANId=0, DstPANId=0;

    if (call Frame.hasStandardCompliantHeader(frame)){
      frameType = call Frame.getFrameType(frame);
      if (frameType > FRAMETYPE_CMD)
        frameType = 4;
      call Frame.getSrcPANId(frame, &SrcPANId);
      call Frame.getDstPANId(frame, &DstPANId);
      call Frame.getSrcAddr(frame, &SrcAddress);
      call Frame.getDstAddr(frame, &DstAddress);
      SrcAddrMode = call Frame.getSrcAddrMode(frame);
      DstAddrMode = call Frame.getDstAddrMode(frame);

      printf("\n");
      printf("Frametype: %s", m_frametype[frameType]);
      if (frameType == FRAMETYPE_CMD){
        cmdFrameType = payload[0];
        if (cmdFrameType > 9)
          cmdFrameType = 0;
        printf(" (%s)", m_cmdframetype[cmdFrameType]);
      }
      printf("\n");
      printf("SrcAddrMode: %d\n", SrcAddrMode);
      printf("SrcAddr: ");
      if (SrcAddrMode == ADDR_MODE_SHORT_ADDRESS){
        printf("0x%hx\n", SrcAddress.shortAddress);
        printf("SrcPANId: 0x%x\n", SrcPANId);
      } else if (SrcAddrMode == ADDR_MODE_EXTENDED_ADDRESS){
        for (i=0; i<8; i++)
          printf("0x%hx ", ((uint8_t*) &(SrcAddress.extendedAddress))[i]);
        printf("\n");
        printf("SrcPANId: 0x%x\n", SrcPANId);
      } else printf("\n");
      printf("DstAddrMode: %d\n", DstAddrMode);
      printf("DstAddr: ");
      if ( DstAddrMode == ADDR_MODE_SHORT_ADDRESS){
        printf("0x%hx\n", DstAddress.shortAddress);
        printf("DestPANId: 0x%x\n", DstPANId);
      } else if  ( DstAddrMode == ADDR_MODE_EXTENDED_ADDRESS) {
        for (i=0; i<8; i++)
          printf("0x%hx ", ((uint8_t*) &(DstAddress.extendedAddress))[i]);
        printf("\n");    
        printf("DestPANId: 0x%x\n", DstPANId);
      } else printf("\n");

      printf("DSN: %d\n", call Frame.getDSN(frame));
      printf("MHRLen: %d\n", headerLen);
      printf("MHR: ");
      for (i=0; i<headerLen; i++){
        printf("0x%hx ", header[i]);
      }
      printf("\n");      
      printf("PayloadLen: %d\n", payloadLen);
      printf("Payload: ");
      for (i=0; i<payloadLen; i++){
        printf("0x%hx ", payload[i]);
      }
      printf("\n");
      printf("MpduLinkQuality: %d\n", call Frame.getLinkQuality(frame));

      printf("Timestamp: ");
      if (call Frame.isTimestampValid(frame))
        printf("%ld\n", call Frame.getTimestamp(frame));
      else
        printf("INVALID\n");
      printfflush(); 
    }
    call Leds.led1Toggle();
    return frame;
  }

  event void MCPS_DATA.confirm( message_t *msg, uint8_t msduHandle, ieee154_status_t status, uint32_t Timestamp){}
  event void PromiscuousMode.startDone(error_t error) 
  {
    printf("\n*** Radio is now in promiscuous mode, listening on channel %d ***\n", RADIO_CHANNEL);
    printfflush(); 
  }
  event void PromiscuousMode.stopDone(error_t error) {}
}
