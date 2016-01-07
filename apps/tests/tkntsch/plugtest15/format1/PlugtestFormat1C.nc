/*
 * Copyright (c) 2015, Technische Universitaet Berlin
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
 * @author Jasper Büsch <buesch@tkn.tu-berlin.de>
 */

/**
 * Configuration for the Plugtest 2015 TD_6TiSCH_FORMAT_01 test.                
 *                                                                              
 * Test Objective: Check the format of the IEEE802.15.4e EB packet is correct.
 **/

#include "Timer.h"
//#include "Timer62500hz.h"

#ifdef NEW_PRINTF_SEMANTICS
#include "printf.h"
#else
#define printf(...)
#define printfflush()
#endif

#ifndef APP_RADIO_CHANNEL
#define APP_RADIO_CHANNEL RADIO_CHANNEL
#endif

#include "app_profile.h"

#include "plain154_message_structs.h"
#include "plain154_values.h"

module PlugtestFormat1C
{
  uses {
    interface Timer<TMilli> as Timer0;
    interface Boot;

    // Frame handling
    interface Plain154Frame as Frame;

    interface Init as TknTschInit;
    interface TknTschMlmeTschMode as TschMode;
    interface TknTschMlmeSet as MLME_SET;
    interface Plain154PlmeSet as PLME_SET;
    interface TknTschMlmeBeacon as MLME_BEACON;

    interface Pool<message_t> as RxMsgPool @safe();
  }
}
implementation
{
  // Variables

  // constants

  // Prototypes

  // Interface commands and events
  event void Boot.booted()
  {
    bool is_coordinator;

    printf("PlugtestFormat1C booted.\n");
    printf("Set PAN ID to: 0x%.2X, result: %d\n", PAN_ID, call MLME_SET.macPanId(PAN_ID));
    printf("Set short address to: 0x%.4X, result: %d\n", COORDINATOR_ADDRESS, call MLME_SET.macShortAddr(COORDINATOR_ADDRESS));

    call PLME_SET.phyCurrentChannel(APP_RADIO_CHANNEL);
    call TknTschInit.init();

    printf("Sending beacons every 10s ...\n");
    is_coordinator = TRUE;
    call MLME_SET.isCoordinator(is_coordinator);
    call TschMode.request(TKNTSCH_MODE_ON);

    printfflush();
  }

  event void TschMode.confirm(tkntsch_mode_t TSCHMode, tkntsch_status_t Status) {
    printf("Received event TschMode.confirm with status 0x%x\n", Status);
    call Timer0.startOneShot(1024);
  }

  event void Timer0.fired() {
    plain154_address_t dstaddr;
    uint8_t ret;

    dstaddr.shortAddress = 0xFFFF;
    ret = call MLME_BEACON.request (
        TKNTSCH_BEACON_TYPE_BEACON,
        0, // channel
        0, // channel page
        NULL, // security
        PLAIN154_ADDR_SHORT, // dst mode
        &dstaddr,
        FALSE // BSN suppresion
      );

    if (ret != TKNTSCH_SUCCESS) {
      call Timer0.startOneShot(1024);
      atomic printf("MLME_BEACON.request (0x%x)\n", ret);
    }
  }

  event void MLME_BEACON.confirm(plain154_status_t Status) {
    atomic printf("MLME_BEACON.confirm (0x%x)\n", Status);
    call Timer0.startOneShot(10 * 1024); // 10s
  }
}
