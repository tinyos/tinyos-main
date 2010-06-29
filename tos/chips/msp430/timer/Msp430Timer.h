//$Id: Msp430Timer.h,v 1.5 2010-06-29 22:07:45 scipio Exp $

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

//@author Cory Sharp <cssharp@eecs.berkeley.edu>

#ifndef _H_Msp430Timer_h
#define _H_Msp430Timer_h

enum {
  MSP430TIMER_CM_NONE = 0,
  MSP430TIMER_CM_RISING = 1,
  MSP430TIMER_CM_FALLING = 2,
  MSP430TIMER_CM_BOTH = 3,

  MSP430TIMER_STOP_MODE = 0,
  MSP430TIMER_UP_MODE = 1,
  MSP430TIMER_CONTINUOUS_MODE = 2,
  MSP430TIMER_UPDOWN_MODE = 3,

  MSP430TIMER_TACLK = 0,
  MSP430TIMER_TBCLK = 0,
  MSP430TIMER_ACLK = 1,
  MSP430TIMER_SMCLK = 2,
  MSP430TIMER_INCLK = 3,

  MSP430TIMER_CLOCKDIV_1 = 0,
  MSP430TIMER_CLOCKDIV_2 = 1,
  MSP430TIMER_CLOCKDIV_4 = 2,
  MSP430TIMER_CLOCKDIV_8 = 3,
};

typedef struct
{
  int ccifg : 1;    // capture/compare interrupt flag
  int cov : 1;      // capture overflow flag
  int out : 1;      // output value
  int cci : 1;      // capture/compare input value
  int ccie : 1;     // capture/compare interrupt enable
  int outmod : 3;   // output mode
  int cap : 1;      // 1=capture mode, 0=compare mode
  int clld : 2;     // compare latch load
  int scs : 1;      // synchronize capture source
  int ccis : 2;     // capture/compare input select: 0=CCIxA, 1=CCIxB, 2=GND, 3=VCC
  int cm : 2;       // capture mode: 0=none, 1=rising, 2=falling, 3=both
} msp430_compare_control_t;

typedef struct
{
  int taifg : 1;    // timer A interrupt flag
  int taie : 1;     // timer A interrupt enable
  int taclr : 1;    // timer A clear: resets TAR, .id, and .mc
  int _unused0 : 1; // unused
  int mc : 2;       // mode control: 0=stop, 1=up, 2=continuous, 3=up/down
  int id : 2;       // input divisor: 0=/1, 1=/2, 2=/4, 3=/8
  int tassel : 2;   // timer A source select: 0=TxCLK, 1=ACLK, 2=SMCLK, 3=INCLK
  int _unused1 : 6; // unused
} msp430_timer_a_control_t;

typedef struct
{
  int tbifg : 1;    // timer B interrupt flag
  int tbie : 1;     // timer B interrupt enable
  int tbclr : 1;    // timer B clear: resets TAR, .id, and .mc
  int _unused0 : 1; // unused
  int mc : 2;       // mode control: 0=stop, 1=up, 2=continuous, 3=up/down
  int id : 2;       // input divisor: 0=/1, 1=/2, 2=/4, 3=/8
  int tbssel : 2;   // timer B source select: 0=TxCLK, 1=ACLK, 2=SMCLK, 3=INCLK
  int _unused1 : 1; // unused
  int cntl : 2;     // counter length: 0=16-bit, 1=12-bit, 2=10-bit, 3=8-bit
  int tbclgrp : 2;  // tbclx group: 0=independent, 1=0/12/34/56, 2=0/123/456, 3=all
  int _unused2 : 1; // unused
} msp430_timer_b_control_t;

#endif//_H_Msp430Timer_h

