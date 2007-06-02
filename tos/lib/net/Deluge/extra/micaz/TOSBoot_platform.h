// $Id: TOSBoot_platform.h,v 1.1 2007-06-02 00:09:15 razvanm Exp $

/*                                                                      tab:2
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

/**
 * @author  Jonathan Hui <jwhui@cs.berkeley.edu>
 */

#ifndef __TOSBOOT_PLATFORM_H__
#define __TOSBOOT_PLATFORM_H__

enum {
  // address of TOSBoot args in internal flash
  TOSBOOT_ARGS_ADDR = 0xff0,
  // number of resets to force golden image
  TOSBOOT_GESTURE_MAX_COUNT = 3,
  // address of the golden image in external flash
  TOSBOOT_GOLDEN_IMG_ADDR = 0x0L,
  // size of each internal program flash page
  TOSBOOT_INT_PAGE_SIZE = SPM_PAGESIZE,
};

enum {
  DELUGE_MIN_ADV_PERIOD_LOG2 = 9,
  DELUGE_QSIZE = 2,
};

#endif
