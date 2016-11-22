/*
 * Copyright (c) 2016, Eric B. Decker
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
 * - Neither the name of the University of California nor the names of
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

/**
 *
 * Basic CPU stack interface
 *
 * @author Eric B. Decker
 * @date   Nov 7, 2010
 * Updated for 32 bit Cortex-M
 * @date   Nov 15, 2016
 */

#include "cpu_stack.h"

extern uint32_t __stack_start__;        /* last used byte of last segment in RAM (linker) */
extern uint32_t __StackTop__;		/* top of stack */


module StackP {
  provides interface Stack;
}

implementation {

  /*
   * Set stack to known good state.
   *
   * 1) set stack itself to STACK_UNUSED
   * 2) set guard word (_end) to STACK_GUARD
   */

  async command void Stack.init() {
    uint32_t *ptr = &__stack_start__;
    register void *stkptr asm("sp");

    *ptr++ = STACK_GUARD;
    while (ptr < (uint32_t *) stkptr)
      *ptr++ = STACK_UNUSED;
  }


  /*
   * Check for stack overflow
   *
   * returns: 0 - all okay
   *	      1 - not so good
   */

  async command bool Stack.overflow() {
    uint32_t *p = &__stack_start__;

    return (*p != STACK_GUARD);
  }


  /*
   * Return number of remaining bytes on the stack.
   *
   * Given the current stack pointer, how much space is left.
   */

  async command uint32_t Stack.remaining() {
    register void *stkptr asm("sp");

    return (uint32_t) stkptr - (uint32_t) &__stack_start__ - STACK_GUARD_SIZE;
  }


  async command uint32_t Stack.unused() {
    register void *stkptr asm("sp");
    uint32_t *p = (void *) ((uint8_t *) &__stack_start__ + STACK_GUARD_SIZE);

    while (p < (uint32_t *) stkptr) {
      if (*p != STACK_UNUSED)
	break;
      p++;
    }
    return (uint32_t) p - (uint32_t) &__stack_start__ - STACK_GUARD_SIZE;
  }


  /*
   * Return total size of the stack
   */

  async command uint32_t Stack.size() {
    return (uint32_t) &__StackTop__ - (uint32_t) &__stack_start__ - STACK_GUARD_SIZE;
  }
}
