// $Id: Atm128Timer.h,v 1.2 2010-06-29 22:07:43 scipio Exp $

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

/*
 * Copyright (c) 2007, Vanderbilt University
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
 */


/*
 * This file contains the configuration constants for the Atmega2560
 * clocks and timers.
 *
 * @author Philip Levis
 * @author Martin Turon
 * @author Janos Sallai <janos.sallai@vanderbilt.edu>
 */

#ifndef _H_Atm128Timer_h
#define _H_Atm128Timer_h

/* Prescaler values for Timer/Counter 2 (8-bit asynchronous ) */
enum {
  ATM128_CLK8_OFF         = 0x0,
  ATM128_CLK8_NORMAL      = 0x1,
  ATM128_CLK8_DIVIDE_8    = 0x2,
  ATM128_CLK8_DIVIDE_32   = 0x3,
  ATM128_CLK8_DIVIDE_64   = 0x4,
  ATM128_CLK8_DIVIDE_128  = 0x5,
  ATM128_CLK8_DIVIDE_256  = 0x6,
  ATM128_CLK8_DIVIDE_1024 = 0x7,
};

/* Prescaler values for Timer/Counter 0 (8-bit) and 1, 3, 4, 5 (16-bit) */
enum {
  ATM128_CLK16_OFF           = 0x0,
  ATM128_CLK16_NORMAL        = 0x1,
  ATM128_CLK16_DIVIDE_8      = 0x2,
  ATM128_CLK16_DIVIDE_64     = 0x3,
  ATM128_CLK16_DIVIDE_256    = 0x4,
  ATM128_CLK16_DIVIDE_1024   = 0x5,
  ATM128_CLK16_EXTERNAL_FALL = 0x6,
  ATM128_CLK16_EXTERNAL_RISE = 0x7,
};

/* Common scales across both 8-bit and 16-bit clocks. */
enum {
    AVR_CLOCK_OFF = 0,
    AVR_CLOCK_ON  = 1,
    AVR_CLOCK_DIVIDE_8 = 2,
};

enum {
    ATM128_TIMER_COMPARE_NORMAL = 0,
    ATM128_TIMER_COMPARE_TOGGLE,
    ATM128_TIMER_COMPARE_CLEAR,
    ATM128_TIMER_COMPARE_SET
};


/* 8-bit Waveform Generation Modes */
enum {
    ATM128_WAVE8_NORMAL = 0,
    ATM128_WAVE8_PWM,
    ATM128_WAVE8_CTC,
    ATM128_WAVE8_PWM_FAST,
};

/* 16-bit Waveform Generation Modes */
enum {
    ATM128_WAVE16_NORMAL = 0,
    ATM128_WAVE16_PWM_8BIT,
    ATM128_WAVE16_PWM_9BIT,
    ATM128_WAVE16_PWM_10BIT,
    ATM128_WAVE16_CTC_COMPARE,
    ATM128_WAVE16_PWM_FAST_8BIT,
    ATM128_WAVE16_PWM_FAST_9BIT,
    ATM128_WAVE16_PWM_FAST_10BIT,
    ATM128_WAVE16_PWM_CAPTURE_LOW,
    ATM128_WAVE16_PWM_COMPARE_LOW,
    ATM128_WAVE16_PWM_CAPTURE_HIGH,
    ATM128_WAVE16_PWM_COMPARE_HIGH,
    ATM128_WAVE16_CTC_CAPTURE,
    ATM128_WAVE16_RESERVED,
    ATM128_WAVE16_PWM_FAST_CAPTURE,
    ATM128_WAVE16_PWM_FAST_COMPARE,
};

/* 8-bit Timer compare settings */
enum {
    ATM128_COMPARE_OFF = 0,  //!< compare disconnected
    ATM128_COMPARE_TOGGLE,   //!< toggle on match (PWM reserved
    ATM128_COMPARE_CLEAR,    //!< clear on match  (PWM downcount)
    ATM128_COMPARE_SET,      //!< set on match    (PWN upcount)
};

