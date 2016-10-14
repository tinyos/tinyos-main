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
 * @author Jasper Buesch <buesch@tkn.tu-berlin.de>
 */

#include "message.h"
#include "Jn516.h"
//#include "plain154_message_structs.h"
#include "plain154_values.h"

module Plain154PhyPacketTransformP {
  provides {
    interface Plain154PacketTransform;
  } uses {
    interface Plain154Frame;
    interface Packet;
  }
}
implementation {

  unsigned short crc16_data(const unsigned char *data, int len, unsigned short acc);
  inline unsigned short crc16_add(unsigned char b, unsigned short acc);

  async command error_t Plain154PacketTransform.Plain154ToMMAC(plain154_txframe_t* from, tsPhyFrame* to) {
    uint8_t u8_tmp, *ptr, data_index;
    uint16_t u16_tmp;
    //error_t error;
    //plain154_address_t address;
    uint16_t checksum;

    data_index = 0;
    ptr = to->uPayload.au8Byte;

    to->u8PayloadLength = (from->headerLen) + (from->payloadLen) + 2;  // plus 2 byte CRC
    ptr[data_index++] = from->header->fcf1;
    ptr[data_index++] = from->header->fcf2;
    ptr[data_index++] = from->header->dsn;


    if (call Plain154Frame.getDstPANId(from->header, &u16_tmp) == SUCCESS) {
      ptr[data_index++] = (uint8_t) u16_tmp;
      ptr[data_index++] = (uint8_t) (u16_tmp >> 8);
    }

    u8_tmp = call Plain154Frame.getDstAddrMode(from->header);
    if (u8_tmp > PLAIN154_ADDR_NOT_PRESENT) {
      uint8_t *t;
      t = (uint8_t *) &(from->header->dest.short_addr);
      if (u8_tmp == PLAIN154_ADDR_SHORT) {
        ptr[data_index++] = t[0];
        ptr[data_index++] = t[1];
      } else if (u8_tmp == PLAIN154_ADDR_EXTENDED) {
        memcpy(&ptr[data_index], t, 8);
        data_index += 8;
      } else {
        return FAIL;
      }
    }

    if (call Plain154Frame.getSrcPANId(from->header, &u16_tmp) == SUCCESS) {
      ptr[data_index++] = (uint8_t) u16_tmp;
      ptr[data_index++] = (uint8_t) (u16_tmp >> 8);
    }

    u8_tmp = call Plain154Frame.getSrcAddrMode(from->header);
    if (u8_tmp > PLAIN154_ADDR_NOT_PRESENT) {
      uint8_t *t;
      t = (uint8_t *) &(from->header->src.short_addr);
      if (u8_tmp == PLAIN154_ADDR_SHORT) {
        ptr[data_index++] = t[0];
        ptr[data_index++] = t[1];
      } else if (u8_tmp == PLAIN154_ADDR_EXTENDED) {
        memcpy(&ptr[data_index], t, 8);
        data_index += 8;
      } else {
        return FAIL;
      }
    }

    if (call Plain154Frame.isIEListPresent(from->header)) {
      uint8_t hieLength = 0;
      uint16_t ie_header;
      uint8_t* hiePtr = (uint8_t *) from->header->hie;
      uint8_t ie_length;
      uint8_t ie_eid;
      ie_header = hiePtr[0] + (hiePtr[1] << 8);
      ie_length = ie_header & 0x7f;
      ie_eid = (ie_header >> 7) & 0x7f;
      hieLength += 2;
      while (((ie_eid & 0x7e) != 0x7e) && (hieLength < 6)) {
        // Check for HIE termination (EID bits 7-14; value 0x7e or 0x7f means termination)
        // lowest bit (7th in first byte) is not checked, since the same for 0x7e and 0x7f
        hieLength += ie_length;
        if ((data_index + hieLength) >= from->headerLen)  // catches non terminated ACKS
          break;
        ie_header = hiePtr[hieLength] + (hiePtr[hieLength+1] << 8);
        ie_length = ie_header & 0x7f;
        ie_eid = (ie_header >> 7) & 0x7f;
        hieLength += 2;
      }
      memcpy(&ptr[data_index], from->header->hie, hieLength);
      data_index += hieLength;
    }

    //printf("Plain154PhyPacketTransforP: Payload processing\n");
    //printfflush();

    memcpy(&ptr[data_index], from->payload, from->payloadLen);
    data_index += from->payloadLen;

    checksum = crc16_data((void*) ptr, to->u8PayloadLength-2, 0);
    ptr[data_index++] = checksum;
    ptr[data_index++] = (checksum >> 8) & 0xff;

    return SUCCESS;
  }


  /**
   * Convert the tsPhyFrame format to message_t using plain154_header_t
   */
  // TODO 'to' is a message_t... it has to be handled as such
  async command error_t Plain154PacketTransform.MMACToPlain154(tsPhyFrame* from, message_t* to) {
    plain154_header_t *to_hdr = call Plain154Frame.getHeader(to);
    //uint8_t *payload = call Packet.getPayload(to, call Packet.maxPayloadLength());
    //uint8_t *ptr = (uint8_t *) to;
    uint8_t *from_data;
    uint16_t u16_tmp;
    uint8_t u8_tmp;
    uint8_t *tmp, data_index;
    uint16_t checksum;

    //printf("Transforming a packet now!\n");
    //printfflush();

    from_data = from->uPayload.au8Byte;
    data_index = 0;

    // Check that CRC checksum is correct
    checksum = crc16_data((void*) from_data, from->u8PayloadLength-2, 0);
    checksum -= from_data[from->u8PayloadLength-2];
    checksum -= from_data[from->u8PayloadLength-1] << 8;
    if (checksum != 0) {
      return FAIL;
    }

    to_hdr->fcf1 = from_data[data_index++];
    to_hdr->fcf2 = from_data[data_index++];
    to_hdr->dsn = from_data[data_index++];

    if (call Plain154Frame.getDstPANId(to_hdr, &u16_tmp) == SUCCESS) {
      to_hdr->destpan = from_data[data_index++];
      to_hdr->destpan |= from_data[data_index++] << 8;
    }
    u8_tmp = call Plain154Frame.getDstAddrMode(to_hdr);
    if (u8_tmp > PLAIN154_ADDR_NOT_PRESENT){
      tmp = (uint8_t *) &(to_hdr->dest);
      if (u8_tmp == PLAIN154_ADDR_SHORT) {
        tmp[0] = from_data[data_index++];
        tmp[1] = from_data[data_index++];
      } else if (u8_tmp == PLAIN154_ADDR_EXTENDED) {
        memcpy(tmp, &from_data[data_index], 8);
        data_index += 8;
      } else {
        return FAIL;
      }
    }
    if (call Plain154Frame.getSrcPANId(to_hdr, &u16_tmp) == SUCCESS) {
      to_hdr->srcpan = from_data[data_index++];
      to_hdr->srcpan |= from_data[data_index++] << 8;
    }
    u8_tmp = call Plain154Frame.getSrcAddrMode(to_hdr);
    if (u8_tmp > PLAIN154_ADDR_NOT_PRESENT){
      tmp = (uint8_t *) &(to_hdr->src);
      if (u8_tmp == PLAIN154_ADDR_SHORT) {
        tmp[0] = from_data[data_index++];
        tmp[1] = from_data[data_index++];
      } else if (u8_tmp == PLAIN154_ADDR_EXTENDED) {
        memcpy(tmp, &from_data[data_index], 8);
        data_index += 8;
      } else {
        return FAIL;
      }
    }

    if (call Plain154Frame.isIEListPresent(to_hdr)) {
      uint8_t ieLength;
      uint16_t ieHeader;
      uint8_t ieEid;
      uint8_t iesTotalLen = 0;
      uint8_t fromHdrIndex = data_index;
      uint8_t savelen;

      ieHeader = from_data[fromHdrIndex++];
      ieHeader += (from_data[fromHdrIndex++] << 8);
      ieEid = (ieHeader >> 7) & 0x7f;

      ieLength = ieHeader & 0x7f;
      iesTotalLen += 2;
      while ((ieEid & 0x7e) != 0x7e) {
        savelen = iesTotalLen - 2;
        iesTotalLen += ieLength;
        fromHdrIndex += ieLength;
        ieHeader = from_data[fromHdrIndex++];
        ieHeader += (from_data[fromHdrIndex++] << 8);
        ieLength = ieHeader & 0x7f;
        ieEid = (ieHeader >> 7) & 0x7f;
        iesTotalLen += 2;
        if (iesTotalLen > sizeof(to_hdr->hie)) {
          iesTotalLen = savelen;
          break;
        }
        if ((ieEid != 0x7f) &&
            (from->u8PayloadLength - 2) == (fromHdrIndex + ieLength)) {
          // end of frame reached; HIE is not terminated
          printf("HIE term. missing\n");
          break;
        }
      }
      memcpy(to_hdr->hie, &from_data[data_index], iesTotalLen);
      data_index += iesTotalLen;
    }

    to_hdr->payloadlen = from->u8PayloadLength - data_index - 2; // two bytes CRC
    memcpy(call Packet.getPayload(to, to_hdr->payloadlen), &from_data[data_index], to_hdr->payloadlen);
    data_index += to_hdr->payloadlen;

    call Packet.setPayloadLength(to, to_hdr->payloadlen);

    // TODO: What to do with the CRC??

    return SUCCESS;
  }


  // ----- CRC functions --------------------------------
  // The following two function has been taken from Contiki to calculate the packet's
  // CRC in software in order to be able to use the vMMAC_StartPhyTransmit(..), which
  // doesn't set the CRC

  inline unsigned short crc16_add(unsigned char b, unsigned short acc) {
   acc ^= b;
   acc  = (acc >> 8) | (acc << 8);
   acc ^= (acc & 0xff00) << 4;
   acc ^= (acc >> 8) >> 4;
   acc ^= (acc & 0xff00) >> 5;
   return acc;
  }

  unsigned short crc16_data(const unsigned char *data, int len, unsigned short acc) {
   uint8_t i;

   for(i = 0; i < len; ++i) {
    acc = crc16_add(*data, acc);
    ++data;
   }
   return acc;
  }
}
