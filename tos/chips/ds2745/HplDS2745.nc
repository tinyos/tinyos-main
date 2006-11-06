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
 * HplDS2745 is the HPL inteface to the Dallas DS2745 I2C Battery 
 * Monitor.
 *
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @version $Revision: 1.2 $ $Date: 2006-11-06 11:57:09 $
 */

interface HplDS2745 {

  /**
   * Sets a new value to the DS2745 configuration register.
   *
   * @param val the new value to be written
   *
   * @return SUCCESS if the set will be performed
   */
  command error_t setConfig( uint8_t val );

  /**
   * Signals the completion of the configuration register set.
   *
   * @param error SUCCESS if the set was successful
   */
  async event void setConfigDone( error_t error );


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
   * Starts a voltage measurement.
   *
   * @return SUCCESS if the measurement will be made
   */
  command error_t measureVoltage();

  /**
   * Presents the result of a voltage measurement.
   *
   * @param error SUCCESS if the measurement was successful
   * @param val the voltage reading
   */
  async event void measureVoltageDone( error_t error, uint16_t val);


  /** 
   * Starts a current measurement.
   *
   * @return SUCCESS if the measurement will be made
   */
  command error_t measureCurrent();

  /**
   * Presents the result of a current measurement.
   *
   * @param error SUCCESS if the measurement was successful
   * @param val the current reading
   */
  async event void measureCurrentDone( error_t error, uint16_t val);


  /** 
   * Starts an accumulated current measurement.
   *
   * @return SUCCESS if the measurement will be made
   */
  command error_t measureAccCurrent();

  /**
   * Presents the result of a accumulated current measurement.
   *
   * @param error SUCCESS if the measurement was successful
   * @param val the accumulated current reading
   */
  async event void measureAccCurrentDone( error_t error, uint16_t val);


  /** 
   * Initiates setting of the current offset bias value
   *
   * @param The signed two's complement bias value.
   *
   * @return SUCCESS if the setting will be made
   */
  command error_t setOffsetBias(int8_t val);

  /**
   * Signals completion and error, if any, in setting the current
   * offset bias value.
   *
   * @param error SUCCESS if the setting was successful
   */
  async event void setOffsetBiasDone( error_t error );


  /** 
   * Initiates setting of the accumulated current offset bias value
   *
   * @param The signed two's complement bias value.
   *
   * @return SUCCESS if the setting will be made
   */
  command error_t setAccOffsetBias(int8_t val);

  /**
   * Signals completion and error, if any, in setting the accumulated
   * current offset bias value.
   *
   * @param error SUCCESS if the setting was successful
   */
  async event void setAccOffsetBiasDone( error_t error );


}
