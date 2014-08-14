/*
 * Copyright (c) 2008 Stanford University.
 * All rights reserved.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
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
 * This file is derived from similar files in the TinyThread implementation
 * by William P. McCartney from Cleveland State University (2006)
 *
 * This file contains MSP430 platform-specific routines for implementing
 * threads in TinyOS
 *
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */

//Define on platform specific basis for inclusion in
// the thread control block
typedef struct thread_regs {
  uint16_t status;
  uint16_t r4;
  uint16_t r5;
  uint16_t r6;
  uint16_t r7;
  uint16_t r8;
  uint16_t r9;
  uint16_t r10;
  uint16_t r11;
  uint16_t r12;
  uint16_t r13;
  uint16_t r14;
  uint16_t r15;
} thread_regs_t;

typedef uint16_t* stack_ptr_t;
  
#define STACK_TOP(stack, size)    \
  (&(((uint8_t*)stack)[size - sizeof(stack_ptr_t)]))
  
//Save stack pointer
#define SAVE_STACK_PTR(t)            		  		\
  __asm__("mov.w r1,%0" : "=m" ((t)->stack_ptr))

//Save status register
#define SAVE_STATUS(t)                   	  		\
  __asm__("mov.w r2,%0" : "=r" ((t)->regs.status))

//Save General Purpose Registers
#define SAVE_GPR(t)                        			\
  __asm__("mov.w r4,%0" : "=m" ((t)->regs.r4));    	\
  __asm__("mov.w r5,%0" : "=m" ((t)->regs.r5));    	\
  __asm__("mov.w r6,%0" : "=m" ((t)->regs.r6));    	\
  __asm__("mov.w r7,%0" : "=m" ((t)->regs.r7));    	\
  __asm__("mov.w r8,%0" : "=m" ((t)->regs.r8));    	\
  __asm__("mov.w r9,%0" : "=m" ((t)->regs.r9));    	\
  __asm__("mov.w r10,%0" : "=m" ((t)->regs.r10));  	\
  __asm__("mov.w r11,%0" : "=m" ((t)->regs.r11));  	\
  __asm__("mov.w r12,%0" : "=m" ((t)->regs.r12));  	\
  __asm__("mov.w r13,%0" : "=m" ((t)->regs.r13));  	\
  __asm__("mov.w r14,%0" : "=m" ((t)->regs.r14));  	\
  __asm__("mov.w r15,%0" : "=m" ((t)->regs.r15))
  
//Restore stack pointer
#define RESTORE_STACK_PTR(t)           			 	\
  __asm__("mov.w %0,r1" : : "m" ((t)->stack_ptr))

//Restore status register
#define RESTORE_STATUS(t)                 			\
  __asm__("mov.w %0,r2" : : "r" ((t)->regs.status))

//Restore the general purpose registers
#define RESTORE_GPR(t)           	         		\
  __asm__("mov.w %0,r4" : : "m" ((t)->regs.r4));   	\
  __asm__("mov.w %0,r5" : : "m" ((t)->regs.r5));   	\
  __asm__("mov.w %0,r6" : : "m" ((t)->regs.r6));   	\
  __asm__("mov.w %0,r7" : : "m" ((t)->regs.r7));   	\
  __asm__("mov.w %0,r8" : : "m" ((t)->regs.r8));   	\
  __asm__("mov.w %0,r9" : : "m" ((t)->regs.r9));   	\
  __asm__("mov.w %0,r10" : : "m" ((t)->regs.r10)); 	\
  __asm__("mov.w %0,r11" : : "m" ((t)->regs.r11)); 	\
  __asm__("mov.w %0,r12" : : "m" ((t)->regs.r12)); 	\
  __asm__("mov.w %0,r13" : : "m" ((t)->regs.r13)); 	\
  __asm__("mov.w %0,r14" : : "m" ((t)->regs.r14)); 	\
  __asm__("mov.w %0,r15" : : "m" ((t)->regs.r15))
  
#define SAVE_TCB(t) \
  SAVE_GPR(t);	 	\
  SAVE_STATUS(t);	\
  SAVE_STACK_PTR(t) 
  
#define RESTORE_TCB(t)  \
  RESTORE_STACK_PTR(t); \
  RESTORE_STATUS(t);    \
  RESTORE_GPR(t)
  
#define SWITCH_CONTEXTS(from, to) \
  SAVE_TCB(from);				  \
  RESTORE_TCB(to)

#define SWAP_STACK_PTR(OLD, NEW)   			\
  __asm__("mov.w r1,%0" : "=m" (OLD));		\
  __asm__("mov.w %0,r1" : : "m" (NEW))
  
#define PREPARE_THREAD(t, thread_ptr)		\
  *((t)->stack_ptr) = (uint16_t)(&(thread_ptr));	\
  SAVE_STATUS(t)
