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
 * Module to duty cycle the radio on and off, performing CCA receive checks.
 * When a carrier is sensed, this will leave the radio on. It is then up
 * to higher layers to turn the radio off again.  Once the radio is turned
 * off, this module will automatically continue duty cycling and looking for
 * a modulated signal.
 *
 * Suggested TODO's:
 *  > TransmitC and ReceiveC provide Energy, Byte, and Packet indicators.
 *    Tap into those to add more detection levels and granularity. Only let
 *    the radio turn off when we're not actively receiving bytes.  Right now
 *    the packet indicator is a little backwards.
 *  > Let one component be in charge of maintaining State information about
 *    the power of the radio, probably lower in the stack.
 *  > Wire SplitControl, Send, and Receive through this component.  Make it
 *    responsible for packet-level detections and being completely responsible
 *    for controlling the power of the radio without the use of upper layers
 *  > Remove unnecessary State components and Timers.
 *
 * @author David Moss
 */

#include "DefaultLpl.h"

module PowerCycleP {
  provides {
    interface PowerCycle;
    interface SplitControl;
  }

  uses {
    interface Timer<TMilli> as OnTimer;
    interface SplitControl as SubControl;
    interface State as RadioPowerState;
    interface State as SplitControlState;
    interface State as SendState;
    interface Leds;
    interface ReceiveIndicator as EnergyIndicator;
    interface ReceiveIndicator as ByteIndicator;
    interface ReceiveIndicator as PacketIndicator;
  }
}

