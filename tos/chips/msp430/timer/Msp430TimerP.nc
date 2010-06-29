
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

#include "msp430regtypes.h"

generic module Msp430TimerP(
  uint16_t TxIV_addr,
  uint16_t TxR_addr,
  uint16_t TxCTL_addr,
  uint16_t TxIFG,
  uint16_t TxCLR,
  uint16_t TxIE,
  uint16_t TxSSEL0,
  uint16_t TxSSEL1,
  bool isClockSourceAsync ) @safe()
{
  provides interface Msp430Timer as Timer;
  provides interface Msp430TimerEvent as Event[uint8_t n];
  uses interface Msp430TimerEvent as Overflow;
  uses interface Msp430TimerEvent as VectorTimerX0;
  uses interface Msp430TimerEvent as VectorTimerX1;
}
implementation
{
  #define TxIV (*TCAST(volatile TYPE_TAIV* ONE, TxIV_addr))
  #define TxR (*TCAST(volatile TYPE_TAR* ONE, TxR_addr))
  #define TxCTL (*TCAST(volatile TYPE_TACTL* ONE, TxCTL_addr))

  async command uint16_t Timer.get()
  {
    // CSS 10 Feb 2006: Brano Kusy notes MSP430 User's Guide, Section 12.2.1,
    // Note says reading a counter may return garbage if its clock source is
    // async.  The noted work around is to take a majority vote.

    if( isClockSourceAsync ) {
      atomic {
        uint16_t t0;
        uint16_t t1=TxR;
        do { t0=t1; t1=TxR; } while( t0 != t1 );
        return t1;
      }
    }
    else {
      return TxR;
    }
  }

  async command bool Timer.isOverflowPending()
  {
    return TxCTL & TxIFG;
  }

  async command void Timer.clearOverflow()
  {
    CLR_FLAG(TxCTL,TxIFG);
  }

  async command void Timer.setMode( int mode )
  {
    TxCTL = (TxCTL & ~(MC1|MC0)) | ((mode<<4) & (MC1|MC0));
  }

  async command int Timer.getMode()
  {
    return (TxCTL & (MC1|MC0)) >> 4;
  }

  async command void Timer.clear()
  {
    TxCTL |= TxCLR;
  }

  async command void Timer.enableEvents()
  {
    TxCTL |= TxIE;
  }

  async command void Timer.disableEvents()
  {
    TxCTL &= ~TxIE;
  }

  async command void Timer.setClockSource( uint16_t clockSource )
  {
    TxCTL = (TxCTL & ~(TxSSEL0|TxSSEL1)) | ((clockSource << 8) & (TxSSEL0|TxSSEL1));
  }

  async command void Timer.setInputDivider( uint16_t inputDivider )
  {
    TxCTL = (TxCTL & ~(ID0|ID1)) | ((inputDivider << 6) & (ID0|ID1));
  }

  async event void VectorTimerX0.fired()
  {
    signal Event.fired[0]();
  }

  async event void VectorTimerX1.fired()
  {
    uint8_t n = TxIV;
    signal Event.fired[ n >> 1 ]();
  }

  async event void Overflow.fired()
  {
    signal Timer.overflow();
  }

  default async event void Timer.overflow()
  {
  }

  default async event void Event.fired[uint8_t n]()
  {
  }
}

