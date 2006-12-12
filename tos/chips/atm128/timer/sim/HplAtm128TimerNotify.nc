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
 * The TOSSIM-specific timer interface needed to notify when the state
 * of the underlying timer has changed. E.g., if a compare is built on top
 * of the timer, but someone sets the counter register, the compare will need
 * adjust its event timing.
 *
 * @date November 22 2005
 *
 * @author Philip Levis <pal@cs.stanford.edu>
 */

// $Id: HplAtm128TimerNotify.nc,v 1.4 2006-12-12 18:23:04 vlahan Exp $/// $Id: HplAtm128Timer2C.nc,


interface HplAtm128TimerNotify {

  /**
   * Signaled whenever the state of the counter has changed. Dependent
   * abstractions should recalculate.
   */
   
  async event void changed();

  /**
   * Basic utility function so the counter itself can specify the
   * ticks pps. */
  
  async command sim_time_t clockTicksPerSec();

}