implementation {
  
  /** The current period of the duty cycle, equivalent of wakeup interval */
  uint16_t sleepInterval = LPL_DEF_LOCAL_WAKEUP;
  
  /** The number of times the CCA has been sampled in this wakeup period */
  uint16_t ccaChecks;
  
  /**
   * Radio Power, Check State, and Duty Cycling State
   */
  enum {
    S_OFF, // off by default
    S_TURNING_ON,
    S_ON,
    S_TURNING_OFF,
  };
  
  
  /***************** Prototypes ****************/
  task void stopRadio();
  task void startRadio();
  task void getCca();
  
  bool finishSplitControlRequests();
  bool isDutyCycling();
  
  /***************** PowerCycle Commands ****************/
  /**
   * Set the sleep interval, in binary milliseconds
   * @param sleepIntervalMs the sleep interval in [ms]
   */
  command void PowerCycle.setSleepInterval(uint16_t sleepIntervalMs) {
    if (!sleepInterval && sleepIntervalMs) {
      // We were always on, now lets duty cycle
      post stopRadio();  // Might want to delay turning off the radio
    }
    
    sleepInterval = sleepIntervalMs;
    
    if(sleepInterval == 0 && call SplitControlState.isState(S_ON)) {
      /*
       * Leave the radio on permanently if sleepInterval == 0 and the radio is 
       * supposed to be enabled
       */
      if(call RadioPowerState.getState() == S_OFF) {
        call SubControl.start();
      }
    }
  }
  
  /**
   * @return the sleep interval in [ms]
   */
  command uint16_t PowerCycle.getSleepInterval() {
    return sleepInterval;
  }
  
  
  /***************** SplitControl Commands ****************/
  command error_t SplitControl.start() {
    if(call SplitControlState.isState(S_ON)) {
      return EALREADY;
      
    } else if(call SplitControlState.isState(S_TURNING_ON)) {
      return SUCCESS;
    
    } else if(!call SplitControlState.isState(S_OFF)) {
      return EBUSY;
    }
    
    // Radio was off, now has been told to turn on or duty cycle.
    call SplitControlState.forceState(S_TURNING_ON);
    
    if(sleepInterval > 0) {
      // Begin duty cycling
      post stopRadio();
      return SUCCESS;
      
    } else {
      post startRadio();
      return SUCCESS;
    }
  }
  
  command error_t SplitControl.stop() {
    if(call SplitControlState.isState(S_OFF)) {
      return EALREADY;
      
    } else if(call SplitControlState.isState(S_TURNING_OFF)) {
      return SUCCESS;
    
    } else if(!call SplitControlState.isState(S_ON)) {
      return EBUSY;
    }
    
    call SplitControlState.forceState(S_TURNING_OFF);
    post stopRadio();
    return SUCCESS;
  }
  
  /***************** Timer Events ****************/
  event void OnTimer.fired() {
    if(isDutyCycling()) {
      if(call RadioPowerState.getState() == S_OFF) {
        ccaChecks = 0;
        
         /*
          * Turn on the radio only after the uC is fully awake.  ATmega128's 
          * have this issue when running on an external crystal.
          */
         post getCca();
        
      } else {
        // Someone else turned on the radio, try again in awhile
        call OnTimer.startOneShot(sleepInterval);
      }
    }
  }
  
  /***************** SubControl Events ****************/
  event void SubControl.startDone(error_t error) {
    call RadioPowerState.forceState(S_ON);
    //call Leds.led2On();
    
    if(finishSplitControlRequests()) {
      return;
      
    } else if(isDutyCycling()) {
      post getCca();
    }
  }
  
  event void SubControl.stopDone(error_t error) {
    call RadioPowerState.forceState(S_OFF);
    //call Leds.led2Off();
    
    if(finishSplitControlRequests()) {
      return;
      
    } else if(isDutyCycling()) {
      call OnTimer.startOneShot(sleepInterval);
    }
    
  }
  
  
  /***************** Tasks ****************/
  task void stopRadio() {
    error_t error = call SubControl.stop();
    if(error != SUCCESS) {
      // Already stopped?
      finishSplitControlRequests();
      call OnTimer.startOneShot(sleepInterval);
    }
  }

  task void startRadio() {
    error_t startResult = call SubControl.start();
    // If the radio wasn't started successfully, or already on, try again
    if ((startResult != SUCCESS && startResult != EALREADY)) {
      post startRadio();
    }
  }
  
  task void getCca() {
    uint8_t detects = 0;
    if(isDutyCycling()) {
      
      ccaChecks++;
      if(ccaChecks == 1) {
        // Microcontroller is ready, turn on the radio and sample a few times
        post startRadio();
        return;
      }

      atomic {
        for( ; ccaChecks < MAX_LPL_CCA_CHECKS && call SendState.isIdle(); ccaChecks++) {
          if(call PacketIndicator.isReceiving()) {
            signal PowerCycle.detected();
            return;
          }
          
          if(call EnergyIndicator.isReceiving()) {
            detects++;
            if(detects > MIN_SAMPLES_BEFORE_DETECT) {
              signal PowerCycle.detected(); 
              return;
            }
            // Leave the radio on for upper layers to perform some transaction
          }
        }
      }
      
      if(call SendState.isIdle()) {
        post stopRadio();
      }
    }  
  }
  
  /**
   * @return TRUE if the radio should be actively duty cycling
   */
  bool isDutyCycling() {
    return sleepInterval > 0 && call SplitControlState.isState(S_ON);
  }
  
  
  /**
   * @return TRUE if we successfully handled a SplitControl request
   */
  bool finishSplitControlRequests() {
    if(call SplitControlState.isState(S_TURNING_OFF)) {
      call SplitControlState.forceState(S_OFF);
      signal SplitControl.stopDone(SUCCESS);
      return TRUE;
      
    } else if(call SplitControlState.isState(S_TURNING_ON)) {
      // Starting while we're duty cycling first turns off the radio
      call SplitControlState.forceState(S_ON);
      signal SplitControl.startDone(SUCCESS);
      return TRUE;
    }
    
    return FALSE;
  }
  
  /**************** Defaults ****************/
  default event void PowerCycle.detected() {
  }


  default event void SplitControl.startDone(error_t error) {
  }
  
  default event void SplitControl.stopDone(error_t error) {
  }
}


