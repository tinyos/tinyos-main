/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2004-2006, Technische Universitaet Berlin
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
 * - Neither the name of the Technische Universitaet Berlin nor the names
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
 *
 */

#include "radiopacketfunctions.h"
#include "message.h"
#include "PacketAck.h"

/**
 * This is the implementation of a really simple link layer. 
 *
 * @author Andreas Koepke <koepke@tkn.tu-berlin.de>
 */
module LinkLayerP {
    provides {
      interface Init;
      interface SplitControl;
      interface Receive;
      interface Send;
      interface PacketAcknowledgements;
    }
    uses {
      interface SplitControl as MacSplitControl;
      interface SplitControl as RadioSplitControl;
      interface MacSend as SendDown;
      interface MacReceive as ReceiveLower;
      interface Packet;
    }
}
implementation
{
  /* Tx/Rx buffers & pointers */
  message_t* txBufPtr;
  message_t* rxBufPtr;
  message_t  rxBuf;

  /* state vars */
  error_t splitStateError;    // state of SplitControl interfaces
  bool rxBusy;                // blocks an incoming packet if the rxBuffer is in use
    
// #define LLCM_DEBUG  
    /**************** Helper functions ******/
    void signalFailure() {
#ifdef LLCM_DEBUG
        atomic {
            for(;;) {
                ;
            }
        }
#endif
    }
    
    /**************** Init  *****************/
    command error_t Init.init(){
        atomic {
          rxBufPtr = &rxBuf;
          txBufPtr = 0;
          splitStateError = EOFF;
          rxBusy = FALSE;
        }
        return SUCCESS;
    }

    /**************** Start  *****************/
    void checkStartDone(error_t error) {
      atomic {
        if ( (splitStateError == SUCCESS) && (error == SUCCESS) ) {
          signal SplitControl.startDone(SUCCESS);
        } else if ( (error == SUCCESS) && (splitStateError == EOFF) ) {
          splitStateError = SUCCESS;
        } else {
          signal SplitControl.startDone(FAIL);
        }
      }
    }
    
    event void MacSplitControl.startDone(error_t error) {
      checkStartDone(error);
    }
    
    event void RadioSplitControl.startDone(error_t error) {
      checkStartDone(error);
    }
    
    command error_t SplitControl.start() {
      call MacSplitControl.start();
      call RadioSplitControl.start();
      return SUCCESS;
    }
    /**************** Stop  *****************/
    void checkStopDone(error_t error) {
      atomic {
        if ( (splitStateError == EOFF) && (error == SUCCESS) ) {
          signal SplitControl.stopDone(SUCCESS);
        } else if ( (error == SUCCESS) && (splitStateError == SUCCESS) ) {
          splitStateError = EOFF;
        } else {
          signal SplitControl.stopDone(FAIL);
        }
      }
    }
    
    event void MacSplitControl.stopDone(error_t error) {
      checkStopDone(error);
    }
    
    event void RadioSplitControl.stopDone(error_t error) {
      checkStopDone(error);
    }
    
    command error_t SplitControl.stop(){
      call MacSplitControl.stop();
      call RadioSplitControl.stop();
      return SUCCESS;
    }
    /**************** Send ****************/
    task void SendDoneSuccessTask() {
      message_t* txPtr;
      atomic txPtr = txBufPtr;
      signal Send.sendDone(txPtr, SUCCESS);
    }
    task void SendDoneCancelTask() {
      message_t* txPtr;
      atomic txPtr = txBufPtr;
      signal Send.sendDone(txPtr, ECANCEL); 
    }
    task void SendDoneFailTask() {
      message_t* txPtr;
      atomic txPtr = txBufPtr;
      signal Send.sendDone(txPtr, FAIL);
    }
    
    command error_t Send.send(message_t *msg, uint8_t len) {
        if(getMetadata(msg)->ack != NO_ACK_REQUESTED) {
            // ensure reasonable value
            getMetadata(msg)->ack = ACK_REQUESTED;
        }
        return call SendDown.send(msg, len);
    }

    command error_t Send.cancel(message_t* msg) {
      return call SendDown.cancel(msg);
    }
    
    command uint8_t Send.maxPayloadLength() {
      return call Packet.maxPayloadLength();
    }

    command void* Send.getPayload(message_t* msg) {
      return call Packet.getPayload(msg, (uint8_t*) (call Packet.payloadLength(msg)) );
    }
    
    async event void SendDown.sendDone(message_t* msg, error_t error) { 
        atomic {
          txBufPtr = msg;
        }
        if (error == SUCCESS) {
          post SendDoneSuccessTask();
        } else if (error == ECANCEL) {
          post SendDoneCancelTask();
        } else {
          post SendDoneFailTask();
        }
    }
    
    /*************** Receive ***************/
    task void ReceiveTask() {
      void *payload;
      uint8_t len;
      message_t* tmpMsgPtr;
      atomic {
        len = call Packet.payloadLength(rxBufPtr);
        payload = call Packet.getPayload(rxBufPtr, &len);
        tmpMsgPtr = rxBufPtr;
      }
      tmpMsgPtr = signal Receive.receive(tmpMsgPtr, payload , len);
      atomic {
        rxBufPtr = tmpMsgPtr;
        rxBusy = FALSE;
      }
    }
    
    async event message_t* ReceiveLower.receiveDone(message_t* msg) {
      message_t* msgPtr;
      atomic {
        if (rxBusy) {
          msgPtr = msg;
        }
        else {
          rxBusy = TRUE;
          msgPtr = rxBufPtr;
          rxBufPtr = msg;
          post ReceiveTask();
        }
      } 
      return msgPtr;
    }

    command void* Receive.getPayload(message_t* msg, uint8_t* len) {
      return call Packet.getPayload(msg, len);
    }

    command uint8_t Receive.payloadLength(message_t* msg) {
      return call Packet.payloadLength(msg);
    }

    /*************** default events ***********/

    /* for lazy buggers who do not want to do something with a packet */
    default event void Send.sendDone(message_t* sent, error_t success) {
    }

    default event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
        return msg;
    }     
    
    
    /* PacketAcknowledgements interface */

    async command error_t PacketAcknowledgements.requestAck(message_t* msg) {
        getMetadata(msg)->ack = ACK_REQUESTED;
        return SUCCESS;
    }

    async command error_t PacketAcknowledgements.noAck(message_t* msg) {
        getMetadata(msg)->ack = NO_ACK_REQUESTED;
        return SUCCESS;
    }

    async command bool PacketAcknowledgements.wasAcked(message_t* msg) {
        bool rVal = FALSE;
        if(getMetadata(msg)->ack == WAS_ACKED) rVal = TRUE;
        return rVal;
    }
}



