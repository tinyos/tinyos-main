/*
 * Copyright (c) 2007 Stanford University.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Kevin Klues <klueska@cs.stanford.edu>
 * @date July 24, 2007
 */

#include "LowPowerSensingConstants.h"
#include "SensorSample.h"
module LowPowerSensingPeriodicSamplerC {
  uses {
    interface Boot;
    interface SampleLogRead<sensor_sample_t>;
    interface SampleNxConverter;
    interface Leds;
    interface SplitControl as AMControl;
    interface AMPacket;
    interface Packet;
    interface AMSend as SampleSend;
    interface Receive as RequestSamplesReceive;
    interface LowPowerListening as LPL;
  }
}
implementation {
  message_t sample_msg;
  bool sendBusy = FALSE;

  task void readNextTask();
  task void sendSampleMsgTask();

  void readNext() {
    error_t error = call SampleLogRead.readNext();
    if(error == FAIL)
      post readNextTask();
    else if(error == ECANCEL) {
      sendBusy = FALSE;
      call Leds.led1Toggle();
    }
  }
  
  void sendSampleMsg() {
    call LPL.setRemoteWakeupInterval(&sample_msg, 0);
    if(call SampleSend.send(BASE_STATION_ADDR, &sample_msg, sizeof(nx_sensor_sample_t)) != SUCCESS)
      post sendSampleMsgTask();
    else call Leds.led2On();
  }
  
  task void readNextTask() { readNext(); }
  task void sendSampleMsgTask() { sendSampleMsg(); }
	
  event void Boot.booted() {
    call LPL.setLocalWakeupInterval(LPL_INTERVAL);
    call AMControl.start();
  }
  
  event void AMControl.startDone(error_t e) {
  	if(e != SUCCESS)
  		call AMControl.start();
  }
  
  event void AMControl.stopDone(error_t e) {
  }
  
  event void SampleLogRead.readDone(sensor_sample_t* sample, error_t error) {
    if(error == SUCCESS) {
      nx_sensor_sample_t* nx_sample = call SampleSend.getPayload(&sample_msg, sizeof(nx_sample));
      call SampleNxConverter.copyToNx(nx_sample, sample);
      sendSampleMsg();
    }
    else post readNextTask();
  }

  event message_t* RequestSamplesReceive.receive(message_t* msg, void* payload, uint8_t len) {
    call Leds.led0Toggle();
    if(sendBusy == FALSE) {
      sendBusy = TRUE;
      readNext();
    }
    return msg;
  }

  event void SampleSend.sendDone(message_t* msg, error_t error) {
    if(error != SUCCESS)
      post sendSampleMsgTask();
    else {
      call Leds.led2Off();
      readNext();
    }
  }
}
