/// $Id: HplAtm128Timer1C.nc,v 1.2 2010-06-29 22:07:51 scipio Exp $

/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
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
 * - Neither the name of Crossbow Technology nor the names of
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
 * HPL interface to Atmega128 timer 1.
 *
 * @author Martin Turon <mturon@xbow.com>
 * @author David Gay <dgay@intel-research.net>
 */

configuration HplAtm128Timer1C
{
  provides {
    // 16-bit Timers
    interface HplAtm128Timer<uint16_t>   as Timer;
    interface HplAtm128TimerCtrl16       as TimerCtrl;
    interface HplAtm128Capture<uint16_t> as Capture;
    interface HplAtm128Compare<uint16_t> as Compare[uint8_t id];
  }
}
implementation
{
  components HplAtm128Timer0AsyncC, HplAtm128Timer1P;

  Timer = HplAtm128Timer1P;
  TimerCtrl = HplAtm128Timer1P;
  Capture = HplAtm128Timer1P;

  Compare[0] = HplAtm128Timer1P.CompareA; 
  Compare[1] = HplAtm128Timer1P.CompareB;
  Compare[2] = HplAtm128Timer1P.CompareC;

  HplAtm128Timer1P.Timer0Ctrl -> HplAtm128Timer0AsyncC;
  
  components PlatformInterruptC;
  HplAtm128Timer1P.PlatformInterrupt -> PlatformInterruptC;
}
