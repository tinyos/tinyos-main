/*
 * Copyright (c) 2011 University of Utah. 
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:  
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Thomas Schmid
 * @date   March 2011
 */

#include "Timer.h"
#include "TestADE7753.h"
#include "ACMeter.h"

module TestADE7753C @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;

    interface SplitControl as MeterControl;
    interface ReadStream<uint32_t> as ReadEnergy;
    interface GetSet<acmeter_state_t> as RelayConfig;
    interface GetSet<uint8_t> as GainConfig;
    interface Get<uint32_t> as GetPeriod32;
  }
}
implementation {

  message_t packet;

  bool locked;
  uint16_t counter = 0;

  uint32_t energyBuffer1[BUF_SIZE];
  uint32_t energyBuffer2[BUF_SIZE];
  uint32_t *currBuffer;

  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    call MeterControl.start();
  }

  void readEnergy() {
    // setup the buffers
    call ReadEnergy.postBuffer(energyBuffer1, BUF_SIZE);
    call ReadEnergy.postBuffer(energyBuffer2, BUF_SIZE);
    // setup the current buffer
    currBuffer = energyBuffer1;
    // start reading energy in 1s intervals
    call ReadEnergy.read(1000000);
  }

  event void MeterControl.startDone(error_t err) {
    readEnergy();
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }

  event void MeterControl.stopDone(error_t err) {
    // do nothing
  }

  event void MilliTimer.fired() {
  }

  task void sendData() {
    uint8_t i;

    counter++;
    if (locked) {
      return;
    }
    else {
      testade7753_msg_t* rcm = (testade7753_msg_t*)call Packet.getPayload(&packet, sizeof(testade7753_msg_t));
      if (rcm == NULL) {
        return;
      }

      // we can't do a memcopy because it's a newtork type!
      for(i=0; i<BUF_SIZE; i++)
        rcm->energy[i] = (int32_t)currBuffer[i];

      // post the buffer again
      call ReadEnergy.postBuffer(currBuffer, BUF_SIZE);
      rcm->counter = counter;
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(testade7753_msg_t)) == SUCCESS) {
        dbg("TestADE7753C", "TestADE7753C: packet sent.\n", counter);	
        locked = TRUE;
      }
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, 
      void* payload, uint8_t len) {
    dbg("TestADE7753C", "TestADE7753 packet of length %hhu.\n", len);
    if (len != sizeof(testade7753_msg_t)) {return bufPtr;}
    else {
      //testade7753_msg_t* rcm = (testade7753_msg_t*)payload;
      return bufPtr;
    }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

  event void ReadEnergy.bufferDone(error_t result,
      uint32_t* buf, uint16_t count) {
    // do something with the buffer here
    call Leds.led0Toggle();
    currBuffer = buf;
    post sendData();

  }

  event void ReadEnergy.readDone(error_t result, uint32_t usActualPeriod) {
    // we should never get here... it would be really bad as we loose samples!
    // Just in case, start energy reading again.
    readEnergy();
  }

}
