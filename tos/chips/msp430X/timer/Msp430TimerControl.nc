
/* "Copyright (c) 2000-2003 The Regents of the University of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 * @author Joe Polastre
 */

#include "Msp430Timer.h"

interface Msp430TimerControl
{
  async command msp430_compare_control_t getControl();
  async command bool isInterruptPending();
  async command void clearPendingInterrupt();

  async command void setControl(msp430_compare_control_t control);
  async command void setControlAsCompare();
  
  /** 
  * Sets the timer in capture mode.
  * @param cm configures the capture to occur on none, rising, falling or rising_and_falling edges
  * Msp430Timer.h has convenience definitions:
  * MSP430TIMER_CM_NONE, MSP430TIMER_CM_RISING, MSP430TIMER_CM_FALLING, MSP430TIMER_CM_BOTH
  */ 
  async command void setControlAsCapture(uint8_t cm);

  async command void enableEvents();
  async command void disableEvents();
  async command bool areEventsEnabled();

}

