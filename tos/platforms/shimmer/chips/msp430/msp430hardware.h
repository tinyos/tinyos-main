
/* Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
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
 */

// @author Vlado Handziski <handzisk@tkn.tu-berlin.de>
// @author Joe Polastre <polastre@cs.berkeley.edu>
// @author Cory Sharp <cssharp@eecs.berkeley.edu>

#ifndef _H_msp430hardware_h
#define _H_msp430hardware_h

#if defined(__MSPGCC__)
/* mspgcc */
#include <msp430.h>
#include <legacymsp430.h>
#else /* __MSPGCC__ */
/* old mspgcc3, forked mspgcc4 */
#include <io.h>
#include <signal.h>
#endif /* __MSPGCC__ */
#include "msp430regtypes.h"
#include "Msp430DcoSpec.h"


#ifdef __MSP430_TI_HEADERS__

/* TI's msp430 headers define FAIL to be 0x80 in the flash module.
 * I'd prefer that it match the value assigned to it in the
 * TinyError.h. */
#undef FAIL

/* Accommodate old gcc alias */
#define MC_STOP MC__STOP

/* Port registers in MSP430 chips have two naming conventions: by
 * number (e.g., P1IN), and by letter (e.g. PAIN).  The numeric-named
 * registers provide 8-bit values, while the alpha-named registers
 * provide 16-bit values.
 *
 * The headers for certain chips define numeric-named registers.
 *
 * In a very few cases, both numeric-named and alpha-named registers
 * are defined.  By inspection, this occurs only for PAIN, which
 * combines P7IN (at the address of PAIN) and P8IN (at 1+&PAIN); and
 * for PBIN, which combines P9IN (at the address of PBIN) and P10IN
 * (at 1+&PBIN).
 *
 * In more recent chips, only alpha-named registers are provided.
 * Since the current TinyOS MSP430 port interface assumes 8-bit
 * registers, by convention we map numeric-named registers to the
 * alpha-named registers beginning with PAIN==P1IN. */

#if defined(__MSP430_HAS_PORTA__) || defined(__MSP430_HAS_PORTA_R__)
#if (! defined(P1IN_)) && (defined(__MSP430_HAS_PORT1__) || defined(__MSP430_HAS_PORT1_R__))
#define P1IN_ (uint16_t)(PAIN_)
#define P1OUT_ (uint16_t)(PAOUT_)
#define P1DIR_ (uint16_t)(PADIR_)
#define P1SEL_ (uint16_t)(PASEL_)
#if defined(__MSP430_HAS_PORT1_R__)
#define P1REN_ (uint16_t)(PAREN_)
#endif /* __MSP430_HAS_PORT1_R__ */
#endif /* __MSP430_HAS_PORT1__ */

#if (! defined(P2IN_)) && (defined(__MSP430_HAS_PORT2__) || defined(__MSP430_HAS_PORT2_R__))
#define P2IN_ (uint16_t)(PAIN_+1)
#define P2OUT_ (uint16_t)(PAOUT_+1)
#define P2DIR_ (uint16_t)(PADIR_+1)
#define P2SEL_ (uint16_t)(PASEL_+1)
#if defined(__MSP430_HAS_PORT2_R__)
#define P2REN_ (uint16_t)(PAREN_+1)
#endif /* __MSP430_HAS_PORT2_R__ */
#endif /* __MSP430_HAS_PORT2__ */
#endif /* __MSP430_HAS_PORTA__ */


#if defined(__MSP430_HAS_PORTB__) || defined(__MSP430_HAS_PORTB_R__)
#if (! defined(P3IN_)) && (defined(__MSP430_HAS_PORT3__) || defined(__MSP430_HAS_PORT3_R__))
#define P3IN_ (uint16_t)(PBIN_)
#define P3OUT_ (uint16_t)(PBOUT_)
#define P3DIR_ (uint16_t)(PBDIR_)
#define P3SEL_ (uint16_t)(PBSEL_)
#if defined(__MSP430_HAS_PORT3_R__)
#define P3REN_ (uint16_t)(PBREN_)
#endif /* __MSP430_HAS_PORT3_R__ */
#endif /* __MSP430_HAS_PORT3__ */

