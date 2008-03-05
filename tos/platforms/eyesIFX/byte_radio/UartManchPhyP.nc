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
 * - Description ---------------------------------------------------------
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.7 $
 * $Date: 2008-03-05 11:14:00 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * @author: Philipp Huppertz <huppertz@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "manchester.h"

/**
 * Implementation of the physical layer for the eyesIFX byte radio.
 * Together with the PacketSerializerP this module turns byte streams 
 * into packets.
 *
 * @author Kevin Klues <klues@tkn.tu-berlin.de>
 * @author Philipp Huppertz <huppertz@tkn.tu-berlin.de>
 */
module UartManchPhyP {
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
        STATE_PREAMBLE_MANCHESTER,
        STATE_SYNC,
        STATE_SFD,
        STATE_HEADER_DONE,
        STATE_DATA_HIGH,
        STATE_DATA_LOW,
        STATE_FOOTER_START,
        STATE_FOOTER_DONE
    } phyState_t;

#define PREAMBLE_LENGTH   2
#define BYTE_TIME         TDA5250_32KHZ_BYTE_TIME
#define PREAMBLE_BYTE     0x55
#define SYNC_BYTE         0xFF
#define SFD_BYTE          0x50

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
            atomic byteTime = byteTimeout * 33;
            return SUCCESS;
        }
    }
    
    async command bool UartPhyControl.isBusy() {
        return phyState != STATE_PREAMBLE;
    }
    
    void resetState() {
        atomic {
            call RxByteTimer.stop();
            switch(phyState) {
                case STATE_SYNC:
                case STATE_SFD:
                    signal PhyPacketRx.recvHeaderDone(FAIL);
                    break;
                case STATE_DATA_HIGH:
                case STATE_DATA_LOW:
                case STATE_FOOTER_START:
                    signal PhyPacketRx.recvFooterDone(FAIL);
                    break;
                default:
                    break;
            }
            phyState = STATE_PREAMBLE; 
        }
    }
    
    async event void RxByteTimer.fired() {
        // no bytes have arrived, so...
        resetState();
    }

    async command void PhyPacketTx.sendHeader() {
        atomic {
            phyState = STATE_PREAMBLE;
            preambleCount = numPreambles;
        }
        TransmitNextByte();
    }

    async command void SerializerRadioByteComm.txByte(uint8_t data) {
        bufByte = data;
        call RadioByteComm.txByte(manchesterEncodeNibble((bufByte & 0xf0) >> 4));
        phyState = STATE_DATA_LOW;
    }

    async command bool SerializerRadioByteComm.isTxDone() {
        return call RadioByteComm.isTxDone();
    }

    async command void PhyPacketTx.sendFooter() {
        atomic phyState = STATE_FOOTER_START;
        TransmitNextByte();
    }


    /* Radio Recv */
    async command void PhyPacketRx.recvFooter() {
        // currently there is no footer
        // atomic phyState = STATE_FOOTER_START;
        atomic {
            phyState = STATE_PREAMBLE;
        }
        call RxByteTimer.stop();
        signal PhyPacketRx.recvFooterDone(SUCCESS);
    }

    
    /* Tx Done */
    async event void RadioByteComm.txByteReady(error_t error) {
        if(error == SUCCESS) {
            TransmitNextByte();
        } else {
            atomic {
                signal SerializerRadioByteComm.txByteReady(error);
                phyState = STATE_PREAMBLE;
            }
        }
    }

    void TransmitNextByte() {
        atomic {
            switch(phyState) {
                case STATE_PREAMBLE:
                    if(preambleCount > 1) {
                        preambleCount--;
                    } else {
                        phyState = STATE_SYNC;
                    }
                    call RadioByteComm.txByte(PREAMBLE_BYTE);
                    break;
                case STATE_SYNC:
                    phyState = STATE_SFD;
                    call RadioByteComm.txByte(SYNC_BYTE);
                    break;
                case STATE_SFD:
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
                case STATE_DATA_LOW:
                    call RadioByteComm.txByte(manchesterEncodeNibble(bufByte & 0x0f));
                    phyState = STATE_DATA_HIGH;                    
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
                    call RadioByteComm.txByte(manchesterEncodeNibble(bufByte & 0x0f));
                    break;
                case STATE_FOOTER_DONE:
                    phyState = STATE_PREAMBLE;
                    signal PhyPacketTx.sendFooterDone();
                    break;
                default:
                    break;
            }
        }
    }

    /* Rx Done */
    async event void RadioByteComm.rxByteReady(uint8_t data) {
        call RxByteTimer.start(byteTime);
        ReceiveNextByte(data);
    }

    /* Receive the next Byte from the USART */
    void ReceiveNextByte(uint8_t data) {
        uint8_t decodedByte;
        atomic {
            switch(phyState) {
                case STATE_SYNC:
                    if(data != PREAMBLE_BYTE) {
                        if (data == SFD_BYTE) {
                            signal PhyPacketRx.recvHeaderDone(SUCCESS);
                            phyState = STATE_DATA_HIGH;
                        } else {
                            phyState = STATE_SFD;
                        } 
                    }
                    break;
                case STATE_SFD:
                    if (data == SFD_BYTE) {
                        signal PhyPacketRx.recvHeaderDone(SUCCESS);
                        phyState = STATE_DATA_HIGH;
                    } else {
                        phyState = STATE_PREAMBLE; 
                    }
                    break;
                case STATE_PREAMBLE:
                    if(data == PREAMBLE_BYTE) {
                        phyState = STATE_SYNC;
                    }
                    else if(manchesterDecodeByte(data) != 0xff) {
                        phyState = STATE_PREAMBLE_MANCHESTER;
                    }
                    break;
                case STATE_PREAMBLE_MANCHESTER:
                    if(data == PREAMBLE_BYTE) {
                        phyState = STATE_SYNC;
                    }
                    else if(manchesterDecodeByte(data) == 0xff) {
                        phyState = STATE_PREAMBLE; 
                    }
                    break;
                case STATE_DATA_HIGH:
                    decodedByte = manchesterDecodeByte(data);
                    if(decodedByte != 0xff) {
                        bufByte = decodedByte << 4;
                        phyState = STATE_DATA_LOW;
                    }
                    else {
                        resetState();
                    }
                    break;
                case STATE_DATA_LOW:
                    decodedByte = manchesterDecodeByte(data);
                    if(decodedByte != 0xff) {
                        bufByte |= decodedByte;
                        phyState = STATE_DATA_HIGH;
                        signal SerializerRadioByteComm.rxByteReady(bufByte);
                    }
                    else {
                        resetState();
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
