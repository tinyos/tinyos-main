/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * - Neither the name of the Arched Rock Corporation nor the names of
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
 * HalTMP175ControlP device specific Hal interfaces for the TI TMP175 Chip.
 *
 * Note that only the data path uses split phase resource arbitration
 * 
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @version $Revision: 1.4 $ $Date: 2006/12/12 18:23:14 $
 */

module HalTMP102ControlP
{
  provides interface HalTMP102Advanced;

  uses interface HplTMP102;
  uses interface Resource as TMP102Resource;
}

implementation {

  enum {
    STATE_SET_MODE,
    STATE_SET_POLARITY,
    STATE_SET_FQ,
    STATE_SET_CR,
    STATE_SET_EM
    STATE_NONE,

    STATE_SET_TLOW,
    STATE_SET_THIGH,
  };

  uint8_t mState = STATE_NONE;
  uint8_t mConfigRegVal = 0;
  error_t mHplError;

  task void complete_Alert() {
    signal HalTMP102Advanced.alertThreshold();
  }

  static error_t setCfg(uint8_t nextState, uint32_t val) {
    error_t error;

    mState = nextState;

    error = call HplTMP102.setConfigReg(val);

    if (error) {
      call TMP102Resource.release();
    }
    else {
      mConfigRegVal = val;
    }

    return error;
  }

  static error_t setThresh(uint8_t nextState, uint32_t val) {
    error_t error;

    mState = nextState;

    if(mState == STATE_SET_TLOW)
      error = call HplTMP102.setTLowReg(val << 4);
    else
      error = call HplTMP102.setTHighReg(val << 4);

    if (error) {
      call TMP102Resource.release();
    }

    return error;
  }

  command error_t HalTMP102Advanced.setThermostatMode(bool useInt) {
    error_t error;
    uint8_t newRegVal;

    error = call TMP102Resource.immediateRequest();
    if (error) {
      return error;
    }

    newRegVal = (useInt) ? (mConfigRegVal | TMP102_CFG_TM) : (mConfigRegVal & ~TMP102_CFG_TM);
    error = setCfg(STATE_SET_MODE, newRegVal);

    return error;
  }


  command error_t HalTMP175Advanced.setPolarity(bool polarity) {
    error_t error;
    uint8_t newRegVal;

    error = call TMP102Resource.immediateRequest();
    if (error) {
      return error;
    }

    newRegVal = (polarity) ? (mConfigRegVal | TMP102_CFG_POL) : (mConfigRegVal & ~TMP102_CFG_POL);
    error = setCfg(STATE_SET_POLARITY, newRegVal);

    return error;
  }

  command error_t HalTMP175Advanced.setFaultQueue(tmp102_fqd_t depth) {
    error_t error;
    uint8_t newRegVal;

    if ((uint8_t)depth > 3) {
      error = EINVAL;
      return error;
    }

    error = call TMP102Resource.immediateRequest();
    if (error) {
      return error;
    }

    newRegVal = (mConfigRegVal & ~TMP102_CFG_FQ(3)) | (TMP102_CFG_FQ(depth));
    error = setCfg(STATE_SET_FQ, newRegVal);

    return error;
  }

  command error_t HalTMP102Advanced.setTLow(uint16_t val) {
    error_t error;

    error = call TMP102Resource.immediateRequest();
    if (error) {
      return error;
    }

    error = setThresh(STATE_SET_TLOW, val);

    if (error) {
      call TMP102Resource.release();
    }

    return error;
  }

  command error_t HalTMP102Advanced.setTHigh(uint16_t val) {
    error_t error;

    error = call TMP102Resource.immediateRequest();
    if (error) {
      return error;
    }

    error = setThresh(STATE_SET_THIGH, val);

    if (error) {
      call TMP102Resource.release();
    }

    return error;
  }

  task void handleConfigReg() {
    error_t lasterror;
    atomic lasterror = mHplError;
    call TMP102Resource.release();
    switch (mState) {
    case STATE_SET_MODE:
      mState = STATE_NONE;
      signal HalTMP102Advanced.setThermostatModeDone(lasterror);
      break;
    case STATE_SET_POLARITY:
      mState = STATE_NONE;
      signal HalTMP102Advanced.setPolarityDone(lasterror);
      break;
    case STATE_SET_FQ:
      mState = STATE_NONE;
      signal HalTMP102Advanced.setFaultQueueDone(lasterror);
      break;
    case STATE_SET_RES:
      mState = STATE_NONE;
      signal HalTMP102Advanced.setResolutionDone(lasterror);
      break;
    default:
      break;
    }
    //mState = STATE_NONE;
    return;
  }

  task void handleTReg() {
    error_t lasterror;
    atomic lasterror = mHplError;
    call TMP102Resource.release();
    switch (mState) {
    case STATE_SET_TLOW:
      mState = STATE_NONE;
      signal HalTMP102Advanced.setTLowDone(lasterror);
      break;
    case STATE_SET_THIGH:
      mState = STATE_NONE;
      signal HalTMP102Advanced.setTHighDone(lasterror);
      break;
    default:
      mState = STATE_NONE;
      break;
    }
    //mState = STATE_NONE;
  }

  event void TMP102Resource.granted() {
    // intentionally left blank
  }

  async event void HplTMP102.setConfigRegDone(error_t error) {
    mHplError = error;
    post handleConfigReg();
    return;
  }

  async event void HplTMP102.setTLowRegDone(error_t error) {
    mHplError = error;
    post handleTReg();

  }

  async event void HplTMP102.setTHighRegDone(error_t error) {
    mHplError = error;
    post handleTReg();
  }

  async event void HplTMP102.alertThreshold() {
    post complete_Alert();
  }

  async event void HplTMP102.measureTemperatureDone(error_t error, uint16_t val) {
    // intentionally left blank
  }
  
  default event void HalTMP102Advanced.setTHighDone(error_t error) { return; }
  default event void HalTMP102Advanced.setThermostatModeDone(error_t error){ return; } 
  default event void HalTMP102Advanced.setPolarityDone(error_t error){ return; }
  default event void HalTMP102Advanced.setFaultQueueDone(error_t error){ return; }
  default event void HalTMP102Advanced.setResolutionDone(error_t error){ return; }
  default event void HalTMP102Advanced.setTLowDone(error_t error){ return; }
  default event void HalTMP102Advanced.alertThreshold(){ return; }
  
  //we must include other functions for tmp102.
  
}
