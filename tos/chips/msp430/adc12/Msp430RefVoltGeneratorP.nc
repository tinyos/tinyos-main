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
 * $Revision: 1.4 $
 * $Date: 2006-12-12 18:23:07 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
#include <Timer.h>
module Msp430RefVoltGeneratorP
{
  provides interface SplitControl as RefVolt_1_5V;
  provides interface SplitControl as RefVolt_2_5V;
  uses {
    interface HplAdc12;
    interface Timer<TMilli> as SwitchOnTimer;
    interface Timer<TMilli> as SwitchOffTimer;
  }
} implementation {
  
  enum
  {
    GENERATOR_OFF,
    REFERENCE_1_5V_PENDING, 
    REFERENCE_2_5V_PENDING,
    REFERENCE_1_5V_STABLE,
    REFERENCE_2_5V_STABLE,
  };

  uint8_t state;

  error_t switchOn(uint8_t level)
  {
    atomic {
      if (call HplAdc12.isBusy())
        return FAIL;
      else {
        adc12ctl0_t ctl0 = call HplAdc12.getCtl0();
        ctl0.enc = 0;
        call HplAdc12.setCtl0(ctl0);
        ctl0.refon = 1;
        if (level == REFERENCE_1_5V_PENDING)
          ctl0.r2_5v = 0;
        else
          ctl0.r2_5v = 1;
        call HplAdc12.setCtl0(ctl0);
        return SUCCESS;
      }
    }
  }
    
  error_t switchOff()
  {
    atomic {
      if (call HplAdc12.isBusy())
        return FAIL;
      else {
        adc12ctl0_t ctl0 = call HplAdc12.getCtl0();
        ctl0.enc = 0;
        call HplAdc12.setCtl0(ctl0);
        ctl0.refon = 0;
        call HplAdc12.setCtl0(ctl0);
        return SUCCESS;
      }
    }
  }  
    
  command error_t RefVolt_1_5V.start()
  {
    switch (state)
    {
      case REFERENCE_1_5V_STABLE:
        call SwitchOffTimer.stop();
        signal RefVolt_1_5V.startDone(SUCCESS);
        return SUCCESS;
      case GENERATOR_OFF:
        if (switchOn(REFERENCE_1_5V_PENDING) == SUCCESS){
          call SwitchOnTimer.startOneShot(STABILIZE_INTERVAL);
          state = REFERENCE_1_5V_PENDING;
          return SUCCESS;
        } else
          return FAIL;
      case REFERENCE_2_5V_STABLE:
        if (switchOn(REFERENCE_1_5V_PENDING) == SUCCESS){
          call SwitchOffTimer.stop();
          state = REFERENCE_1_5V_STABLE;
          signal RefVolt_1_5V.startDone(SUCCESS);
          return SUCCESS;
        } else
          return FAIL;         
      case REFERENCE_1_5V_PENDING:
        // fall through
      case REFERENCE_2_5V_PENDING:
        // fall through
      default:
        // illegal state
        return FAIL;
    }
  }

  command error_t RefVolt_1_5V.stop()
  {
    switch (state)
    {
      case REFERENCE_1_5V_PENDING:
        // fall through
      case REFERENCE_2_5V_PENDING:
        if (switchOff() == SUCCESS){
          call SwitchOnTimer.stop();
          state = GENERATOR_OFF;
          if (state == REFERENCE_1_5V_PENDING)
            signal RefVolt_1_5V.stopDone(SUCCESS);
          else
            signal RefVolt_2_5V.stopDone(SUCCESS);
          return SUCCESS;
        } else 
          return FAIL;
      case REFERENCE_1_5V_STABLE:
        // fall through
      case REFERENCE_2_5V_STABLE:
        call SwitchOffTimer.startOneShot(SWITCHOFF_INTERVAL);
        return SUCCESS;
      case GENERATOR_OFF:
        // fall through
      default:
        // illegal state
        return FAIL;
    }
  }

  command error_t RefVolt_2_5V.start()
  {
    switch (state)
    {
      case REFERENCE_2_5V_STABLE:
        call SwitchOffTimer.stop();
        signal RefVolt_2_5V.startDone(SUCCESS);
        return SUCCESS;
      case GENERATOR_OFF:
        if (switchOn(REFERENCE_2_5V_PENDING) == SUCCESS){
          call SwitchOnTimer.startOneShot(STABILIZE_INTERVAL);
          state = REFERENCE_2_5V_PENDING;
          return SUCCESS;
        } else
          return FAIL;
      case REFERENCE_1_5V_STABLE:
        if (switchOn(REFERENCE_2_5V_PENDING) == SUCCESS){
          call SwitchOffTimer.stop();
          state = REFERENCE_2_5V_STABLE;
          signal RefVolt_2_5V.startDone(SUCCESS);
          return SUCCESS;
        } else
          return FAIL;         
      case REFERENCE_2_5V_PENDING:
        // fall through
      case REFERENCE_1_5V_PENDING:
        // fall through
      default:
        // illegal state
        return FAIL;
    }
  }
  
  command error_t RefVolt_2_5V.stop()
  {
    switch (state)
    {
      case REFERENCE_2_5V_PENDING:
        // fall through
      case REFERENCE_1_5V_PENDING:
        if (switchOff() == SUCCESS){
          call SwitchOnTimer.stop();
          state = GENERATOR_OFF;
          if (state == REFERENCE_2_5V_PENDING)
            signal RefVolt_2_5V.stopDone(SUCCESS);
          else
            signal RefVolt_1_5V.stopDone(SUCCESS);
          return SUCCESS;
        } else 
          return FAIL;
      case REFERENCE_2_5V_STABLE:
        // fall through
      case REFERENCE_1_5V_STABLE:
        call SwitchOffTimer.startOneShot(SWITCHOFF_INTERVAL);
        return SUCCESS;
      case GENERATOR_OFF:
        // fall through
      default:
        // illegal state
        return FAIL;
    }
  }

  event void SwitchOnTimer.fired() 
  {
    switch (state)
    {
      case REFERENCE_1_5V_PENDING:
        state = REFERENCE_1_5V_STABLE;
        signal RefVolt_1_5V.startDone(SUCCESS);
        break;
      case REFERENCE_2_5V_PENDING:
         state = REFERENCE_2_5V_STABLE;
        signal RefVolt_2_5V.startDone(SUCCESS);
        break;
      case REFERENCE_1_5V_STABLE:
        // fall through
      case GENERATOR_OFF:
        // fall through
      case REFERENCE_2_5V_STABLE:
        // fall through
      default:
        // illegal state
        return;
    }
  }
    
  event void SwitchOffTimer.fired() 
  {
    switch (state)
    {
      case REFERENCE_1_5V_STABLE:
        if (switchOff() == SUCCESS){
          state = GENERATOR_OFF;
          signal RefVolt_1_5V.stopDone(SUCCESS);
        } else
          call SwitchOffTimer.startOneShot(SWITCHOFF_INTERVAL);
        break;
      case REFERENCE_2_5V_STABLE:
        if (switchOff() == SUCCESS){
          state = GENERATOR_OFF;
          signal RefVolt_2_5V.stopDone(SUCCESS);
        } else
          call SwitchOffTimer.startOneShot(SWITCHOFF_INTERVAL);
        break;
      case GENERATOR_OFF:
        // fall through
      case REFERENCE_1_5V_PENDING:
        // fall through
      case REFERENCE_2_5V_PENDING:
        // fall through
      default:
        // illegal state
        return;
    }
  }

  async event void HplAdc12.conversionDone(uint16_t iv){}

  default event void RefVolt_1_5V.startDone(error_t error){}
  default event void RefVolt_2_5V.startDone(error_t error){}
  default event void RefVolt_1_5V.stopDone(error_t error){}
  default event void RefVolt_2_5V.stopDone(error_t error){}
}

