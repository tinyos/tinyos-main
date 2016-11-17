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
 * Basic stack interface.   Simple CPU stack manipulation.  Initilization,
 * checking, and size access.
 *
 * A stack on a small uComputer is a scarce resource and can easily overflow
 * its bounds.   Provisions for setting the stack to an initial value, setting
 * any guard words, and providing for verification are provided by this interface.
 *
 * Setting the stack to an initial value also allows us to see dynamically the
 * stack depth.
 *
 * @author Eric B. Decker
 */

#include "cpu_stack.h"

interface Stack {

  /**
   * Set the stack to its initial state.
   *
   * initilize stack contents to known good value and set the Guard word.
   */
  async command void init();


  /**
   * Check for stack overflow.
   *
   * Verify guard word has not been clobbered.
   *
   * Returns:   0 - no problem.
   *		1 - stack overflow has occured.
   */
  async command bool overflow();


  /**
   * return remaining bytes on the stack.
   *
   * given the current stack pointer, how much more room
   * is there on the stack.
   */
  async command uint32_t remaining();


  /**
   * return number of unused stack bytes.
   *
   * unused bytes are stack bytes that have never been touched.
   */
  async command uint32_t unused();


  /**
   * return size of the stack
   */
  async command uint32_t size();
}
