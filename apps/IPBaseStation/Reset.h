// $Id: Reset.h,v 1.6 2010-04-09 15:01:33 r-studio Exp $

/*									tab:4
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/* 
 * Authors:  Wei Hong
 *           Intel Research Berkeley Lab
 * Date:     7/15/2002
 *
 */

/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */


void resetMote()
{
#if defined(PLATFORM_MICA) || defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_MICAZ) || defined(PLATFORM_IRIS)
    	cli(); 
  	wdt_enable(0); 
  	while (1) { 
  		__asm__ __volatile__("nop" "\n\t" ::);
  	}
#elif defined(PLATFORM_TELOS) || defined(PLATFORM_TELOSB) || defined(PLATFORM_EPIC) || defined(PLATFORM_SHIMMER) || defined(PLATFORM_SHIMMER2) || defined(PLATFORM_SPAN)
        WDTCTL = 0;
#elif defined(PLATFORM_MULLE)
            PRCR.BIT.PRC0 = 1; // Turn off protection on CM registers.
            PRCR.BIT.PRC1 = 1; // Turn off protection on PM registers.
            CM0.BIT.CM0_6 = 1;  
            PM1.BIT.PM1_2 = 1; // Reset on WDT underflow.
            WDTS = 1; // Start watchdog timer.
            PRCR.BIT.PRC0 = 0; // Turn on protection on CM registers.
            PRCR.BIT.PRC1 = 0; // Turn on protection on PM registers.
            while (1); // Wait for underflow in the watchdog timer.
#else
#error "Reset.h not defined/supported for your platform, aborting..."
#endif
}

