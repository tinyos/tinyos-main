// $Id: pxa27xhardware.h,v 1.3 2006-11-07 19:31:10 scipio Exp $

/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */


/*
 *
 * Authors:   Philip Buonadonna
 *
 * Edits:	Josh Herbach
 * Revised: 09/02/2005
 */

#ifndef PXA27X_HARDWARE_H
#define PXA27X_HARDWARE_H

#include "arm_defs.h"
#include "pxa27x_registers.h"

#define _pxa27x_perf_clear() {asm volatile ("mcr p14,0,%0,c0,c1,0\n\t"::"r" (0x5));}
#define _pxa27x_perf_get(_x) {asm volatile ("mrc p14,0,%0,c1,c1,0":"=r" (_x));}

// External utility functions
extern void enableICache();
extern void initSyncFlash();

inline uint32_t _pxa27x_clzui(uint32_t i) {
  uint32_t count;
  asm volatile ("clz %0,%1": "=r" (count) : "r" (i));
  return count;
}

typedef uint32_t __nesc_atomic_t;

//NOTE...at the moment, these functions will ONLY disable the IRQ...FIQ is left alone
inline __nesc_atomic_t __nesc_atomic_start(void) __attribute__((spontaneous))
{
  uint32_t result = 0;
  uint32_t temp = 0;

  asm volatile (
		"mrs %0,CPSR\n\t"
		"orr %1,%2,%4\n\t"
		"msr CPSR_cf,%3"
		: "=r" (result) , "=r" (temp)
		: "0" (result) , "1" (temp) , "i" (ARM_CPSR_INT_MASK)
		);
  return result;
}

inline void __nesc_atomic_end(__nesc_atomic_t oldState) __attribute__((spontaneous))
{
  uint32_t  statusReg = 0;
  //make sure that we only mess with the INT bit
  oldState &= ARM_CPSR_INT_MASK;
  asm volatile (
		"mrs %0,CPSR\n\t"
		"bic %0, %1, %2\n\t"
		"orr %0, %1, %3\n\t"
		"msr CPSR_c, %1"
		: "=r" (statusReg)
		: "0" (statusReg),"i" (ARM_CPSR_INT_MASK), "r" (oldState)
		);

  return;
}

inline void __nesc_enable_interrupt() {

  uint32_t statusReg = 0;

  asm volatile (
	       "mrs %0,CPSR\n\t"
	       "bic %0,%1,#0xc0\n\t"
	       "msr CPSR_c, %1"
	       : "=r" (statusReg)
	       : "0" (statusReg)
	       );
  return;
}

inline void __nesc_disable_interrupt() {

  uint32_t statusReg = 0;

  asm volatile (
		"mrs %0,CPSR\n\t"
		"orr %0,%1,#0xc0\n\t"
		"msr CPSR_c,%1\n\t"
		: "=r" (statusReg)
		: "0" (statusReg)
		);
  return;

}


inline void __nesc_atomic_sleep()
{
  /* 
   * Atomically enable interrupts and sleep , 
   * LN : FOR NOW SLEEP IS DISABLED will be adding this functionality shortly
   */
  __nesc_enable_interrupt();
  return;
}

typedef uint8_t mcu_power_t @combine("mcombine");

/** Combine function.  */
mcu_power_t mcombine(mcu_power_t m1, mcu_power_t m2) {
  return (m1 < m2)? m1: m2;
}


#endif //TOSH_HARDWARE_H
