//$Id: SerialDispatcherP.nc,v 1.10 2010-06-29 22:07:50 scipio Exp $

/* Copyright (c) 2000-2005 The Regents of the University of California.  
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
 */

/**
 * This component provides functionality to send many different kinds
 * of serial packets on top of a general packet sending component. It
 * achieves this by knowing where the different packets in a message_t
 * exist through the SerialPacketInfo interface.
 *
 * @author Philip Levis
 * @author Ben Greenstein
 * @date August 7 2005
 *
 */

#include "Serial.h"

generic module SerialDispatcherP() {
  provides {
    interface Receive[uart_id_t id];
    interface Send[uart_id_t id];
  }
  uses {
    interface SerialPacketInfo as PacketInfo[uart_id_t id];
    interface ReceiveBytePacket;
    interface SendBytePacket;
    interface Leds;
  }
}
implementation {

  typedef enum {
    SEND_STATE_IDLE = 0,
    SEND_STATE_BEGIN = 1,
    SEND_STATE_DATA = 2
  } send_state_t;

  enum {
    RECV_STATE_IDLE = 0,
    RECV_STATE_BEGIN = 1,
    RECV_STATE_DATA = 2,
  }; 
  
  typedef struct {
    uint8_t which:1;
    uint8_t bufZeroLocked:1;
    uint8_t bufOneLocked:1;
    uint8_t state:2;
  } recv_state_t;
  
  // We are not busy, the current buffer to use is zero,
  // neither buffer is locked, and we are idle
  recv_state_t receiveState = {0, 0, 0, RECV_STATE_IDLE};
  uint8_t recvType = TOS_SERIAL_UNKNOWN_ID;
  uint8_t recvIndex = 0;

  /* This component provides double buffering. */
  message_t messages[2];     // buffer allocation
  message_t* ONE messagePtrs[2] = { &messages[0], &messages[1]};
  
  // We store a separate receiveBuffer variable because indexing
  // into a pointer array can be costly, and handling interrupts
  // is time critical.
  uint8_t* COUNT_NOK(sizeof(message_t)) receiveBuffer = (uint8_t* COUNT_NOK(sizeof(message_t)))(&messages[0]);

  uint8_t *COUNT_NOK(sizeof(message_t)) sendBuffer = NULL;
  send_state_t sendState = SEND_STATE_IDLE;
  uint8_t sendLen = 0;
  uint8_t sendIndex = 0;
  norace error_t sendError = SUCCESS;
  bool sendCancelled = FALSE;
  uint8_t sendId = 0;


  uint8_t receiveTaskPending = FALSE;
  uart_id_t receiveTaskType = 0;
  uint8_t receiveTaskWhich;
  message_t * ONE_NOK receiveTaskBuf = NULL;
  uint8_t receiveTaskSize = 0;

  command error_t Send.send[uint8_t id](message_t* msg, uint8_t len) {
    if (sendState != SEND_STATE_IDLE) {
      return EBUSY;
    }

    atomic {
      sendIndex = call PacketInfo.offset[id]();
      if (sendIndex > sizeof(message_header_t)) {
	return ESIZE;
      }
      
      sendError = SUCCESS;
      sendBuffer = (uint8_t*)msg;
      sendState = SEND_STATE_DATA;
      sendId = id;
      sendCancelled = FALSE;
      // If something we're starting past the header, something is wrong
      // Bug fix from John Regehr


      // sendLen is where in the buffer the packet stops.
      // This is the length of the packet, plus its start point
      sendLen = call PacketInfo.dataLinkLength[id](msg, len) + sendIndex;
    }
    if (call SendBytePacket.startSend(id) == SUCCESS) {
      return SUCCESS;
    }
    else {
      sendState = SEND_STATE_IDLE;
      return FAIL;
    }
  }

  command uint8_t Send.maxPayloadLength[uint8_t id]() {
    return (sizeof(message_t));
  }

  command void* Send.getPayload[uint8_t id](message_t* m, uint8_t len) {
    if (len > sizeof(message_t)) {
      return NULL;
    }
    else {
      return m;
    }
  }

    
  task void signalSendDone(){
    error_t error;

    sendState = SEND_STATE_IDLE;
    atomic error = sendError;

    if (sendCancelled) error = ECANCEL;
    signal Send.sendDone[sendId]((message_t *)sendBuffer, error);
  }

  command error_t Send.cancel[uint8_t id](message_t *msg){
    if (sendState == SEND_STATE_DATA && sendBuffer == ((uint8_t *)msg) &&
	id == sendId){
      call SendBytePacket.completeSend();
      sendCancelled = TRUE;
      return SUCCESS;
    }
    return FAIL;
  }

  async event uint8_t SendBytePacket.nextByte() {
    uint8_t b;
    uint8_t indx;
    atomic {
      b = sendBuffer[sendIndex];
      sendIndex++;
      indx = sendIndex;
    }
    if (indx > sendLen) {
      call SendBytePacket.completeSend();
      return 0;
    }
    else {
      return b;
    }
  }
  async event void SendBytePacket.sendCompleted(error_t error){
    atomic sendError = error;
    post signalSendDone();
  }

  bool isCurrentBufferLocked() {
    return (receiveState.which)? receiveState.bufOneLocked : receiveState.bufZeroLocked;
  }

  void lockCurrentBuffer() {
    if (receiveState.which) {
      receiveState.bufOneLocked = 1;
    }
    else {
      receiveState.bufZeroLocked = 1;
    }
  }

  void unlockBuffer(uint8_t which) {
    if (which) {
      receiveState.bufOneLocked = 0;
    }
    else {
      receiveState.bufZeroLocked = 0;
    }
  }
  
  void receiveBufferSwap() {
    receiveState.which = (receiveState.which)? 0: 1;
    receiveBuffer = (uint8_t*)(messagePtrs[receiveState.which]);
  }
  
  async event error_t ReceiveBytePacket.startPacket() {
    error_t result = SUCCESS;
    atomic {
      if (!isCurrentBufferLocked()) {
        // We are implicitly in RECV_STATE_IDLE, as it is the only
        // way our current buffer could be unlocked.
        lockCurrentBuffer();
        receiveState.state = RECV_STATE_BEGIN;
        recvIndex = 0;
        recvType = TOS_SERIAL_UNKNOWN_ID;
      }
      else {
        result = EBUSY;
      }
    }
    return result;
  }

  async event void ReceiveBytePacket.byteReceived(uint8_t b) {
    atomic {
      switch (receiveState.state) {
      case RECV_STATE_BEGIN:
        receiveState.state = RECV_STATE_DATA;
        recvIndex = call PacketInfo.offset[b]();
        recvType = b;
        break;
        
      case RECV_STATE_DATA:
        if (recvIndex < sizeof(message_t)) {
          receiveBuffer[recvIndex] = b;
          recvIndex++;
        }
        else {
          // Drop extra bytes that do not fit in a message_t.
          // We assume that either the higher layer knows what to
          // do with partial packets, or performs sanity checks (e.g.,
          // CRC).
        }
        break;
        
      case RECV_STATE_IDLE:
      default:
        // Do nothing. This case can be reached if the component
        // does not have free buffers: it will ignore a packet start
        // and stay in the IDLE state.
      }
    }
  }
  
  task void receiveTask(){
    uart_id_t myType;
    message_t *myBuf;
    uint8_t mySize;
    uint8_t myWhich;
    atomic {
      myType = receiveTaskType;
      myBuf = receiveTaskBuf;
      mySize = receiveTaskSize;
      myWhich = receiveTaskWhich;
    }
    mySize -= call PacketInfo.offset[myType]();
    mySize = call PacketInfo.upperLength[myType](myBuf, mySize);
    myBuf = signal Receive.receive[myType](myBuf, myBuf, mySize);
    atomic {
      messagePtrs[myWhich] = myBuf;
      unlockBuffer(myWhich);
      receiveTaskPending = FALSE;
    }
  }

  async event void ReceiveBytePacket.endPacket(error_t result) {
    uint8_t postsignalreceive = FALSE;
    atomic {
      if (!receiveTaskPending && result == SUCCESS){
        postsignalreceive = TRUE;
        receiveTaskPending = TRUE;
        receiveTaskType = recvType;
        receiveTaskWhich = receiveState.which;
        receiveTaskBuf = (message_t *)receiveBuffer;
        receiveTaskSize = recvIndex;
        receiveBufferSwap();
        receiveState.state = RECV_STATE_IDLE;
      } else {
        // we can't deliver the packet, better free the current buffer.
        unlockBuffer(receiveState.which);
      }
    }
    if (postsignalreceive){
      post receiveTask();
    }    

    // These are all local variables to release component state that
    // will allow the component to start receiving serial packets
    // ASAP.
    //
    // We need myWhich in case we happen to receive a whole new packet
    // before the signal returns, at which point receiveState.which
    // might revert back to us (via receiveBufferSwap()).
    
/*     uart_id_t myType;   // What is the type of the packet in flight?  */
/*     uint8_t myWhich;  // Which buffer ptr entry is it? */
/*     uint8_t mySize;   // How large is it? */
/*     message_t* myBuf; // A pointer, for buffer swapping */

    // First, copy out all of the important state so we can receive
    // the next packet. Then do a receiveBufferSwap, which will
    // tell the component to use the other available buffer.
    // If the buffer is 
/*     atomic { */
/*       myType = recvType; */
/*       myWhich = receiveState.which; */
/*       myBuf = (message_t*)receiveBuffer; */
/*       mySize = recvIndex; */
/*       receiveBufferSwap(); */
/*       receiveState.state = RECV_STATE_IDLE; */
/*     } */

/*     mySize -= call PacketInfo.offset[myType](); */
/*     mySize = call PacketInfo.upperLength[myType](myBuf, mySize); */

/*     if (result == SUCCESS){ */
/*       // TODO is the payload the same as the message? */
/*       myBuf = signal Receive.receive[myType](myBuf, myBuf, mySize); */
/*     } */
/*     atomic { */
/*       messagePtrs[myWhich] = myBuf; */
/*       if (myWhich) { */
/*         unlockBuffer(myWhich); */
/*       } */
/*     } */
  }

  default async command uint8_t PacketInfo.offset[uart_id_t id](){
    return 0;
  }
  default async command uint8_t PacketInfo.dataLinkLength[uart_id_t id](message_t *msg,
                                                          uint8_t upperLen){
    return 0;
  }
  default async command uint8_t PacketInfo.upperLength[uart_id_t id](message_t *msg,
                                                       uint8_t dataLinkLen){
    return 0;
  }


  default event message_t *Receive.receive[uart_id_t idxxx](message_t *msg,
                                                         void *payload,
                                                         uint8_t len){
    return msg;
  }
  default event void Send.sendDone[uart_id_t idxxx](message_t *msg, error_t error){
    return;
  }

  
}
