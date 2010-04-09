/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
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
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Some M16c/62p needed macros and defines.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 * @author Fan Zhang <fanzha@ltu.se>
 */

#ifndef __M16C62PHARDWARE_H__
#define __M16C62PHARDWARE_H__

#include "interrupts.h"
#include "iom16c62p.h"
#include "bits.h"
#include "uart/M16c62pUart.h"
#include "pins/M16c62pPin.h"

#define true 1
#define false 0

//Bit operators using bit number
#define _BV(bit)  (1 << bit)
#define SET_BIT(port, bit)    ((port) |= _BV(bit))
#define CLR_BIT(port, bit)    ((port) &= ~_BV(bit))
#define READ_BIT(port, bit)   (((port) & _BV(bit)) != 0)
#define FLIP_BIT(port, bit)   ((port) ^= _BV(bit))
#define WRITE_BIT(port, bit, value) \
  if (value) SET_BIT((port), (bit)); \
    else CLR_BIT((port), (bit))

// Bit operators using bit flag mask
#define SET_FLAG(port, flag)  ((port) |= (flag))
#define CLR_FLAG(port, flag)  ((port) &= ~(flag))
#define READ_FLAG(port, flag) ((port) & (flag))

// We need slightly different defs than M16C_INTERRUPT
// for interrupt handlers.
#define M16C_INTERRUPT_HANDLER(id) \
  M16C_INTERRUPT(id) @atomic_hwevent() @C()
 
// The mov instruction should be used when clearing the interrupt flag.
// More information can be found in the manual for the MCU.
inline void clear_interrupt(uint16_t interrupt_addr)
{
  atomic
  {
  uint8_t tmp = (*TCAST(volatile uint8_t* ONE, interrupt_addr));
  CLR_BIT(tmp, 3);
  asm("mov.w %[interrupt_addr], a0\n\t"
      "mov.b %[tmp], [a0]"
      :
      : [tmp] "r" (tmp) , [interrupt_addr] "r" (interrupt_addr)
      : "a0");
  }
}

typedef uint8_t mcu_power_t @combine("ecombine");

mcu_power_t mcombine(mcu_power_t m1, mcu_power_t m2)
{
  return (m1 < m2) ? m1: m2;
}

enum
{
  M16C62P_POWER_WAIT        = 1,
  M16C62P_POWER_STOP        = 2,
};

inline void __nesc_enable_interrupt(void) { asm("fset i"); }
inline void __nesc_disable_interrupt(void) { asm("fclr i"); }

// Macro to create union casting functions.
#define DEFINE_UNION_CAST(func_name, from_type, to_type) \
  to_type func_name(from_type x_type) { \
    union {from_type f_type; to_type t_type;} c_type = {f_type:x_type}; return c_type.t_type; }

typedef uint16_t __nesc_atomic_t;

#ifndef NESC_BUILD_BINARY
/**
 * Start atomic section.
 */
inline __nesc_atomic_t __nesc_atomic_start(void) @spontaneous()
{
  __nesc_atomic_t result;
  // Save the flag register (FLG)
  asm volatile ("stc flg, %0": "=r"(result): : "%flg");
  // Disable interrupts
  __nesc_disable_interrupt();
  asm volatile("" : : : "memory"); // ensure atomic section effect visibility
  return result;
}

/**
 * End atomic section.
 */
inline void __nesc_atomic_end(__nesc_atomic_t original_FLG) @spontaneous()
{
  // Restore the flag register (FLG)
  asm volatile("" : : : "memory"); // ensure atomic section effect visibility
  asm volatile ("ldc %0, flg": : "r"(original_FLG): "%flg");
}
#endif

// If the platform doesnt have defined any main crystal speed it will
// get a default value of 16MHz
#ifndef MAIN_CRYSTAL_SPEED
#define MAIN_CRYSTAL_SPEED 16 /*MHZ*/
#endif

// If the PLL_MULTIPLIER is not defined it will be default to M16C62P_PLL_2.
#ifndef PLL_MULTIPLIER
#define PLL_MULTIPLIER M16C62P_PLL_2
#endif

// Default inactive pin states
#ifndef PORT_P0_INACTIVE_STATE
#define PORT_P0_INACTIVE_STATE M16C_PIN_INACTIVE_DONT_CARE
#endif

#ifndef PORT_P1_INACTIVE_STATE
#define PORT_P1_INACTIVE_STATE M16C_PIN_INACTIVE_DONT_CARE
#endif

#ifndef PORT_P2_INACTIVE_STATE
#define PORT_P2_INACTIVE_STATE M16C_PIN_INACTIVE_DONT_CARE
#endif

#ifndef PORT_P3_INACTIVE_STATE
#define PORT_P3_INACTIVE_STATE M16C_PIN_INACTIVE_DONT_CARE
#endif

#ifndef PORT_P4_INACTIVE_STATE
#define PORT_P4_INACTIVE_STATE M16C_PIN_INACTIVE_DONT_CARE
#endif

#ifndef PORT_P5_INACTIVE_STATE
#define PORT_P5_INACTIVE_STATE M16C_PIN_INACTIVE_DONT_CARE
#endif

#ifndef PORT_P6_INACTIVE_STATE
#define PORT_P6_INACTIVE_STATE M16C_PIN_INACTIVE_DONT_CARE
#endif

#ifndef PORT_P7_INACTIVE_STATE
#define PORT_P7_INACTIVE_STATE M16C_PIN_INACTIVE_DONT_CARE
#endif

#ifndef PORT_P8_INACTIVE_STATE
#define PORT_P8_INACTIVE_STATE M16C_PIN_INACTIVE_DONT_CARE
#endif

#ifndef PORT_P9_INACTIVE_STATE
#define PORT_P9_INACTIVE_STATE M16C_PIN_INACTIVE_DONT_CARE
#endif

#ifndef PORT_P_10_INACTIVE_STATE
#define PORT_P_10_INACTIVE_STATE M16C_PIN_INACTIVE_DONT_CARE
#endif

#endif  // __M16C62PHARDWARE_H__
