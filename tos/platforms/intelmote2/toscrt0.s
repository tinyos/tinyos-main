/*
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
/*
 *
 * Authors: Phil Buonadonna,David Gay
 * Date last modified:  $Revision: 1.6 $
 *
 */
			
	.equ	ARM_CPSR_MODE_MASK,(0x0000001F)
	.equ	ARM_CPSR_INT_MASK,(0x000000C0)
	.equ	ARM_CPSR_COND_MASK,(0xF8000000)
	
	.equ	ARM_CPSR_MODE_USR,(0x10)
	.equ	ARM_CPSR_MODE_FIQ,(0x11)
	.equ	ARM_CPSR_MODE_IRQ,(0x12)
	.equ	ARM_CPSR_MODE_SVC,(0x13)
	.equ	ARM_CPSR_MODE_ABT,(0x17)
	.equ	ARM_CPSR_MODE_UND,(0x1B)
	.equ	ARM_CPSR_MODE_SYS,(0x1F)

	.equ	ARM_CPSR_BIT_N,(0x80000000)
	.equ	ARM_CPSR_BIT_Z,(0x40000000)
	.equ	ARM_CPSR_BIT_C,(0x20000000)
	.equ	ARM_CPSR_BIT_V,(0x10000000)
	.equ	ARM_CPSR_BIT_Q,(0x08000000)
	
	.equ	ARM_CPSR_BIT_I,(0x00000080)
	.equ	ARM_CPSR_BIT_F,(0x00000040)
	.equ	ARM_CPRS_BIT_T,(0x00000020)

	.equ   _TOS_STACK_SIZE,(0x400)		@ TinyOS Exception stack sizes
	.equ   _TOS_ISRAM_PHYSBASE,(0x5C000000)	@ Internal SRAM on PXA27X
	.text
	
.globl start
start:
	mrs	r0, CPSR
	bic	r0, r0, #ARM_CPSR_MODE_MASK
	orr	r0, r0, #(ARM_CPSR_MODE_SVC | ARM_CPSR_INT_MASK)
	msr	cpsr_cf, r0
	
	/* Initialize the stack pointers for all modes */
	mov	r0,#_TOS_ISRAM_PHYSBASE
	ldr	r2, =(256*1024 - 4)		@ and go to the last slot (256K - 4)
	add	r2,r2,r0
	
	mov	r0, #ARM_CPSR_MODE_ABT			
	msr	CPSR_c, R0
	mov	sp, r2
	sub	r2, r2, #_TOS_STACK_SIZE

	mov	r0, #ARM_CPSR_MODE_UND	
	msr	CPSR_c, R0
	mov	sp, r2
	sub	r2, r2, #_TOS_STACK_SIZE
	
	mov	r0, #ARM_CPSR_MODE_FIQ			
	msr	CPSR_c, R0
	mov	sp, r2
	sub	r2, r2, #_TOS_STACK_SIZE

	mov	r0, #ARM_CPSR_MODE_IRQ			
	msr	CPSR_c, R0
	mov	sp, r2
	sub	r2, r2, #(_TOS_STACK_SIZE * 2)
	
	mov	r0, #ARM_CPSR_MODE_SVC			
	msr	CPSR_c, R0
	mov	sp, r2
	
		
	/* copy data */
	ldr	r0, =__data_load_start
	ldr	r1, =__data_load_end
	ldr	r2, =__data_start
.Lcopy:	
	cmp	r0, r1
	beq	.Lcopydone
	ldrb	r3, [r0], #1
	strb	r3, [r2], #1
	b	.Lcopy
.Lcopydone:
	/* clear bss */
	ldr	r0, =__bss_start__
	ldr	r1, =__bss_end__
	mov	r2, #0
.Lclear:	
	cmp	r0, r1
	beq	.Lcleardone
	strb	r2, [r0], #1
	b	.Lclear
.Lcleardone:	
	mov	r0, #0 /* argc? */
	mov	r1, #0 /* argv? */
	bl	main

.L1:	
	nop
	b	.L1

@if we receive and interrupt that we don't handle, behavior will depend on whether we're in release or not
.ifdef RELEASE 
@reboot...assumes that we started out in supervisor mode..and that we'll be returning  
hplarmv_undef:
	movs PC, #0
hplarmv_swi:
	movs PC, #0
hplarmv_pabort:
	movs PC, #0
hplarmv_dabort:
	movs PC, #0
hplarmv_reserved:
	movs PC, #0
hplarmv_irq:
	movs PC, #0
