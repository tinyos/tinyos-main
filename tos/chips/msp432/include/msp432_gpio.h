/*
 * Copyright (c) 2016 Eric B. Decker
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
 * - Neither the name of the University of California nor the names of
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
 * @author Eric B. Decker
 */

#ifndef __MSP432_GPIO_H__
#define __MSP432_GPIO_H__

enum {
  MSP432_GPIO_IO    = 0,
  MSP432_GPIO_MOD   = 1,
  MSP432_GPIO_MOD2  = 2,
  MSP432_GPIO_MOD3  = 3,
  MSP432_GPIO_MOD1,
  MSP432_GPIO_ANALOG,
};

enum {
  MSP432_GPIO_RESISTOR_INVALID,
  MSP432_GPIO_RESISTOR_OFF,
  MSP432_GPIO_RESISTOR_PULLDOWN,
  MSP432_GPIO_RESISTOR_PULLUP,
};

enum {
  MSP432_GPIO_DS_INVALID,
  MSP432_GPIO_DS_DEFAULT,
  MSP432_GPIO_DS_REGULAR,
  MSP432_GPIO_DS_HIGH,
};

#endif  /* __MSP432_GPIO_H__ */
