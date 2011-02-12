
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

#error "Msp430DcoCalibP is broken and will incorrectly adjust TimerA because it does not take into account MCU sleep."

module Msp430DcoCalibP
{
  uses interface Msp430Timer as TimerMicro;
  uses interface Msp430Timer as Timer32khz;
}
implementation
{
  uint16_t m_prev;

  enum
  {
    TARGET_DELTA = 2048, // number of 32khz ticks during 65536 ticks at 1mhz
    MAX_DEVIATION = 7, // about 0.35% error
  };

  // this gets executed 32 times a second
  async event void TimerMicro.overflow()
  {
    uint16_t now = call Timer32khz.get();
    uint16_t delta = now - m_prev;
    m_prev = now;

    if( delta > (TARGET_DELTA+MAX_DEVIATION) )
    {
      // too many 32khz ticks means the DCO is running too slow, speed it up
      if( DCOCTL < 0xe0 )
      {
        DCOCTL++;
      }
      else if( (BCSCTL1 & 7) < 7 )
      {
        BCSCTL1++;
        DCOCTL = 96;
      }
    }
    else if( delta < (TARGET_DELTA-MAX_DEVIATION) )
    {
      // too few 32khz ticks means the DCO is running too fast, slow it down
      if( DCOCTL > 0 )
      {
        DCOCTL--;
      }
      else if( (BCSCTL1 & 7) > 0 )
      {
        BCSCTL1--;
        DCOCTL = 128;
      }
    }
  }

  async event void Timer32khz.overflow()
  {
  }
}

