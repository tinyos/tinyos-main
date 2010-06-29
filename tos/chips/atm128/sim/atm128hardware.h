/*                                                                     
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
 *  Copyright (c) 2002-2003 Intel Corporation.
 *  Copyright (c) 2000-2003 The Regents of the University  of California.    
 *  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
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
 *  @author Jason Hill, Philip Levis, Nelson Lee, David Gay
 *  @author Martin Turon <mturon@xbow.com>
 *
 *  $Id: atm128hardware.h,v 1.8 2010-06-29 22:07:43 scipio Exp $
 */

#ifndef _H_atmega128hardware_H
#define _H_atmega128hardware_H

#include <atm128_sim.h>
#include <sim_tossim.h>

uint8_t atm128RegFile[TOSSIM_MAX_NODES][0xa0];

#define REG_ACCESS(x) atm128RegFile[sim_node()][x]

/* We need slightly different defs than SIGNAL, INTERRUPT */
#define AVR_ATOMIC_HANDLER(signame) \
  void signame() @spontaneous() @C()

#define AVR_NONATOMIC_HANDLER(signame) \
  void signame() @spontaneous() @C()

/* Macro to create union casting functions. */
#define DEFINE_UNION_CAST(func_name, from_type, to_type) \
  to_type func_name(from_type x_type) { \
    union {from_type f_type; to_type t_type;} c_type = {f_type:x_type}; return c_type.t_type; }

// Bit operators using bit number
#define SET_BIT(port, bit)    ((REG_ACCESS(port)) |= _BV(bit))
#define CLR_BIT(port, bit)    ((REG_ACCESS(port)) &= ~_BV(bit))
#define READ_BIT(port, bit)   (((REG_ACCESS(port)) & _BV(bit)) != 0)
#define FLIP_BIT(port, bit)   ((REG_ACCESS(port)) ^= _BV(bit))
#define WRITE_BIT(port, bit, value) \
   if (value) SET_BIT((port), (bit)); \
   else CLR_BIT((port), (bit))

// Bit operators using bit flag mask
#define SET_FLAG(port, flag)  ((REG_ACCESS(port)) |= (flag))
#define CLR_FLAG(port, flag)  ((REG_ACCESS(port)) &= ~(flag))
#define READ_FLAG(port, flag) ((REG_ACCESS(port)) & (flag))

#define sei() (SET_BIT(SREG, 7))
#define cli() (CLR_BIT(SREG, 7))

/* Enables interrupts. */
inline void __nesc_enable_interrupt() {
    sei();
}
/* Disables all interrupts. */
inline void __nesc_disable_interrupt() {
    cli();
}

/* Defines data type for storing interrupt mask state during atomic. */
typedef uint8_t __nesc_atomic_t;

/* Saves current interrupt mask state and disables interrupts. */
inline __nesc_atomic_t 
__nesc_atomic_start(void) @spontaneous()
{
    __nesc_atomic_t result = SREG;
    __nesc_disable_interrupt();
    return result;
}

/* Restores interrupt mask to original state. */
inline void 
__nesc_atomic_end(__nesc_atomic_t original_SREG) @spontaneous()
{
  SREG = original_SREG;
}

inline void
__nesc_atomic_sleep()
{
  //sbi(MCUCR, SE);  power manager will enable/disable sleep
  sei();  // Make sure interrupts are on, so we can wake up!
  asm volatile ("sleep");
}

typedef uint8_t mcu_power_t @combine("mcombine");
/* Combine function.  */
mcu_power_t mcombine(mcu_power_t m1, mcu_power_t m2) {
  return (m1 < m2)? m1: m2;
}

enum {
  ATM128_POWER_IDLE        = 0,
  ATM128_POWER_ADC_NR      = 1,
  ATM128_POWER_EXT_STANDBY = 2,
  ATM128_POWER_SAVE        = 3,
  ATM128_POWER_STANDBY     = 4,
  ATM128_POWER_DOWN        = 5, 
};

#endif //_H_atmega128hardware_H
