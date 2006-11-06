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
 * Low Power Listening for the CC1000
 *
 * @author David Moss
 */

#include "CC1000LowPowerListening.h"

module CC1000LowPowerListeningP {
  provides {
    interface Init;
    interface Send;
    interface Receive;
    interface CsmaBackoff[am_id_t amId];
  }
  
  uses {
    interface LowPowerListening;
    interface CsmaBackoff as SubBackoff;
    interface CsmaControl;
    interface Leds;
    interface Send as SubSend;
    interface Receive as SubReceive;
    interface AMPacket;
    interface SplitControl as SubControl;
    interface PacketAcknowledgements;
    interface State as SendState;
    interface State as RadioPowerState;
    interface Random;
    interface Timer<TMilli> as SendDoneTimer;
  }
}

implementation {
  
  /** The message currently being sent */
  message_t *currentSendMsg;
  
  /** The length of the current send message */
  uint8_t currentSendLen;
 
  /** Tx DSN to ensure multiple transmitted messages get across only once */ 
  uint8_t txDsn;
  
  /** The last received broadcast DSN. TODO is this the best way? */
  uint8_t lastRxDsn;

  /** TRUE if the first message of the current LPL delivery has been sent */
  norace bool firstMessageSent;
  
  /**
   * Radio State
   */
  enum {
    S_OFF,
    S_ON,
  };
  
  /**
   * Send States
   */
  enum {
    S_IDLE,
    S_SENDING,
  };
  
  
  /***************** Prototypes ***************/
  task void send();
  task void startRadio();
  task void stopRadio();
  
  cc1000_header_t *getHeader(message_t *msg);
  cc1000_metadata_t *getMetadata(message_t* msg);
  uint16_t getActualDutyCycle(uint16_t dutyCycle);
  void signalDone(error_t error);
  
  /***************** Init Commands ***************/
  command error_t Init.init() {
    txDsn = call Random.rand16();
    return SUCCESS;
  }
  
  
  /***************** SubBackoff Events ****************/
  async event uint16_t SubBackoff.initial(message_t* m) {
    if(call SendState.getState() == S_SENDING
        && getMetadata(m)->strength_or_preamble > ONE_MESSAGE
        && firstMessageSent) {
      call CsmaControl.disableCca();
      return 1;
      
    } else {
      return signal CsmaBackoff.initial[getHeader(m)->type](m);
    }
  }

  async event uint16_t SubBackoff.congestion(message_t* m) {
    if(call SendState.getState() == S_SENDING
        && getMetadata(m)->strength_or_preamble > ONE_MESSAGE
        && firstMessageSent) {
      call CsmaControl.disableCca();
      return 1;
      
    } else {
      return signal CsmaBackoff.congestion[getHeader(m)->type](m);
    }
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
    if(call RadioPowerState.getState() == S_OFF) {
      // Everything is off right now, start SplitControl and try again
      return EOFF;
    }
    
    if(call SendState.requestState(S_SENDING) == SUCCESS) {
      currentSendMsg = msg;
      currentSendLen = len;
      (getHeader(msg))->dsn = ++txDsn;
      
      firstMessageSent = FALSE;
      if(call LowPowerListening.getRxSleepInterval(currentSendMsg) 
          > ONE_MESSAGE) {
          
        // Send it repetitively within our transmit window
        call PacketAcknowledgements.requestAck(currentSendMsg);
        call SendDoneTimer.startOneShot(
            call LowPowerListening.getRxSleepInterval(currentSendMsg) * 2);
      }
      
      // If the radio is off, the CC1000Csma will automatically turn it on
      post send();
      return SUCCESS;
    }
    
    return FAIL;
  }

  command error_t Send.cancel(message_t *msg) {
    if(currentSendMsg == msg) {
      call SendState.toIdle();
      return SUCCESS;
    }
    
    return FAIL;
  }
  
  
  command uint8_t Send.maxPayloadLength() {
    return call SubSend.maxPayloadLength();
  }

  command void *Send.getPayload(message_t* msg) {
    return call SubSend.getPayload(msg);
  }
  
  /***************** Receive Commands ***************/
  command void *Receive.getPayload(message_t* msg, uint8_t* len) {
    return call SubReceive.getPayload(msg, len);
  }

  command uint8_t Receive.payloadLength(message_t* msg) {
    return call SubReceive.payloadLength(msg);
  }

  
  /***************** SubControl Events ***************/
  event void SubControl.startDone(error_t error) {
    if(!error) {
      call RadioPowerState.forceState(S_ON);
    }
  }
    
  event void SubControl.stopDone(error_t error) {
    if(!error) {
      call RadioPowerState.forceState(S_OFF);
    }
  }
  
  /***************** SubSend Events ***************/
  event void SubSend.sendDone(message_t* msg, error_t error) {
    if(call SendState.getState() == S_SENDING  
        && call SendDoneTimer.isRunning()) {
      if(call PacketAcknowledgements.wasAcked(msg)) {
        signalDone(error);
        
      } else {
        post send();
      }
      
      return;
    }
    
    signalDone(error);
  }
  
  /***************** SubReceive Events ***************/
  /**
   * If the received message is new, we signal the receive event and
   * start the off timer.  If the last message we received had the same
   * DSN as this message, then the chances are pretty good
   * that this message should be ignored, especially if the destination address
   * as the broadcast address
   *
   * TODO
   * What happens if a unicast Tx doesn't get Rx's ack, and resends that
   * message?
   */
  event message_t *SubReceive.receive(message_t* msg, void* payload, 
      uint8_t len) {
    
    if((getHeader(msg))->dsn == lastRxDsn 
        && call AMPacket.destination(msg) == AM_BROADCAST_ADDR) {
      // Already got this broadcast message.
      // TODO should we do something similar with unicast messages?
      return msg;

    } else {
      lastRxDsn = (getHeader(msg))->dsn;
      return signal Receive.receive(msg, payload, len);
    }
  }
  
  /***************** Timer Events ****************/  
  /**
   * When this timer is running, that means we're sending repeating messages
   * to a node that is receive check duty cycling.
   */
  event void SendDoneTimer.fired() {
    if(call SendState.getState() == S_SENDING) {
      // The next time SubSend.sendDone is signaled, send is complete.
      call SendState.toIdle();
    }
  }
  
  /***************** Tasks ***************/
  task void send() {
    if(call SubSend.send(currentSendMsg, currentSendLen) != SUCCESS) {
      post send();
    }
  }
  
  task void startRadio() {
    if(call SubControl.start() != SUCCESS) {
      post startRadio();
    }
  }
  
  task void stopRadio() {
    if(call SubControl.stop() != SUCCESS) {
      post stopRadio();
    }
  }
  
  /***************** Functions ***************/  
  /**
   * Check the bounds on a given duty cycle
   * We're never over 100%, and we're never at 0%
   */
  uint16_t getActualDutyCycle(uint16_t dutyCycle) {
    if(dutyCycle > 10000) {
      return 10000;
    } else if(dutyCycle == 0) {
      return 1;
    }
    
    return dutyCycle;
  }
  
  cc1000_header_t *getHeader(message_t *msg) {
    return (cc1000_header_t *)(msg->data - sizeof( cc1000_header_t ));
  }
  
  cc1000_metadata_t *getMetadata(message_t* msg) {
    return (cc1000_metadata_t*)msg->metadata;
  }
  
  void signalDone(error_t error) {
    call CsmaControl.enableCca();
    call SendState.toIdle();
    // TODO check for broadcast destination
    signal Send.sendDone(currentSendMsg, error);
    currentSendMsg = NULL;
  }
  
  
    
  /***************** Defaults ****************/
  default async event uint16_t CsmaBackoff.initial[am_id_t amId](message_t *m) {
    return ( call Random.rand16() % (0x1F * CC1000_BACKOFF_PERIOD) 
        + CC1000_MIN_BACKOFF);
  }

  default async event uint16_t CsmaBackoff.congestion[am_id_t amId](message_t *m) {
    return ( call Random.rand16() % (0x7 * CC1000_BACKOFF_PERIOD) 
        + CC1000_MIN_BACKOFF);
  }
}

