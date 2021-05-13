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
 * @author Sonali Deo <code-tinyos@tkn.tu-berlin.de>
 */

#include "printf.h"
#include "IeeeEui64.h"
#include "plain154_types.h"
#include "plain154_message_structs.h"
#include "message.h"
#include "plain154_values.h"
#include "tkntsch_lock.h"
#include "tkntsch_pib.h"
#include "tkntsch_types.h"


#ifndef APP_RADIO_CHANNEL
#define APP_RADIO_CHANNEL 22
#endif

module TestTSCHFramesP {
  uses {
    interface Boot;
    interface Leds;

    interface Plain154Frame as PF;
    interface TknTschFrames as F;
  }
} implementation {

  uint8_t* payload;
  message_t msg;
  uint8_t msglength;
  uint8_t payloadlength;
  uint8_t data[10];
  plain154_header_t* hdr;
  uint8_t frameType;
  bool IEListPresent;
  uint8_t seqno;

  tkntsch_status_t ackCreatestatus;
  tkntsch_status_t enhancedAckCreatestatus;
  tkntsch_status_t enhancedBeaconCreatestatus;
  tkntsch_status_t dataCreatestatus;

  tkntsch_status_t penhancedAckCreatestatus;
  tkntsch_status_t penhancedBeaconCreatestatus;


  event void Boot.booted() {
    data[0] = 0x12;
    data[1] = 0x22;
    data[2] = 0x33;
    data[3] = 0x44;
    data[4] = 0x55;
    data[5] = 0x66;
    data[6] = 0x77;
    data[7] = 0x88;
    data[8] = 0x99;
    data[9] = 0xaa;

    payload = (uint8_t*) data;
    payloadlength = 10;
    msglength = 104;

    ackCreatestatus = call F.createAckFrame(&msg, msglength);
    printf("Ack frame creation: %d\n", ackCreatestatus);
    hdr = call PF.getHeader(&msg);
    frameType = call PF.getFrameType(hdr);
    printf("Header=%p\n", hdr);
    printf("Frame Type(ACK=2)=%p\n", frameType);
    printfflush();

    enhancedAckCreatestatus = call F.createEnhancedAckFrame(&msg, msglength, payload, payloadlength);
    printf("Enhanced Ack frame creation: %d\n", enhancedAckCreatestatus);
    hdr = call PF.getHeader(&msg);
    frameType = call PF.getFrameType(hdr);
  //  printf("Header=%p\n", hdr);
    printf("Frame Type(ACK=2)=%p\n", frameType);
    IEListPresent = call PF.isIEListPresent(hdr);
    printf("IEListPresent=%p\n", IEListPresent);
    printfflush();

    penhancedAckCreatestatus = call F.parseEnhancedAckFrame(&msg, msglength, payload, &payloadlength);
    printf("Enhanced Ack frame parsing: %d\n", penhancedAckCreatestatus);
    printfflush();

    enhancedBeaconCreatestatus = call F.createEnhancedBeaconFrame(&msg, msglength, payload, payloadlength);
    printf("Enhanced Beacon frame creation: %d\n", enhancedBeaconCreatestatus);
    hdr = call PF.getHeader(&msg);
    frameType = call PF.getFrameType(hdr);
    printf("Header=%p\n", hdr);
    printf("Frame Type(BCN=0)=%p\n", frameType);
    IEListPresent = call PF.isIEListPresent(hdr);
    printf("IEListPresent=%p\n", IEListPresent);
    printfflush();

    penhancedBeaconCreatestatus = call F.parseEnhancedBeaconFrame(&msg, msglength, payload, &payloadlength);
    printf("Enhanced Beacon frame parsing: %d\n", penhancedBeaconCreatestatus);
    printfflush();

    dataCreatestatus = call F.createDataFrame(&msg, msglength, payload, payloadlength);
    hdr = call PF.getHeader(&msg);
    frameType = call PF.getFrameType(hdr);
    printf("Header=%p\n", hdr);
    printf("Frame Type(DATA=1)=%p\n", frameType);
    IEListPresent = call PF.isIEListPresent(hdr);
    printf("IEListPresent=%p\n", IEListPresent);
    seqno = call PF.getDSN(hdr);
    printf("seqno(0d)=%p\n", seqno);
    printf("Data frame creation: %d\n", dataCreatestatus);
    printfflush();

  }
}