#if (! defined(P4IN_)) && (defined(__MSP430_HAS_PORT4__) || defined(__MSP430_HAS_PORT4_R__))
#define P4IN_ (uint16_t)(PBIN_+1)
#define P4OUT_ (uint16_t)(PBOUT_+1)
#define P4DIR_ (uint16_t)(PBDIR_+1)
#define P4SEL_ (uint16_t)(PBSEL_+1)
#if defined(__MSP430_HAS_PORT4_R__)
#define P4REN_ (uint16_t)(PBREN_+1)
#endif /* __MSP430_HAS_PORT4_R__ */
#endif /* __MSP430_HAS_PORT4__ */
#endif /* __MSP430_HAS_PORTB__ */


#if defined(__MSP430_HAS_PORTC__) || defined(__MSP430_HAS_PORTC_R__)
#if (! defined(P5IN_)) && (defined(__MSP430_HAS_PORT5__) || defined(__MSP430_HAS_PORT5_R__))
#define P5IN_ (uint16_t)(PCIN_)
#define P5OUT_ (uint16_t)(PCOUT_)
#define P5DIR_ (uint16_t)(PCDIR_)
#define P5SEL_ (uint16_t)(PCSEL_)
#if defined(__MSP430_HAS_PORT5_R__)
#define P5REN_ (uint16_t)(PCREN_)
#endif /* __MSP430_HAS_PORT5_R__ */
#endif /* __MSP430_HAS_PORT5__ */

#if (! defined(P6IN_)) && (defined(__MSP430_HAS_PORT6__) || defined(__MSP430_HAS_PORT6_R__))
#define P6IN_ (uint16_t)(PCIN_+1)
#define P6OUT_ (uint16_t)(PCOUT_+1)
#define P6DIR_ (uint16_t)(PCDIR_+1)
#define P6SEL_ (uint16_t)(PCSEL_+1)
#if defined(__MSP430_HAS_PORT6_R__)
#define P6REN_ (uint16_t)(PCREN_+1)
#endif /* __MSP430_HAS_PORT6_R__ */
#endif /* __MSP430_HAS_PORT6__ */
#endif /* __MSP430_HAS_PORTC__ */


#if defined(__MSP430_HAS_PORTD__) || defined(__MSP430_HAS_PORTD_R__)
#if (! defined(P7IN_)) && (defined(__MSP430_HAS_PORT7__) || defined(__MSP430_HAS_PORT7_R__))
#define P7IN_ (uint16_t)(PDIN_)
#define P7OUT_ (uint16_t)(PDOUT_)
#define P7DIR_ (uint16_t)(PDDIR_)
#define P7SEL_ (uint16_t)(PDSEL_)
#if defined(__MSP430_HAS_PORT7_R__)
#define P7REN_ (uint16_t)(PDREN_)
#endif /* __MSP430_HAS_PORT7_R__ */
#endif /* __MSP430_HAS_PORT7__ */

#if (! defined(P8IN_)) && (defined(__MSP430_HAS_PORT8__) || defined(__MSP430_HAS_PORT8_R__))
#define P8IN_ (uint16_t)(PDIN_+1)
#define P8OUT_ (uint16_t)(PDOUT_+1)
#define P8DIR_ (uint16_t)(PDDIR_+1)
#define P8SEL_ (uint16_t)(PDSEL_+1)
#if defined(__MSP430_HAS_PORT8_R__)
#define P8REN_ (uint16_t)(PDREN_+1)
#endif /* __MSP430_HAS_PORT8_R__ */
#endif /* __MSP430_HAS_PORT8__ */
#endif /* __MSP430_HAS_PORTD__ */


#if defined(__MSP430_HAS_PORTE__) || defined(__MSP430_HAS_PORTE_R__)
#if (! defined(P9IN_)) && (defined(__MSP430_HAS_PORT9__) || defined(__MSP430_HAS_PORT9_R__))
#define P9IN_ (uint16_t)(PEIN_)
#define P9OUT_ (uint16_t)(PEOUT_)
#define P9DIR_ (uint16_t)(PEDIR_)
#define P9SEL_ (uint16_t)(PESEL_)
#if defined(__MSP430_HAS_PORT9_R__)
#define P9REN_ (uint16_t)(PEREN_)
#endif /* __MSP430_HAS_PORT9_R__ */
#endif /* __MSP430_HAS_PORT9__ */

