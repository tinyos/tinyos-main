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
 * This is a state controller for any and every component's
 * state machine(s).
 *
 * There are several compelling reasons to use the State module/interface
 * in all your components that have any kind of state associated with them:
 *
 *   1) It provides a unified interface to control any state, which makes
 *      it easy for everyone to understand your code
 *   2) You can easily keep track of multiple state machines in one component
 *   3) You could have one state machine control several components
 *
 * There are three ways to change a component's state:
 *  > Request a state change
 *     The state is only changed if the state is currently in S_IDLE.  If
 *     the state changes and access is grated, requestState returns SUCCESS.
 *
 *  > Force a state change
 *     The state changes no matter what
 * 
 *  > toIdle()
 *     The state changes to S_IDLE, no matter what state the component is in.
 *
 * S_IDLE is the default state, and is always equal to 0.  Therefore,
 * setup the enums in your internal component so the IDLE/default state is
 * always 0.
 *
 * @author David Moss - dmm@rincon.com
 */
 
#include "State.h"
 
module StateImplP {
  provides {
  	interface Init;
    interface State[uint8_t id];
  }
}

implementation {

  /** Each component's state - uniqueCount("State") of them */
  uint8_t state[uniqueCount(UQ_STATE)];
  
  enum {
    S_IDLE = 0,
  };

  /***************** Init Commands ****************/
  command error_t Init.init() {
    int i;
    for(i = 0; i < uniqueCount(UQ_STATE); i++) {
      state[i] = S_IDLE;
    }
    return SUCCESS;
  }
  
  
  /***************** State Commands ****************/  
  /**
   * This will allow a state change so long as the current
   * state is S_IDLE.
   * @return SUCCESS if the state is change, FAIL if it isn't
   */
  async command error_t State.requestState[uint8_t id](uint8_t reqState) {
    error_t returnVal = FAIL;
    atomic {
      if(reqState == S_IDLE || state[id] == S_IDLE) {
        state[id] = reqState;
        returnVal = SUCCESS;
      }
    }
    return returnVal;
  }
  
  /**
   * Force the state machine to go into a certain state,
   * regardless of the current state it's in.
   */
  async command void State.forceState[uint8_t id](uint8_t reqState) {
    atomic state[id] = reqState;
  }
    
  /**
   * Set the current state back to S_IDLE
   */
  async command void State.toIdle[uint8_t id]() {
    atomic state[id] = S_IDLE;
  }
  
    
  /**
   * @return TRUE if the state machine is in S_IDLE
   */
  async command bool State.isIdle[uint8_t id]() {
    return call State.isState[id](S_IDLE);
  }
  
  /**
   * @return TRUE if the state machine is in the given state
   */
  async command bool State.isState[uint8_t id](uint8_t myState) {
    bool isState;
    atomic isState = (state[id] == myState);
    return isState;
  }
  
  
  /**
   * Get the current state
   */
  async command uint8_t State.getState[uint8_t id]() {
    uint8_t theState;
    atomic theState = state[id];
    return theState;
  }
  
}

