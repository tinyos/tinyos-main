
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
 */

/**
 * HPL for the TI MSP430 family of microprocessors. This provides an
 * abstraction for general-purpose I/O.
 *
 * @author Joe Polastre
 */

configuration HplMsp430GeneralIOC
{
  // provides all the ports as raw ports
#ifdef __msp430_have_port1
  provides interface HplMsp430GeneralIO as Port10;
  provides interface HplMsp430GeneralIO as Port11;
  provides interface HplMsp430GeneralIO as Port12;
  provides interface HplMsp430GeneralIO as Port13;
  provides interface HplMsp430GeneralIO as Port14;
  provides interface HplMsp430GeneralIO as Port15;
  provides interface HplMsp430GeneralIO as Port16;
  provides interface HplMsp430GeneralIO as Port17;
#endif

#ifdef __msp430_have_port2
  provides interface HplMsp430GeneralIO as Port20;
  provides interface HplMsp430GeneralIO as Port21;
  provides interface HplMsp430GeneralIO as Port22;
  provides interface HplMsp430GeneralIO as Port23;
  provides interface HplMsp430GeneralIO as Port24;
  provides interface HplMsp430GeneralIO as Port25;
  provides interface HplMsp430GeneralIO as Port26;
  provides interface HplMsp430GeneralIO as Port27;
#endif

#ifdef __msp430_have_port3
  provides interface HplMsp430GeneralIO as Port30;
  provides interface HplMsp430GeneralIO as Port31;
  provides interface HplMsp430GeneralIO as Port32;
  provides interface HplMsp430GeneralIO as Port33;
  provides interface HplMsp430GeneralIO as Port34;
  provides interface HplMsp430GeneralIO as Port35;
  provides interface HplMsp430GeneralIO as Port36;
  provides interface HplMsp430GeneralIO as Port37;
#endif

#ifdef __msp430_have_port4
  provides interface HplMsp430GeneralIO as Port40;
  provides interface HplMsp430GeneralIO as Port41;
  provides interface HplMsp430GeneralIO as Port42;
  provides interface HplMsp430GeneralIO as Port43;
  provides interface HplMsp430GeneralIO as Port44;
  provides interface HplMsp430GeneralIO as Port45;
  provides interface HplMsp430GeneralIO as Port46;
  provides interface HplMsp430GeneralIO as Port47;
#endif

#ifdef __msp430_have_port5
  provides interface HplMsp430GeneralIO as Port50;
  provides interface HplMsp430GeneralIO as Port51;
  provides interface HplMsp430GeneralIO as Port52;
  provides interface HplMsp430GeneralIO as Port53;
  provides interface HplMsp430GeneralIO as Port54;
  provides interface HplMsp430GeneralIO as Port55;
  provides interface HplMsp430GeneralIO as Port56;
  provides interface HplMsp430GeneralIO as Port57;
#endif

#ifdef __msp430_have_port6
  provides interface HplMsp430GeneralIO as Port60;
  provides interface HplMsp430GeneralIO as Port61;
  provides interface HplMsp430GeneralIO as Port62;
  provides interface HplMsp430GeneralIO as Port63;
  provides interface HplMsp430GeneralIO as Port64;
  provides interface HplMsp430GeneralIO as Port65;
  provides interface HplMsp430GeneralIO as Port66;
  provides interface HplMsp430GeneralIO as Port67;
#endif

  // provides special ports explicitly 
  // this section of HplMsp430GeneralIOC supports the F14x series
#ifdef __msp430x14x
  provides interface HplMsp430GeneralIO as STE0;
  provides interface HplMsp430GeneralIO as SIMO0;
  provides interface HplMsp430GeneralIO as SOMI0;
  provides interface HplMsp430GeneralIO as UCLK0;
  provides interface HplMsp430GeneralIO as UTXD0;
  provides interface HplMsp430GeneralIO as URXD0;

  provides interface HplMsp430GeneralIO as STE1;
  provides interface HplMsp430GeneralIO as SIMO1;
  provides interface HplMsp430GeneralIO as SOMI1;
  provides interface HplMsp430GeneralIO as UCLK1;
  provides interface HplMsp430GeneralIO as UTXD1;
  provides interface HplMsp430GeneralIO as URXD1;

  provides interface HplMsp430GeneralIO as ADC0;
  provides interface HplMsp430GeneralIO as ADC1;
  provides interface HplMsp430GeneralIO as ADC2;
  provides interface HplMsp430GeneralIO as ADC3;
  provides interface HplMsp430GeneralIO as ADC4;
  provides interface HplMsp430GeneralIO as ADC5;
  provides interface HplMsp430GeneralIO as ADC6;
  provides interface HplMsp430GeneralIO as ADC7;
#endif

  // this section of HplMsp430GeneralIOC supports the F16x series
#ifdef __msp430x16x
  provides interface HplMsp430GeneralIO as STE0;
  provides interface HplMsp430GeneralIO as SIMO0;
  provides interface HplMsp430GeneralIO as SDA;
  provides interface HplMsp430GeneralIO as SOMI0;
  provides interface HplMsp430GeneralIO as UCLK0;
  provides interface HplMsp430GeneralIO as SCL;
  provides interface HplMsp430GeneralIO as UTXD0;
  provides interface HplMsp430GeneralIO as URXD0;

  provides interface HplMsp430GeneralIO as STE1;
  provides interface HplMsp430GeneralIO as SIMO1;
  provides interface HplMsp430GeneralIO as SOMI1;
  provides interface HplMsp430GeneralIO as UCLK1;
  provides interface HplMsp430GeneralIO as UTXD1;
  provides interface HplMsp430GeneralIO as URXD1;

  provides interface HplMsp430GeneralIO as ADC0;
  provides interface HplMsp430GeneralIO as ADC1;
  provides interface HplMsp430GeneralIO as ADC2;
  provides interface HplMsp430GeneralIO as ADC3;
  provides interface HplMsp430GeneralIO as ADC4;
  provides interface HplMsp430GeneralIO as ADC5;
  provides interface HplMsp430GeneralIO as ADC6;
  provides interface HplMsp430GeneralIO as ADC7;

  provides interface HplMsp430GeneralIO as DAC0;
  provides interface HplMsp430GeneralIO as DAC1;

  provides interface HplMsp430GeneralIO as SVSIN;
  provides interface HplMsp430GeneralIO as SVSOUT;
#endif
}
implementation
{
  components 
#ifdef __msp430_have_port1
    new HplMsp430GeneralIOP(P1IN_, P1OUT_, P1DIR_, P1SEL_, 0) as P10,
    new HplMsp430GeneralIOP(P1IN_, P1OUT_, P1DIR_, P1SEL_, 1) as P11,
    new HplMsp430GeneralIOP(P1IN_, P1OUT_, P1DIR_, P1SEL_, 2) as P12,
    new HplMsp430GeneralIOP(P1IN_, P1OUT_, P1DIR_, P1SEL_, 3) as P13,
    new HplMsp430GeneralIOP(P1IN_, P1OUT_, P1DIR_, P1SEL_, 4) as P14,
    new HplMsp430GeneralIOP(P1IN_, P1OUT_, P1DIR_, P1SEL_, 5) as P15,
    new HplMsp430GeneralIOP(P1IN_, P1OUT_, P1DIR_, P1SEL_, 6) as P16,
    new HplMsp430GeneralIOP(P1IN_, P1OUT_, P1DIR_, P1SEL_, 7) as P17,
#endif

#ifdef __msp430_have_port2
    new HplMsp430GeneralIOP(P2IN_, P2OUT_, P2DIR_, P2SEL_, 0) as P20,
    new HplMsp430GeneralIOP(P2IN_, P2OUT_, P2DIR_, P2SEL_, 1) as P21,
    new HplMsp430GeneralIOP(P2IN_, P2OUT_, P2DIR_, P2SEL_, 2) as P22,
    new HplMsp430GeneralIOP(P2IN_, P2OUT_, P2DIR_, P2SEL_, 3) as P23,
    new HplMsp430GeneralIOP(P2IN_, P2OUT_, P2DIR_, P2SEL_, 4) as P24,
    new HplMsp430GeneralIOP(P2IN_, P2OUT_, P2DIR_, P2SEL_, 5) as P25,
    new HplMsp430GeneralIOP(P2IN_, P2OUT_, P2DIR_, P2SEL_, 6) as P26,
    new HplMsp430GeneralIOP(P2IN_, P2OUT_, P2DIR_, P2SEL_, 7) as P27,
#endif

#ifdef __msp430_have_port3
    new HplMsp430GeneralIOP(P3IN_, P3OUT_, P3DIR_, P3SEL_, 0) as P30,
    new HplMsp430GeneralIOP(P3IN_, P3OUT_, P3DIR_, P3SEL_, 1) as P31,
    new HplMsp430GeneralIOP(P3IN_, P3OUT_, P3DIR_, P3SEL_, 2) as P32,
    new HplMsp430GeneralIOP(P3IN_, P3OUT_, P3DIR_, P3SEL_, 3) as P33,
    new HplMsp430GeneralIOP(P3IN_, P3OUT_, P3DIR_, P3SEL_, 4) as P34,
    new HplMsp430GeneralIOP(P3IN_, P3OUT_, P3DIR_, P3SEL_, 5) as P35,
    new HplMsp430GeneralIOP(P3IN_, P3OUT_, P3DIR_, P3SEL_, 6) as P36,
    new HplMsp430GeneralIOP(P3IN_, P3OUT_, P3DIR_, P3SEL_, 7) as P37,
#endif

#ifdef __msp430_have_port4
    new HplMsp430GeneralIOP(P4IN_, P4OUT_, P4DIR_, P4SEL_, 0) as P40,
    new HplMsp430GeneralIOP(P4IN_, P4OUT_, P4DIR_, P4SEL_, 1) as P41,
    new HplMsp430GeneralIOP(P4IN_, P4OUT_, P4DIR_, P4SEL_, 2) as P42,
    new HplMsp430GeneralIOP(P4IN_, P4OUT_, P4DIR_, P4SEL_, 3) as P43,
    new HplMsp430GeneralIOP(P4IN_, P4OUT_, P4DIR_, P4SEL_, 4) as P44,
    new HplMsp430GeneralIOP(P4IN_, P4OUT_, P4DIR_, P4SEL_, 5) as P45,
    new HplMsp430GeneralIOP(P4IN_, P4OUT_, P4DIR_, P4SEL_, 6) as P46,
    new HplMsp430GeneralIOP(P4IN_, P4OUT_, P4DIR_, P4SEL_, 7) as P47,
#endif

#ifdef __msp430_have_port5
    new HplMsp430GeneralIOP(P5IN_, P5OUT_, P5DIR_, P5SEL_, 0) as P50,
    new HplMsp430GeneralIOP(P5IN_, P5OUT_, P5DIR_, P5SEL_, 1) as P51,
    new HplMsp430GeneralIOP(P5IN_, P5OUT_, P5DIR_, P5SEL_, 2) as P52,
    new HplMsp430GeneralIOP(P5IN_, P5OUT_, P5DIR_, P5SEL_, 3) as P53,
    new HplMsp430GeneralIOP(P5IN_, P5OUT_, P5DIR_, P5SEL_, 4) as P54,
    new HplMsp430GeneralIOP(P5IN_, P5OUT_, P5DIR_, P5SEL_, 5) as P55,
    new HplMsp430GeneralIOP(P5IN_, P5OUT_, P5DIR_, P5SEL_, 6) as P56,
    new HplMsp430GeneralIOP(P5IN_, P5OUT_, P5DIR_, P5SEL_, 7) as P57,
#endif

#ifdef __msp430_have_port6
    new HplMsp430GeneralIOP(P6IN_, P6OUT_, P6DIR_, P6SEL_, 0) as P60,
    new HplMsp430GeneralIOP(P6IN_, P6OUT_, P6DIR_, P6SEL_, 1) as P61,
    new HplMsp430GeneralIOP(P6IN_, P6OUT_, P6DIR_, P6SEL_, 2) as P62,
    new HplMsp430GeneralIOP(P6IN_, P6OUT_, P6DIR_, P6SEL_, 3) as P63,
    new HplMsp430GeneralIOP(P6IN_, P6OUT_, P6DIR_, P6SEL_, 4) as P64,
    new HplMsp430GeneralIOP(P6IN_, P6OUT_, P6DIR_, P6SEL_, 5) as P65,
    new HplMsp430GeneralIOP(P6IN_, P6OUT_, P6DIR_, P6SEL_, 6) as P66,
    new HplMsp430GeneralIOP(P6IN_, P6OUT_, P6DIR_, P6SEL_, 7) as P67
#endif
    ;

#ifdef __msp430_have_port1
  Port10 = P10;
  Port11 = P11;
  Port12 = P12;
  Port13 = P13;
  Port14 = P14;
  Port15 = P15;
  Port16 = P16;
  Port17 = P17;
#endif

#ifdef __msp430_have_port2
  Port20 = P20;
  Port21 = P21;
  Port22 = P22;
  Port23 = P23;
  Port24 = P24;
  Port25 = P25;
  Port26 = P26;
  Port27 = P27;
#endif

#ifdef __msp430_have_port3
  Port30 = P30;
  Port31 = P31;
  Port32 = P32;
  Port33 = P33;
  Port34 = P34;
  Port35 = P35;
  Port36 = P36;
  Port37 = P37;
#endif

#ifdef __msp430_have_port4
  Port40 = P40;
  Port41 = P41;
  Port42 = P42;
  Port43 = P43;
  Port44 = P44;
  Port45 = P45;
  Port46 = P46;
  Port47 = P47;
#endif
 
#ifdef __msp430_have_port5
  Port50 = P50;
  Port51 = P51;
  Port52 = P52;
  Port53 = P53;
  Port54 = P54;
  Port55 = P55;
  Port56 = P56;
  Port57 = P57;
#endif

#ifdef __msp430_have_port6
  Port60 = P60;
  Port61 = P61;
  Port62 = P62;
  Port63 = P63;
  Port64 = P64;
  Port65 = P65;
  Port66 = P66;
  Port67 = P67;
#endif

#ifdef __msp430x14x
  STE0 = P30;
  SIMO0 = P31;
  SOMI0 = P32;
  UCLK0 = P33;
  UTXD0 = P34;
  URXD0 = P35;

  STE1 = P50;
  SIMO1 = P51;
  SOMI1 = P52;
  UCLK1 = P53;
  UTXD1 = P36;
  URXD1 = P37;

  ADC0 = P60;
  ADC1 = P61;
  ADC2 = P62;
  ADC3 = P63;
  ADC4 = P64;
  ADC5 = P65;
  ADC6 = P66;
  ADC7 = P67;
#endif

#ifdef __msp430x16x
  STE0 = P30;
  SIMO0 = P31;
  SDA = P31;
  SOMI0 = P32;
  UCLK0 = P33;
  SCL = P33;
  UTXD0 = P34;
  URXD0 = P35;

  STE1 = P50;
  SIMO1 = P51;
  SOMI1 = P52;
  UCLK1 = P53;
  UTXD1 = P36;
  URXD1 = P37;

  ADC0 = P60;
  ADC1 = P61;
  ADC2 = P62;
  ADC3 = P63;
  ADC4 = P64;
  ADC5 = P65;
  ADC6 = P66;
  ADC7 = P67;

  DAC0 = P66;
  DAC1 = P67;

  SVSIN = P67;
  SVSOUT = P57;
#endif
}

