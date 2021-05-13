/**
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
 */
#define NEW_PRINTF_SEMANTICS
#include "printf.h"
#include "message.h"

#include "tkn_fsm.h"
#include "app_config.h"

#ifndef APP_RADIO_CHANNEL
#define APP_RADIO_CHANNEL 20
#endif

module TestTknFsmC {
  uses {
    interface Boot;
    interface Leds;
    interface TknFsm as fsm;
    interface Timer<TMilli> as Timer0;
  }
  provides {
    interface TknEventReceive as fsmReceive;
  }
} implementation {
  int stage;
  int numSuccess = 0;
  int numFail = 0;

  tknfsm_state_entry_t eventhandler_table[] = {
    { TKNFSM_STATE_INIT, TKNFSM_EVENT_INIT, STATE_A, HANDLER_INIT },
    { STATE_A, EVENT_ONE, STATE_A, HANDLER_AONE },
    { STATE_A, EVENT_TWO, STATE_B, HANDLER_ATWO },
    { STATE_B, EVENT_ONE, STATE_B, HANDLER_BONE },
    { STATE_B, EVENT_TWO, STATE_C, HANDLER_BTWO },
    { STATE_C, EVENT_ONE, STATE_C, HANDLER_CONE },
    { STATE_C, EVENT_TWO, STATE_C, HANDLER_CTWO }
  };

  void reportResult(char* func, int status) {
    if (status == TKNFSM_STATUS_SUCCESS) {
      printf("  %s returned TKNFSM_STATUS_SUCCESS\n", func);
      numSuccess++;
      return;
    }
    else if (status == TKNFSM_STATUS_NO_EVENT_HANDLER)
      printf("  %s returned TKNFSM_STATUS_NO_EVENT_HANDLER\n", func);
    else if (status == TKNFSM_STATUS_INVALID_ARGUMENT)
      printf("  %s returned TKNFSM_STATUS_INVALID_ARGUMENT\n", func);
//    else if (status == )
//      printf("  %s returned \n", func);
    else
      printf("  %s returned an unknown status code: %x\n", func, status);
    numFail++;
  }

  task void testTask() {
    uint8_t ret;

    if (stage > 8) {
      printf("\nDone.\n\nSucceeded: %i\nFailed: %i\n", numSuccess, numFail);
      if ((numSuccess > 0) && (numFail == 0))
        printf("Status: PASS\n");
      else
        printf("Status: FAIL\n");
      printfflush();

      call Leds.led0Off();
      return;
    }

    switch (stage) {
      case 0:
      printf("> Initializing the FSM...\n");
      ret = call fsm.setEventHandlerTable(eventhandler_table, sizeof(eventhandler_table) / sizeof(tknfsm_state_entry_t));
      reportResult("setEventHandlerTable", ret);
      /*ret =*/ call fsm.forceState(TKNFSM_STATE_INIT);
      //reportResult("forceState(TKNFSM_STATE_INIT)", ret);
      printf("\n"); printfflush();
      break;

      case 1:
      printf("> Emitting the INIT event...\n");
      ret = signal fsmReceive.receive(TKNFSM_EVENT_INIT);
      reportResult("fsmReceive.receive", ret);
      printf("\n"); printfflush();
      break;

      case 2: case 4: case 6:
      printf("> Emitting the EVENT_ONE event...\n");
      ret = signal fsmReceive.receive(EVENT_ONE);
      reportResult("fsmReceive.receive", ret);
      printf("\n"); printfflush();
      break;

      case 3: case 5: case 7:
      printf("> Emitting the EVENT_TWO event...\n");
      ret = signal fsmReceive.receive(EVENT_TWO);
      reportResult("fsmReceive.receive", ret);
      printf("\n"); printfflush();
      break;

      case 8:
      printf("> Emitting unhandled event 0x55...\n");
      ret = signal fsmReceive.receive(0x55);
      reportResult("fsmReceive.receive", ret);
      printf("\n"); printfflush();
      break;

    }
    atomic stage++;
    call Timer0.startOneShot(1024);
  }

  event void Timer0.fired() {
    post testTask();
  }

  event void Boot.booted() {
    printf("\nTestTknFsmC booted\n\n");
    call Leds.led0On();

    atomic stage = 0;
    call Timer0.startOneShot(1024);
  }
}