#if (! defined(P10IN_)) && (defined(__MSP430_HAS_PORT10__) || defined(__MSP430_HAS_PORT10_R__))
#define P10IN_ (uint16_t)(PEIN_+1)
#define P10OUT_ (uint16_t)(PEOUT_+1)
#define P10DIR_ (uint16_t)(PEDIR_+1)
#define P10SEL_ (uint16_t)(PESEL_+1)
#if defined(__MSP430_HAS_PORT10_R__)
#define P10REN_ (uint16_t)(PEREN_+1)
#endif /* __MSP430_HAS_PORT10_R__ */
#endif /* __MSP430_HAS_PORT10__ */
#endif /* __MSP430_HAS_PORTE__ */


#if defined(__MSP430_HAS_PORTF__) || defined(__MSP430_HAS_PORTF_R__)
#if (! defined(P11IN_)) && (defined(__MSP430_HAS_PORT11__) || defined(__MSP430_HAS_PORT11_R__))
#define P11IN_ (uint16_t)(PFIN_)
#define P11OUT_ (uint16_t)(PFOUT_)
#define P11DIR_ (uint16_t)(PFDIR_)
#define P11SEL_ (uint16_t)(PFSEL_)
#if defined(__MSP430_HAS_PORT11_R__)
#define P11REN_ (uint16_t)(PFREN_)
#endif /* __MSP430_HAS_PORT11_R__ */
#endif /* __MSP430_HAS_PORT11__ */

#if (! defined(P12IN_)) && (defined(__MSP430_HAS_PORT12__) || defined(__MSP430_HAS_PORT12_R__))
#define P12IN_ (uint16_t)(PFIN_+1)
#define P12OUT_ (uint16_t)(PFOUT_+1)
#define P12DIR_ (uint16_t)(PFDIR_+1)
#define P12SEL_ (uint16_t)(PFSEL_+1)
#if defined(__MSP430_HAS_PORT12_R__)
#define P12REN_ (uint16_t)(PFREN_+1)
#endif /* __MSP430_HAS_PORT12_R__ */
#endif /* __MSP430_HAS_PORT12__ */
#endif /* __MSP430_HAS_PORTF__ */


#endif /* __MSP430_TI_HEADERS__ */

// CPU memory-mapped register access will cause nesc to issue race condition
// warnings.  Race conditions are a significant conern when accessing CPU
// memory-mapped registers, because they can change even while interrupts
// are disabled.  This means that the standard nesc tools for resolving race
// conditions, atomic statements that disable interrupt handling, do not
// resolve CPU register race conditions.  So, CPU registers access must be
// treated seriously and carefully.

// The macro MSP430REG_NORACE allows individual modules to internally
// redeclare CPU registers as norace, eliminating nesc's race condition
// warnings for their access.  This macro should only be used after the
// specific CPU register use has been verified safe and correct.  Example
// use:
//
//    module MyLowLevelModule
//    {
//      // ...
//    }
//    implementation
//    {
//      MSP430REG_NORACE(TACCTL0);
//      // ...
//    }

#undef norace

