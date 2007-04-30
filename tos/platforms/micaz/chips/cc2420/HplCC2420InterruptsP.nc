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
 * MicaZ implementation of the CC2420 interrupts. FIFOP is a real
 * interrupt, while CCA and FIFO are emulated through timer polling.
 * <pre>
 *  $Id: HplCC2420InterruptsP.nc,v 1.5 2007-04-30 17:31:08 rincon Exp $
 * <pre>
 *
 * @author Philip Levis
 * @author Matt Miller
 * @author David Moss
 * @version @version $Revision: 1.5 $ $Date: 2007-04-30 17:31:08 $
 */

module HplCC2420InterruptsP {
  provides {
    interface GpioInterrupt as CCA;
  }
  
  uses {
    interface GeneralIO as CC_CCA;
  }
}
implementation {

  norace uint8_t ccaWaitForState;
  
  norace uint8_t ccaLastState;
  
  bool ccaCheckDisabled = FALSE;

  // ************* CCA Interrupt handlers and dispatch *************
  
  /**
   * enable an edge interrupt on the CCA pin
   * NOT an interrupt in MICAz. Implement as a task polled pin monitor
   */

  task void CCATask() {
    uint8_t CCAState;
    atomic {
      if (ccaCheckDisabled) {
        return;
      }
    }
    
    //check CCA state
    CCAState = call CC_CCA.get(); //get current state here if waiting for edge
    if ((ccaLastState != ccaWaitForState) && (CCAState == ccaWaitForState)) {
      signal CCA.fired();
    }
    
    //if CCA Pin is correct and edge found
    //repost task and try again
    ccaLastState = CCAState;
    post CCATask();
  }
  
  async command error_t CCA.enableRisingEdge() { 
    atomic ccaWaitForState = TRUE; //save the state we are waiting for
    atomic ccaCheckDisabled = FALSE;
    ccaLastState = call CC_CCA.get(); //get current state
    post CCATask();
    return SUCCESS;
  }

  async command error_t CCA.enableFallingEdge() { 
    atomic ccaWaitForState = FALSE; //save the state we are waiting for
    atomic ccaCheckDisabled = FALSE;
    ccaLastState = call CC_CCA.get(); //get current state
    post CCATask();
    return SUCCESS;
  }
  
  async command error_t CCA.disable() {
    atomic ccaCheckDisabled = TRUE;
    return SUCCESS;
  }


  /***************** Defaults ****************/
  default async event void CCA.fired() {
  }

}

