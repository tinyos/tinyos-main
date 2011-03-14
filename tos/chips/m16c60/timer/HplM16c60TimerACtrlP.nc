/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Implementation of the HplM16c60TimerACtrl interface.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#include "M16c60Timer.h"

generic module HplM16c60TimerACtrlP (uint8_t timer,
                                      uint16_t mode_addr,
                                      uint16_t taitg_addr,
                                      uint8_t taitg_start_bit)
{
  provides interface HplM16c60TimerACtrl as TimerACtrl;
}
implementation
{
#define mode (*TCAST(volatile uint8_t* ONE, mode_addr))
#define taitg (*TCAST(volatile uint8_t* ONE, taitg_addr))
  inline void UDFBit(uint16_t bit, uint16_t value)
  {
    uint8_t tmp = UDF;
    WRITE_BIT(tmp, bit, value);
    // Move tmp variable into UDF (adress 0x0384)
    asm("mov.b %0,(0x0384)" : : "r"(tmp) );
  }
  
  inline void setTAiTG(uint8_t flag)
  {
    CLR_FLAG(taitg, 0x03 << taitg_start_bit);
    SET_FLAG(taitg, flag << taitg_start_bit);
  }

  async command void TimerACtrl.setTimerMode(st_timer settings)
  {
    uint8_t flags = 0;
    // If timer nr > 1 set "Two-phase pulse signal" bit to zero.
    if (timer > 1)
    {
      UDFBit(timer + 3, 0);
    }
    flags = settings.output_pulse << 2 | settings.gate_func << 3 | settings.count_src << 6;
    mode = flags;
  }

  async command void TimerACtrl.setCounterMode(sta_counter settings)
  {
    uint8_t flags;
    uint8_t TAiTG;
    mode = 1;
    flags = settings.operation_type << 6;
    if (settings.two_phase_pulse_mode && timer > 1)
    {
      uint8_t tmp = timer; // Used to remove left shift warning
      // Set flags
      flags |= 0x04 | settings.two_phase_processing << 7;
      // If two-phase signal procressing is desired UDF TAiP bit must be set.
      UDFBit(timer + 3, 1);
      // Set TAiTGH and TAiTGL in TRGSR to "00b" (TAiIN pin input).
      if (tmp == 0)
        tmp = 1; // This line will never be executed because tmp is always > 1
      CLR_FLAG(TRGSR.BYTE, 0x03 << ((tmp - 1) * 2));
      TAiTG = 0x00;
    }
    else
    {
      flags |= settings.output_pulse << 2 | settings.count_rising_edge << 3 |
          settings.up_down_switch << 4;
      // If two-phase signal procressing is not desired UDF TAiP bit must be cleared.
      // Note this is only availible for timers A2, A3 and A4
      if (timer > 1)
      {
        UDFBit(timer + 3, 0);
      }
      UDFBit(timer, settings.up_count);
      TAiTG = settings.event_source;
    }
    setTAiTG(TAiTG);
    mode |= flags;
  }

  async command void TimerACtrl.setOneShotMode(sta_one_shot settings)
  {
    uint8_t flags;
    mode = 0x02;
    flags = settings.output_pulse << 2 | settings.ext_trigger_rising_edge << 3 | settings.trigger << 4 | settings.count_src << 6;
    setTAiTG(settings.TAiTG_trigger_source);
    mode |= flags;
  }

  async command void TimerACtrl.oneShotFire()
  {
    SET_BIT(ONSF.BYTE, timer);
  }
}
