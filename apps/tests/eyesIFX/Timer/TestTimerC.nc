/*                                  tab:4
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
/**
 *
 **/

#include "Timer.h"
configuration TestTimerC {
}
implementation {
  components Main, TestTimerM
           , new AlarmMilliC() as Timer0
           , new AlarmMilliC() as Timer1
           , new AlarmMilliC() as Timer2
           , new AlarmMilliC() as Timer3
					 , new AlarmMilliC() as Timer4					 					 					 					 
					 , new AlarmMilliC() as Timer5	
					 , new AlarmMilliC() as Timer6	
					 , new AlarmMilliC() as Timer7	
					 , new AlarmMilliC() as Timer8	
           ;

  TestTimerM -> Main.Boot;

  TestTimerM.Timer0 -> Timer0;
	TestTimerM.Timer1 -> Timer1;
	TestTimerM.Timer2 -> Timer2;
	TestTimerM.Timer3 -> Timer3;
	TestTimerM.Timer4 -> Timer4;
	TestTimerM.Timer5 -> Timer5;
	TestTimerM.Timer6 -> Timer6;
	TestTimerM.Timer7 -> Timer7;
	TestTimerM.Timer8 -> Timer8;
}



