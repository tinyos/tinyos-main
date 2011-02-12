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
 * HalTMP102ReaderP provides the service level HIL and device
 * specific Hal interfaces for the TI TMP102 Chip.
 *
 * Note that only the data path uses split phase resource arbitration
 * 
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @version $Revision: 1.4 $ $Date: 2006/12/12 18:23:14 $
 */

generic module HalTMP102ReaderP()
{
  provides interface Read<uint16_t> as Temperature;

  uses interface HplTMP102;
  uses interface Resource as TMP102Resource;
}

implementation {

  enum {
    STATE_SET_MODE,
    STATE_SET_POLARITY,
    STATE_SET_FQ,
    STATE_SET_CR,
    STATE_SET_EM,
    STATE_NONE
  };

  uint8_t mState = STATE_NONE;
  uint8_t mConfigRegVal = 0;
  error_t mHplError;

  command error_t Temperature.read() {
    return call TMP102Resource.request();
  }

  event void TMP102Resource.granted() {
    error_t error;
    
    error = call HplTMP102.measureTemperature();
    if (error) {
      call TMP102Resource.release();
      signal Temperature.readDone(error,0);
    }
    return;
  }

  async event void HplTMP102.measureTemperatureDone(error_t tmp102_error, uint16_t val) {
    call TMP102Resource.release();
    signal Temperature.readDone(tmp102_error,(val >> 4));
    return;
  }

  // intentionally left empty
  async event void HplTMP102.setTLowRegDone(error_t error) {}
  async event void HplTMP102.setTHighRegDone(error_t error) {}
  async event void HplTMP102.setConfigRegDone(error_t error) {}
  async event void HplTMP102.alertThreshold() {}

  default event void Temperature.readDone(error_t error, uint16_t val) {return ;}

}
