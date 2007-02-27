/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2006, Technische Universitaet Berlin
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
 */

#include "code4b6b.h"

/**
 * Implementation of the physical layer for the eyesIFX byte radio.
 * Together with the PacketSerializerP this module turns byte streams 
 * into packets.
 *
 * @author Andreas Koepke <koepke@tkn.tu-berlin.de>
 */
module Uart4b6bPhyP {
    provides {
        interface Init;
        interface PhyPacketTx;
        interface RadioByteComm as SerializerRadioByteComm;
        interface PhyPacketRx;
        interface UartPhyControl;
    }
    uses {
        interface RadioByteComm;
        interface Alarm<T32khz, uint16_t> as RxByteTimer;
    }
}
implementation
{
    /* Module Definitions  */
    typedef enum {
        STATE_PREAMBLE,
        STATE_PREAMBLE_CODE,
        STATE_SYNC,
        STATE_SFD1,
        STATE_SFD2,
        STATE_SFD3,
        STATE_HEADER_DONE,
        STATE_DATA_HIGH_OR_SFD,
        STATE_DATA_HIGH,
        STATE_DATA_MIDDLE,
        STATE_DATA_LOW,
        STATE_DATA_LOW_FOOTER,
        STATE_FOOTER_START,
        STATE_FOOTER_DONE
    } phyState_t;

    /* constants */
    enum {
        PREAMBLE_LENGTH=2,
        BYTE_TIME=9,
        PREAMBLE_BYTE=0x55,
        SYNC_BYTE=0xFF,
        SFD_BYTE=0x83,
        SFD_BYTE2=0x7c
    };
    
    /** Module Global Variables  */
    phyState_t phyState;    // Current Phy state State
    uint16_t preambleCount;
    uint16_t numPreambles;  // Number of preambles to send before the packet
    uint8_t byteTime;       // max. time between two bytes
    uint8_t bufByte;
    /* Local Function Declarations */
    void TransmitNextByte();
    void ReceiveNextByte(uint8_t data);

    /* Radio Init */
    command error_t Init.init(){
        atomic {
            phyState = STATE_PREAMBLE;
            numPreambles = PREAMBLE_LENGTH;
            byteTime = BYTE_TIME;
        }
        return SUCCESS;
    }
    
    async command error_t UartPhyControl.setNumPreambles(uint16_t numPreambleBytes) {
        atomic {
            numPreambles = numPreambleBytes;
        }
        return SUCCESS;
    }
    
    command error_t UartPhyControl.setByteTimeout(uint8_t byteTimeout) {
        if (call RxByteTimer.isRunning() == TRUE) {
            return FAIL;
        } else {
            byteTime = byteTimeout * 33;
            return SUCCESS;
        }
    }
    
    async command bool UartPhyControl.isBusy() {
        return phyState != STATE_PREAMBLE;
    }
    
    void resetState() {
        call RxByteTimer.stop();
        if(phyState >= STATE_DATA_HIGH) {
            signal PhyPacketRx.recvFooterDone(FAIL);
        }
        phyState = STATE_PREAMBLE; 
    }

    async event void RxByteTimer.fired() {
        // no bytes have arrived, so...
        resetState();
    }

    async command void PhyPacketTx.sendHeader() {
        phyState = STATE_PREAMBLE;
        preambleCount = numPreambles;
        TransmitNextByte();
    }

    async command void SerializerRadioByteComm.txByte(uint8_t data) {
        uint8_t high = nibbleToSixBit[(data & 0xf0) >> 4];
        uint8_t low = nibbleToSixBit[data & 0x0f];
        if(phyState == STATE_DATA_HIGH) {
            high <<= 2;
            if(low & 0x20) high |= 2;
            if(low & 0x10) high |= 1;
            bufByte = low << 4;
            call RadioByteComm.txByte(high);
            phyState = STATE_DATA_MIDDLE;
        }
        else {
            call RadioByteComm.txByte(bufByte | (high >> 2));
            if(high & 0x02) low |= 0x80;
            if(high & 0x01) low |= 0x40;
            bufByte = low;
            phyState = STATE_DATA_LOW;
        }
    }

    async command bool SerializerRadioByteComm.isTxDone() {
        return call RadioByteComm.isTxDone();
    }

    async command void PhyPacketTx.sendFooter() {
        if(phyState == STATE_DATA_MIDDLE) {
            bufByte |= (nibbleToSixBit[0] >> 2);
            phyState = STATE_DATA_LOW_FOOTER;
            call RadioByteComm.txByte(bufByte);
        } else {
            phyState = STATE_FOOTER_START;
            TransmitNextByte();
        }
    }
    


    /* Radio Recv */
    async command void PhyPacketRx.recvFooter() {
        // currently there is no footer
        // atomic phyState = STATE_FOOTER_START;
        phyState = STATE_PREAMBLE;
        call RxByteTimer.stop();
        signal PhyPacketRx.recvFooterDone(SUCCESS);
    }

    
    /* Tx Done */
    async event void RadioByteComm.txByteReady(error_t error) {
        if(error == SUCCESS) {
            TransmitNextByte();
        } else {
            signal SerializerRadioByteComm.txByteReady(error);
            phyState = STATE_PREAMBLE;
        }
    }

    void TransmitNextByte() {
        switch(phyState) {
            case STATE_PREAMBLE:
                if(preambleCount > 0) {
                    preambleCount--;
                } else {
                    phyState = STATE_SYNC;
                }
                call RadioByteComm.txByte(PREAMBLE_BYTE);
                break;
            case STATE_SYNC:
                phyState = STATE_SFD1;
                call RadioByteComm.txByte(SYNC_BYTE);
                break;
            case STATE_SFD1:
                phyState = STATE_SFD2;
                call RadioByteComm.txByte(SFD_BYTE);
                break;
            case STATE_SFD2:
                phyState = STATE_SFD3;
                call RadioByteComm.txByte(SFD_BYTE);
                break;
            case STATE_SFD3:
                phyState = STATE_HEADER_DONE;
                call RadioByteComm.txByte(SFD_BYTE);
                break;
            case STATE_HEADER_DONE:
                phyState = STATE_DATA_HIGH;
                signal PhyPacketTx.sendHeaderDone();
                break;
            case STATE_DATA_HIGH:
                signal SerializerRadioByteComm.txByteReady(SUCCESS);
                break;
            case STATE_DATA_MIDDLE:
                signal SerializerRadioByteComm.txByteReady(SUCCESS);
                break;
            case STATE_DATA_LOW:
                call RadioByteComm.txByte(bufByte);
                phyState = STATE_DATA_HIGH;
                break;
            case STATE_DATA_LOW_FOOTER:
                phyState = STATE_FOOTER_START;
                call RadioByteComm.txByte(bufByte);
                break;
            case STATE_FOOTER_START:
                /* Pseudo-Footer: the MSP430 has two buffers: one for
                 * transmit, one to store the next byte to be transmitted,
                 * this footer fills the next-to-transmit buffer, to make
                 * sure that the last real byte is actually
                 * transmitted. The byte stored by this call may not be
                 * transmitted fully or not at all. 
                 */
                phyState = STATE_FOOTER_DONE;
                call RadioByteComm.txByte(bufByte);
                break;
            case STATE_FOOTER_DONE:
                phyState = STATE_PREAMBLE;
                signal PhyPacketTx.sendFooterDone();
                break;
            default:
                break;
        }
    }

    /* Rx Done */
    async event void RadioByteComm.rxByteReady(uint8_t data) {
        uint8_t decodedByte;
        uint8_t low;
        uint8_t high;
        if((data == SFD_BYTE) && (phyState != STATE_SFD2) && (phyState != STATE_DATA_HIGH_OR_SFD)) {
            resetState();
            phyState = STATE_SFD2;
            call RxByteTimer.start(byteTime<<1);
        }
        else {
            switch(phyState) {
                case STATE_SFD2:
                    if(data == SFD_BYTE) {
                        phyState = STATE_DATA_HIGH_OR_SFD;
                        call RxByteTimer.start(byteTime << 1);
                    }
                    else {
                        resetState();
                    }
                    break;
                case STATE_DATA_HIGH_OR_SFD:    
                    if(data != SFD_BYTE) {
                        decodedByte = sixBitToNibble[data >> 2];
                        if(decodedByte != ILLEGAL_CODE) {
                            bufByte = decodedByte << 2;
                            bufByte |= data & 0x03;
                            bufByte <<= 2;
                            phyState = STATE_DATA_MIDDLE;
                            signal PhyPacketRx.recvHeaderDone(SUCCESS);
                            call RxByteTimer.start(byteTime);
                        }
                        else {
                            resetState();
                        }
                    }
                    else {
                        phyState = STATE_DATA_HIGH;
                        signal PhyPacketRx.recvHeaderDone(SUCCESS);
                        call RxByteTimer.start(byteTime);
                    }
                    break;
                case STATE_DATA_HIGH:
                    decodedByte = sixBitToNibble[data >> 2];
                    if(decodedByte != ILLEGAL_CODE) {
                        bufByte = decodedByte << 2;
                        bufByte |= data & 0x03;
                        bufByte <<= 2;
                        phyState = STATE_DATA_MIDDLE;
                        call RxByteTimer.start(byteTime);
                    }
                    else {
                        resetState();
                    }
                    break;
                case STATE_DATA_MIDDLE:
                    decodedByte = sixBitToNibble[((bufByte & 0x0f)<<2) | (data >> 4)];
                    if(decodedByte != ILLEGAL_CODE) {
                        phyState = STATE_DATA_LOW;
                        signal SerializerRadioByteComm.rxByteReady((bufByte & 0xf0) | decodedByte);
                        bufByte = (data & 0x0f) << 2;
                        call RxByteTimer.start(byteTime);
                    }
                    else {
                        resetState();
                    }
                    break;
                case STATE_DATA_LOW:
                    decodedByte = sixBitToNibble[bufByte | (data >> 6)];
                    if(decodedByte != ILLEGAL_CODE) {
                        bufByte = (decodedByte << 4);
                        decodedByte = sixBitToNibble[data & 0x3f];
                        if(decodedByte != ILLEGAL_CODE) {
                            phyState = STATE_DATA_HIGH;
                            signal SerializerRadioByteComm.rxByteReady(bufByte | decodedByte);
                            call RxByteTimer.start(byteTime);
                        }
                        else {
                            resetState();
                        }
                    }
                    else {
                        resetState();
                    }
                    break;
                case STATE_PREAMBLE:
                    low = data & 0xf;
                    high = data >> 4;
                    if((low > 0) && (low < 0xf) && (high > 0) && (high < 0xf)) {
                        phyState = STATE_PREAMBLE_CODE;
                        call RxByteTimer.start(byteTime);
                    }
                    break;
                case STATE_PREAMBLE_CODE:
                    low = data & 0xf;
                    high = data >> 4;
                    if((low == 0) || (low == 0xf) || (high == 0) || (high == 0xf)) {
                        phyState = STATE_PREAMBLE;
                    }
                    else {
                        call RxByteTimer.start(byteTime);
                    }
                    break;
                    // maybe there will be a time.... we will need this. but for now there is no footer
                    //case STATE_FOOTER_START:
                    //phyState = STATE_FOOTER_DONE;
                    //break;
                    //case STATE_FOOTER_DONE:
                    //phyState = STATE_NULL;
                    //signal PhyPacketRx.recvFooterDone(TRUE);
                    //break;
                default:
                    break;
            }
        }
        
    }
}
