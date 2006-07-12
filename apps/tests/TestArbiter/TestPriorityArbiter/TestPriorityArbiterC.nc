/*
 * Copyright (c) 2004, Technische Universitat Berlin
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
 * - Neither the name of the Technische Universitat Berlin nor the names
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
 * - Revision -------------------------------------------------------------
 * $Revision: 1.2 $
 * $Date: 2006-07-12 16:59:17 $
 * ========================================================================
 */


/**
 * TestPriorityArbiter Application
 * This application is used to test the functionality of the FcfsPriorityArbiter
 * component developed using the Resource and ResourceUser interfaces.
 * <br>
 * In this test there are 4 users of one ressource. The Leds indicate which
 * user is the owner of the resource:<br>
 * <li> normal priority client 1  - led 0
 * <li> normal priority client 2  - led 1
 * <li> power manager             - led 2
 * <li> high priority client      - led 0 and led 1 and led 2
 * <br><br>
 * The short flashing of the according leds inidicate that a user has requested the
 * resource. The users have the following behaviour:<br><br>
 * <li> Normal priority clients are idle for a period of time before requesting the resource.
 *      If they are granted the resource they will use it for a specific amount of time before releasing it.
 * <li> Power manager only request the resource if its idle. It releases the resource immediatly
 *       if there is a request from another client.
 * <li> High priority client behaves like a normal client but it will release the resource
 *      after a shorter period of time if there are requests from other clients.
 * <br><br>
 * The poliy of the arbiter should be FirstComeFirstServed with one exception:
 * If the high priority client requests the resource, the resource will be granted to the
 * high priority client after the release of the current owner regardless of the internal queue of the arbiter. After
 * the high priority client releases the resource the normal FCFS arbitration resumes.
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * @author Philipp Huppertz (extended test FcfsPriorityArbiter)
 */
#include "Timer.h"

module TestPriorityArbiterC {
  uses {
    interface Boot;
    interface Leds;
    interface Resource as Client1;
    interface Resource as Client2;
    interface ResourceController as PowerManager;
    interface ResourceController as HighClient;
    interface BusyWait<TMicro,uint16_t>;
    interface Timer<TMilli> as TimerClient1;
    interface Timer<TMilli> as TimerClient2;
    interface Timer<TMilli> as TimerHighClient;
  }
}
implementation {

#define HIGHCLIENT_FULL_PERIOD     8000
#define HIGHCLIENT_SAFE_PERIOD     1000
#define HIGHCLIENT_SLEEP_PERIOD    10000

#define CLIENT2_ACTIVE_PERIOD   1000
#define CLIENT2_WAIT_PERIOD     6000

#define CLIENT1_ACTIVE_PERIOD   2000
#define CLIENT1_WAIT_PERIOD     6000



  // internal states of Resource4 (High Prio Resource)
  uint8_t sleepCnt = 0;
  bool resReq = FALSE;

  // internal state Resources (active / not active)
      bool client1Active = FALSE;
  bool client2Active = FALSE;


  task void startHighClientSafePeriod() {
    call TimerHighClient.stop();
    call TimerHighClient.startOneShot(HIGHCLIENT_SAFE_PERIOD);
  }

  // flash the apropriate leds when requesting the ressource
      event void TimerClient1.fired() {
    if (client1Active) {
      call Client1.release();
      call TimerClient1.startOneShot(CLIENT1_WAIT_PERIOD);
      call Leds.led0Off();
      client1Active = FALSE;
    } else {
      call Leds.led0Toggle();
      call BusyWait.wait(100);
      call Leds.led0Toggle();
      call Client1.request();
    }
      }

  // flash the apropriate leds when requesting the ressource
      event void TimerClient2.fired() {
    if (client2Active) {
      call Client2.release();
      call TimerClient2.startOneShot(CLIENT2_WAIT_PERIOD);
      call Leds.led1Off();
      client2Active = FALSE;
    } else {
      call Leds.led1Toggle();
      call BusyWait.wait(100);
      call Leds.led1Toggle();
      call Client2.request();
    }
      }

  // flash the apropriate leds when requesting the ressource
      event void TimerHighClient.fired() {
    call Leds.led0Toggle();
    call Leds.led1Toggle();
    call Leds.led2Toggle();
    call BusyWait.wait(100);
    call Leds.led0Toggle();
    call Leds.led1Toggle();
    call Leds.led2Toggle();
    call HighClient.release();
    // and request again 'cause we know that one client will be served in between...
        call HighClient.request();
    atomic {resReq = FALSE;}
      }


  //All resources try to gain access at the start
      event void Boot.booted() {
    call Client1.request();
    call Client2.request();
    call HighClient.request();
      }

  //If granted the resource, turn on an LED 0
      event void Client1.granted() {
        call Leds.led0On();
        call Leds.led1Off();
        call Leds.led2Off();
        call TimerClient1.startOneShot(CLIENT1_ACTIVE_PERIOD);
        client1Active = TRUE;
      }

  //If granted the resource, turn on an LED 1
      event void Client2.granted() {
        call Leds.led0Off();
        call Leds.led1On();
        call Leds.led2Off();
        call TimerClient2.startOneShot(CLIENT2_ACTIVE_PERIOD);
        client2Active = TRUE;
      }

  //If granted the resource, turn on an LED 2
      event void PowerManager.granted() {
        call Leds.led0Off();
        call Leds.led1Off();
        call Leds.led2On();
      }

  //If granted the resource, turn on an LED  0 & 1 & 2
      event void HighClient.granted() {
        if (sleepCnt > 7) {
      // immediatly release resource and sleep
          call HighClient.release();
      call TimerHighClient.startOneShot(HIGHCLIENT_SLEEP_PERIOD);
      sleepCnt = 0;
        } else {
          call Leds.led0On();
          call Leds.led1On();
          call Leds.led2On();
          atomic {
            if (resReq) {
              call TimerHighClient.startOneShot(HIGHCLIENT_SAFE_PERIOD);
            } else {
              call TimerHighClient.startOneShot(HIGHCLIENT_FULL_PERIOD);
            }
          }
        }
        ++sleepCnt;
      }

  //If detect that someone else wants the resource,
  //  release it
      async event void PowerManager.requested() {
    call PowerManager.release();
      }

  //If detect that someone else wants the resource,
  //  release it if its safe
      async event void HighClient.requested() {
    if (!resReq) {
      if ( call HighClient.isOwner() ) {
        post startHighClientSafePeriod();
      } else {}
      atomic {resReq = TRUE;}
    }
      }

  // do something
      async event void PowerManager.idle() {
    call PowerManager.request();
      }

  // do nothing
      async event void HighClient.idle() {
      }
}

