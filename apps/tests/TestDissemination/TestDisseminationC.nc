#include <Timer.h>

/*
 * Copyright (c) 2006 Arched Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arched Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 */

/**
 * TestDisseminationC exercises the dissemination layer, by causing
 * the node with ID 1 to inject 2 new values into the network every 4
 * seconds. For the 32-bit object with key 0x1234, node 1 toggles LED
 * 0 when it sends, and every other node toggles LED 0 when it
 * receives the correct value. For the 16-bit object with key 0x2345,
 * node 1 toggles LED 1 when it sends, and every other node toggles
 * LED 1 when it receives the correct value.
 *
 * See TEP118 - Dissemination for details.
 * 
 * @author Gilman Tolle <gtolle@archedrock.com>
 * @version $Revision: 1.4 $ $Date: 2006-12-12 18:22:50 $
 */

module TestDisseminationC {
  uses interface Boot;

  uses interface DisseminationValue<uint32_t> as Value32;
  uses interface DisseminationUpdate<uint32_t> as Update32;

  uses interface DisseminationValue<uint16_t> as Value16;
  uses interface DisseminationUpdate<uint16_t> as Update16;

  uses interface Leds;

  uses interface Timer<TMilli>;
}
implementation {
  event void Boot.booted() {
    if ( TOS_NODE_ID % 4 == 1 ) {
      call Timer.startPeriodic(20000);
    }
  }

  event void Timer.fired() {
    uint32_t newVal32 = 0xDEADBEEF;
    uint16_t newVal16 = 0xABCD;
    call Leds.led0Toggle();
    call Leds.led1Toggle();
    call Update32.change( &newVal32 );
    call Update16.change( &newVal16 );
    dbg("TestDisseminationC", "TestDisseminationC: Timer fired.\n");
  }

  event void Value32.changed() {
    const uint32_t* newVal = call Value32.get();
    if ( *newVal == 0xDEADBEEF ) {
      call Leds.led0Toggle();
      dbg("TestDisseminationC", "Received new correct 32-bit value @ %s.\n", sim_time_string());
    }
    else {
      dbg("TestDisseminationC", "Received new incorrect 32-bit value.\n");
    }
  }

  event void Value16.changed() {
    const uint16_t* newVal = call Value16.get();
    if ( *newVal == 0xABCD ) {
      call Leds.led1Toggle();
      dbg("TestDisseminationC", "Received new correct 16-bit value @ %s.\n", sim_time_string());
    }
    else {
      dbg("TestDisseminationC", "Received new incorrect 16-bit value: 0x%hx\n", *newVal);
    }
  }
}
