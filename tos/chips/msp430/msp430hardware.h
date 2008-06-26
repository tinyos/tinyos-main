
/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// @author Vlado Handziski <handzisk@tkn.tu-berlin.de>
// @author Joe Polastre <polastre@cs.berkeley.edu>
// @author Cory Sharp <cssharp@eecs.berkeley.edu>

#ifndef _H_msp430hardware_h
#define _H_msp430hardware_h

#include <io.h>
#include <signal.h>
#include "msp430regtypes.h"


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
   is #defined, to avoid duplicate functions definitions wheb binary
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

#endif//_H_msp430hardware_h

