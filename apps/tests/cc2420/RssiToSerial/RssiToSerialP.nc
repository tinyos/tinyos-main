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
 
#include "Timer.h"
#include "RssiToSerial.h"
 
 /**
  * This is more of a general demonstration than a test.
  *
  * Install this application to one node, connected to the computer.
  * The node will measure the environmental RSSI from the CC2420 and
  * sending those readings over the serial port.
  *
  * Use the Java application to display the relative RSSI readings.
  *
  * @author Jared Hill
 * @date   23 March 2007
  */
 
module RssiToSerialP {
  uses {
    interface Leds;
    interface Boot;
    interface AMSend;
    interface SplitControl as AMControl;
    interface SplitControl as SerialControl;
    interface Packet;
    interface Read<uint16_t> as ReadRssi;
    interface CC2420Config as Config;
  }
}
implementation {

  /******* Global Variables ****************/
  message_t packet;
  bool locked;
  uint32_t total;
  uint16_t largest;
  uint16_t reads;
  
  /******** Declare Tasks *******************/
  task void readRssi();
  task void sendSerialMsg();
  
  /************ Boot Events *****************/
  event void Boot.booted() {
    call AMControl.start();
    total = 0;
    largest = 0;
    reads = 0;
    locked = FALSE;
  }

  /************ AMControl Events ******************/
  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call SerialControl.start();
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  
  /***************SerialControl Events*****************/
  event void SerialControl.startDone(error_t error){
    if (error == SUCCESS) {
      post readRssi();
    }
    else {
      call AMControl.start();
    }
  }
  
  event void SerialControl.stopDone(error_t error){
    //do nothing
  }
  
  /***************** AMSend Events ****************************/
  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    
    if (&packet == bufPtr) {
      locked = FALSE;
    }
    //post readRssi();
  }
  
  /**************** ReadRssi Events *************************/
  event void ReadRssi.readDone(error_t result, uint16_t val ){
    
    if(result != SUCCESS){
      post readRssi();
      return;
    }
    atomic{
      total += val;
      reads ++;
      if(largest < val){
        largest = val;
      }
    } 
    if(reads == (1<<LOG2SAMPLES)){
      post sendSerialMsg();
    }
    
    post readRssi();
    
  }
  
  /********************* Config Events *************************/
  event void Config.syncDone(error_t error){
  
  }

  /***************** TASKS *****************************/  
  task void readRssi(){
   
    if(call ReadRssi.read() != SUCCESS){
      post readRssi();
    }
  }
  
  task void sendSerialMsg(){
    if(locked){
      return;
    }
    else {
      rssi_serial_msg_t* rsm = (rssi_serial_msg_t*)call Packet.getPayload(&packet, sizeof(rssi_serial_msg_t));
      
      if (call Packet.maxPayloadLength() < sizeof(rssi_serial_msg_t)) {
	    return;
      }
	  atomic{
	    rsm->rssiAvgValue = (total >> (LOG2SAMPLES));
	    rsm->rssiLargestValue = largest;
	    total = 0;
	    largest = 0;
	    reads = 0;
	  }
	  rsm->channel = call Config.getChannel();
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(rssi_serial_msg_t)) == SUCCESS) {
	    locked = TRUE;
      }
    }
  }

}




