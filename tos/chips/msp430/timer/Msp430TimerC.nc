
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

configuration Msp430TimerC
{
  provides interface Msp430Timer as TimerA;
  provides interface Msp430TimerControl as ControlA0;
  provides interface Msp430TimerControl as ControlA1;
  provides interface Msp430TimerControl as ControlA2;
  provides interface Msp430Compare as CompareA0;
  provides interface Msp430Compare as CompareA1;
  provides interface Msp430Compare as CompareA2;
  provides interface Msp430Capture as CaptureA0;
  provides interface Msp430Capture as CaptureA1;
  provides interface Msp430Capture as CaptureA2;

  provides interface Msp430Timer as TimerB;
  provides interface Msp430TimerControl as ControlB0;
  provides interface Msp430TimerControl as ControlB1;
  provides interface Msp430TimerControl as ControlB2;
  provides interface Msp430TimerControl as ControlB3;
  provides interface Msp430TimerControl as ControlB4;
  provides interface Msp430TimerControl as ControlB5;
  provides interface Msp430TimerControl as ControlB6;
  provides interface Msp430Compare as CompareB0;
  provides interface Msp430Compare as CompareB1;
  provides interface Msp430Compare as CompareB2;
  provides interface Msp430Compare as CompareB3;
  provides interface Msp430Compare as CompareB4;
  provides interface Msp430Compare as CompareB5;
  provides interface Msp430Compare as CompareB6;
  provides interface Msp430Capture as CaptureB0;
  provides interface Msp430Capture as CaptureB1;
  provides interface Msp430Capture as CaptureB2;
  provides interface Msp430Capture as CaptureB3;
  provides interface Msp430Capture as CaptureB4;
  provides interface Msp430Capture as CaptureB5;
  provides interface Msp430Capture as CaptureB6;
}
implementation
{
  components new Msp430TimerP( TAIV_, TAR_, TACTL_, TAIFG, TACLR, TAIE,
               TASSEL0, TASSEL1, FALSE ) as Msp430TimerA
           , new Msp430TimerP( TBIV_, TBR_, TBCTL_, TBIFG, TBCLR, TBIE,
               TBSSEL0, TBSSEL1, TRUE ) as Msp430TimerB
           , new Msp430TimerCapComP( TACCTL0_, TACCR0_ ) as Msp430TimerA0
           , new Msp430TimerCapComP( TACCTL1_, TACCR1_ ) as Msp430TimerA1
           , new Msp430TimerCapComP( TACCTL2_, TACCR2_ ) as Msp430TimerA2
           , new Msp430TimerCapComP( TBCCTL0_, TBCCR0_ ) as Msp430TimerB0
           , new Msp430TimerCapComP( TBCCTL1_, TBCCR1_ ) as Msp430TimerB1
           , new Msp430TimerCapComP( TBCCTL2_, TBCCR2_ ) as Msp430TimerB2
           , new Msp430TimerCapComP( TBCCTL3_, TBCCR3_ ) as Msp430TimerB3
           , new Msp430TimerCapComP( TBCCTL4_, TBCCR4_ ) as Msp430TimerB4
           , new Msp430TimerCapComP( TBCCTL5_, TBCCR5_ ) as Msp430TimerB5
           , new Msp430TimerCapComP( TBCCTL6_, TBCCR6_ ) as Msp430TimerB6
           , Msp430TimerCommonP as Common
           ;

  // Timer A
  TimerA = Msp430TimerA.Timer;
  Msp430TimerA.Overflow -> Msp430TimerA.Event[5];
  Msp430TimerA.VectorTimerX0 -> Common.VectorTimerA0;
  Msp430TimerA.VectorTimerX1 -> Common.VectorTimerA1;

  // Timer A0
  ControlA0 = Msp430TimerA0.Control;
  CompareA0 = Msp430TimerA0.Compare;
  CaptureA0 = Msp430TimerA0.Capture;
  Msp430TimerA0.Timer -> Msp430TimerA.Timer;
  Msp430TimerA0.Event -> Msp430TimerA.Event[0];

  // Timer A1
  ControlA1 = Msp430TimerA1.Control;
  CompareA1 = Msp430TimerA1.Compare;
  CaptureA1 = Msp430TimerA1.Capture;
  Msp430TimerA1.Timer -> Msp430TimerA.Timer;
  Msp430TimerA1.Event -> Msp430TimerA.Event[1];

  // Timer A2
  ControlA2 = Msp430TimerA2.Control;
  CompareA2 = Msp430TimerA2.Compare;
  CaptureA2 = Msp430TimerA2.Capture;
  Msp430TimerA2.Timer -> Msp430TimerA.Timer;
  Msp430TimerA2.Event -> Msp430TimerA.Event[2];

  // Timer B
  TimerB = Msp430TimerB.Timer;
  Msp430TimerB.Overflow -> Msp430TimerB.Event[7];
  Msp430TimerB.VectorTimerX0 -> Common.VectorTimerB0;
  Msp430TimerB.VectorTimerX1 -> Common.VectorTimerB1;

  // Timer B0
  ControlB0 = Msp430TimerB0.Control;
  CompareB0 = Msp430TimerB0.Compare;
  CaptureB0 = Msp430TimerB0.Capture;
  Msp430TimerB0.Timer -> Msp430TimerB.Timer;
  Msp430TimerB0.Event -> Msp430TimerB.Event[0];

  // Timer B1
  ControlB1 = Msp430TimerB1.Control;
  CompareB1 = Msp430TimerB1.Compare;
  CaptureB1 = Msp430TimerB1.Capture;
  Msp430TimerB1.Timer -> Msp430TimerB.Timer;
  Msp430TimerB1.Event -> Msp430TimerB.Event[1];

  // Timer B2
  ControlB2 = Msp430TimerB2.Control;
  CompareB2 = Msp430TimerB2.Compare;
  CaptureB2 = Msp430TimerB2.Capture;
  Msp430TimerB2.Timer -> Msp430TimerB.Timer;
  Msp430TimerB2.Event -> Msp430TimerB.Event[2];

  // Timer B3
  ControlB3 = Msp430TimerB3.Control;
  CompareB3 = Msp430TimerB3.Compare;
  CaptureB3 = Msp430TimerB3.Capture;
  Msp430TimerB3.Timer -> Msp430TimerB.Timer;
  Msp430TimerB3.Event -> Msp430TimerB.Event[3];

  // Timer B4
  ControlB4 = Msp430TimerB4.Control;
  CompareB4 = Msp430TimerB4.Compare;
  CaptureB4 = Msp430TimerB4.Capture;
  Msp430TimerB4.Timer -> Msp430TimerB.Timer;
  Msp430TimerB4.Event -> Msp430TimerB.Event[4];

  // Timer B5
  ControlB5 = Msp430TimerB5.Control;
  CompareB5 = Msp430TimerB5.Compare;
  CaptureB5 = Msp430TimerB5.Capture;
  Msp430TimerB5.Timer -> Msp430TimerB.Timer;
  Msp430TimerB5.Event -> Msp430TimerB.Event[5];

  // Timer B6
  ControlB6 = Msp430TimerB6.Control;
  CompareB6 = Msp430TimerB6.Compare;
  CaptureB6 = Msp430TimerB6.Capture;
  Msp430TimerB6.Timer -> Msp430TimerB.Timer;
  Msp430TimerB6.Event -> Msp430TimerB.Event[6];
  
  components HplMsp430InterruptSigP;
  Common.SIGNAL_TIMERA0_VECTOR -> HplMsp430InterruptSigP.SIGNAL_TIMERA0_VECTOR;
  Common.SIGNAL_TIMERA1_VECTOR -> HplMsp430InterruptSigP.SIGNAL_TIMERA1_VECTOR;
  Common.SIGNAL_TIMERB0_VECTOR -> HplMsp430InterruptSigP.SIGNAL_TIMERB0_VECTOR;
  Common.SIGNAL_TIMERB1_VECTOR -> HplMsp430InterruptSigP.SIGNAL_TIMERB1_VECTOR;
}

