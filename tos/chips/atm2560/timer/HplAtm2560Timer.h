/*
 * Copyright (c) 2010, University of Szeged
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
 * - Neither the name of the copyright holder nor the names of
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
 *
 * Author: Miklos Maroti
 */

#ifndef HPLATM2560TIMER_H
#define HPLATM2560TIMER_H

// ------- 8-bit timers -------

// constants for HplAtmegaTimer.setMode
enum
{
	// timer control register (TCCR), clock select bits (CS)
	ATM2560_CLK8_OFF         = 0,
	ATM2560_CLK8_NORMAL      = 1,
	ATM2560_CLK8_DIVIDE_8    = 2,
	ATM2560_CLK8_DIVIDE_32   = 3,
	ATM2560_CLK8_DIVIDE_64   = 4,
	ATM2560_CLK8_DIVIDE_128  = 5,
	ATM2560_CLK8_DIVIDE_256  = 6,
	ATM2560_CLK8_DIVIDE_1024 = 7,

	// timer control register (TCCR), wave generation mode (WGM)
	ATM2560_WGM8_NORMAL       = 0 << 3,
	ATM2560_WGM8_PWM          = 1 << 3,
	ATM2560_WGM8_CTC          = 2 << 3,
	ATM2560_WGM8_PWM_FAST     = 3 << 3,
	ATM2560_WGM8_COMPARE_HIGH = 5 << 3,
	ATM2560_WGM8_COMPARE_LOW  = 7 << 3,

	// asynchronous status register (ASSR) clock bits (EXCLK and AS2)
	ATM2560_ASYNC_OFF = 0 << 6,
	ATM2560_ASYNC_ON  = 1 << 6,
	ATM2560_ASYNC_EXT = 3 << 6,
};

// constants for HplAtmegaCompare.setMode
enum
{
	// timer control register (TCCR), compare output mode (COM)
	ATM2560_COM8_OFF = 0, 
	ATM2560_COM8_TOGGLE,
	ATM2560_COM8_CLEAR,
	ATM2560_COM8_SET,
};


// ------- 16-bit timers -------

// constants for HplAtmegaTimer.setMode
enum
{
	// timer control register (TCCR), clock select bits (CS)
	ATM2560_CLK16_OFF           = 0,
	ATM2560_CLK16_NORMAL        = 1,
	ATM2560_CLK16_DIVIDE_8      = 2,
	ATM2560_CLK16_DIVIDE_64     = 3,
	ATM2560_CLK16_DIVIDE_256    = 4,
	ATM2560_CLK16_DIVIDE_1024   = 5,
	ATM2560_CLK16_EXTERNAL_FALL = 6,
	ATM2560_CLK16_EXTERNAL_RISE = 7,

	// timer control register (TCCR), wave generation mode (WGM)
	ATM2560_WGM16_NORMAL           = 0 << 3,
	ATM2560_WGM16_PWM_8BIT         = 1 << 3,
	ATM2560_WGM16_PWM_9BIT         = 2 << 3,
	ATM2560_WGM16_PWM_10BIT        = 3 << 3,
	ATM2560_WGM16_CTC_COMPARE      = 4 << 3,
	ATM2560_WGM16_PWM_FAST_8BIT    = 5 << 3,
	ATM2560_WGM16_PWM_FAST_9BIT    = 6 << 3,
	ATM2560_WGM16_PWM_FAST_10BIT   = 7 << 3,
	ATM2560_WGM16_PWM_CAPTURE_LOW  = 8 << 3,
	ATM2560_WGM16_PWM_COMPARE_LOW  = 9 << 3,
	ATM2560_WGM16_PWM_CAPTURE_HIGH = 10 << 3,
	ATM2560_WGM16_PWM_COMPARE_HIGH = 11 << 3,
	ATM2560_WGM16_CTC_CAPTURE      = 12 << 3,
	ATM2560_WGM16_RESERVED         = 13 << 3,
	ATM2560_WGM16_PWM_FAST_CAPTURE = 14 << 3,
	ATM2560_WGM16_PWM_FAST_COMPARE = 15 << 3,
};

// constants for HplAtmegaCompare.setMode
enum
{
	// timer control register (TCCR), compare output mode (COM)
	ATM2560_COM16_NORMAL = 0,
	ATM2560_COM16_TOGGLE,
	ATM2560_COM16_CLEAR,
	ATM2560_COM16_SET
};

// constants for HplAtmegaCapture.setMode
enum
{
	ATM2560_CAP16_RISING_EDGE = 0x01,
	ATM2560_CAP16_NOISE_CANCEL = 0x02,
};

#endif // HPLATM2560TIMER_H


