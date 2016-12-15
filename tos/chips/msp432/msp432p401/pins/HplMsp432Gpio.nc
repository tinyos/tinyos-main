/*
 * Copyright (c) 2016, Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * HPL for the TI MSP432 family of microprocessors. This provides an
 * abstraction for general-purpose I/O (gpio).
 *
 * See msp432_gpio.h for definitions of what can be passed.
 *
 * @author Eric B. Decker <cire831@gmail.com>
 */

#include "TinyError.h"
#include "msp432_gpio.h"

interface HplMsp432Gpio {
  async command void set();     /* set to high */
  async command void clr();     /* set to low  */
  async command void toggle();  /* yep, toggle */

  /**
   * Read pin value.
   *
   * @return TRUE if pin is high, FALSE otherwise.
   */
  async command bool get();

  /**
   * Set pin direction to input.
   */
  async command void makeInput();
  async command bool isInput();
  
  /**
   * Set pin direction to output.
   */
  async command void makeOutput();
  async command bool isOutput();
  
  /**
   * Set pin for module specific functionality.
   */
  async command error_t setFunction(uint8_t func);
  async command uint8_t getFunction();

  /**
   * Set pin pullup / pull down resistor mode.
   * @param mode One of the MSP432_GPIO_RESISTOR_* values
   */
  async command void    setResistorMode(uint8_t mode);
  async command uint8_t getResistorMode();

  /**
   * Set drive strength for a pin
   * @param mode One of the MSP432_GPIO_DS_* values
   */
  async command void    setDSMode(uint8_t mode);
  async command uint8_t getDSMode();
}
