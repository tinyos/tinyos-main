/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
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
 */

/**
 * Demo application of the TAOS Tsl2561. Originally developed for the
 * Intel Mote 2 sensorboard.
 *
 * @author Kaisen Lin
 * @author Philip Buonadonna
 */
#include "../TestSensor.h"

/* Uncomment the flag below to test the interrupt functions of the chip */
//#define USE_INTERRUPTS

module TestSensorM
{
  uses interface Boot;
  
  uses interface Timer<TMilli> as Timer0;

  uses interface Read<uint16_t> as ReadIR;
  uses interface Read<uint16_t> as ReadBroadband;
  uses interface SplitControl as SubControl;

  uses interface HalTsl2561Advanced;

  uses interface Leds;
  uses interface AMSend;
  uses interface Packet;
}
implementation
{
  message_t packet;
  uint8_t initCounter = 0;

  event void Boot.booted() {
    call SubControl.start();
  }

  event void Timer0.fired() {
    call ReadBroadband.read();
  }

  event void SubControl.startDone(error_t result) {
#ifndef USE_INTERRUPTS
    call Timer0.startPeriodic( 100 );
#else
    call HalTsl2561Advanced.enableAlert(FALSE);
#endif
    return;
  }

  event void SubControl.stopDone(error_t result) { }
  
  event void ReadBroadband.readDone(error_t result, uint16_t val) {
    TestSensorMsg *rcm = (TestSensorMsg *)call Packet.getPayload(&packet, NULL);

    call Leds.led0Toggle();

    if (call Packet.maxPayloadLength() < sizeof(TestSensorMsg)) {
      return;
    }
    rcm->value = val;

    call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(TestSensorMsg));
  }
  
  event void ReadIR.readDone(error_t result, uint16_t val) { }
  
  event void HalTsl2561Advanced.setGainDone(error_t error) { }
  event void HalTsl2561Advanced.setIntegrationDone(error_t error) { }

  event void HalTsl2561Advanced.setPersistenceDone(error_t error) {
    call HalTsl2561Advanced.enableAlert(TRUE);
  }
  event void HalTsl2561Advanced.setTLowDone(error_t error) {
    call HalTsl2561Advanced.setTHigh(7000);
  }
  event void HalTsl2561Advanced.setTHighDone(error_t error) { 
    call HalTsl2561Advanced.setPersistence(1);
  }
  event void HalTsl2561Advanced.enableAlertDone(error_t error) {
    switch (initCounter) {
    case 0:
      call HalTsl2561Advanced.setTLow(200);
      initCounter++;
      break;
    case 1:
      call Leds.set(LEDS_LED2 | LEDS_LED0);	
      initCounter++;
      break;
    default:
      break;
    }
  }

  event void HalTsl2561Advanced.alertThreshold() {
    call Leds.led1Toggle();
    call HalTsl2561Advanced.enableAlert(TRUE); // Clears interrupt
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    return;
  }

}