/* 8-bit Timer/Counter 0 Control Register A*/
typedef union
{
  uint8_t flat;
  struct {
    uint8_t wgm00 : 1;  //!< Waveform generation mode (low bit)
    uint8_t wgm01 : 1;  //!< Waveform generation mode (high bit)
    uint8_t resv1 : 2;  //!< Compare Match Output
    uint8_t com0b0: 1;  //!< Compare Match Output
    uint8_t com0b1: 1;  //!< Compare Match Output
    uint8_t com0a0: 1;  //!< Compare Match Output
    uint8_t com0a1: 1;  //!< Compare Match Output
  } bits;
} Atm128_TCCR0A_t;

/* 8-bit Timer/Counter 0 Control Register B*/
typedef union
{
  uint8_t flat;
  struct {
    uint8_t cs00  : 1;  //!< Clock Select 0
    uint8_t cs01  : 1;  //!< Clock Select 1
    uint8_t cs02  : 2;  //!< Clock Select 2
    uint8_t wgm02 : 1;  //!< Waveform Generation Mode
    uint8_t resv1 : 2;  //!< Reserved
    uint8_t foc0b : 1;  //!< Force Output Compare B
    uint8_t foc0a : 1;  //!< Force Output Compare A
  } bits;
} Atm128_TCCR0B_t;

/* Timer/Counter 0 Interrupt Mask Register */
typedef union
{
  uint8_t flat;
  struct {
    uint8_t toie0 : 1; //!< Timer/Counter0 Overflow Interrupt Enable
    uint8_t ocie0a: 1; //!< Timer/Counter0 Output Compare Match A Interrupt Enable
    uint8_t ocie0e: 1; //!< Timer/Counter Output Compare Match B Interrupt Enable
    uint8_t resv1 : 5; //!< Reserved
  } bits;
} Atm128_TIMSK0_t;

/* Timer/Counter 0 Interrupt Flag Register*/
typedef union
{
  uint8_t flat;
  struct {
    uint8_t tov0  : 1; //!< Timer/Counter0 Overflow Flag
    uint8_t ocf0a : 1; //!< Timer/Counter 0 Output Compare A Match Flag
    uint8_t ocf0b : 1; //!< Timer/Counter 0 Output Compare B Match Flag
    uint8_t resv1 : 5; //!< Reserved
  } bits;
} Atm128_TIFR0_t;

/* Asynchronous Status Register -- Timer2 */
typedef union
{
  uint8_t flat;
  struct {
    uint8_t tcr2bub: 1;  //!< Timer/Counter Control Register2 Update Busy
    uint8_t tcr2aub: 1;  //!< Timer/Counter Control Register2 Update Busy
    uint8_t ocr2bub: 1;  //!< Output Compare Register2 Update Busy
    uint8_t ocr2aub: 1;  //!< Output Compare Register2 Update Busy
    uint8_t tcn2ub : 1;  //!< Timer/Counter2 Update Busy
    uint8_t as2    : 1;  //!< Asynchronous Timer/Counter2 (off=CLK_IO,on=TOSC1)
    uint8_t exclk  : 1;  //!< Enable External Clock Input
    uint8_t resv1  : 1;  //!< Reserved
  } bits;
} Atm128_ASSR_t;

/* Timer/Counter 2 Control Register A*/
typedef union
{
  uint8_t flat;
  struct {
    uint8_t wgm20 : 1; //!< Waveform Generation Mode
    uint8_t wgm21 : 1; //!< Waveform Generation Mode
    uint8_t resv1 : 2; //!< Reserved
    uint8_t comb: 2; //!< Compare Output Mode for Channel B
    uint8_t coma: 2; //!< Compare Output Mode for Channel A
  } bits;
} Atm128_TCCR2A_t;

/* Timer/Counter 2 Control Register B*/
typedef union
{
  uint8_t flat;
  struct {
    uint8_t cs    : 3; //!< Clock Select
    uint8_t wgm22 : 1; //!< Waveform Generation Mode
    uint8_t resv1 : 2; //!< Reserved
    uint8_t foc2b : 1; //!< Force Output Compare B
    uint8_t foc2a : 1; //!< Force Output Compare A
  } bits;
} Atm128_TCCR2B_t;

