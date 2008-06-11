/*
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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

module BusyWaitMicroC
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
