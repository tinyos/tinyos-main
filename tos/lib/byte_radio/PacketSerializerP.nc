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
 * $Revision: 1.9 $
 * $Date: 2010-01-27 14:42:10 $
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
        interface PhySend;
        interface PhyReceive;
        interface Packet;
        interface RadioTimeStamping;
    }
    uses {
        interface RadioByteComm;
        interface PhyPacketTx;
        interface PhyPacketRx;
#ifdef PACKETSERIALIZER_DEBUG
        interface SerialDebug;
#endif
    }
}
implementation {
    
#ifdef PACKETSERIALIZER_DEBUG
    void sdDebug(uint16_t p) {
        call SerialDebug.putPlace(p);
    }
#else
    void sdDebug(uint16_t p) {};
#endif

    /* Module Global Variables */

    message_t rxMsg;      // rx message buffer
    message_t *rxBufPtr = &rxMsg;  // pointer to rx buffer
    message_t *txBufPtr = NULL;  // pointer to tx buffer
    uint16_t crc = 0;         // CRC value of either the current incoming or outgoing packet
    uint8_t byteCnt = 0;      // index into current datapacket
      
    /* Local Function Declarations */
    void TransmitNextByte();
    void ReceiveNextByte(uint8_t data);

    typedef enum {
        SFD_OFFSET  =  sizeof(message_header_t) - sizeof(message_radio_header_t) + 2
    } pserializer_constants_t;
  
    /*- Radio Send */
    async command error_t PhySend.send(message_t* msg, uint8_t len) {
        atomic {
            crc = 0;
            txBufPtr = msg;
            // assume "right (LSB) aligned" unions -- highly compiler and platform specific
            byteCnt = sizeof(message_header_t) - sizeof(message_radio_header_t);
            getHeader(msg)->length = len;
            sdDebug(4000 + getHeader(msg)->token);
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
            signal PhySend.sendDone(txBufPtr, FAIL);
        }
    }

    void TransmitNextByte() {
        if(byteCnt < sizeof(message_header_t) + getHeader(txBufPtr)->length) {
            // transmit the data part
            uint8_t* buf = (uint8_t *)(txBufPtr);
            crc = crcByte(crc, buf[byteCnt]);
            call RadioByteComm.txByte(buf[byteCnt]);
            byteCnt++;
            if(byteCnt == SFD_OFFSET) {
                signal RadioTimeStamping.transmittedSFD(0, txBufPtr);
            }
        }
        else if(byteCnt == sizeof(message_header_t) + getHeader(txBufPtr)->length) {
            call RadioByteComm.txByte(crc);
            byteCnt++;            
        }
        else if(byteCnt == sizeof(message_header_t) + getHeader(txBufPtr)->length + 1) {
            call RadioByteComm.txByte(crc >> 8);
            byteCnt++;
        }
        else {
            call PhyPacketTx.sendFooter();
        }
    }
    
    async event void PhyPacketTx.sendFooterDone() {
        sdDebug(6000 + getHeader(txBufPtr)->token);
        signal PhySend.sendDone((message_t*)txBufPtr, SUCCESS);
    }
  
    /* Radio Receive */
    async event void PhyPacketRx.recvHeaderDone(error_t error) {
        if(error == SUCCESS) {
            byteCnt = sizeof(message_header_t) - sizeof(message_radio_header_t);
            getHeader(rxBufPtr)->length = sizeof(message_radio_header_t);
            crc = 0;
            signal PhyReceive.receiveDetected();
        }
    }
    
    async event void RadioByteComm.rxByteReady(uint8_t data) {
        ReceiveNextByte(data);
    }

    async event void PhyPacketRx.recvFooterDone(error_t error) {
        // we care about wrong crc in this layer
        if(!getFooter(rxBufPtr)->crc) {
            error = FAIL;
        }
        else {
            
        }
        byteCnt = 0;
        rxBufPtr = signal PhyReceive.receiveDone(rxBufPtr, rxBufPtr->data, getHeader(rxBufPtr)->length, error);
    }
    
    /* Receive the next Byte from the USART */
    void ReceiveNextByte(uint8_t data) {
        uint8_t* buf = (uint8_t *)(rxBufPtr);
        buf[byteCnt++] = data;
        if(byteCnt <= sizeof(message_header_t) + getHeader(rxBufPtr)->length) {
            crc = crcByte(crc, data);
            if(byteCnt == SFD_OFFSET) {
                signal RadioTimeStamping.receivedSFD(0);
            }
            else if(byteCnt == sizeof(message_header_t) + getHeader(rxBufPtr)->length) {
                byteCnt = offsetof(message_t, footer) + offsetof(message_radio_footer_t, crc);
            }
            if(getHeader(rxBufPtr)->length > TOSH_DATA_LENGTH) {
                getFooter(rxBufPtr)->crc = 0;
                call PhyPacketRx.recvFooter();
            }
        }
        else if(byteCnt >= offsetof(message_t, footer) + offsetof(message_radio_footer_t, crc) + sizeof(crc)) {
            message_radio_footer_t* footer = getFooter(rxBufPtr);
            footer->crc = (footer->crc == crc);
            call PhyPacketRx.recvFooter();
            sdDebug(5000 + getHeader(rxBufPtr)->token);
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
