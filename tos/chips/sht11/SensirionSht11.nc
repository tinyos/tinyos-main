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
 * SensirionSht11 is the rich interface to the Sensirion SHT11
 * temperature/humidity sensor. 
 *
 * @author Gilman Tolle <gtolle@archrock.com>
 * @version $Revision: 1.3 $ $Date: 2006-11-07 19:31:14 $
 */

interface SensirionSht11 {

  /**
   * Resets the sensor.
   *
   * @return SUCCESS if the sensor will be reset
   */
  command error_t reset();

  /**
   * Signals that the sensor has been reset.
   *
   * @param result SUCCESS if the reset succeeded
   */
  event void resetDone( error_t result );

  /**
   * Starts a temperature measurement.
   *
   * @return SUCCESS if the measurement will be made
   */
  command error_t measureTemperature();

  /**
   * Presents the result of a temperature measurement.
   *
   * @param result SUCCESS if the measurement was successful
   * @param val the temperature reading
   */
  event void measureTemperatureDone( error_t result, uint16_t val );

  /**
   * Starts a humidity measurement.
   *
   * @return SUCCESS if the measurement will be made
   */  
  command error_t measureHumidity();

  /**
   * Presents the result of a humidity measurement.
   *
   * @param result SUCCESS if the measurement was successful
   * @param val the humidity reading
   */
  event void measureHumidityDone( error_t result, uint16_t val );

  /**
   * Reads the current contents of the SHT11 status and control
   * register. See the datasheet for interpretation of this register.
   *
   * @return SUCCESS if the read will be performed
   */
  command error_t readStatusReg();

  /**
   * Presents the value of the status register.
   *
   * @param result SUCCESS if the read succeeded
   * @param val the value of the register
   */
  event void readStatusRegDone( error_t result, uint8_t val );

  /**
   * Writes a new value to the SHT11 status and control register.
   *
   * @param val the new value to be written
   *
   * @return SUCCESS if the write will be performed
   */
  command error_t writeStatusReg( uint8_t val );

  /**
   * Signals the completion of the status register write.
   *
   * @param result SUCCESS if the write was successful
   */
  event void writeStatusRegDone( error_t result );
}
