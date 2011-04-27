/*
 * Copyright (c) 2011, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Janos Sallai
 */ 
 
 /**
 Configure the timer subsystem such that TimerA=ACLK (32kHz) and 
 TimerB=SMCLK/4 (1MHz).
 */
 
configuration Msp430TimerMicroMapC
{
  provides interface Msp430Timer[ uint8_t id ];
  provides interface Msp430TimerControl[ uint8_t id ];
  provides interface Msp430Compare[ uint8_t id ];
}
implementation
{
  components Msp430TimerC;

  // Timer B0 is used for SFD capture on the CC2420 radio

  Msp430Timer[0] = Msp430TimerC.TimerB;
  Msp430TimerControl[0] = Msp430TimerC.ControlB1;
  Msp430Compare[0] = Msp430TimerC.CompareB1;

  Msp430Timer[1] = Msp430TimerC.TimerB;
  Msp430TimerControl[1] = Msp430TimerC.ControlB2;
  Msp430Compare[1] = Msp430TimerC.CompareB2;

  Msp430Timer[2] = Msp430TimerC.TimerB;
  Msp430TimerControl[2] = Msp430TimerC.ControlB3;
  Msp430Compare[2] = Msp430TimerC.CompareB3;

  Msp430Timer[3] = Msp430TimerC.TimerB;
  Msp430TimerControl[3] = Msp430TimerC.ControlB4;
  Msp430Compare[3] = Msp430TimerC.CompareB4;

  Msp430Timer[4] = Msp430TimerC.TimerB;
  Msp430TimerControl[4] = Msp430TimerC.ControlB5;
  Msp430Compare[4] = Msp430TimerC.CompareB5;

  Msp430Timer[5] = Msp430TimerC.TimerB;
  Msp430TimerControl[5] = Msp430TimerC.ControlB6;
  Msp430Compare[5] = Msp430TimerC.CompareB6;
}

