/*
 * Copyright (c) 2014 ZOLERTIA LABS
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
 * - Neither the name of the copyright holders nor the names of
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

/*
 * Basic analog driver to read data from a Phidget sensor
 * http://www.phidgets.com
 *
 * [1] http://zolertia.sourceforge.net/wiki/images/e/e8/Z1_RevC_Datasheet.pdf
 *
 * @author: Antonio Linan <alinan@zolertia.com>
 */

#include "phidgets.h"
#include "Msp430Adc12.h"

interface Phidgets {

  /**
   * Configure the phidget analog port and phidget sensor to be used
   * @param port Phidget analog port (North port, see [1], Msp430Adc12.h file)
   * @param phidget Phidget type, see phidgets.h header
   * @return EINVAL if invalid port/unsupported phidget sensor, EALREADY if the
   *         sensor was already configured, else SUCCESS
   */

  command error_t enable (uint8_t port, uint16_t phidget);

  /**
   * Disables a given phidget port
   * @param port Phidget analog port
   * @return EINVAL if invalid port, EALREADY if already disabled, else SUCCESS
   */

  command error_t disable (uint8_t port);

  /**
   * Requests a reading from the configured Phidget sensor
   * @return EOFF if not configured, SUCCESS otherwise
   */

  command error_t read (void);

  /**
   * Returns a reading from the configured Phidget sensor
   * @param error SUCCESS, else FAIL if something fails
   * @param phidget Connected phidget
   * @param data sensor information, already processed
   */

  event void readDone(error_t error, uint8_t phidget, uint16_t data);

}
