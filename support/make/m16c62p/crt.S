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
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 * @author Per Lindgren
 * @author Johan Eriksson
 * @author Johan Nordlander
 * @author Simon Aittamaa
 */
 
.set PM0, 0x04
.set PRCR, 0x0a

.text
	.global __vector_default

	.extern _main

.section .init0,"ax",@progbits
	.global _start

_start:
	/* Setup processor mode, single chip mode, and stack pointers */
	ldc	#_istack, isp
	mov.b	#0x02, PRCR
	mov.b	#0x00, PM0
	mov.b	#0x00, PRCR

	/* Setup the FLG register to some sane defaults. */
	ldc		#0, flg
	fset	u
	ldc	#_ustack, sp

	/* Setup interrupt vector. */
	ldc		#%hi16(_vectors_variable), intbh
	ldc		#%lo16(_vectors_variable), intbl

	/* Copy .data. */
	mov.b	#%hi8(__data_start), r1h
	mov.w	#%lo16(__data_start), a0
	mov.w	#__ram_start, a1
	mov.w	#__data_size, r3
	smovf.b

	/* Zero out .bss. */
	mov.b	#0x00, R0L
	mov.w	#__bss_size, r3
	mov.w	#__bss_start, a1
	sstr.b

	/* Enter main(). */
	jsr.a	_main

	/* In case we return, should realy generate a reset :/ */
	jmp.b	0

/* We should probably not get here. */
__vector_default:
	jmp.a	__vector_default

/* Fixed hardware vector table. */
.section .vectors_fixed, "a",@progbits

.size	_vectors_fixed, 36
.type	_vectors_fixed, @object

_vectors_fixed:

.long	0 /* Undefined Instruction. */
.long	0 /* Overflow INTO Instruction. */
.long	0 /* BRK Instruction.*/
.long	0 /* Address Match Interupt. */
.long	0 /* Single Step Interrupt. */
.long	0 /* Watchdog, Oscillation, Voltage Interrupt. */
.long	0 /* DBC. */
.long	0 /* NMI. */
.long	_start /* Reset. */


/* Boot args for tosboot. */
.section .boot_args, "a",@progbits

.size	_boot_args, 8
.type	_boot_args, @object

_boot_args:

.long	0xFFFFFFFF 
.long	0xFFFFFFFF

/* Variable vector table. */
.section .vectors_variable

.size _vectors_variable, 256
.type _vectors_variable, @object

_vectors_variable:

.long	__vector_0
.long	__vector_1
.long	__vector_2
.long	__vector_3
.long	__vector_4
.long	__vector_5
.long	__vector_6
.long	__vector_7
.long	__vector_8
.long	__vector_9
.long	__vector_10
.long	__vector_11
.long	__vector_12
.long	__vector_13
.long	__vector_14
.long	__vector_15
.long	__vector_16
.long	__vector_17
.long	__vector_18
.long	__vector_19
.long	__vector_20
.long	__vector_21
.long	__vector_22
.long	__vector_23
.long	__vector_24
.long	__vector_25
.long	__vector_26
.long	__vector_27
.long	__vector_28
.long	__vector_29
.long	__vector_30
.long	__vector_31
.long	__vector_32
.long	__vector_33
.long	__vector_34
.long	__vector_35
.long	__vector_36
.long	__vector_37
.long	__vector_38
.long	__vector_39
.long	__vector_40
.long	__vector_41
.long	__vector_42
.long	__vector_43
.long	__vector_44
.long	__vector_45
.long	__vector_46
.long	__vector_47
.long	__vector_48
.long	__vector_49
.long	__vector_50
.long	__vector_51
.long	__vector_52
.long	__vector_53
.long	__vector_54
.long	__vector_55
.long	__vector_56
.long	__vector_57
.long	__vector_58
.long	__vector_59
.long	__vector_60
.long	__vector_61
.long	__vector_62
.long	__vector_63
