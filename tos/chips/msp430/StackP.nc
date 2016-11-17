/*
 * Copyright (c) 2010, Eric B. Decker
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
 */

#include "cpu_stack.h"

extern uint16_t _end;			/* last used byte of last segment in RAM (linker) */
extern uint16_t __stack;		/* top of stack */


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
    uint16_t *ptr = &_end;
    register void *stkptr asm("r1");

    *ptr++ = STACK_GUARD;

    while (ptr < (uint16_t *) stkptr)
      *ptr++ = STACK_UNUSED;
  }


  /*
   * Check for stack overflow
   *
   * returns: 0 - all okay
   *	      1 - not so good
   */

  async command bool Stack.overflow() {
    uint16_t *p = &_end;

    return (*p != STACK_GUARD);
  }


  /*
   * Return number of remaining bytes on the stack.
   *
   * Given the current stack pointer, how much space is left.
   */

  async command int16_t Stack.remaining() {
    register void *stkptr asm("r1");

    return (uint16_t) stkptr - (uint16_t) &_end - STACK_GUARD_SIZE;
  }


  async command int16_t Stack.unused() {
    register void *stkptr asm("r1");
    uint16_t *p = (void *) ((uint8_t *) &_end + STACK_GUARD_SIZE);

    while (p < (uint16_t *) stkptr) {
      if (*p != STACK_UNUSED)
	break;
      p++;
    }
    return (uint16_t) p - (uint16_t) &_end - STACK_GUARD_SIZE;
  }


  /*
   * Return total size of the stack
   */

  async command uint16_t Stack.size() {
    return (uint16_t) &__stack - (uint16_t) &_end - STACK_GUARD_SIZE;
  }
}
