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
 * Reliable Packet Link Functionality
 * @author David Moss
 * @author Jon Wyant
 */
 
#include "Jn516.h"
#include <MMAC.h>

module PacketLinkP {
  provides {
    interface Send;
    interface PacketLink;
  }
  
  uses {
    interface Send as SubSend;
    interface State as SendState;
    interface PacketAcknowledgements;
    interface Timer<TMilli> as DelayTimer;
    interface Jn516PacketBody;
  }
}

implementation {
  
  /** The message currently being sent */
  message_t *currentSendMsg;
  
  /** Length of the current send message */
  uint8_t currentSendLen;
  
  /** The length of the current send message */
  uint16_t totalRetries;
  
  
  /**
   * Send States
   */
  enum {
    S_IDLE,
    S_SENDING,
  };
  
  
  /***************** Prototypes ***************/
  task void send();
  void signalDone(error_t error);
    
  /***************** PacketLink Commands ***************/
  /**
   * Set the maximum number of times attempt message delivery
   * Default is 0
   * @param msg
   * @param maxRetries the maximum number of attempts to deliver
   *     the message
   */
  command void PacketLink.setRetries(message_t *msg, uint16_t maxRetries) {
    (call Jn516PacketBody.getMetadata(msg))->maxRetries = maxRetries;
  }

  /**
   * Set a delay between each retry attempt
   * @param msg
   * @param retryDelay the delay betweeen retry attempts, in milliseconds
   */
  command void PacketLink.setRetryDelay(message_t *msg, uint16_t retryDelay) {
    (call Jn516PacketBody.getMetadata(msg))->retryDelay = retryDelay;
  }

  /** 
   * @return the maximum number of retry attempts for this message
   */
  command uint16_t PacketLink.getRetries(message_t *msg) {
    return (call Jn516PacketBody.getMetadata(msg))->maxRetries;
  }

  /**
   * @return the delay between retry attempts in ms for this message
   */
  command uint16_t PacketLink.getRetryDelay(message_t *msg) {
    return (call Jn516PacketBody.getMetadata(msg))->retryDelay;
  }

  /**
   * @return TRUE if the message was delivered.
   */
  command bool PacketLink.wasDelivered(message_t *msg) {
    return call PacketAcknowledgements.wasAcked(msg);
  }
  
  /***************** Send Commands ***************/
  /**
   * Each call to this send command gives the message a single
   * DSN that does not change for every copy of the message
   * sent out.  For messages that are not acknowledged, such as
   * a broadcast address message, the receiving end does not
   * signal receive() more than once for that message.
   */
  command error_t Send.send(message_t *msg, uint8_t len) {
    error_t error;
    if(call SendState.requestState(S_SENDING) == SUCCESS) {
    
      currentSendMsg = msg;
      currentSendLen = len;
      totalRetries = 0;

      if(call PacketLink.getRetries(msg) > 0) {
        call PacketAcknowledgements.requestAck(msg);
      }
     
      if((error = call SubSend.send(msg, len)) != SUCCESS) {
        call SendState.toIdle();
      }
      
      return error;
    }
    return EBUSY;
  }

  command error_t Send.cancel(message_t *msg) {
    if(currentSendMsg == msg) {
      call SendState.toIdle();
      return call SubSend.cancel(msg);
    }
    
    return FAIL;
  }
  
  
  command uint8_t Send.maxPayloadLength() {
    return call SubSend.maxPayloadLength();
  }

  command void *Send.getPayload(message_t* msg, uint8_t len) {
    return call SubSend.getPayload(msg, len);
  }
  
  
  /***************** SubSend Events ***************/
  event void SubSend.sendDone(message_t* msg, error_t error) {
    if(call SendState.getState() == S_SENDING) {
      totalRetries++;
      if(call PacketAcknowledgements.wasAcked(msg)) {
        signalDone(SUCCESS);
        return;
        
      } else if(totalRetries < call PacketLink.getRetries(currentSendMsg)) {
        
        if(call PacketLink.getRetryDelay(currentSendMsg) > 0) {
          // Resend after some delay
          call DelayTimer.startOneShot(call PacketLink.getRetryDelay(currentSendMsg));
          
        } else {
          // Resend immediately
          post send();
        }
        
        return;
      }
    }
    
    signalDone(error);
  }
  
  
  /***************** Timer Events ****************/  
  /**
   * When this timer is running, that means we're sending repeating messages
   * to a node that is receive check duty cycling.
   */
  event void DelayTimer.fired() {
    if(call SendState.getState() == S_SENDING) {
      post send();
    }
  }
  
  /***************** Tasks ***************/
  task void send() {
    if(call PacketLink.getRetries(currentSendMsg) > 0) {
      call PacketAcknowledgements.requestAck(currentSendMsg);
    }
    
    if(call SubSend.send(currentSendMsg, currentSendLen) != SUCCESS) {
      post send();
    }
  }
  
  /***************** Functions ***************/  
  void signalDone(error_t error) {
    call DelayTimer.stop();
    call SendState.toIdle();

    // update only if retries were explicitly asked for
    if((call Jn516PacketBody.getMetadata(currentSendMsg))->maxRetries > 0)
	    (call Jn516PacketBody.getMetadata(currentSendMsg))->maxRetries = totalRetries;

    signal Send.sendDone(currentSendMsg, error);
  }
}

