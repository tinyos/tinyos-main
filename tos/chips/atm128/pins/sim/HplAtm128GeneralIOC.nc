// $Id: HplAtm128GeneralIOC.nc,v 1.3 2006-11-07 19:30:44 scipio Exp $

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
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPATM128_PORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */

/// @author Martin Turon <mturon@xbow.com>

/**
 * Provide GeneralIO interfaces for all of the ATmega128's pins.
 */

#include <atm128hardware.h>

configuration HplAtm128GeneralIOC
{
  // provides all the ports as raw ports
  provides {
    interface GeneralIO as PortA0;
    interface GeneralIO as PortA1;
    interface GeneralIO as PortA2;
    interface GeneralIO as PortA3;
    interface GeneralIO as PortA4;
    interface GeneralIO as PortA5;
    interface GeneralIO as PortA6;
    interface GeneralIO as PortA7;

    interface GeneralIO as PortB0;
    interface GeneralIO as PortB1;
    interface GeneralIO as PortB2;
    interface GeneralIO as PortB3;
    interface GeneralIO as PortB4;
    interface GeneralIO as PortB5;
    interface GeneralIO as PortB6;
    interface GeneralIO as PortB7;

    interface GeneralIO as PortC0;
    interface GeneralIO as PortC1;
    interface GeneralIO as PortC2;
    interface GeneralIO as PortC3;
    interface GeneralIO as PortC4;
    interface GeneralIO as PortC5;
    interface GeneralIO as PortC6;
    interface GeneralIO as PortC7;

    interface GeneralIO as PortD0;
    interface GeneralIO as PortD1;
    interface GeneralIO as PortD2;
    interface GeneralIO as PortD3;
    interface GeneralIO as PortD4;
    interface GeneralIO as PortD5;
    interface GeneralIO as PortD6;
    interface GeneralIO as PortD7;

    interface GeneralIO as PortE0;
    interface GeneralIO as PortE1;
    interface GeneralIO as PortE2;
    interface GeneralIO as PortE3;
    interface GeneralIO as PortE4;
    interface GeneralIO as PortE5;
    interface GeneralIO as PortE6;
    interface GeneralIO as PortE7;

    interface GeneralIO as PortF0;
    interface GeneralIO as PortF1;
    interface GeneralIO as PortF2;
    interface GeneralIO as PortF3;
    interface GeneralIO as PortF4;
    interface GeneralIO as PortF5;
    interface GeneralIO as PortF6;
    interface GeneralIO as PortF7;

    interface GeneralIO as PortG0;
    interface GeneralIO as PortG1;
    interface GeneralIO as PortG2;
    interface GeneralIO as PortG3;
    interface GeneralIO as PortG4;
  }
}

