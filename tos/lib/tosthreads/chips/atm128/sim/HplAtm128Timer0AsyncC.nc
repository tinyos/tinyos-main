/*
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * The TOSSIM implementation of the Atm128 Timer0. It is built from a
 * timer-specific counter component and a generic compare
 * component. The counter component has an additional simulation-only
 * interface to let the compare component know when its state has
 * changed (e.g., TCNTX was set).
 *
 * @date November 22 2005
 *
 * @author Philip Levis <pal@cs.stanford.edu>
 * @author Martin Turon <mturon@xbow.com>
 * @author David Gay <dgay@intel-research.net>
 */

// $Id: HplAtm128Timer0AsyncC.nc,v 1.1 2008-06-12 14:02:20 klueska Exp $/// $Id: HplAtm128Timer2C.nc,

#include <Atm128Timer.h>

configuration HplAtm128Timer0AsyncC
{
  provides {
    // 8-bit Timers
    interface HplAtm128Timer<uint8_t>   as Timer;
    interface HplAtm128TimerCtrl8       as TimerCtrl;
    interface HplAtm128Compare<uint8_t> as Compare;
    interface HplAtm128TimerAsync       as TimerAsync;
  }
}
implementation {
  components HplAtm128Timer0AsyncP;
  Timer = HplAtm128Timer0AsyncP;
  TimerCtrl = HplAtm128Timer0AsyncP;
  Compare = HplAtm128Timer0AsyncP;
  TimerAsync = HplAtm128Timer0AsyncP;
  
  components TinyThreadSchedulerC;
  HplAtm128Timer0AsyncP.ThreadScheduler -> TinyThreadSchedulerC;
}
