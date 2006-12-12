// $Id: Atm128Timer.h,v 1.4 2006-12-12 18:23:04 vlahan Exp $

/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */

/*
 * This file contains the configuration constants for the Atmega128
 * clocks and timers.
 *
 * @author Philip Levis
 * @author Martin Turon
 * @date   September 21 2005
 */

#ifndef _H_Atm128Timer_h
#define _H_Atm128Timer_h

//====================== 8 bit Timers ==================================

// Timer0 and Timer2 are 8-bit timers.

/* 8-bit Timer0 clock source select bits CS02, CS01, CS0 (page 103,
   ATmega128L data sheet Rev. 2467M-AVR-11/04 */
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

/* 8-bit Waveform Generation Modes */
enum {
    ATM128_WAVE8_NORMAL = 0,
    ATM128_WAVE8_PWM,
    ATM128_WAVE8_CTC,
    ATM128_WAVE8_PWM_FAST,
};

/* 8-bit Timer compare settings */
enum {
    ATM128_COMPARE_OFF = 0,  //!< compare disconnected
    ATM128_COMPARE_TOGGLE,   //!< toggle on match (PWM reserved
    ATM128_COMPARE_CLEAR,    //!< clear on match  (PWM downcount)
    ATM128_COMPARE_SET,      //!< set on match    (PWN upcount)
};

/* 8-bit Timer Control Register */
typedef union
{
  uint8_t flat;
  struct {
    uint8_t cs    : 3;  //!< Clock Source Select
    uint8_t wgm1  : 1;  //!< Waveform generation mode (high bit)
    uint8_t com   : 2;  //!< Compare Match Output
    uint8_t wgm0  : 1;  //!< Waveform generation mode (low bit)
    uint8_t foc   : 1;  //!< Force Output Compare
  } bits;
} Atm128TimerControl_t;

typedef Atm128TimerControl_t Atm128_TCCR0_t;  //!< Timer0 Control Register
typedef uint8_t Atm128_TCNT0_t;               //!< Timer0 Control Register
typedef uint8_t Atm128_OCR0_t;         //!< Timer0 Output Compare Register

typedef Atm128TimerControl_t Atm128_TCCR2_t;  //!< Timer2 Control Register
typedef uint8_t Atm128_TCNT2_t;               //!< Timer2 Control Register
typedef uint8_t Atm128_OCR2_t;         //!< Timer2 Output Compare Register
// Timer2 shares compare lines with Timer1C

/* Asynchronous Status Register -- Timer0 */
typedef union
{
  uint8_t flat;
  struct {
    uint8_t tcr0ub : 1;  //!< Timer0 Control Resgister Update Busy
    uint8_t ocr0ub : 1;  //!< Timer0 Output Compare Register Update Busy
    uint8_t tcn0ub : 1;  //!< Timer0 Update Busy
    uint8_t as0    : 1;  //!< Asynchronous Timer/Counter (off=CPU,on=32KHz osc)
    uint8_t rsvd   : 4;  //!< Reserved
  } bits;
} Atm128_ASSR_t;

/* Timer/Counter Interrupt Mask Register */
typedef union
{
  uint8_t flat;
  struct {
    uint8_t toie0 : 1; //!< Timer0 Overflow Interrupt Enable
    uint8_t ocie0 : 1; //!< Timer0 Output Compare Interrupt Enable
    uint8_t toie1 : 1; //!< Timer1 Overflow Interrupt Enable
    uint8_t ocie1b: 1; //!< Timer1 Output Compare B Interrupt Enable
    uint8_t ocie1a: 1; //!< Timer1 Output Compare A Interrupt Enable
    uint8_t ticie1: 1; //!< Timer1 Input Capture Enable
    uint8_t toie2 : 1; //!< Timer2 Overflow Interrupt Enable
    uint8_t ocie2 : 1; //!< Timer2 Output Compare Interrupt Enable
  } bits;
} Atm128_TIMSK_t;
// + Note: Contains some 16-bit Timer flags

/* Timer/Counter Interrupt Flag Register */
typedef union
{
  uint8_t flat;
  struct {
    uint8_t tov0  : 1; //!< Timer0 Overflow Flag
    uint8_t ocf0  : 1; //!< Timer0 Output Compare Flag
    uint8_t tov1  : 1; //!< Timer1 Overflow Flag
    uint8_t ocf1b : 1; //!< Timer1 Output Compare B Flag
    uint8_t ocf1a : 1; //!< Timer1 Output Compare A Flag
    uint8_t icf1  : 1; //!< Timer1 Input Capture Flag 
    uint8_t tov2  : 1; //!< Timer2 Overflow Flag
    uint8_t ocf2  : 1; //!< Timer2 Output Compare Flag
  } bits;
} Atm128_TIFR_t;
// + Note: Contains some 16-bit Timer flags

/* Timer/Counter Interrupt Flag Register */
typedef union
{
  uint8_t flat;
  struct {
    uint8_t psr321 : 1; //!< Prescaler Reset Timer1,2,3
    uint8_t psr0   : 1; //!< Prescaler Reset Timer0
    uint8_t pud    : 1; //!< 
    uint8_t acme   : 1; //!< 
    uint8_t rsvd   : 3; //!< Reserved
    uint8_t tsm    : 1; //!< Timer/Counter Synchronization Mode
  } bits;
} Atm128_SFIOR_t;


