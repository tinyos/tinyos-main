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
 * Demo application of the TI TMP175. Originally developed for the
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

  uses interface Read<uint16_t> as Temperature;
  uses interface SplitControl as SubControl;

  uses interface HalTMP175Advanced;

  uses interface Leds;
  uses interface AMSend;
  uses interface Packet;
}
implementation
{
  uint8_t ledcount = 0;
  message_t packet;

  event void Boot.booted() {
    call SubControl.start();
  }

  event void Timer0.fired() {
    call Temperature.read();
  }

  event void SubControl.startDone(error_t result) {
#ifdef USE_INTERRUPTS
    call HalTMP175Advanced.setPolarity(TRUE);
#else
    call Timer0.startPeriodic( 100 );
#endif
  }

  event void SubControl.stopDone(error_t result) { }
  
  event void Temperature.readDone(error_t result, uint16_t val) {
    TestSensorMsg *rcm = (TestSensorMsg *)call Packet.getPayload(&packet, NULL);
    call Leds.led0Toggle();

    if (call Packet.maxPayloadLength() < sizeof(TestSensorMsg)) {
      return;
    }
    rcm->value = val;

    call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(TestSensorMsg));

  }

  event void HalTMP175Advanced.setTHighDone(error_t error) {
    call HalTMP175Advanced.setTLow(352);
  }
  event void HalTMP175Advanced.setThermostatModeDone(error_t error){
    call HalTMP175Advanced.setTHigh(448);
  } 

  event void HalTMP175Advanced.setPolarityDone(error_t error){
    call HalTMP175Advanced.setThermostatMode(TRUE);
  }
  event void HalTMP175Advanced.setFaultQueueDone(error_t error){ return; }
  event void HalTMP175Advanced.setResolutionDone(error_t error){ return; }
  event void HalTMP175Advanced.setTLowDone(error_t error){
    //call Timer0.startPeriodic( 1000 );
    call Leds.led2Toggle();
  }
  event void HalTMP175Advanced.alertThreshold() {
#ifdef USE_INTERRUPTS
    call Temperature.read();
    call Leds.led0Toggle();
#endif
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    return;
  }

}
