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
module LowPowerSensingBaseC {
  uses {
    interface Boot;
    interface Queue<message_t> as MsgQueue;
    interface Leds;
    interface LowPowerListening as LPL;

    interface SplitControl as SerialAMControl;
    interface AMPacket as SerialAMPacket;
    interface Packet as SerialPacket;

    interface SplitControl as RadioAMControl;
    interface AMPacket as RadioAMPacket;
    interface Packet as RadioPacket;

    interface Receive as SerialRequestSampleMsgsReceive;
    interface AMSend as RadioRequestSampleMsgsSend;
    interface Receive as RadioSampleMsgReceive;
    interface AMSend as SerialSampleMsgSend;
  }
}
implementation {
  bool serialSending;
  am_addr_t dest_addr;
  message_t request_samples_msg;
  message_t sample_msg;
  serial_sample_msg_t* sample_msg_payload;

  event void Boot.booted() {
    serialSending = FALSE;
    sample_msg_payload = (serial_sample_msg_t*)call SerialPacket.getPayload(&sample_msg, NULL);
    call RadioAMControl.start();
  }
  
  event void RadioAMControl.startDone(error_t error) {
    call SerialAMControl.start();
  }

  event void SerialAMControl.startDone(error_t error) {
  }

  event void RadioAMControl.stopDone(error_t error) {
  }

  event void SerialAMControl.stopDone(error_t error) {
  }

  event message_t* SerialRequestSampleMsgsReceive.receive(message_t* msg, void* payload, uint8_t len) {
    serial_request_samples_msg_t* request_msg = payload;
    call Leds.led0On();
    call LPL.setRxSleepInterval(&request_samples_msg, LPL_INTERVAL+100);
    call RadioRequestSampleMsgsSend.send(request_msg->addr, &request_samples_msg, sizeof(request_samples_msg_t));
    return msg;
  }

  event void RadioRequestSampleMsgsSend.sendDone(message_t* msg, error_t error) {
    if(error == SUCCESS)
      call Leds.led0Off();
  }

  event message_t* RadioSampleMsgReceive.receive(message_t* msg, void* payload, uint8_t len) {
    call Leds.led2Toggle();
    if(call MsgQueue.empty() == FALSE || serialSending == TRUE)
      call MsgQueue.enqueue(*msg);
    else {
      sample_msg_payload->src_addr = call RadioAMPacket.source(msg);
      sample_msg_payload->sample = *((nx_sensor_sample_t*)payload);
      dest_addr = call SerialAMPacket.destination(msg); 
      serialSending = TRUE;
      call SerialSampleMsgSend.send(dest_addr, &sample_msg, sizeof(*sample_msg_payload));
    }
    return msg;
  }

  event void SerialSampleMsgSend.sendDone(message_t* msg, error_t error) {
    if(call MsgQueue.empty() == FALSE) {
      sample_msg = call MsgQueue.dequeue();
      dest_addr = call SerialAMPacket.destination(msg);
      call SerialSampleMsgSend.send(dest_addr, &sample_msg, sizeof(serial_sample_msg_t));
    }
    else serialSending = FALSE;
  }
}