/* Timer/Counter 2 Interrupt Mask Register */
typedef union
{
  uint8_t flat;
  struct {
    uint8_t toie : 1; //!< Timer/Counter2 Overflow Interrupt Enable
    uint8_t ociea: 1; //!< Timer/Counter2 Output Compare Match A Interrupt Enable
    uint8_t ocieb: 1; //!< Timer/Counter Output Compare Match B Interrupt Enable
    uint8_t resv1 : 5; //!< Reserved
  } bits;
} Atm128_TIMSK2_t;

/* Timer/Counter 2 Interrupt Flag Register */
typedef union
{
  uint8_t flat;
  struct {
    uint8_t tov  : 1; //!< Timer1 Overflow Flag
    uint8_t ocfa : 1; //!< Timer1 Output Compare Flag A
    uint8_t ocfb : 1; //!< Timer1 Output Compare Flag B
    uint8_t resv1 : 5; //!< Reserved
  } bits;
} Atm128_TIFR2_t;


/* Timer/Counter 1,3,4,5 Control Register A*/
typedef union
{
  uint8_t flat;
  struct {
    uint8_t wgm01  : 2; //!< Waveform Generation Mode
    uint8_t comc   : 2; //!< Compare Output Mode for Channel C
    uint8_t comb   : 2; //!< Compare Output Mode for Channel B
    uint8_t coma   : 2; //!< Compare Output Mode for Channel A
  } bits;
} Atm128_TCCRA_t;

/* Timer/Counter 1,3,4,5 Control Register B*/
typedef union
{
  uint8_t flat;
  struct {
    uint8_t cs    : 3; //!< Clock Select
    uint8_t wgm23 : 2; //!< Waveform Generation Mode
    uint8_t resv1 : 1; //!< Reserved
    uint8_t ices  : 1; //!< Input Capture Edge Select
    uint8_t icnc  : 1; //!< Input Capture Noise Canceler
  } bits;
} Atm128_TCCRB_t;

/* Timer/Counter 1,3,4,5 Control Register C*/
typedef union
{
  uint8_t flat;
  struct {
    uint8_t resv1 : 5; //!< Reserved
    uint8_t focc : 1; //!< Force Output Compare for Channel A
    uint8_t focb : 1; //!< Force Output Compare for Channel A
    uint8_t foca : 1; //!< Force Output Compare for Channel A
  } bits;
} Atm128_TCCRC_t;

/* Timer/Counter 1,3,4,5 Interrupt Mask Register */
typedef union
{
  uint8_t flat;
  struct {
    uint8_t toie : 1; //!< Timer/Counter1 Overflow Interrupt Enable
    uint8_t ociea: 1; //!< Timer/Counter1 Output Compare Match A Interrupt Enable
    uint8_t ocieb: 1; //!< Timer/Counter1 Output Compare Match B Interrupt Enable
    uint8_t ociec: 1; //!< Timer/Counter1 Output Compare Match C Interrupt Enable
    uint8_t resv1: 1; //!< Reserved
    uint8_t icie : 1; //!< Timer/Counter1, Input Capture Interrupt Enable
    uint8_t resv2 : 2; //!< Reserved
  } bits;
} Atm128_TIMSK_t;

/* Timer/Counter 1,3,4,5 Interrupt Flag Register */
typedef union
{
  uint8_t flat;
  struct {
    uint8_t tov  : 1; //!< Timer1 Overflow Flag
    uint8_t ocfa : 1; //!< Timer1 Output Compare Flag A
    uint8_t ocfb : 1; //!< Timer1 Output Compare Flag B
    uint8_t ocfc : 1; //!< Timer1 Output Compare Flag C
    uint8_t resv1: 1; //!< Reserved
    uint8_t icf  : 1; //!< Timer1 Input Capture Flag 
    uint8_t resv2: 2; //!< Reserved
  } bits;
} Atm128_TIFR_t;

/* General Timer/Counter Control Register */
typedef union
{
  uint8_t flat;
  struct {
    uint8_t psrsync: 1; //!< Prescaler Reset for Synchronous Timer/Counters 0,1,3,4,5
    uint8_t psrasy : 1; //!< Prescaler Reset Timer/Counter2
    uint8_t resv1  : 5; //!< Reserved
    uint8_t tsm    : 1; //!< Timer/Counter Synchronization Mode
  } bits;
} Atm128_GTCCR_t;

