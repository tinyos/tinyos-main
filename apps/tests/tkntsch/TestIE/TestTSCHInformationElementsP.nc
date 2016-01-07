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
#include "tkntsch_types.h"
#include "plain154_types.h"
#include "tkntsch_lock.h"
#include "tkntsch_pib.h"


module TestTSCHInformationElementsP {
  uses {
    interface Boot;
    interface Leds;
    interface TknTschInformationElement as IE;
  }
} implementation {

  uint8_t* frame_payload;
  uint8_t data[24];

  bool ack;
  int16_t timecorrection;
  uint8_t IElen1;

  tkntsch_asn_t asn;
  uint8_t joinpriority;
  uint8_t IElen2;

  // for slotframes
  parsedSlots_t noSlotStatus;
  uint8_t noSlotframes;
  macSlotframeEntry_t slotframes[2];
  uint8_t noLinks;
  macLinkEntry_t links[2];
  uint8_t IElen3;

  macTimeslotTemplate_t template;
  uint8_t IElen4;

  uint8_t sequenceID;
  uint8_t IElen5;

  // IE creation status
  tkntsch_status_t timecorrectionIEstatus;
  tkntsch_status_t syncIEstatus;
  tkntsch_status_t slotframeIEstatus;
  tkntsch_status_t timeslotIEstatus;
  tkntsch_status_t hoppingIEstatus;

  // IE parsing status
  tkntsch_status_t ptimecorrectionIEstatus;
  tkntsch_status_t psyncIEstatus;
  tkntsch_status_t pslotframeIEstatus;
  tkntsch_status_t pFirstslotframeIEstatus;
  tkntsch_status_t pNextslotframeIEstatus;
  tkntsch_status_t ptimeslotIEstatus;
  tkntsch_status_t phoppingIEstatus;

  typeIEparsed_t parsed;

  typeIE_t frameIE;

  event void Boot.booted() {

    frame_payload = (uint8_t*) data;
    ack = TRUE;
    timecorrection = 0x1111;

    asn = 0x12345;
    joinpriority = 0x22;

    noSlotframes = 0x02;
    slotframes[0].macSlotframeHandle = 0x11;
    slotframes[0].macSlotframeSize = 0x4444;
    slotframes[1].macSlotframeHandle = 0x22;
    slotframes[1].macSlotframeSize = 0x2222;
    noLinks = 0x02;
    links[0].sfHandle = 0x11;
    links[0].macTimeslot = 0x6666;
    links[0].macChannelOffset = 0x9999;
    links[0].macLinkOptions = 0x03;
    links[1].sfHandle = 0x22;
    links[1].macTimeslot = 0x6600;
    links[1].macChannelOffset = 0x0009;
    links[1].macLinkOptions = 0x07;

    template.macTimeslotTemplateId = 0x55;
    template.macTsCCAOffset = 0x4444;
    template.macTsCCA = 0x7654;
    template.macTsTxOffset = 0x0003;
    template.macTsRxOffset = 0x0005;
    template.macTsRxAckDelay = 0x0008;
    template.macTsTxAckDelay = 0x0009;
    template.macTsRxWait = 0x0012;
    template.macTsAckWait = 0x0048;
    template.macTsRxTx = 0x0064;
    template.macTsMaxAck = 0x0054;
    template.macTsMaxTx = 0x0060;
    template.macTsTimeslotLength = 0x0029;
    sequenceID = 0xaa;

    // IE creation & parsing
    //----Time Correction IE----
    timecorrectionIEstatus = call IE.createTimeCorrection(frame_payload, ack, timecorrection, &IElen1);
    printf("Time correction IE creation: %d\n", timecorrectionIEstatus);

    ptimecorrectionIEstatus = call IE.parseTimeCorrection(frame_payload, &ack, &timecorrection);
    printf("Time correction IE parsing: %d\n", ptimecorrectionIEstatus);
    printfflush();

    //----Sync IE----
    syncIEstatus = call IE.createSyncIE(frame_payload, &asn, joinpriority, &IElen2);
    printf("Sync IE creation: %d\n", syncIEstatus);

    psyncIEstatus = call IE.parseSyncIE(frame_payload, &asn, &joinpriority, &parsed);
    printf("Sync IE parsing: %d\n", psyncIEstatus);

    printf("Parsed IEs:%p\n", parsed.noIEparsed);
    printfflush();

   //----Slotframe IE----
    slotframeIEstatus = call IE.createSlotframeIE(frame_payload, noSlotframes, slotframes, noLinks, links, &IElen3);
    printf("Slotframe IE creation: %d\n", slotframeIEstatus);
    printfflush();

    pFirstslotframeIEstatus = call IE.parseFirstSlotframeIE(frame_payload, &noSlotframes, &slotframes,
    &noLinks, &links, &noSlotStatus, &parsed);
    printf("First Slotframe IE parsing: %d\n", pFirstslotframeIEstatus);
    printfflush();

    pNextslotframeIEstatus = call IE.parseNextSlotframeIE( noSlotStatus.stoppedAt, &slotframes, &noLinks,
    &links, &noSlotStatus, &parsed);
    printf("Next Slotframe IE parsing: %d\n", pNextslotframeIEstatus);
    printfflush();

  /*  pslotframeIEstatus = call IE.parseSlotframeIE(frame_payload, &noSlotframes, slotframes,
    &noLinks, links, &parsed);
    printf("slotframe IE parsing: %d\n", pslotframeIEstatus);
    printf("Parsed IEs:%p\n", parsed.noIEparsed);
    printfflush();  */

    //----Timeslot IE----
    timeslotIEstatus = call IE.createTimeslotIE(frame_payload, &template, &IElen4);
    printf("Timeslot IE creation: %d\n", timeslotIEstatus);

    ptimeslotIEstatus = call IE.parseTimeslotIE(frame_payload, &template, &parsed);
    printf("Timeslot IE parsing: %d\n", ptimeslotIEstatus);

    printf("Parsed IEs:%p\n", parsed.noIEparsed);
    printfflush();

    //----Hopping IE----
    hoppingIEstatus = call IE.createHoppingIE(frame_payload, sequenceID, &IElen5);
    printf("Hopping IE creation: %d\n", hoppingIEstatus);

    phoppingIEstatus = call IE.parseHoppingIE(frame_payload, &sequenceID, &parsed);
    printf("Hopping IE parsing: %d\n", phoppingIEstatus);

    printf("Parsed IEs:%p\n", parsed.noIEparsed);
    printfflush();

    //----IEs present----
    /* To test for IE creation & parsing (not frames), make i = 0
       in function implementation in file TknTschInformationElementP.nc */
    /*
    call IE.presentPIEs(frame_payload, 24, &frameIE);
    printf("Total IEs in data:%p\n", frameIE.totalIEs);
    printf("total Length of imp IEs:%p\n", frameIE.totalIEsLength);
    printf("Sync IE present:%p\n", frameIE.syncIEpresent);
    printf("Slotframe IE present:%p\n", frameIE.slotframeIEpresent);
    printf("Timeslot IE present:%p\n", frameIE.timeslotIEpresent);
    printf("Hopping IE present:%p\n", frameIE.hoppingIEpresent);
    printf("sync IE from:%p\n", frameIE.syncIEfrom);
    printf("slotframe IE from:%p\n", frameIE.slotframeIEfrom);
    printf("timeslot IE from:%p\n", frameIE.timeslotIEfrom);
    printf("hopping IE from:%p\n", frameIE.hoppingIEfrom);
    printfflush();
    */
  }

}
