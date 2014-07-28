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
} thread_regs_t;

typedef uint16_t* stack_ptr_t;

#define STACK_TOP(stack, size)    \
  (&(((uint8_t*)stack)[size - sizeof(stack_ptr_t)]))

//Save stack pointer
#define SAVE_STACK_PTR(t)

//Save status register
#define SAVE_STATUS(t)

//Save General Purpose Registers
#define SAVE_GPR(t)

//Restore stack pointer
#define RESTORE_STACK_PTR(t)

//Restore status register
#define RESTORE_STATUS(t)

//Restore the general purpose registers
#define RESTORE_GPR(t)

#define SAVE_TCB(t)

#define RESTORE_TCB(t)

#define SWITCH_CONTEXTS(from, to)

#define SWAP_STACK_PTR(OLD, NEW)

#define PREPARE_THREAD(t, thread_ptr)