// Read/Write these 16-bit Timer registers
// Access as bytes.  Read low before high.  Write high before low. 
typedef uint8_t Atm128_TCNT1H_t;  //!< Timer1 Register
typedef uint8_t Atm128_TCNT1L_t;  //!< Timer1 Register
typedef uint8_t Atm128_TCNT3H_t;  //!< Timer3 Register
typedef uint8_t Atm128_TCNT3L_t;  //!< Timer3 Register
typedef uint8_t Atm128_TCNT4H_t;  //!< Timer4 Register
typedef uint8_t Atm128_TCNT4L_t;  //!< Timer4 Register
typedef uint8_t Atm128_TCNT5H_t;  //!< Timer5 Register
typedef uint8_t Atm128_TCNT5L_t;  //!< Timer5 Register

/* Contains value to continuously compare with Timer1 */
typedef uint8_t Atm128_OCR1AH_t;  //!< Output Compare Register 1A
typedef uint8_t Atm128_OCR1AL_t;  //!< Output Compare Register 1A
typedef uint8_t Atm128_OCR1BH_t;  //!< Output Compare Register 1B
typedef uint8_t Atm128_OCR1BL_t;  //!< Output Compare Register 1B
typedef uint8_t Atm128_OCR1CH_t;  //!< Output Compare Register 1C
typedef uint8_t Atm128_OCR1CL_t;  //!< Output Compare Register 1C

/* Contains value to continuously compare with Timer3 */
typedef uint8_t Atm128_OCR3AH_t;  //!< Output Compare Register 3A
typedef uint8_t Atm128_OCR3AL_t;  //!< Output Compare Register 3A
typedef uint8_t Atm128_OCR3BH_t;  //!< Output Compare Register 3B
typedef uint8_t Atm128_OCR3BL_t;  //!< Output Compare Register 3B
typedef uint8_t Atm128_OCR3CH_t;  //!< Output Compare Register 3C
typedef uint8_t Atm128_OCR3CL_t;  //!< Output Compare Register 3C

/* Contains value to continuously compare with Timer4 */
typedef uint8_t Atm128_OCR4AH_t;  //!< Output Compare Register 4A
typedef uint8_t Atm128_OCR4AL_t;  //!< Output Compare Register 4A
typedef uint8_t Atm128_OCR4BH_t;  //!< Output Compare Register 4B
typedef uint8_t Atm128_OCR4BL_t;  //!< Output Compare Register 4B
typedef uint8_t Atm128_OCR4CH_t;  //!< Output Compare Register 4C
typedef uint8_t Atm128_OCR4CL_t;  //!< Output Compare Register 4C

/* Contains value to continuously compare with Timer5 */
typedef uint8_t Atm128_OCR5AH_t;  //!< Output Compare Register 5A
typedef uint8_t Atm128_OCR5AL_t;  //!< Output Compare Register 5A
typedef uint8_t Atm128_OCR5BH_t;  //!< Output Compare Register 5B
typedef uint8_t Atm128_OCR5BL_t;  //!< Output Compare Register 5B
typedef uint8_t Atm128_OCR5CH_t;  //!< Output Compare Register 5C
typedef uint8_t Atm128_OCR5CL_t;  //!< Output Compare Register 5C

/* Contains counter value when event occurs on ICPn pin. */
typedef uint8_t Atm128_ICR1H_t;  //!< Input Capture Register 1
typedef uint8_t Atm128_ICR1L_t;  //!< Input Capture Register 1
typedef uint8_t Atm128_ICR3H_t;  //!< Input Capture Register 3
typedef uint8_t Atm128_ICR3L_t;  //!< Input Capture Register 3
typedef uint8_t Atm128_ICR4H_t;  //!< Input Capture Register 4
typedef uint8_t Atm128_ICR4L_t;  //!< Input Capture Register 4
typedef uint8_t Atm128_ICR5H_t;  //!< Input Capture Register 5
typedef uint8_t Atm128_ICR5L_t;  //!< Input Capture Register 5

/* Resource strings for timer 1 and 3 compare registers */
#define UQ_TIMER1_COMPARE "atm128.timer1"
#define UQ_TIMER3_COMPARE "atm128.timer3" 

#endif //_H_Atm128Timer_h

