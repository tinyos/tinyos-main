/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
 * Copyright (c) 2002-2003 Intel Corporation.
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
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.

/**
 * This application tests the coexistence of radio and flash.
 * (based on RadioCountToLeds)
 *
 * @see README.TXT
 * @author Philipp Huppertz
 * @author Philip Levis (RadioCountToLeds)
 * @date   June 6 2005
 */

#include "Timer.h"
#include "RadioCountToFlash.h"
#define LOG_LENGTH 15

module RadioCountToFlashC {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as FlashTimer;
    interface Timer<TMilli> as RadioTimer;
    interface SplitControl as AMControl;
    interface Packet;
    interface LogRead;
    interface LogWrite;
    interface GeneralIO as FailureLed;
  }
}
implementation {

  message_t packet;

  bool locked;
  uint16_t sendingCounter = 0;
  uint16_t receiveCounter = 0;
  uint16_t readBuffer = 0;
  uint16_t logCounter = 0;      
 
  void failure() {
    call FailureLed.set();
    for (;;) {
      ;
    }
  } 
  
  task void readingTask() {
    if (call LogRead.read((void*) &readBuffer, sizeof(receiveCounter)) != SUCCESS) {
      post readingTask();
    }
  }
  
  task void writingTask() {
    if (call LogWrite.append((void*)receiveCounter, sizeof(receiveCounter)) != SUCCESS) {
      post writingTask();
    }
  }
  
  event void Boot.booted() {
    call LogWrite.erase();
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call RadioTimer.startPeriodic(1000);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    	// do nothing
  }
  
  event void FlashTimer.fired() {
    if (call LogRead.read((void*) &readBuffer, sizeof(receiveCounter)) != SUCCESS) {
      post readingTask();
    }
  }
      
  event void RadioTimer.fired() {
    dbg("RadioCountToLedsC", "RadioCountToLedsC: timer fired, counter is %hu.\n", counter);
    if (locked) {
      return;
    }
    else {
      RadioCountMsg* rcm = (RadioCountMsg*)call Packet.getPayload(&packet, sizeof(rcm));
      if (rcm == NULL || call Packet.maxPayloadLength() < sizeof(RadioCountMsg)) {
        return;
      }
      ++sendingCounter;
      rcm->counter = sendingCounter;	
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(RadioCountMsg)) == SUCCESS) {
        dbg("RadioCountToLedsC", "RadioCountToLedsC: packet sent.\n", counter);	
        locked = TRUE;
      }
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    dbg("RadioCountToLedsC", "Received packet of length %hhu.\n", len);
    if (len != sizeof(RadioCountMsg)) {return bufPtr;}
    else {
      RadioCountMsg* rcm = (RadioCountMsg*)payload;
      receiveCounter = rcm->counter;
      if (call LogWrite.append((void*)&receiveCounter, sizeof(receiveCounter)) != SUCCESS) {
        post writingTask();
      }
    }
    return bufPtr;
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

  event void LogRead.readDone(void* buf, storage_len_t len, error_t error) {
    --logCounter;
    if (error != SUCCESS) {
      failure();
    }
    readBuffer = *(uint16_t*)buf;
    if ( logCounter > 0 ) {
      if (readBuffer & 0x1) {
        call Leds.led0On();
      }
      else {
        call Leds.led0Off();
      }
      if (readBuffer & 0x2) {
        call Leds.led1On();
      }
      else {
        call Leds.led1Off();
      }
      if (readBuffer & 0x4) {
        call Leds.led2On();
      }
      else {
        call Leds.led2Off();
      }
      call FlashTimer.startOneShot(100);
    } 
  }  
      
  event void LogRead.seekDone(error_t error) {
    if (error != SUCCESS) {
      failure();
    }
  }
  
  event void LogWrite.appendDone(void* buf, storage_len_t len, bool recordsLost, error_t error) {
    ++logCounter;
    if (error != SUCCESS) {
      failure();
    }
    if (logCounter > LOG_LENGTH) {
      if (call LogWrite.sync() != SUCCESS) {
        failure();
      } 
    } 
  }

  event void LogWrite.syncDone(error_t error) {
    if (error != SUCCESS) {
      failure();
    }
    call FlashTimer.startOneShot(100);
  }
      
  event void LogWrite.eraseDone(error_t error) {
    if (error != SUCCESS) {
      failure();
    }
  }
      
}

