/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
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
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */
 
/**
 * Test the effectiveness of the PacketLink layer
 *
 * Transmitter == 1, 2, 3, 4, or 5 (up to MAX_TRANSMITTERS)
 * Receiver == 0
 *
 * Expect:
 *   Transmitter (ID not 0) -
 *     led1 toggling on every successfully delivered message
 *     led0 toggling on every unsuccessfully delivered message (and stay on
 *       until the next dropped packet)
 *   
 *   Receiver (ID 0) -
 *     Leds represent the binary count of sets of messages that were dropped
 *     or duplicated.
 * 
 *     Ideally, if the transmitter and receiver are in range of each other, 
 *     the receiver's LEDs should never turn on.  You can pull the receiver
 *     out of range for up to two seconds before the transmission will fail.
 *     If you aren't convinced the receiver is doing anything because its 
 *     leds aren't flashing, just turn it off and watch the transmitter's
 *     reaction.
 *
 * @author David Moss
 */
  
#include "TestPacketLink.h"

module TestPacketLinkP {
  uses {
    interface Boot;
    interface SplitControl as RadioSplitControl;
    interface SplitControl as SerialSplitControl;
    interface AMSend;
    interface AMSend as SerialAMSend;
    interface AMPacket;
    interface Receive;
    interface PacketLink;
    interface Leds;
    interface Timer<TMilli>;
  }
}

implementation {

  /** The message we'll be sending */
  message_t myMsg;
  
  /** Serial message for status */
  message_t serialMsg;
  
  /** The local count we're sending or should receive on each unique message */
  uint32_t count[MAX_TRANSMITTERS];
  
  /** The total number of packets missed by the receiver */
  uint8_t missedPackets;
  
  /** True if this mote is the transmitter mote */
  bool transmitter;
  
  enum {
    MSG_DESTINATION = 0,
  };
  
  /***************** Prototypes ****************/
  task void send();
  task void sendSerial();
  
  /***************** Boot Events ****************/
  event void Boot.booted() {
    int i;
    
    /*
     * Setup this message in advance to retry up to 50 times with 40 ms of
     * delay between each message.  50 * 40 ms = 2 seconds before it quits.
     * It only needs to be setup once to be stored in the msg's metadata.
     */
    call PacketLink.setRetries(&myMsg, 50);
    call PacketLink.setRetryDelay(&myMsg, 40);
    missedPackets = 0;
    
    for(i = 0; i < MAX_TRANSMITTERS; i++) {
      count[i] = 0;
    }
    
    transmitter = (call AMPacket.address() != 0);
    call RadioSplitControl.start();
    
    if(!transmitter) {
      call SerialSplitControl.start();
    }
  }
  
  /***************** SplitControl Events *****************/
  event void RadioSplitControl.startDone(error_t error) {
    if(transmitter) {
      post send();
    }
  }
  
  event void RadioSplitControl.stopDone(error_t error) {
  }

  /***************** SerialSplitControl Events ****************/
  event void SerialSplitControl.startDone(error_t error) {
  }
  
  event void SerialSplitControl.stopDone(error_t error) {
  }
  
  /***************** AMSend Events ****************/
  event void AMSend.sendDone(message_t *msg, error_t error) {
    if(call PacketLink.wasDelivered(msg)) {
      count[0]++;
      call Leds.led1Toggle();
    } else {
      call Leds.led0Toggle();
    }
    
    ((PacketLinkMsg *) call AMSend.getPayload(&myMsg, sizeof(PacketLinkMsg)))->count = count[0];
    call Timer.startOneShot(50);
  }
  
  /***************** SerialAMSend Events ****************/
  event void SerialAMSend.sendDone(message_t *msg, error_t error) {
  }
  
  /***************** Receive Events ****************/
  event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len) {
    PacketLinkMsg *linkMsg = (PacketLinkMsg *) payload;
    uint16_t source = call AMPacket.source(msg);
    
    if(transmitter || source > MAX_TRANSMITTERS - 1) {
      return msg;
    }
    
    if(linkMsg->count != count[source]) {
      ((PacketLinkMsg *) (call SerialAMSend.getPayload(&serialMsg, sizeof(PacketLinkMsg))))->src = source;
      if(linkMsg->count > count[source]) {
        ((PacketLinkMsg *) (call SerialAMSend.getPayload(&serialMsg, sizeof(PacketLinkMsg))))->cmd = CMD_DROPPED_PACKET;
      } else {
        ((PacketLinkMsg *) (call SerialAMSend.getPayload(&serialMsg, sizeof(PacketLinkMsg))))->cmd = CMD_DUPLICATE_PACKET;
      }
      post sendSerial();
      
      if(count[source] != 0) {
        missedPackets++;
        call Leds.set(missedPackets);
      }
    }
    
    count[source] = linkMsg->count;
    count[source]++;
    return msg;
  }
  
  /***************** Timer Events ***************/
  event void Timer.fired() {
    post send();
  }
  
  /***************** Tasks ****************/
  task void send() {
    if(call AMSend.send(MSG_DESTINATION, &myMsg, sizeof(PacketLinkMsg)) != SUCCESS) {
      post send();
    }
  }
  
  task void sendSerial() {
    if(call SerialAMSend.send(0, &serialMsg, sizeof(PacketLinkMsg)) != SUCCESS) {
      post sendSerial();
    }
  }
}

