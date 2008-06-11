/*
 * Copyright (c) 2005 Arched Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arched Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/**
 * This interface provides a 'per-pin' abstraction for the PXA27x
 * GPIO system. It is parameterized by the specific GPIO Pin number
 * of the PXA27x. 
 *
 * @author Phil Buonadonna
 */

interface HplPXA27xGPIOPin 
{
  /** 
   * Returns the logic state of a GPIO Pin.
   *
   * @return bool TRUE if logic '1', FALSE if logic '0'
   */
  async command bool getGPLRbit();

  /** 
   * Configures the direction of a GPIO pin.
   *
   * @param dir TRUE to configure as an output, FALSE to configure as an input.
   */
  async command void setGPDRbit(bool dir);

  /** 
   * Get's the current pin direction configuration.
   *
   * @return bool TRUE if configured as an output, FALSE if configured 
   *  as an input.
   */
  async command bool getGPDRbit();

  /** 
   * Sets a GPIO pin configured as an output to a HIGH state.
   *
   */
  async command void setGPSRbit();

  /** 
   * Sets a GPIO pin configured as an output to a LOW state.
   *
   */
  async command void setGPCRbit();

  /** 
   * Enables/Disables events on the rising edge of a GPIO pin 
   * signal. Calls to this function are independent of calls
   * to 'setFallingEDEnable()'
   *
   * @param flag TRUE to enable rising edge detection, FASLE to
   * disable.
   *
   */
  async command void setGRERbit(bool flag);

  /** 
   * Returns the status of rising edge detection.
   *
   * @return val TRUE if rising edge detection is enable, FALSE
   * otherwise.
   */
  async command bool getGRERbit();

  /** 
   * Enables/Disables events on the falling edge of a GPIO pin 
   * signal. Calls to this function are independent of calls to
   * 'setRisingEDEnable()'
   *
   * @param flag TRUE to enable falling edge detection, FASLE to
   * disable.
   */
  async command void setGFERbit(bool flag);

  /** 
   * Returns the status of falling edge detection.
   *
   * @return val TRUE if falling edge detection is enable, FALSE
   * otherwise.
   */
  async command bool getGFERbit();

  /** 
   * Indicates wether an edge detection event is pending for GPIO Pin
   *
   * @return val TRUE if an event is pending.
   */
  async command bool getGEDRbit();

  /** 
   * Clears the edge detection event status.
   *
   * @return val TRUE if there was a pending event prior to clearing, 
   * FALSE otherwise.
   */
  async command bool clearGEDRbit();

  /** 
   * Sets the GPIO pin to one of it's alternate peripheral functions.
   * Refer to the PXA27x Developers Manual for information on available
   * alternate functions.
   *
   * @param func An integer between 0 and 3 indicating the desired 
   * pin alternate function. 
   */
  async command void setGAFRpin(uint8_t func);

  /** 
   * Returns the current alternate function selected for the GPIO pin.
   *
   * @return val An integer between 0 and 3 indicated the current
   * alternate function.
   */
  async command uint8_t getGAFRpin();

  /** 
   * The pin edge detection event. Signalled when a rising/falling edge
   * occurs on the PIN and the respective edge detect enable is set.
   * The default event DOES NOT clear any pending requests.
   *
   */
  async event void interruptGPIOPin();
}

