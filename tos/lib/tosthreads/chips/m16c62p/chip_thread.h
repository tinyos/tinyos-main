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
 * This file contains M16c/62p mcu-specific routines for implementing
 * threads in TinyOS
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */

typedef struct thread_regs {
  uint16_t r0;
  uint16_t r1;
  uint16_t r2;
  uint16_t r3;
  uint16_t a0;
  uint16_t a1;
  uint16_t fb;
  uint16_t flg;
  uint16_t mem0;
  uint16_t mem2;
  uint16_t mem4;
  uint16_t mem6;
  uint16_t mem8;
  uint16_t mem10;
  uint16_t mem12;
  uint16_t mem14;
} thread_regs_t;

/**
 * Memory is addressed by 16 bits on M16c/62p but because
 * is can be addressed in 8 bit units we typedef the
 * stack pointer as a uint8_t.
 */
typedef uint8_t* stack_ptr_t;
  
#define STACK_TOP(stack, size)    \
  (&(((uint8_t*)stack)[size - 1]))
  
//Save stack pointer
#define SAVE_STACK_PTR(t)            		  		\
  asm volatile ("stc sp, %0": "=r"(t->stack_ptr));

//Save status register
#define SAVE_STATUS(t)                   	  		\
   asm volatile ("stc flg, %0": "=r"(t->regs.flg));
  
//Save General Purpose Registers
#define SAVE_GPR(t)                        			    \
 asm volatile ("mov.w r0, %0 \n\t" : "=r" ((t)->regs.r0) : );   \
 asm volatile ("mov.w r1, %0 \n\t" : "=r" ((t)->regs.r1) : );   \
 asm volatile ("mov.w r2, %0 \n\t" : "=r" ((t)->regs.r2) : );   \
 asm volatile ("mov.w r3, %0 \n\t" : "=r" ((t)->regs.r3) : );   \
 asm volatile ("mov.w a0, %0 \n\t" : "=r" ((t)->regs.a0) : );   \
 asm volatile ("mov.w a1, %0 \n\t" : "=r" ((t)->regs.a1) : );   \
 asm volatile ("stc fb, %0 \n\t" : "=r" ((t)->regs.fb) : ); \
 asm volatile ("mov.w mem0, %0 \n\t" : "=r" ((t)->regs.mem0) : );  \
 asm volatile ("mov.w mem2, %0 \n\t" : "=r" ((t)->regs.mem2) : );  \
 asm volatile ("mov.w mem4, %0 \n\t" : "=r" ((t)->regs.mem4) : );  \
 asm volatile ("mov.w mem6, %0 \n\t" : "=r" ((t)->regs.mem6) : );  \
 asm volatile ("mov.w mem8, %0 \n\t" : "=r" ((t)->regs.mem8) : );  \
 asm volatile ("mov.w mem10, %0 \n\t" : "=r" ((t)->regs.mem10) : );  \
 asm volatile ("mov.w mem12, %0 \n\t" : "=r" ((t)->regs.mem12) : );  \
 asm volatile ("mov.w mem14, %0 \n\t" : "=r" ((t)->regs.mem14) : );  
  
//Restore stack pointer
#define RESTORE_STACK_PTR(t)           			 	 \
  asm volatile ("ldc %0, sp \n\t" :: "r" ((t)->stack_ptr))

//Restore status register
#define RESTORE_STATUS(t)                 			\
  asm volatile ("ldc %0, flg \n\t" :: "r" (t->regs.flg) ); 

//Restore the general purpose registers
#define RESTORE_GPR(t)           	         		     \
 asm volatile ("mov.w %0, r0 \n\t" :: "r" ((t)->regs.r0)  );   \
 asm volatile ("mov.w %0, r1 \n\t" :: "r" ((t)->regs.r1)  );   \
 asm volatile ("mov.w %0, r2 \n\t" :: "r" ((t)->regs.r2)  );   \
 asm volatile ("mov.w %0, r3 \n\t" :: "r" ((t)->regs.r3)  );   \
 asm volatile ("mov.w %0, a0 \n\t" :: "r" ((t)->regs.a0)  );   \
 asm volatile ("mov.w %0, a1 \n\t" :: "r" ((t)->regs.a1)  );   \
 asm volatile ("ldc %0, fb \n\t" :: "r" ((t)->regs.fb)  ); \
 asm volatile ("mov.w %0, mem0 \n\t" :: "r" ((t)->regs.mem0)  );   \
 asm volatile ("mov.w %0, mem2 \n\t" :: "r" ((t)->regs.mem2)  );   \
 asm volatile ("mov.w %0, mem4 \n\t" :: "r" ((t)->regs.mem4)  );   \
 asm volatile ("mov.w %0, mem6 \n\t" :: "r" ((t)->regs.mem6)  );   \
 asm volatile ("mov.w %0, mem8 \n\t" :: "r" ((t)->regs.mem8)  );   \
 asm volatile ("mov.w %0, mem10 \n\t" :: "r" ((t)->regs.mem10)  );   \
 asm volatile ("mov.w %0, mem12 \n\t" :: "r" ((t)->regs.mem12)  );   \
 asm volatile ("mov.w %0, mem14 \n\t" :: "r" ((t)->regs.mem14)  );   
  
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

#define PREPARE_THREAD(t, start_function)		               \
  t->stack_ptr[0] = 0; \
  t->stack_ptr[-1] = (uint8_t)((uint16_t)&start_function >> 8) & 0xFF; \
  t->stack_ptr[-2] = (uint8_t)((uint16_t)&start_function) & 0xFF; \
  t->stack_ptr -= 2; \
  SAVE_STATUS(t) 
