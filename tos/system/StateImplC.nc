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

configuration StateImplC {
  provides {
    interface State[uint8_t id];
  }
}

implementation {
  components MainC, 
      StateImplP;

  MainC.SoftwareInit -> StateImplP;
  State = StateImplP;
  
}

