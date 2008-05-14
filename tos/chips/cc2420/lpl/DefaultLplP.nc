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
 * Low Power Listening for the CC2420.  This component is responsible for
 * delivery of an LPL packet, and for turning off the radio when the radio
 * has run out of tasks.
 *
 * The PowerCycle component is responsible for duty cycling the radio
 * and performing receive detections.
 *
 * @author David Moss
 */

#include "DefaultLpl.h"
#include "AM.h"

module DefaultLplP {
  provides {
    interface Init;
    interface LowPowerListening;
    interface Send;
    interface Receive;
  }
  
  uses {
    interface Send as SubSend;
    interface CC2420Transmit as Resend;
    interface RadioBackoff;
    interface Receive as SubReceive;
    interface AMPacket;
    interface SplitControl as SubControl;
    interface PowerCycle;
    interface CC2420PacketBody;
    interface PacketAcknowledgements;
    interface State as SendState;
    interface State as RadioPowerState;
    interface State as SplitControlState;
    interface Timer<TMilli> as OffTimer;
    interface Timer<TMilli> as SendDoneTimer;
    interface Random;
    interface Leds;
  }
}

implementation {
  
  /** The message currently being sent */
  norace message_t *currentSendMsg;
  
  /** The length of the current send message */
  uint8_t currentSendLen;
  
  /** TRUE if the radio is duty cycling and not always on */
  bool dutyCycling;

  /**
   * Radio Power State
   */
  enum {
    S_OFF, // off by default
    S_TURNING_ON,
    S_ON,
    S_TURNING_OFF,
  };
  
  /**
   * Send States
   */
  enum {
    S_IDLE,
    S_SENDING,
  };
  
  enum {
    ONE_MESSAGE = 0,
  };
  
  /***************** Prototypes ***************/
  task void send();
  task void resend();
  task void startRadio();
  task void stopRadio();
  
  void initializeSend();
  void startOffTimer();
  uint16_t getActualDutyCycle(uint16_t dutyCycle);
  
  /***************** Init Commands ***************/
  command error_t Init.init() {
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
    call PowerCycle.setSleepInterval(sleepIntervalMs);
  }
  
  /**
   * @return the local node's sleep interval, in [ms]
   */
  command uint16_t LowPowerListening.getLocalSleepInterval() {
    return call PowerCycle.getSleepInterval();
  }
  
  /**
   * Set this node's radio duty cycle rate, in units of [percentage*100].
   * For example, to get a 0.05% duty cycle,
   * <code>
   *   call LowPowerListening.setDutyCycle(5);
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
    call PowerCycle.setSleepInterval(
        call LowPowerListening.dutyCycleToSleepInterval(dutyCycle));
  }
  
  /**
   * @return this node's radio duty cycle rate, in units of [percentage*100]
   */
  command uint16_t LowPowerListening.getLocalDutyCycle() {
    return call LowPowerListening.sleepIntervalToDutyCycle(
        call PowerCycle.getSleepInterval());
  }
  
  
  /**
   * Configure this outgoing message so it can be transmitted to a neighbor mote
   * with the specified Rx sleep interval.
   * @param msg Pointer to the message that will be sent
   * @param sleepInterval The receiving node's sleep interval, in [ms]
   */
  command void LowPowerListening.setRxSleepInterval(message_t *msg, 
      uint16_t sleepIntervalMs) {
    (call CC2420PacketBody.getMetadata(msg))->rxInterval = sleepIntervalMs;
  }
  
  /**
   * @return the destination node's sleep interval configured in this message
   */
  command uint16_t LowPowerListening.getRxSleepInterval(message_t *msg) {
    return (call CC2420PacketBody.getMetadata(msg))->rxInterval;
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
    (call CC2420PacketBody.getMetadata(msg))->rxInterval =
        call LowPowerListening.dutyCycleToSleepInterval(dutyCycle);
  }
  
    
  /**
   * @return the destination node's duty cycle configured in this message
   *     in units of [percentage*100]
   */
  command uint16_t LowPowerListening.getRxDutyCycle(message_t *msg) {
    return call LowPowerListening.sleepIntervalToDutyCycle(
        (call CC2420PacketBody.getMetadata(msg))->rxInterval);
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
    
    if(call SendState.requestState(S_LPL_SENDING) == SUCCESS) {
      currentSendMsg = msg;
      currentSendLen = len;
      
      // In case our off timer is running...
      call OffTimer.stop();
      call SendDoneTimer.stop();
      
      if(call RadioPowerState.getState() == S_ON) {
        initializeSend();
        return SUCCESS;
        
      } else {
        post startRadio();
      }
      
      return SUCCESS;
    }
    
    return EBUSY;
  }

  command error_t Send.cancel(message_t *msg) {
    if(currentSendMsg == msg) {
      call SendState.toIdle();
      call SendDoneTimer.stop();
      startOffTimer();
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
  
  
  /***************** RadioBackoff Events ****************/
  async event void RadioBackoff.requestInitialBackoff(message_t *msg) {
    if((call CC2420PacketBody.getMetadata(msg))->rxInterval 
        > ONE_MESSAGE) {
      call RadioBackoff.setInitialBackoff( call Random.rand16() 
          % (0x4 * CC2420_BACKOFF_PERIOD) + CC2420_MIN_BACKOFF);
    }
  }
  
  async event void RadioBackoff.requestCongestionBackoff(message_t *msg) {
    if((call CC2420PacketBody.getMetadata(msg))->rxInterval 
        > ONE_MESSAGE) {
      call RadioBackoff.setCongestionBackoff( call Random.rand16() 
          % (0x3 * CC2420_BACKOFF_PERIOD) + CC2420_MIN_BACKOFF);
    }
  }
  
  async event void RadioBackoff.requestCca(message_t *msg) {
  }
  

  /***************** DutyCycle Events ***************/
  /**
   * A transmitter was detected.  You must now take action to
   * turn the radio off when the transaction is complete.
   */
  event void PowerCycle.detected() {
    // At this point, the duty cycling has been disabled temporary
    // and it will be this component's job to turn the radio back off
    // Wait long enough to see if we actually receive a packet, which is
    // just a little longer in case there is more than one lpl transmitter on
    // the channel.
    
    startOffTimer();
  }
  
  
  /***************** SubControl Events ***************/
  event void SubControl.startDone(error_t error) {
    if(!error) {
      call RadioPowerState.forceState(S_ON);
      
      if(call SendState.getState() == S_LPL_FIRST_MESSAGE
          || call SendState.getState() == S_LPL_SENDING) {
        initializeSend();
      }
    }
  }
    
  event void SubControl.stopDone(error_t error) {
    if(!error) {

      if(call SendState.getState() == S_LPL_FIRST_MESSAGE
          || call SendState.getState() == S_LPL_SENDING) {
        // We're in the middle of sending a message; start the radio back up
        post startRadio();
        
      } else {        
        call OffTimer.stop();
        call SendDoneTimer.stop();
      }
    }
  }
  
  /***************** SubSend Events ***************/
  event void SubSend.sendDone(message_t* msg, error_t error) {
   
    switch(call SendState.getState()) {
    case S_LPL_SENDING:
      if(call SendDoneTimer.isRunning()) {
        if(!call PacketAcknowledgements.wasAcked(msg)) {
          post resend();
          return;
        }
      }
      break;
      
    case S_LPL_CLEAN_UP:
      /**
       * We include this state so upper layers can't send a different message
       * before the last message gets done sending
       */
      break;
      
    default:
      break;
    }  
    
    call SendState.toIdle();
    call SendDoneTimer.stop();
    startOffTimer();
    signal Send.sendDone(msg, error);
  }
  
  /***************** SubReceive Events ***************/
  /**
   * If the received message is new, we signal the receive event and
   * start the off timer.  If the last message we received had the same
   * DSN as this message, then the chances are pretty good
   * that this message should be ignored, especially if the destination address
   * as the broadcast address
   */
  event message_t *SubReceive.receive(message_t* msg, void* payload, 
      uint8_t len) {
    startOffTimer();
    return signal Receive.receive(msg, payload, len);
  }
  
  /***************** Timer Events ****************/
  event void OffTimer.fired() {    
    /*
     * Only stop the radio if the radio is supposed to be off permanently
     * or if the duty cycle is on and our sleep interval is not 0
     */
    if(call SplitControlState.getState() == S_OFF
        || (call PowerCycle.getSleepInterval() > 0
            && call SplitControlState.getState() != S_OFF
                && call SendState.getState() == S_LPL_NOT_SENDING)) { 
      post stopRadio();
    }
  }
  
  /**
   * When this timer is running, that means we're sending repeating messages
   * to a node that is receive check duty cycling.
   */
  event void SendDoneTimer.fired() {
    if(call SendState.getState() == S_LPL_SENDING) {
      // The next time SubSend.sendDone is signaled, send is complete.
      call SendState.forceState(S_LPL_CLEAN_UP);
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
    if(call Resend.resend(TRUE) != SUCCESS) {
      post resend();
    }
  }
  
  task void startRadio() {
    if(call SubControl.start() != SUCCESS) {
      post startRadio();
    }
  }
  
  task void stopRadio() {
    if(call SendState.getState() == S_LPL_NOT_SENDING) {
      if(call SubControl.stop() != SUCCESS) {
        post stopRadio();
      }
    }
  }
  
  /***************** Functions ***************/
  void initializeSend() {
    if(call LowPowerListening.getRxSleepInterval(currentSendMsg) 
      > ONE_MESSAGE) {
    
      if(call AMPacket.destination(currentSendMsg) == AM_BROADCAST_ADDR) {
        call PacketAcknowledgements.noAck(currentSendMsg);
      } else {
        // Send it repetitively within our transmit window
        call PacketAcknowledgements.requestAck(currentSendMsg);
      }

      call SendDoneTimer.startOneShot(
          call LowPowerListening.getRxSleepInterval(currentSendMsg) + 20);
    }
        
    post send();
  }
  
  
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
}

