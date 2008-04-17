
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
 */
 
module Msp430TimerCommonP
{
  provides interface Msp430TimerEvent as VectorTimerA0;
  provides interface Msp430TimerEvent as VectorTimerA1;
  provides interface Msp430TimerEvent as VectorTimerB0;
  provides interface Msp430TimerEvent as VectorTimerB1;
  uses interface HplMsp430InterruptSig as SIGNAL_TIMERA0_VECTOR;
  uses interface HplMsp430InterruptSig as SIGNAL_TIMERA1_VECTOR;
  uses interface HplMsp430InterruptSig as SIGNAL_TIMERB0_VECTOR;
  uses interface HplMsp430InterruptSig as SIGNAL_TIMERB1_VECTOR;
}
implementation
{
  inline async event void SIGNAL_TIMERA0_VECTOR.fired() { signal VectorTimerA0.fired(); }
  inline async event void SIGNAL_TIMERA1_VECTOR.fired() { signal VectorTimerA1.fired(); }
  inline async event void SIGNAL_TIMERB0_VECTOR.fired() { signal VectorTimerB0.fired(); }
  inline async event void SIGNAL_TIMERB1_VECTOR.fired() { signal VectorTimerB1.fired(); }
}

