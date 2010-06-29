
/* Copyright (c) 2000-2003 The Regents of the University of California.
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
 * - Neither the name of the copyright holders nor the names of
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