hplarmv_fiq:	
	movs PC, #0
.else
@infinite loop so that we can detect what happened with a debugger
@in future, we'll want to blink specific LED patter or something for the USER...or perhaps blue light of death
hplarmv_undef:
	b hplarmv_undef	
hplarmv_swi:
	b hplarmv_swi
hplarmv_pabort:
	b hplarmv_pabort
hplarmv_dabort:
	b hplarmv_dabort
hplarmv_reserved:
	b hplarmv_reserved	
hplarmv_irq:
	b hplarmv_irq	
hplarmv_fiq:	
	b hplarmv_fiq
.endif

reset_handler_start:
@ reset handler should first check whether this is a debug exception
@ or a real RESET event.
@ NOTE: r13 is only safe register to use.
@ - For RESET, don∆t really care about which register is used
@ - For debug exception, r13=DBG_r13, prevents application registers
@ - from being corrupted, before debug handler can save.
	mrs r13, cpsr
	and r13, r13, #0x1f
	cmp r13, #0x15			@ are we in DBG mode?
	beq dbg_handler_stub		@ if so, go to the dbg handler stub
	mov r13, #0x8000001c		@ otherwise, enable debug, set MOE bits
	mcr p14, 0, r13, c10, c0, 0	@ and continue with the reset handler
@ normal reset handler initialization follows code here,
@ or branch to the reset handler.	
	b	start

.align 5 @ align code to a cache line boundary.
dbg_handler_stub:
@ First save the state of the IC enable/disable bit in DBG_LR[0].
	mrc p15, 0, r13, c1, c0, 0
	and r13, r13, #0x1000
	orr r14, r14, r13, lsr #12
@ Next, enable the IC.
	mrc p15, 0, r13, c1, c0, 0
	orr r13, r13, #0x1000
	mcr p15, 0, r13, c1, c0, 0
@ do a sync operation to ensure all outstanding instr fetches have
@ completed before continuing. The invalidate cache line function
@ serves as a synchronization operation, that∆s why it is used
@ here. The target line is some scratch address in memory.
	adr r13, line2
	mcr p15, 0, r13, c7, c5, 1
@ invalidate BTB. make sure downloaded vector table does not hit one of
@ the application∆s branches cached in the BTB, branch to the wrong place
	mcr p15, 0, r13, c7, c5, 6
@ Now, send Êready for download∆ message to debugger, indicating debugger
@ can begin the download. Êready for download∆ = 0x00B00000.
TXloop:
	mrc p14, 0, r15, c14, c0, 0	@ first make sure TX reg. is available
	bvs TXloop
	mov r13, #0x00B00000
	mcr p14, 0, r13, c8, c0, 0	@ now write to TX
@ Wait for debugger to indicate that the download is complete.
	RXloop:
	mrc p14, 0, r15, c14, c0, 0	@ spin in loop waiting for data from the
	bpl RXloop			@ debugger in RX.
@ before reading the RX register to get the address to branch to, restore
@ the state of the IC (saved in DBG_r14[0]) to the value it have at the
@ start of the debug handler stub. Also, note it must be restored before	
@ reading the RX register because of limited scratch registers (r13)
	mrc p15, 0, r13, c1, c0, 0
@ First, check DBG_LR[0] to see if the IC was enabled or disabled
	tst r14, #0x1
@ Then, if it was previously disabled, then disable it now, otherwise,
@ there∆s no need to change the state, because its already enabled.
	biceq r13, r13, #0x1000
	mcr p15, 0, r13, c1, c0, 0
@ Restore the link register value
	bic r14, r14, #0x1
@ Now r13 can be used to read RX and get the target address to branch to.
	mrc p14, 0, r13, c9, c0, 0	@ Read RX and
	mov pc, r13			@ branch to downloaded address.
@ scratch memory space used by the invalidate IC line function above.
.align 5 @ make sure it starts at a cache line
@ boundary, so nothing else is affected
line2:
.word 0
.word 0
.word 0
.word 0
.word 0
.word 0
.word 0
.word 0	
	
	.weak hplarmv_undef, hplarmv_swi, hplarmv_pabort, hplarmv_dabort, hplarmv_reserved, hplarmv_irq, hplarmv_fiq

	.section	.vectors
	b	reset_handler_start
	b	hplarmv_undef
	b	hplarmv_swi
	b	hplarmv_pabort
	b	hplarmv_dabort
	b	hplarmv_reserved
	b	hplarmv_irq
	b	hplarmv_fiq

.end
	

	