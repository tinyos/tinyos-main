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
 * @author David Moss
 */
 
module CC2420DutyCycleP {
  provides {
    interface CC2420DutyCycle;
    interface Init;
    interface SplitControl;
  }

  uses {
    interface Timer<TMilli> as OnTimer;
    interface SplitControl as SubControl;
    interface State as RadioPowerState;
    interface State as DutyCycleState;
    interface State as SplitControlState;
    interface State as CheckState;
    interface State as SendState;
    interface Leds;
    interface CC2420Cca;
    interface Random;
  }
}

implementation {
  
  /** The current period of the duty cycle, equivalent of wakeup interval */
  uint16_t sleepInterval;
  
  /** The number of times the CCA has been sampled in this wakeup period */
  uint16_t ccaChecks;
  
  /** TRUE if we get an Rx interrupt that stops our CCA checking loop */
  bool detectionForced;
  
  /**
   * Radio Power, Check State, and Duty Cycling State
   */
  enum {
    S_OFF, // off by default
    S_ON,
  };
  
  
  /***************** Prototypes ****************/
  task void stopRadio();
  task void startRadio();
  task void getCca();
  
  /***************** Init Commands ****************/
  command error_t Init.init() {
    sleepInterval = 0;
   return SUCCESS;
  }
  
  /***************** CC2420DutyCycle Commands ****************/
  /**
   * Set the sleep interval, in binary milliseconds
   * @param sleepIntervalMs the sleep interval in [ms]
   */
  command void CC2420DutyCycle.setSleepInterval(uint16_t sleepIntervalMs) {
    if (!sleepInterval && sleepIntervalMs) {
      // We were always on, now lets duty cycle
      call DutyCycleState.forceState(S_ON);
      call CheckState.toIdle();
      post stopRadio();  // Might want to delay turning off the radio
    }
    
    detectionForced = FALSE;
    sleepInterval = sleepIntervalMs;
    
    if(sleepInterval == 0 && call DutyCycleState.getState() == S_ON) {
      call DutyCycleState.forceState(S_OFF);
      call CheckState.toIdle();
      
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
  command uint16_t CC2420DutyCycle.getSleepInterval() {
    return sleepInterval;
  }
  
  command void CC2420DutyCycle.forceDetected() {
    detectionForced = TRUE;
  }
  
  /***************** SplitControl Commands ****************/
  command error_t SplitControl.start() {
    call SplitControlState.forceState(S_ON);
    
    if(sleepInterval > 0) {
      // Begin duty cycling
      call DutyCycleState.forceState(S_ON);
      call CheckState.toIdle();
      post stopRadio();
      signal SplitControl.startDone(SUCCESS);
      
    } else {
      call DutyCycleState.forceState(S_OFF);
      call CheckState.toIdle();
      
      /*
       * Leave the radio on permanently if sleepInterval == 0 and the radio is 
       * supposed to be enabled
       */
      if(call RadioPowerState.getState() == S_OFF) {
        call SubControl.start();
        // Here, SplitControl.startDone is signaled on SubControl.startDone
        
      } else {
        // Radio is already on
        signal SplitControl.startDone(SUCCESS);
      }
    }

    return SUCCESS;
  }
  
  command error_t SplitControl.stop() {
    call SplitControlState.forceState(S_OFF);
    call DutyCycleState.forceState(S_OFF);
    call CheckState.toIdle();
    return call SubControl.stop();
    
    /*
     * SubControl.stopDone signals SplitControl.stopDone when  
     * DutyCycleState is S_OFF
     */
  }
  
  /***************** Timer Events ****************/
  event void OnTimer.fired() {
    if(call DutyCycleState.getState() == S_ON) {
      if(call RadioPowerState.getState() == S_OFF) {
        call CheckState.forceState(S_ON);
        ccaChecks = 0;
        
        /*
         * The MicaZ, running on an external oscillator I think, and
         * returning the microcontroller out of a sleep state to immediately
         * perform an ADC conversion, sucks.  The first ADC conversion out
         * of a sleep state lasts about a second.  We don't want the radio
         * on that long.  Like the CC1000 RSSI pulse check implementation
         * done in the Rincon CC1000Radio stack, we will perform
         * a single ADC conversion and then flip on the radio to check
         * the channel.
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
    if(call DutyCycleState.getState() == S_ON && error) {
      // My responsibility to try again
      post startRadio();
      return;
    }
    
    call RadioPowerState.forceState(S_ON);
    //call Leds.led2On();
    
    if(call DutyCycleState.getState() == S_ON) {
      if(call CheckState.getState() == S_ON) {
        post getCca();
      }
      
    } else {
      // Must have turned the radio on manually
      signal SplitControl.startDone(SUCCESS);
    }
  }
  
  event void SubControl.stopDone(error_t error) {
    if(error && call DutyCycleState.getState() == S_ON) {
      // My responsibility to try again
      post stopRadio();
      return;
    }
    
    detectionForced = FALSE;
    call RadioPowerState.forceState(S_OFF);
    //call Leds.led2Off();
    
    if(call DutyCycleState.getState() == S_ON) {
      call OnTimer.startOneShot(sleepInterval);

    } else {
      // Must have turned off the radio manually
      signal SplitControl.stopDone(error);
    }
    
  }
  
  
  /***************** Tasks ****************/
  task void stopRadio() {
    if(call DutyCycleState.getState() == S_ON && !detectionForced) {
      if(call SubControl.stop() != SUCCESS) {
        // Already stopped?
        call OnTimer.startOneShot(sleepInterval);
      }
    }
  }
  
  task void startRadio() {
    if(call DutyCycleState.getState() == S_ON) {
      if(call SubControl.start() != SUCCESS) {
        post startRadio();
      }
    }
  }
 
  
  task void getCca() {
    uint8_t detects = 0;
    if(call DutyCycleState.getState() == S_ON) {
      
      ccaChecks++;
      if(ccaChecks == 1) {
        // Microcontroller is ready, turn on the radio and sample a few times
        post startRadio();
        return;
      }

      atomic {
        for( ; ccaChecks < MAX_LPL_CCA_CHECKS && call SendState.isIdle(); ccaChecks++) {
          if(!call CC2420Cca.isChannelClear() || detectionForced) {
            detects++;
            if(detects > MIN_SAMPLES_BEFORE_DETECT) {
              signal CC2420DutyCycle.detected(); 
              return;
            }
            // Leave the radio on for upper layers to perform some transaction
          }
        }
      }
      
      call CheckState.toIdle();
      if(call SendState.isIdle()) {
        post stopRadio();
      }
    }  
  }
  
  /**************** Defaults ****************/
  default event void CC2420DutyCycle.detected() {
  }


  default event void SplitControl.startDone(error_t error) {
  }
  
  default event void SplitControl.stopDone(error_t error) {
  }
}


