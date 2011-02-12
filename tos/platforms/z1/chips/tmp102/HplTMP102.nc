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
 * HplTMP102 is the HPL inteface to the Texas Instrument TMP102 
 * Digital Temperature Sensor. 
 *
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @version $Revision: 1.4 $ $Date: 2006/12/12 18:23:14 $
 */

interface HplTMP102 {

  /**
   * Starts a temperature measurement.
   *
   * @return SUCCESS if the measurement will be made
   */
  command error_t measureTemperature();

  /**
   * Presents the result of a temperature measurement.
   *
   * @param error SUCCESS if the measurement was successful
   * @param val the temperature reading
   */
  async event void measureTemperatureDone( error_t error, uint16_t val );

  /**
   * Sets a new value to the TMP102 configuration register.
   *
   * @param val the new value to be written
   *
   * @return SUCCESS if the set will be performed
   */
  command error_t setConfigReg( uint16_t val );

  /**
   * Signals the completion of the configuration register set.
   *
   * @param error SUCCESS if the set was successful
   */
  async event void setConfigRegDone( error_t error );

  command error_t setTLowReg(uint16_t val);
  async event void setTLowRegDone(error_t error);

  command error_t setTHighReg(uint16_t val);
  async event void setTHighRegDone(error_t error);

  async event void alertThreshold();

}
