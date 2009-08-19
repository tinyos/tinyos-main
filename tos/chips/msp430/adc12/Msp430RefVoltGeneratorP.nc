/*
 * Copyright (c) 2004, Technische Universität Berlin
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
 * - Neither the name of the Technische Universität Berlin nor the names 
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
 * - Revision -------------------------------------------------------------
 * $Revision: 1.5 $
 * $Date: 2009-08-19 11:06:42 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

module Msp430RefVoltGeneratorP {
  provides {
    interface SplitControl as RefVolt_1_5V;
    interface SplitControl as RefVolt_2_5V;
  }
  
  uses {
    interface HplAdc12;
    interface Timer<TMilli> as SwitchOnTimer;
    interface Timer<TMilli> as SwitchOffTimer;
  }
  
} 

implementation {
  
  typedef enum  {
    // DO NOT CHANGE ANY OF THE CONSTANTS BELOW!
    GENERATOR_OFF = 0,
      
    REFERENCE_1_5V_STABLE = 1,
    REFERENCE_2_5V_STABLE = 2,

    REFERENCE_1_5V_ON_PENDING = 3,
    REFERENCE_2_5V_ON_PENDING = 4,

    REFERENCE_1_5V_OFF_PENDING = 5,
    REFERENCE_2_5V_OFF_PENDING = 6,

  } state_t;

  state_t m_state;

  /***************** Prototypes ****************/
  error_t switchOn(uint8_t level);
  error_t switchOff();
  void signalStartDone(state_t state, error_t result);
  void signalStopDone(state_t state, error_t result);
  error_t start(state_t targetState);
  error_t stop(state_t nextState);
  
  /***************** SplitControl Commands ****************/
  command error_t RefVolt_1_5V.start() {
    return start(REFERENCE_1_5V_STABLE);
  }

  command error_t RefVolt_2_5V.start() {
    return start(REFERENCE_2_5V_STABLE);
  }

  command error_t RefVolt_1_5V.stop() {
    return stop(REFERENCE_1_5V_OFF_PENDING);
  }

  command error_t RefVolt_2_5V.stop() {
    return stop(REFERENCE_2_5V_OFF_PENDING);
  }

  error_t start(state_t targetState){
    error_t result;

    if (m_state == REFERENCE_1_5V_STABLE || m_state == REFERENCE_2_5V_STABLE) {
      if (targetState == m_state) {
        result = EALREADY;
      } else if ((result = switchOn(targetState)) == SUCCESS) {
        m_state = targetState;
        signalStartDone(targetState, SUCCESS);
      }
    } else if (m_state == GENERATOR_OFF) {
      if ((result = switchOn(targetState)) == SUCCESS) {
        call SwitchOnTimer.startOneShot(STABILIZE_INTERVAL);
        m_state = targetState + 2; // +2 turns "XXX_STABLE" state into a "XXX_ON_PENDING" state 
      }
    } else if (m_state == REFERENCE_1_5V_OFF_PENDING || m_state == REFERENCE_2_5V_OFF_PENDING) {
      if ((result = switchOn(targetState)) == SUCCESS) {
        // there is a pending stop() call
        state_t oldState = m_state;
        call SwitchOffTimer.stop();
        m_state = targetState;
        signalStopDone(oldState, FAIL);
        signalStartDone(targetState, SUCCESS);
      }
    } else if (m_state == targetState + 2) // starting already?
      result = SUCCESS;
    else
      result = EBUSY;

    return result;
  }

  error_t stop(state_t nextState){
    error_t result;

    if (m_state == GENERATOR_OFF)
      result = EALREADY;
    else if (m_state == REFERENCE_1_5V_STABLE || m_state == REFERENCE_2_5V_STABLE) {
      if ((result = switchOff()) == SUCCESS) {
        m_state = nextState; // m_state becomes a "XXX_OFF_PENDING" state 
        call SwitchOffTimer.startOneShot(SWITCHOFF_INTERVAL);
      }
    } else if (m_state == REFERENCE_1_5V_ON_PENDING || m_state == REFERENCE_2_5V_ON_PENDING) {
      if ((result = switchOff()) == SUCCESS) {
        // there is a pending start() call
        state_t oldState = m_state;
        call SwitchOnTimer.stop();
        m_state = GENERATOR_OFF;
        signalStartDone(oldState, FAIL);
        signalStopDone(nextState, SUCCESS);
      }
    } else if (m_state == nextState) // stopping already?
      result = SUCCESS;
    else
      result = EBUSY;

    return result;
  }

  void signalStartDone(state_t state, error_t result){
    if (state == REFERENCE_1_5V_STABLE || state == REFERENCE_1_5V_ON_PENDING)
      signal RefVolt_1_5V.startDone(result);
    else
      signal RefVolt_2_5V.startDone(result);
  }

  void signalStopDone(state_t state, error_t result){
    if (state == REFERENCE_1_5V_STABLE || state == REFERENCE_1_5V_OFF_PENDING)
      signal RefVolt_1_5V.stopDone(result);
    else
      signal RefVolt_2_5V.stopDone(result);
  }

  /***************** Timer Events ******************/
  event void SwitchOnTimer.fired() {
    switch (m_state) {
      case REFERENCE_1_5V_ON_PENDING:
        m_state = REFERENCE_1_5V_STABLE;
        signal RefVolt_1_5V.startDone(SUCCESS);
        break;
        
      case REFERENCE_2_5V_ON_PENDING:
         m_state = REFERENCE_2_5V_STABLE;
        signal RefVolt_2_5V.startDone(SUCCESS);
        break;
        
      default:
        return;
    }
  }
    
  event void SwitchOffTimer.fired() {
    switch (m_state) {
      case REFERENCE_1_5V_STABLE:
        if (switchOff() == SUCCESS){
          m_state = GENERATOR_OFF;
          signal RefVolt_1_5V.stopDone(SUCCESS);
          
        } else {
          call SwitchOffTimer.startOneShot(SWITCHOFF_INTERVAL);
        }
        break;
        
      case REFERENCE_2_5V_STABLE:
        if (switchOff() == SUCCESS) {
          m_state = GENERATOR_OFF;
          signal RefVolt_2_5V.stopDone(SUCCESS);
          
        } else {
          call SwitchOffTimer.startOneShot(SWITCHOFF_INTERVAL);
        }
        break;
        
      default:
        break;
    }
  }
  
  /**************** HplAdc12 Events ***************/
  async event void HplAdc12.conversionDone(uint16_t iv) {
  }

  /**************** Functions ****************/
  error_t switchOn(uint8_t level) {
    atomic {
      if (call HplAdc12.isBusy()) {
        return EBUSY;
        
      } else {
        adc12ctl0_t ctl0 = call HplAdc12.getCtl0();
        ctl0.enc = 0;
        call HplAdc12.setCtl0(ctl0);
        ctl0.refon = 1;
        
        // This is why we don't change the enum at the top
        ctl0.r2_5v = level - 1;  
        call HplAdc12.setCtl0(ctl0);
        return SUCCESS;
      }
    }
  }
  
  error_t switchOff() {
    atomic {
      if (call HplAdc12.isBusy()) {
        return EBUSY;
        
      } else {
        adc12ctl0_t ctl0 = call HplAdc12.getCtl0();
        ctl0.enc = 0;
        call HplAdc12.setCtl0(ctl0);
        ctl0.refon = 0;
        call HplAdc12.setCtl0(ctl0);
        return SUCCESS;
      }
    }
  }  
  
  /***************** Defaults ****************/

  default event void RefVolt_1_5V.startDone(error_t error){}
  default event void RefVolt_2_5V.startDone(error_t error){}
  default event void RefVolt_1_5V.stopDone(error_t error){}
  default event void RefVolt_2_5V.stopDone(error_t error){}
}

