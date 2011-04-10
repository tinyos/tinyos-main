/*--------------------------------------------------------------------------------*/
/*
 * Copyright (c) 2010 Eistec AB.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 * OF SUCH DAMAGE.
 *
 *--------------------------------------------------------------------------------*/

.section .init0,"ax",@progbits
  .global __vector_72
  .global __init_watchdog

__init_watchdog:
  ldc     #__istack, isp                /* Load stack pointer address.            */
  fset    u
  ldc     #__ustack,  sp                /* Load stack pointer address.            */
  ldc     #%hi16(__rvectors), intbh     /* Load relocatable vector table address. */
  ldc     #%lo16(__rvectors), intbl
  
  mov.b   #%hi8 (__data_rom_start), r1h            /* Copy initialized data from ROM to RAM  */
  mov.w   #%lo16(__data_rom_start), a0
  mov.w   #__data_start, a1
  mov.w   #__data_count, r3
  smovf.b
  
  mov.b   #0x00,r0l                     /* Fill uninitialized data in RAM with 0s */
  mov.w   #__bss_start, a1
  mov.w   #__bss_count, r3
  sstr.b
  jsr.a   _watchdog

__vector_72:
  
  ldc     #__istack, isp                /* Load stack pointer address.            */
  fset    u
  ldc     #__ustack,  sp                /* Load stack pointer address.            */
  ldc     #%hi16(__rvectors), intbh     /* Load relocatable vector table address. */
  ldc     #%lo16(__rvectors), intbl
  
  mov.b   #0x01, 0x000A                 /* Setup main clock and sub clock         */
  mov.b   #0x00, 0x0006
  mov.b   #0x00, 0x0007
  mov.b   #0x00, 0x000C
  mov.b   #0x00, 0x000A
  
  mov.b   #%hi8 (__data_rom_start), r1h            /* Copy initialized data from ROM to RAM  */
  mov.w   #%lo16(__data_rom_start), a0
  mov.w   #__data_start, a1
  mov.w   #__data_count, r3
  smovf.b
  
  mov.b   #0x00,r0l                     /* Fill uninitialized data in RAM with 0s */
  mov.w   #__bss_start, a1
  mov.w   #__bss_count, r3
  sstr.b
  
  jsr.a   _main                         /* Jump to main function.                 */
  jsr.a   __vector_72                   /* Restart if main function returns.      */

/*--------------------------------------------------------------------------------*/
/*                                                                                */

.text
.global m32c_jsri16
  
m32c_jsri16:
  
  add.w   #-1, sp
  /* Read the address (16 bits) and return address (24 bits) off
    the stack.  */
  mov.w   4[sp], r0
  mov.w   1[sp], r3
  mov.b   3[sp], a0 /* This zero-extends, so the high byte has
                          zero in it.  */
  /* Write the return address, then new address, to the stack.  */
  mov.w   a0, 1[sp] /* Just to get the zero in 2[sp].  */
  mov.w   r0, 0[sp]
  mov.w   r3, 3[sp]
  mov.b   a0, 5[sp]
  
  /* This "returns" to the target address, leaving the pending
  return address on the stack.  */
  rts

/*--------------------------------------------------------------------------------*/
/* Relocatable vector table                                                       */

.section .rvectors, "a", @progbits

  .long __vector_0
  .long __vector_1
  .long __vector_2
  .long __vector_3
  .long __vector_4
  .long __vector_5
  .long __vector_6
  .long __vector_7
  .long __vector_8
  .long __vector_9
  .long __vector_10
  .long __vector_11
  .long __vector_12
  .long __vector_13
  .long __vector_14
  .long __vector_15
  .long __vector_16
  .long __vector_17
  .long __vector_18
  .long __vector_19
  .long __vector_20
  .long __vector_21
  .long __vector_22
  .long __vector_23
  .long __vector_24
  .long __vector_25
  .long __vector_26
  .long __vector_27
  .long __vector_28
  .long __vector_29
  .long __vector_30
  .long __vector_31
  .long __vector_32
  .long __vector_33
  .long __vector_34
  .long __vector_35
  .long __vector_36
  .long __vector_37
  .long __vector_38
  .long __vector_39
  .long __vector_40
  .long __vector_41
  .long __vector_42
  .long __vector_43
  .long __vector_44
  .long __vector_45
  .long __vector_46
  .long __vector_47
  .long __vector_48
  .long __vector_49
  .long __vector_50
  .long __vector_51
  .long __vector_52
  .long __vector_53
  .long __vector_54
  .long __vector_55
  .long __vector_56
  .long __vector_57
  .long __vector_58
  .long __vector_59
  .long __vector_60
  .long __vector_61
  .long __vector_62
  .long __vector_63

/*--------------------------------------------------------------------------------*/
/* Fixed vector table                                                             */

.section .fvectors, "a", @progbits

  .long __vector_64 + 0x00000000        /* Set all ID bytes to 0x00.              */
  .long __vector_65 + 0x00000000
  .long __vector_66 + 0x00000000
  .long __vector_67 + 0x00000000
  .long __vector_68 + 0x00000000
  .long __vector_69 + 0x00000000
  .long __vector_70 + 0x00000000
  .long __vector_71 + 0x00000000
  .long __vector_72 + 0x9F000000        /* Enable power-on reset in OFS register. */
