/**
 * Copyright (c) 2015, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:T
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
 * @author Jasper Buesch <buesch@tkn.tu-berlin.de>
 *
 */


#include <MMAC.h>
#include <Ieee154.h>
#include "printf.h"

#include <stdlib.h>

#include "plain154_values.h"

#ifndef htole16
#define htole16(X)  (X)
#endif

#ifndef RADIO_CHANNEL
 #define RADIO_CHANNEL 11
#endif

module TestC
{
    uses interface Boot;

    uses interface Plain154PhyTx<TMicro, uint32_t> as PhyTx;
    uses interface Plain154PhyRx<TMicro, uint32_t> as PhyRx;
    uses interface Plain154PhyOff;
    uses interface Plain154PlmeGet as PLME_GET;
    uses interface Plain154PlmeSet as PLME_SET;

    uses interface TknTschMlmeGet;
    uses interface TknTschMlmeSet;

    uses interface Plain154Frame as Frame;
    uses interface Plain154Metadata as Metadata;
    uses interface Packet as PacketPayload;

    uses interface Alarm<T32khz, uint32_t>  as Alarm;

    uses interface TknTschInformationElement;
    uses interface TknTschFrames;

    uses interface Init;

}
implementation
{
    #define SEND_INTERVAL 33096

    message_t msg;
    plain154_txframe_t txFrame;
    plain154_header_t *header;
    uint8_t hdr_length;
    uint32_t m_asn = 0;

    uint8_t m_random;


    uint8_t addHie(uint8_t* data)  {
        data[0] = 0x00;
        data[1] = 0x3f;
        return 2;
    }

    uint8_t addPieMlme(uint8_t* data, uint8_t length)  {
        data[0] = length;
        data[1] = 0x88;
        return 2;
    }

    uint8_t addTschTimeslot(uint8_t* data)  {
        data[0] = 0x01;
        data[1] = 0x1c;
        data[2] = 0x00;
        return 3;
    }

    uint8_t addTschChannelHopping(uint8_t* data)  {
        data[0] = 0x01;
        data[1] = 0xc8;
        data[2] = 0x00;
        return 3;
    }

    uint8_t addTschSynch(uint8_t* data, uint32_t asn, uint8_t joinPriority)  {
        data[0] = 0x06;
        data[1] = 0x1a;
        data[2] = (uint8_t) (asn) & 0xff;
        data[3] = (uint8_t) (asn >> 8) & 0xff;
        data[4] = (uint8_t) (asn >> 16) & 0xff;
        data[5] = (uint8_t) (asn >> 24) & 0xff;
        data[6] = 0;
        data[7] = joinPriority;
        return 8;
    }

    uint8_t addTschSlotframe(uint8_t* data)  {
        data[0]  = 0x0a;
        data[1]  = 0x1b;
        data[2]  = 0x01;
        data[3]  = 0x01;
        data[4]  = 0x65;
        data[5]  = 0x00;
        data[6]  = 0x01;
        data[7]  = 0x00;
        data[8]  = 0x00;
        data[9]  = 0x00;
        data[10] = 0x00;
        data[11] = 0x07;
        return 12;
    }

    uint8_t addTPie(uint8_t* data)  {
        data[0] = 0x00;
        data[1] = 0xf8;
        return 2;
    }

    uint8_t writeIEs(uint8_t* ie_ptr, uint32_t asn) {
        uint8_t i;
        uint8_t sort[] = {0, 1, 2, 3};
        for (i=0; i<40; i++) { // shuffling the ref arrays
            uint8_t k, l, temp;
            k = rand() % 4;
            l = rand() % 4;
            temp = sort[k];
            sort[k] = sort[l];
            sort[l] = temp;
        }
        ie_ptr += addPieMlme(ie_ptr, 26);
        for (i=0; i<4; i++) {
            switch (sort[i]) {
                case 0:
                    ie_ptr += addTschSynch(ie_ptr, asn, 0);
                    break;
                case 1:
                    ie_ptr += addTschTimeslot(ie_ptr);
                    break;
                case 2:
                    ie_ptr += addTschChannelHopping(ie_ptr);
                    break;
                case 3:
                    ie_ptr += addTschSlotframe(ie_ptr);
                    break;
            }
        }
        addTPie(ie_ptr);
        return 28;
    }


    void prepareAutomaticFrame(){
        uint8_t headerLength, i, hieLen;
        uint8_t *ptr;
        plain154_address_t addr;
        memset(&msg, 0, sizeof(message_t));

        txFrame.header = call Frame.getHeader(&msg);
        txFrame.metadata = call Metadata.getMetadata(&msg);
        txFrame.payload = call PacketPayload.getPayload(&msg, 40);

        addr.extendedAddress = 0x1122334455667788L;

        if (SUCCESS != call Frame.setAddressingFields(txFrame.header,
                          PLAIN154_ADDR_EXTENDED,
                          PLAIN154_ADDR_EXTENDED,
                          0x1ee7,
                          0xc0fe,
                          &addr,
                          &addr,
                          PLAIN154_FRAMEVERSION_2,
                          FALSE))

        call Frame.setDSN(txFrame.header, 0x99);
        call Frame.setFrameType(txFrame.header, PLAIN154_FRAMETYPE_BEACON);
        //call Frame.setFrameVersion(txFrame.header, PLAIN154_FRAMEVERSION_2);
        call Frame.setAckRequest(txFrame.header, FALSE);
        call Frame.setFramePending(txFrame.header, FALSE);
        call Frame.setIEListPresent(txFrame.header, TRUE);

        addHie((uint8_t *)txFrame.header->hie);

        call Frame.getActualHeaderLength(txFrame.header, &headerLength);
        txFrame.headerLen = headerLength;

        txFrame.payloadLen = writeIEs(txFrame.payload, m_asn);
    }


    void createBeaconFrame() {
        uint8_t i;

        tkntsch_status_t status;
        uint8_t headerLength;
        uint8_t payloadLen;
        uint8_t *payloadPtr;
        status = call TknTschFrames.createEnhancedBeaconFrame(&msg, &txFrame, &payloadLen, TRUE, TRUE, TRUE, TRUE);
        printf("EBeaconFrame creation gave status code: %d\n (payloadLen %d)", status, payloadLen);
        printf("HeaderLen %d, PayloadLen %d\n", txFrame.headerLen, txFrame.payloadLen);


        //payloadPtr = call PacketPayload.getPayload(&msg, payloadLen);
        //txFrame.header = call Frame.getHeader(&msg);
        //txFrame.metadata = call Metadata.getMetadata(&msg);
        //txFrame.payload = payloadPtr;
        //call Frame.getActualHeaderLength(txFrame.header, &headerLength);
        //txFrame.headerLen = headerLength;
        //txFrame.payloadLen = payloadLen;
    }


    event void Boot.booted() {
        uint8_t* ie_ptr;
        uint8_t* ptr = (uint8_t *) (&(msg));

        call Init.init();

        memset(&msg, 0, sizeof(message_t));
        //prepareAutomaticFrame();

        call PLME_SET.phyCurrentChannel(RADIO_CHANNEL);

        call TknTschMlmeSet.macPanId(0x1337);

        call Alarm.start(SEND_INTERVAL);
    }


    async event void Alarm.fired() {
        uint8_t* ptr = (uint8_t *) (&(msg));
        uint8_t i;
        tkntsch_asn_t asn;

        call Alarm.start(SEND_INTERVAL);

        asn = call TknTschMlmeGet.macASN();
        asn += 101;
        call TknTschMlmeSet.macASN(asn);
        createBeaconFrame();

        call PhyTx.transmit(&txFrame, 0, 0);
    }

    async event void PhyTx.transmitDone(plain154_txframe_t *frame, error_t result){
    }

    async event void Plain154PhyOff.offDone() {}

    async event void PhyRx.enableRxDone() {
        printf("Radio is listening now!\n");
    }

    async event message_t* PhyRx.received(message_t *frame) {
        return frame;
    }
}
