/*
 * Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 *
 * Copyright (c) 2002-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Busy wait component as per TEP102. Supports waiting for at least some
 * number of microseconds. This functionality should be used sparingly,
 * when the overhead of posting a Timer or Alarm is greater than simply
 * busy waiting.
 *
 * @author David Gay
 */

module BusyWaitMicroC @safe()
{
  provides interface BusyWait<TMicro,uint16_t>;
}
implementation
{
  inline async command void BusyWait.wait(uint16_t dt) {
  /* In most cases (constant arg), the test is elided at compile-time */
  if (dt)
#if MHZ == 1
    {
      dt = (dt + 3) >> 2;
    /* loop takes 4 cycles. */
      asm volatile (
"1:	sbiw	%0,1\n"
"	brne	1b" : "+w" (dt));
    }
#elif MHZ == 2
    {
      dt = (dt + 1) >> 1;
    /* loop takes 4 cycles. */
      asm volatile (
"1:	sbiw	%0,1\n"
"	brne	1b" : "+w" (dt));
    }
#elif MHZ == 4
    /* loop takes 4 cycles. */
    asm volatile (
"1:	sbiw	%0,1\n"
"	brne	1b" : "+w" (dt));
#elif MHZ == 8
    /* loop takes 8 cycles. this is 1uS if running on an internal 8MHz
       clock, and 1.09uS if running on the external crystal. */
    asm volatile (
"1:	sbiw	%0,1\n"
"	adiw	%0,1\n"
"	sbiw	%0,1\n"
"	brne	1b" : "+w" (dt));
#else
#error "Unknown clock rate. MHZ must be defined to one of 1, 2, 4, or 8."
#endif
  }
}
