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
 * Low Power Listening for the CC2420
 *
 * @author David Moss
 */

#include "CC2420LowPowerListening.h"

module CC2420LowPowerListeningP {
  provides {
    interface Init;
    interface LowPowerListening;
    interface Send;
    interface Receive;
  }
  
  uses {
    interface Leds;
    interface Send as SubSend;
    interface CC2420Transmit as Resend;
    interface Receive as SubReceive;
    interface AMPacket;
    interface SplitControl as SubControl;
    interface CC2420DutyCycle;
    interface PacketAcknowledgements;
    interface State as SendState;
    interface State as RadioState;
    interface State as SplitControlState;
    interface Random;
    interface Timer<TMilli> as OffTimer;
    interface Timer<TMilli> as SendDoneTimer;
  }
}

implementation {
  
  /** The message currently being sent */
  message_t *currentSendMsg;
  
  /** The length of the current send message */
  uint8_t currentSendLen;
  
  /** TRUE if the radio is duty cycling and not always on */
  bool dutyCycling;
 
  /** Tx DSN to ensure multiple transmitted messages get across only once */ 
  uint8_t txDsn;
  
  /** The last received broadcast DSN. TODO is this the best way? */
  uint8_t lastRxDsn;

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
  task void resend();
  task void startRadio();
  task void stopRadio();
  
  void startOffTimer();
  cc2420_header_t *getHeader(message_t *msg);
  cc2420_metadata_t *getMetadata(message_t* msg);
  uint16_t getActualDutyCycle(uint16_t dutyCycle);
  void signalDone(error_t error);
  
  /***************** Init Commands ***************/
  command error_t Init.init() {
    txDsn = call Random.rand16();
    dutyCycling = FALSE;
    return SUCCESS;
  }
  
  /***************** LowPowerListening Commands ***************/
  /**
   * Set this this node's radio sleep interval, in milliseconds.
   * Once every interval, the node will sleep and perform an Rx check 
   * on the radio.  Setting the sleep interval to 0 will keep the radio
   * always on.
   *
   * This is the equivalent of setting the local duty cycle rate.
   *
   * @param sleepIntervalMs the length of this node's Rx check interval, in [ms]
   */
  command void LowPowerListening.setLocalSleepInterval(
      uint16_t sleepIntervalMs) {
    call CC2420DutyCycle.setSleepInterval(sleepIntervalMs);
  }
  
  /**
   * @return the local node's sleep interval, in [ms]
   */
  command uint16_t LowPowerListening.getLocalSleepInterval() {
    return call CC2420DutyCycle.getSleepInterval();
  }
  
  /**
   * Set this node's radio duty cycle rate, in units of [percentage*100].
   * For example, to get a 0.05% duty cycle,
   * <code>
   *   call LowPowerListening.setDutyCycle(5);  // or equivalently...
   *   call LowPowerListening.setDutyCycle(00005);  // for better readability?
   * </code>
   *
   * For a 100% duty cycle (always on),
   * <code>
   *   call LowPowerListening.setDutyCycle(10000);
   * </code>
   *
   * This is the equivalent of setting the local sleep interval explicitly.
   * 
   * @param dutyCycle The duty cycle percentage, in units of [percentage*100]
   */
  command void LowPowerListening.setLocalDutyCycle(uint16_t dutyCycle) {
    call CC2420DutyCycle.setSleepInterval(
        call LowPowerListening.dutyCycleToSleepInterval(dutyCycle));
  }
  
  /**
   * @return this node's radio duty cycle rate, in units of [percentage*100]
   */
  command uint16_t LowPowerListening.getLocalDutyCycle() {
    return call LowPowerListening.sleepIntervalToDutyCycle(
        call CC2420DutyCycle.getSleepInterval());
  }
  
  
  /**
   * Configure this outgoing message so it can be transmitted to a neighbor mote
   * with the specified Rx sleep interval.
   * @param msg Pointer to the message that will be sent
   * @param sleepInterval The receiving node's sleep interval, in [ms]
   */
  command void LowPowerListening.setRxSleepInterval(message_t *msg, 
      uint16_t sleepIntervalMs) {
    getMetadata(msg)->rxInterval = sleepIntervalMs;
  }
  
  /**
   * @return the destination node's sleep interval configured in this message
   */
  command uint16_t LowPowerListening.getRxSleepInterval(message_t *msg) {
    return getMetadata(msg)->rxInterval;
  }
  
  /**
   * Configure this outgoing message so it can be transmitted to a neighbor mote
   * with the specified Rx duty cycle rate.
   * Duty cycle is in units of [percentage*100], i.e. 0.25% duty cycle = 25.
   * 
   * @param msg Pointer to the message that will be sent
   * @param dutyCycle The duty cycle of the receiving mote, in units of 
   *     [percentage*100]
   */
  command void LowPowerListening.setRxDutyCycle(message_t *msg, 
      uint16_t dutyCycle) {
    getMetadata(msg)->rxInterval =
        call LowPowerListening.dutyCycleToSleepInterval(dutyCycle);
  }
  
    
  /**
   * @return the destination node's duty cycle configured in this message
   *     in units of [percentage*100]
   */
  command uint16_t LowPowerListening.getRxDutyCycle(message_t *msg) {
    return call LowPowerListening.sleepIntervalToDutyCycle(
        getMetadata(msg)->rxInterval);
  }
  
  /**
   * Convert a duty cycle, in units of [percentage*100], to
   * the sleep interval of the mote in milliseconds
   * @param dutyCycle The duty cycle in units of [percentage*100]
   * @return The equivalent sleep interval, in units of [ms]
   */
  command uint16_t LowPowerListening.dutyCycleToSleepInterval(
      uint16_t dutyCycle) {
    dutyCycle = getActualDutyCycle(dutyCycle);
    
    if(dutyCycle == 10000) {
      return 0;
    }
    
    return (DUTY_ON_TIME * (10000 - dutyCycle)) / dutyCycle;
  }
  
  /**
   * Convert a sleep interval, in units of [ms], to a duty cycle
   * in units of [percentage*100]
   * @param sleepInterval The sleep interval in units of [ms]
   * @return The duty cycle in units of [percentage*100]
   */
  command uint16_t LowPowerListening.sleepIntervalToDutyCycle(
      uint16_t sleepInterval) {
    if(sleepInterval == 0) {
      return 10000;
    }
    
    return getActualDutyCycle((DUTY_ON_TIME * 10000) 
        / (sleepInterval + DUTY_ON_TIME));
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
    if(call SplitControlState.getState() == S_OFF) {
      // Everything is off right now, start SplitControl and try again
      return EOFF;
    }
    
    if(call SendState.requestState(S_SENDING) == SUCCESS) {
      currentSendMsg = msg;
      currentSendLen = len;
      (getHeader(msg))->dsn = ++txDsn;
      
      // In case our off timer is running...
      call OffTimer.stop();
      
      if(call RadioState.getState() == S_ON) {
        if(call LowPowerListening.getRxSleepInterval(currentSendMsg) 
            > ONE_MESSAGE) {
          // Send it repetitively within our transmit window
          call PacketAcknowledgements.requestAck(currentSendMsg);
          call SendDoneTimer.startOneShot(
              call LowPowerListening.getRxSleepInterval(currentSendMsg) * 2);
        }
        
        post send();
    
      } else {
        post startRadio();
      }
      
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


  /***************** DutyCycle Events ***************/
  /**
   * A transmitter was detected.  You must now take action to
   * turn the radio off when the transaction is complete.
   */
  event void CC2420DutyCycle.detected() {
    // At this point, the duty cycling has been disabled temporary
    // and it will be this component's job to turn the radio back off
   
    startOffTimer();
  }
  
  
  /***************** SubControl Events ***************/
  event void SubControl.startDone(error_t error) {
    if(!error) {
      call RadioState.forceState(S_ON);
      
      if(call SendState.getState() == S_SENDING) {
        if(call LowPowerListening.getRxSleepInterval(currentSendMsg) 
            > ONE_MESSAGE) {
          // Send it repetitively within our transmit window
          call PacketAcknowledgements.requestAck(currentSendMsg);
          call SendDoneTimer.startOneShot(
              call LowPowerListening.getRxSleepInterval(currentSendMsg) * 2);
        }
        
        post send();
      }
    }
  }
    
  event void SubControl.stopDone(error_t error) {
    if(!error) {
      call RadioState.forceState(S_OFF);

      if(call SendState.getState() == S_SENDING) {
        // We're in the middle of sending a message; start the radio back up
        post startRadio();
      }
    }
  }
  
  /***************** SubSend Events ***************/
  event void SubSend.sendDone(message_t* msg, error_t error) {
    if(call SendState.getState() == S_SENDING  
        && call SendDoneTimer.isRunning()) {
      if(call PacketAcknowledgements.wasAcked(msg)) {
        signalDone(error);
        
      } else {
        post resend();
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
      startOffTimer();
      return signal Receive.receive(msg, payload, len);
    }
  }
  
  /***************** Timer Events ****************/
  event void OffTimer.fired() {
    /*
     * Only stop the radio if the radio is supposed to be off permanently
     * or if the duty cycle is on and our sleep interval is not 0
     */
    if(call SplitControlState.getState() == S_OFF
        || (call CC2420DutyCycle.getSleepInterval() > 0
            && call SplitControlState.getState() == S_ON)) { 
      post stopRadio();
    }
  }
  
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
  
  /***************** Resend Events ****************/
  /**
   * Signal that a message has been sent
   *
   * @param p_msg message to send.
   * @param error notifaction of how the operation went.
   */
  async event void Resend.sendDone( message_t* p_msg, error_t error ) {
    // This is actually caught by SubSend.sendDone
  }
  
  
  /***************** Tasks ***************/
  task void send() {
    if(call SubSend.send(currentSendMsg, currentSendLen) != SUCCESS) {
      post send();
    }
  }
  
  task void resend() {
    // Resend the last message without CCA checks.
    if(call Resend.resend() != SUCCESS) {
      post resend();
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
  void startOffTimer() {
    call OffTimer.startOneShot(DELAY_AFTER_RECEIVE);
  }
  
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
  
  cc2420_header_t *getHeader(message_t *msg) {
    return (cc2420_header_t *)(msg->data - sizeof( cc2420_header_t ));
  }
  
  cc2420_metadata_t *getMetadata(message_t* msg) {
    return (cc2420_metadata_t*)msg->metadata;
  }
  
  void signalDone(error_t error) {
    call SendState.toIdle();
    startOffTimer();
    signal Send.sendDone(currentSendMsg, error);
    currentSendMsg = NULL;
  }
}