//====================== 16 bit Timers ==================================

// Timer1 and Timer3 are both 16-bit, and have three compare channels: (A,B,C)

enum {
    ATM128_TIMER_COMPARE_NORMAL = 0,
    ATM128_TIMER_COMPARE_TOGGLE,
    ATM128_TIMER_COMPARE_CLEAR,
    ATM128_TIMER_COMPARE_SET
};

/* Timer/Counter Control Register A Type */
typedef union
{
  uint8_t flat;
  struct {
    uint8_t wgm10 : 2;   //!< Waveform generation mode
    uint8_t comC  : 2;   //!< Compare Match Output C
    uint8_t comB  : 2;   //!< Compare Match Output B
    uint8_t comA  : 2;   //!< Compare Match Output A
  } bits;
} Atm128TimerCtrlCompare_t;

/* Timer1 Compare Control Register A */
typedef Atm128TimerCtrlCompare_t Atm128_TCCR1A_t;

/* Timer3 Compare Control Register A */
typedef Atm128TimerCtrlCompare_t Atm128_TCCR3A_t;

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

/* Timer/Counter Control Register B Type */
typedef union
{
  uint8_t flat;
  struct {
    uint8_t cs    : 3;   //!< Clock Source Select
    uint8_t wgm32 : 2;   //!< Waveform generation mode
    uint8_t rsvd  : 1;   //!< Reserved
    uint8_t ices1 : 1;   //!< Input Capture Edge Select (1=rising, 0=falling)
    uint8_t icnc1 : 1;   //!< Input Capture Noise Canceler
  } bits;
} Atm128TimerCtrlCapture_t;

/* Timer1 Control Register B */
typedef Atm128TimerCtrlCapture_t Atm128_TCCR1B_t;

/* Timer3 Control Register B */
typedef Atm128TimerCtrlCapture_t Atm128_TCCR3B_t;

/* Timer/Counter Control Register C Type */
typedef union
{
  uint8_t flat;
  struct {
    uint8_t rsvd  : 5;   //!< Reserved
    uint8_t focC  : 1;   //!< Force Output Compare Channel C
    uint8_t focB  : 1;   //!< Force Output Compare Channel B
    uint8_t focA  : 1;   //!< Force Output Compare Channel A
  } bits;
} Atm128TimerCtrlClock_t;

/* Timer1 Control Register B */
typedef Atm128TimerCtrlClock_t Atm128_TCCR1C_t;

/* Timer3 Control Register B */
typedef Atm128TimerCtrlClock_t Atm128_TCCR3C_t;

// Read/Write these 16-bit Timer registers according to p.112:
// Access as bytes.  Read low before high.  Write high before low. 
typedef uint8_t Atm128_TCNT1H_t;  //!< Timer1 Register
typedef uint8_t Atm128_TCNT1L_t;  //!< Timer1 Register
typedef uint8_t Atm128_TCNT3H_t;  //!< Timer3 Register
typedef uint8_t Atm128_TCNT3L_t;  //!< Timer3 Register

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

/* Contains counter value when event occurs on ICPn pin. */
typedef uint8_t Atm128_ICR1H_t;  //!< Input Capture Register 1
typedef uint8_t Atm128_ICR1L_t;  //!< Input Capture Register 1
typedef uint8_t Atm128_ICR3H_t;  //!< Input Capture Register 3
typedef uint8_t Atm128_ICR3L_t;  //!< Input Capture Register 3

/* Extended Timer/Counter Interrupt Mask Register */
typedef union
{
  uint8_t flat;
  struct {
    uint8_t ocie1c: 1; //!< Timer1 Output Compare C Interrupt Enable
    uint8_t ocie3c: 1; //!< Timer3 Output Compare C Interrupt Enable
    uint8_t toie3 : 1; //!< Timer3 Overflow Interrupt Enable
    uint8_t ocie3b: 1; //!< Timer3 Output Compare B Interrupt Enable
    uint8_t ocie3a: 1; //!< Timer3 Output Compare A Interrupt Enable
    uint8_t ticie3: 1; //!< Timer3 Input Capture Interrupt Enable
    uint8_t rsvd  : 2; //!< Timer2 Output Compare Interrupt Enable
  } bits;
} Atm128_ETIMSK_t;

/* Extended Timer/Counter Interrupt Flag Register */
typedef union
{
  uint8_t flat;
  struct {
    uint8_t ocf1c : 1; //!< Timer1 Output Compare C Flag
    uint8_t ocf3c : 1; //!< Timer3 Output Compare C Flag
    uint8_t tov3  : 1; //!< Timer/Counter Overflow Flag
    uint8_t ocf3b : 1; //!< Timer3 Output Compare B Flag
    uint8_t ocf3a : 1; //!< Timer3 Output Compare A Flag
    uint8_t icf3  : 1; //!< Timer3 Input Capture Flag 
    uint8_t rsvd  : 2; //!< Reserved
  } bits;
} Atm128_ETIFR_t;

/* Resource strings for timer 1 and 3 compare registers */
#define UQ_TIMER1_COMPARE "atm128.timer1"
#define UQ_TIMER3_COMPARE "atm128.timer3"

#endif //_H_Atm128Timer_h