implementation
{
  components 
  new HplAtm128GeneralIOPortP((uint8_t)ATM128_PORTA, (uint8_t)ATM128_DDRA, (uint8_t)ATM128_PINA) as PortA,
    new HplAtm128GeneralIOPortP((uint8_t)ATM128_PORTB, (uint8_t)ATM128_DDRB, (uint8_t)ATM128_PINB) as PortB,
    new HplAtm128GeneralIOPortP((uint8_t)ATM128_PORTC, (uint8_t)ATM128_DDRC, (uint8_t)ATM128_PINC) as PortC,
    new HplAtm128GeneralIOPortP((uint8_t)ATM128_PORTD, (uint8_t)ATM128_DDRD, (uint8_t)ATM128_PIND) as PortD,
    new HplAtm128GeneralIOPortP((uint8_t)ATM128_PORTE, (uint8_t)ATM128_DDRE, (uint8_t)ATM128_PINE) as PortE,
    new HplAtm128GeneralIOPortP((uint8_t)ATM128_PORTF, (uint8_t)ATM128_DDRF, (uint8_t)ATM128_PINF) as PortF,

  // PortF cannot use sbi, cbi
    new HplAtm128GeneralIOSlowPinP((uint8_t)ATM128_PORTF, (uint8_t)ATM128_DDRF, (uint8_t)ATM128_PINF, 0) as F0,
    new HplAtm128GeneralIOSlowPinP((uint8_t)ATM128_PORTF, (uint8_t)ATM128_DDRF, (uint8_t)ATM128_PINF, 1) as F1,
    new HplAtm128GeneralIOSlowPinP((uint8_t)ATM128_PORTF, (uint8_t)ATM128_DDRF, (uint8_t)ATM128_PINF, 2) as F2,
    new HplAtm128GeneralIOSlowPinP((uint8_t)ATM128_PORTF, (uint8_t)ATM128_DDRF, (uint8_t)ATM128_PINF, 3) as F3,
    new HplAtm128GeneralIOSlowPinP((uint8_t)ATM128_PORTF, (uint8_t)ATM128_DDRF, (uint8_t)ATM128_PINF, 4) as F4,
    new HplAtm128GeneralIOSlowPinP((uint8_t)ATM128_PORTF, (uint8_t)ATM128_DDRF, (uint8_t)ATM128_PINF, 5) as F5,
    new HplAtm128GeneralIOSlowPinP((uint8_t)ATM128_PORTF, (uint8_t)ATM128_DDRF, (uint8_t)ATM128_PINF, 6) as F6,
    new HplAtm128GeneralIOSlowPinP((uint8_t)ATM128_PORTF, (uint8_t)ATM128_DDRF, (uint8_t)ATM128_PINF, 7) as F7,


  // PortG only exposes 5 bits and cannot use sbi, cbi
    new HplAtm128GeneralIOSlowPinP((uint8_t)ATM128_PORTG, (uint8_t)ATM128_DDRG, (uint8_t)ATM128_PING, 0) as G0,
    new HplAtm128GeneralIOSlowPinP((uint8_t)ATM128_PORTG, (uint8_t)ATM128_DDRG, (uint8_t)ATM128_PING, 1) as G1,
    new HplAtm128GeneralIOSlowPinP((uint8_t)ATM128_PORTG, (uint8_t)ATM128_DDRG, (uint8_t)ATM128_PING, 2) as G2,
    new HplAtm128GeneralIOSlowPinP((uint8_t)ATM128_PORTG, (uint8_t)ATM128_DDRG, (uint8_t)ATM128_PING, 3) as G3,
    new HplAtm128GeneralIOSlowPinP((uint8_t)ATM128_PORTG, (uint8_t)ATM128_DDRG, (uint8_t)ATM128_PING, 4) as G4
    ;

  PortA0 = PortA.Pin0;
  PortA1 = PortA.Pin1;
  PortA2 = PortA.Pin2;
  PortA3 = PortA.Pin3;
  PortA4 = PortA.Pin4;
  PortA5 = PortA.Pin5;
  PortA6 = PortA.Pin6;
  PortA7 = PortA.Pin7;

  PortB0 = PortB.Pin0;
  PortB1 = PortB.Pin1;
  PortB2 = PortB.Pin2;
  PortB3 = PortB.Pin3;
  PortB4 = PortB.Pin4;
  PortB5 = PortB.Pin5;
  PortB6 = PortB.Pin6;
  PortB7 = PortB.Pin7;

  PortC0 = PortC.Pin0;
  PortC1 = PortC.Pin1;
  PortC2 = PortC.Pin2;
  PortC3 = PortC.Pin3;
  PortC4 = PortC.Pin4;
  PortC5 = PortC.Pin5;
  PortC6 = PortC.Pin6;
  PortC7 = PortC.Pin7;

  PortD0 = PortD.Pin0;
  PortD1 = PortD.Pin1;
  PortD2 = PortD.Pin2;
  PortD3 = PortD.Pin3;
  PortD4 = PortD.Pin4;
  PortD5 = PortD.Pin5;
  PortD6 = PortD.Pin6;
  PortD7 = PortD.Pin7;

  PortE0 = PortE.Pin0;
  PortE1 = PortE.Pin1;
  PortE2 = PortE.Pin2;
  PortE3 = PortE.Pin3;
  PortE4 = PortE.Pin4;
  PortE5 = PortE.Pin5;
  PortE6 = PortE.Pin6;
  PortE7 = PortE.Pin7;

  PortF0 = PortF.Pin0;
  PortF1 = PortF.Pin1;
  PortF2 = PortF.Pin2;
  PortF3 = PortF.Pin3;
  PortF4 = PortF.Pin4;
  PortF5 = PortF.Pin5;
  PortF6 = PortF.Pin6;
  PortF7 = PortF.Pin7;

  PortG0 = G0;
  PortG1 = G1;
  PortG2 = G2;
  PortG3 = G3;
  PortG4 = G4;
}
