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
 *
 * @author Eric B. Decker <cire831@gmail.com>
 */

#ifndef __MSP432_NESC_H__
#define __MSP432_NESC_H__

/*
 * msp432 uses DEVICE to select correct chip header.  The chip header is
 * responsible for pulling in cmsis (core_cm4.h etc).
 */

#include <msp432.h>
#include <cortexm_nesc.h>

/*
 * All access are atomic because of bit banding other than the toggle.  We
 * don't care about weird interrupt issues on a single bit in a single port.
 * We haven't been able to think of any cases where that would actually be
 * an issue.
 *
 * We also assume that the SET/CLR/TOGGLE work properly because the port is
 * configured as an OUTPUT/IO.  Which if anything is going to work has to be
 * the case, ie.  the port pin is configured as OUTPUT/IO.
 */
#define TOSH_ASSIGN_PIN(name, port, bit) \
  void    TOSH_SET_##name##_PIN()     { BITBAND_PERI(port->OUT,  bit) = 1; }   \
  void    TOSH_CLR_##name##_PIN()     { BITBAND_PERI(port->OUT,  bit) = 0; }   \
  void    TOSH_TOGGLE_##name##_PIN()  { BITBAND_PERI(port->OUT,  bit) =        \
                                             !BITBAND_PERI(port->IN, bit); }   \
  uint8_t TOSH_READ_##name##_PIN()    { return(BITBAND_PERI(port->IN, bit)); } \
  void    TOSH_MAKE_##name##_OUTPUT() { BITBAND_PERI(port->DIR,  bit) = 1; }   \
  void    TOSH_MAKE_##name##_INPUT()  { BITBAND_PERI(port->DIR,  bit) = 0; }   \
  void    TOSH_SEL_##name##_MODFUNC() { BITBAND_PERI(port->SEL0, bit) = 1; }   \
  void    TOSH_SEL_##name##_IOFUNC()  { BITBAND_PERI(port->SEL0, bit) = 0; }

typedef uint8_t mcu_power_t @combine("mcombine");
mcu_power_t mcombine(mcu_power_t m1, mcu_power_t m2) @safe() {
  return (m1 < m2) ? m1: m2;
}

typedef enum {
  MSP432_POWER_ACTIVE = 0,
  MSP432_POWER_AM_LOW,          /* low power, slower, Vcore0 */
  MSP432_POWER_AM_HIGH,         /* high power, fast, Vcore1 */
  MSP432_POWER_SLEEP,           /* LPM0 */
  MSP432_POWER_LPM0,            /* no cpu clocks */
  MSP432_POWER_DEEP_SLEEP,      /* LPM3 */
  MSP432_POWER_LPM3,            /* only RTC/WDT active, 32KiHz , configured SRAM banks */
  MSP432_POWER_LPM35,           /* LPM3 but only Bank0 SRAM, Vcore0 only */
  MSP432_POWER_LPM4,            /* RTC & WDT disabled */
  MSP432_POWER_LPM45            /* Vcore off */
} msp432_power_state_t;


/*
 * Floating-point network-type support.
 *
 * These functions must convert to/from a 32-bit big-endian integer that follows
 * the layout of Java's java.lang.float.floatToRawIntBits method.
 *
 */

typedef float nx_float __attribute__((nx_base_be(afloat)));

inline float __nesc_ntoh_afloat(const void *COUNT(sizeof(float)) source) @safe() {
  float f;
  memcpy(&f, source, sizeof(float));
  return f;
}

inline float __nesc_hton_afloat(void *COUNT(sizeof(float)) target, float value) @safe() {
  memcpy(target, &value, sizeof(float));
  return value;
}

#endif          /* __MSP432_NESC_H__ */
