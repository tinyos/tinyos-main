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
/*
 *
 * Authors:   Philip Buonadonna
 *
 *
 */

#ifndef _ARM_DEFS_H
#define _ARM_DEFS_H

#define	ARM_CPSR_MODE_MASK (0x0000001F)
#define	ARM_CPSR_INT_MASK (0x000000C0)
#define	ARM_CPSR_COND_MASK (0xF8000000)

#define	ARM_CPSR_MODE_USR (0x10)
#define	ARM_CPSR_MODE_FIQ (0x11)
#define	ARM_CPSR_MODE_IRQ (0x12)
#define	ARM_CPSR_MODE_SVC (0x13)
#define	ARM_CPSR_MODE_ABT (0x17)
#define	ARM_CPSR_MODE_UND (0x1B)
#define	ARM_CPSR_MODE_SYS (0x1F)

#define	ARM_CPSR_BIT_N (1 << 31)
#define	ARM_CPSR_BIT_Z (1 << 30)
#define	ARM_CPSR_BIT_C (1 << 29)
#define	ARM_CPSR_BIT_V (1 << 28)
#define	ARM_CPSR_BIT_Q (1 << 27)

#define	ARM_CPSR_BIT_I (1 << 7)
#define	ARM_CPSR_BIT_F (1 << 6)
#define	ARM_CPRS_BIT_T (1 << 5)

#endif /*_ARM_DEFS_H */
