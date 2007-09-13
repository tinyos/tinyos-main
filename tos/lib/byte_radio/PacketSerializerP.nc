/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * $Date: 2007-09-13 23:10:17 $
 * ========================================================================
 */

#include "crc.h"
#include "message.h"
#include "radiopacketfunctions.h"

/**
 * This module in conjunction with the UartPhyC turns byte streams
 * into packtes.
 *
 * @see UartPhyC
 *
 * @author Kevin Klues <klues@tkn.tu-berlin.de>
 * @author Philipp Huppertz <huppertz@tkn.tu-berlin.de>
 */

module PacketSerializerP {
  provides {
    interface Init;
    interface PhySend;
    interface PhyReceive;
    interface Packet;
    interface RadioTimeStamping;
  }
  uses {
    interface RadioByteComm;
    interface PhyPacketTx;
    interface PhyPacketRx;
  }
}
implementation {
  /* Module Global Variables */

  message_t *txBufPtr;  // pointer to tx buffer
  message_t *rxBufPtr;  // pointer to rx buffer
  message_t rxMsg;      // rx message buffer
  uint16_t crc;         // CRC value of either the current incoming or outgoing packet
  uint8_t byteCnt;      // index into current datapacket
      
  /* Local Function Declarations */
  void TransmitNextByte();
  void ReceiveNextByte(uint8_t data);

  typedef enum {
      SFD_OFFSET = sizeof(message_header_t) - sizeof(message_radio_header_t) + 2
  } pserializer_constants_t;
  
  /* Radio Init  */
  command error_t Init.init(){
    atomic {
      crc = 0;
      txBufPtr = NULL;
      rxBufPtr = &rxMsg;
      byteCnt = 0;
    }
    return SUCCESS;
  }

  /*- Radio Send */
  async command error_t PhySend.send(message_t* msg, uint8_t len) {
    message_radio_header_t* header = getHeader(msg);
    atomic {
      crc = 0;
      txBufPtr = msg;
      header->length = len;
      // message_header_t can contain more than only the message_radio_header_t
      byteCnt = (sizeof(message_header_t) - sizeof(message_radio_header_t)); // offset
    }
    call PhyPacketTx.sendHeader();
    return SUCCESS;
  }
  
  async event void PhyPacketTx.sendHeaderDone() {
      TransmitNextByte();
  }

  async event void RadioByteComm.txByteReady(error_t error) {
    if(error == SUCCESS) {
      TransmitNextByte();
    } else {
      signal PhySend.sendDone((message_t*)txBufPtr, FAIL);
    }
  }

  void TransmitNextByte() {
    message_radio_header_t* header = getHeader((message_t*) txBufPtr);
    if (byteCnt < header->length + sizeof(message_header_t) ) {  // send (data + header), compute crc
        if(byteCnt == SFD_OFFSET) {
            signal RadioTimeStamping.transmittedSFD(0, (message_t*)txBufPtr);
        }
        crc = crcByte(crc, ((uint8_t *)(txBufPtr))[byteCnt]);
        call RadioByteComm.txByte(((uint8_t *)(txBufPtr))[byteCnt++]);
    }
    else if (byteCnt == (header->length + sizeof(message_header_t))) {
      ++byteCnt;
      call RadioByteComm.txByte((uint8_t)crc);
    }
    else if  (byteCnt == (header->length + sizeof(message_header_t)+1)) {
      ++byteCnt;
      call RadioByteComm.txByte((uint8_t)(crc >> 8));
    }
    else { /* (byteCnt > (header->length + sizeof(message_header_t)+1)) */
        call PhyPacketTx.sendFooter();
    }
  }

  async event void PhyPacketTx.sendFooterDone() {
    signal PhySend.sendDone((message_t*)txBufPtr, SUCCESS);
  }
  
  /* Radio Receive */
  async event void PhyPacketRx.recvHeaderDone(error_t error) {
    if(error == SUCCESS) {
      byteCnt = (sizeof(message_header_t) - sizeof(message_radio_header_t));
      crc = 0;
      getHeader(rxBufPtr)->length = sizeof(message_radio_header_t); 
      signal PhyReceive.receiveDetected();
    }
  }

  async event void RadioByteComm.rxByteReady(uint8_t data) {
    ReceiveNextByte(data);
  }

  async event void PhyPacketRx.recvFooterDone(error_t error) {
    message_radio_header_t* header = getHeader((message_t*)(rxBufPtr));
    message_radio_footer_t* footer = getFooter((message_t*)rxBufPtr);
    // we care about wrong crc in this layer
    if (footer->crc != 1) error = FAIL;
    rxBufPtr = signal PhyReceive.receiveDone((message_t*)rxBufPtr, ((message_t*)rxBufPtr)->data, header->length, error);
  }

  /* Receive the next Byte from the USART */
  void ReceiveNextByte(uint8_t data) { 
    message_radio_footer_t* footer = getFooter((message_t*)rxBufPtr);
    ((uint8_t *)(rxBufPtr))[byteCnt++] = data;
    if(byteCnt < getHeader(rxBufPtr)->length + sizeof(message_radio_header_t)) {
      if(byteCnt == SFD_OFFSET) {
          signal RadioTimeStamping.receivedSFD(0);
      }
      crc = crcByte(crc, data);
      if (getHeader(rxBufPtr)->length > TOSH_DATA_LENGTH) { 
        // this packet is surely corrupt, so whatever...
        footer->crc = 0;
        call PhyPacketRx.recvFooter();
      }
    } else if (byteCnt == (getHeader(rxBufPtr)->length + sizeof(message_radio_header_t))) {
      crc = crcByte(crc, data);
      byteCnt = offsetof(message_t, footer) + offsetof(message_radio_footer_t, crc);
    } else if (byteCnt == (offsetof(message_t, footer) + sizeof(message_radio_footer_t))) {
      footer->crc = (footer->crc == crc);
      call PhyPacketRx.recvFooter();
    }
  }

  
  /* Packet interface */
      
  command void Packet.clear(message_t* msg) {
    memset(msg, 0, sizeof(message_t));
  }

  command uint8_t Packet.payloadLength(message_t* msg) {
    return (getHeader(msg))->length;
  }

  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    getHeader(msg)->length  = len;
  }
  command uint8_t Packet.maxPayloadLength() {
    return TOSH_DATA_LENGTH;
  }

  command void* Packet.getPayload(message_t* msg, uint8_t len) {
    if (len <= TOSH_DATA_LENGTH) {
      return (void*)msg->data;
    }
    else {
      return NULL;
    }
  }
  
  // Default events for radio send/receive coordinators do nothing.
  // Be very careful using these, or you'll break the stack.
  default async event void RadioTimeStamping.transmittedSFD(uint16_t time, message_t* msgBuff) { }
  default async event void RadioTimeStamping.receivedSFD(uint16_t time) { }
}