#define MSP430REG_NORACE_EXPAND(type,name,addr) \
norace static volatile type name asm(#addr)

#define MSP430REG_NORACE3(type,name,addr) \
MSP430REG_NORACE_EXPAND(type,name,addr)

// MSP430REG_NORACE and MSP430REG_NORACE2 presume naming conventions among
// type, name, and addr, which are defined in the local header
// msp430regtypes.h and mspgcc's header io.h and its children.

#define MSP430REG_NORACE2(rename,name) \
MSP430REG_NORACE3(TYPE_##name,rename,name##_)

#define MSP430REG_NORACE(name) \
MSP430REG_NORACE3(TYPE_##name,name,name##_)

// Avoid the type-punned pointer warnings from gcc 3.3, which are warning about
// creating potentially broken object code.  Union casts are the appropriate work
// around.  Unfortunately, they require a function definiton.
#define DEFINE_UNION_CAST(func_name,to_type,from_type) \
to_type func_name(from_type x) @safe() { union {from_type f; to_type t;} c = {f:x}; return c.t; }

// redefine ugly defines from msp-gcc
#ifndef DONT_REDEFINE_SR_FLAGS
#undef C
#undef Z
#undef N
#undef V
#undef GIE
#undef CPUOFF
#undef OSCOFF
#undef SCG0
#undef SCG1
#undef LPM0_bits
#undef LPM1_bits
#undef LPM2_bits
#undef LPM3_bits
#undef LPM4_bits
#define SR_C       0x0001
#define SR_Z       0x0002
#define SR_N       0x0004
#define SR_V       0x0100
#define SR_GIE     0x0008
#define SR_CPUOFF  0x0010
#define SR_OSCOFF  0x0020
#define SR_SCG0    0x0040
#define SR_SCG1    0x0080
#define LPM0_bits           SR_CPUOFF
#define LPM1_bits           SR_SCG0+SR_CPUOFF
#define LPM2_bits           SR_SCG1+SR_CPUOFF
#define LPM3_bits           SR_SCG1+SR_SCG0+SR_CPUOFF
#define LPM4_bits           SR_SCG1+SR_SCG0+SR_OSCOFF+SR_CPUOFF
#endif//DONT_REDEFINE_SR_FLAGS

#ifdef interrupt
#undef interrupt
#endif

#ifdef wakeup
#undef wakeup
#endif

#ifdef signal
#undef signal
#endif


// Re-definitions for safe tinyOS
// These rely on io.h being included at the top of this file
// thus pulling the affected header files before the re-definitions
#ifdef SAFE_TINYOS
#undef ADC12MEM
#define ADC12MEM            TCAST(int* ONE, ADC12MEM_) /* ADC12 Conversion Memory (for C) */
#undef ADC12MCTL
#define ADC12MCTL           TCAST(char * ONE, ADC12MCTL_)
#endif

// define platform constants that can be changed for different compilers
// these are all msp430-gcc specific (add as necessary)

#ifdef __msp430_headers_adc10_h
#define __msp430_have_adc10
#endif

#ifdef __msp430_headers_adc12_h
#define __msp430_have_adc12
#endif

// backwards compatibility to older versions of the header files
#ifdef __MSP430_HAS_I2C__
#define __msp430_have_usart0_with_i2c
#endif

// I2CBusy flag is not defined by current MSP430-GCC
#ifdef __msp430_have_usart0_with_i2c
#ifndef I2CBUSY
#define I2CBUSY   (0x01 << 5)
#endif
MSP430REG_NORACE2(U0CTLnr,U0CTL);
MSP430REG_NORACE2(I2CTCTLnr,I2CTCTL);
MSP430REG_NORACE2(I2CDCTLnr,I2CDCTL);
#endif

// The signal attribute has opposite meaning in msp430-gcc than in avr-gcc
#define TOSH_SIGNAL(signame) \
  void sig_##signame() __attribute__((interrupt (signame), wakeup)) @C()

// TOSH_INTERRUPT allows nested interrupts
#define TOSH_INTERRUPT(signame) \
  void isr_##signame() __attribute__((interrupt (signame), signal, wakeup)) @C()

inline void TOSH_wait(void)
{
  nop(); nop();
}

// #define TOSH_CYCLE_TIME_NS 250
// Our worst case is 250 ns = 1 cycle.

inline void TOSH_wait_250ns(void)
{
  nop();
}

/* 
   Following the suggestion of the mspgcc.sourceforge.net site
   for an intelligent pause routine
*/
void brief_pause(register unsigned int n)
{
  asm volatile(	"1: \n\t"
		"dec	%0 \n\t"
		"jne	1b\n\t"
		:  "+r" (n));
}

#define TOSH_uwait(n)   brief_pause((((unsigned long long)n) * TARGET_DCO_KHZ * 1024 / 1000000 - 2) / 3)

#define SET_FLAG(port, flag) ((port) |= (flag))
#define CLR_FLAG(port, flag) ((port) &= ~(flag))
#define READ_FLAG(port, flag) ((port) & (flag))

// TOSH_ASSIGN_PIN creates functions that are effectively marked as
// "norace".  This means race conditions that result from their use will not
// be detectde by nesc.

#define TOSH_ASSIGN_PIN_HEX(name, port, hex) \
void TOSH_SET_##name##_PIN() @safe() { MSP430REG_NORACE2(r,P##port##OUT); r |= hex; } \
void TOSH_CLR_##name##_PIN() @safe() { MSP430REG_NORACE2(r,P##port##OUT); r &= ~hex; } \
void TOSH_TOGGLE_##name##_PIN() @safe(){ MSP430REG_NORACE2(r,P##port##OUT); r ^= hex; } \
uint8_t TOSH_READ_##name##_PIN() @safe() { MSP430REG_NORACE2(r,P##port##IN); return (r & hex); } \
void TOSH_MAKE_##name##_OUTPUT() @safe() { MSP430REG_NORACE2(r,P##port##DIR); r |= hex; } \
void TOSH_MAKE_##name##_INPUT() @safe() { MSP430REG_NORACE2(r,P##port##DIR); r &= ~hex; } \
void TOSH_SEL_##name##_MODFUNC() @safe() { MSP430REG_NORACE2(r,P##port##SEL); r |= hex; } \
void TOSH_SEL_##name##_IOFUNC() @safe() { MSP430REG_NORACE2(r,P##port##SEL); r &= ~hex; }

#define TOSH_ASSIGN_PIN(name, port, bit) \
TOSH_ASSIGN_PIN_HEX(name,port,(1<<(bit)))

typedef uint8_t mcu_power_t @combine("mcombine");
mcu_power_t mcombine(mcu_power_t m1, mcu_power_t m2) @safe() {
  return (m1 < m2) ? m1: m2;
}
enum {
  MSP430_POWER_ACTIVE = 0,
  MSP430_POWER_LPM0   = 1,
  MSP430_POWER_LPM1   = 2,
  MSP430_POWER_LPM2   = 3,
  MSP430_POWER_LPM3   = 4,
  MSP430_POWER_LPM4   = 5
};

void __nesc_disable_interrupt(void) @safe()
{
  dint();
  nop();
}

void __nesc_enable_interrupt(void) @safe()
{
  eint();
}

typedef bool __nesc_atomic_t;
__nesc_atomic_t __nesc_atomic_start(void);
void __nesc_atomic_end(__nesc_atomic_t reenable_interrupts);

#ifndef NESC_BUILD_BINARY
/* @spontaneous() functions should not be included when NESC_BUILD_BINARY
   is #defined, to avoid duplicate functions definitions when binary
   components are used. Such functions do need a prototype in all cases,
   though. */
__nesc_atomic_t __nesc_atomic_start(void) @spontaneous() @safe()
{
  __nesc_atomic_t result = ((READ_SR & SR_GIE) != 0);
  __nesc_disable_interrupt();
  asm volatile("" : : : "memory"); /* ensure atomic section effect visibility */
  return result;
}

void __nesc_atomic_end(__nesc_atomic_t reenable_interrupts) @spontaneous() @safe()
{
  asm volatile("" : : : "memory"); /* ensure atomic section effect visibility */
  if( reenable_interrupts )
    __nesc_enable_interrupt();
}
#endif

/* Floating-point network-type support.
   These functions must convert to/from a 32-bit big-endian integer that follows
   the layout of Java's java.lang.float.floatToRawIntBits method.
   Conveniently, for the MSP430 family, this is a straight byte copy...
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

/* Support for chips with configurable resistors on digital inputs.  These
 * are denoted with __MSP430_HAS_PORT1_R__ and similar defines. */
enum {
  MSP430_PORT_RESISTOR_INVALID,    /**< Hardware does not support resistor control, or pin is output */
  MSP430_PORT_RESISTOR_OFF,        /**< Resistor disabled */
  MSP430_PORT_RESISTOR_PULLDOWN,   /**< Pulldown resistor enabled */
  MSP430_PORT_RESISTOR_PULLUP,     /**< Pullup resistor enabled */
};

#endif//_H_msp430hardware_h

