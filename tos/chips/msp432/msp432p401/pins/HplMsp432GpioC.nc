/**
 * Copyright (c) 2016 Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
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
 * Digital pin i/o abstraction, TI MSP432 processors.
 *
 * This is an example HplMsp432GpioC defining pins for the 100 pin
 * PZ package for the msp432p401r chip.  It defines pins in all default
 * positions (default PortMapper settings).
 *
 * If you are using a different configuration for the part, you will need
 * to define an override file.  this file should be named tos/platforms/
 * <platform>/hardware/pins/HplMsp432GpioC.nc
 *
 * @author Eric B. Decker <cire831@gmail.com>
 */

configuration HplMsp432GpioC {
  provides interface HplMsp432Gpio as Port10;
  provides interface HplMsp432Gpio as Port11;
  provides interface HplMsp432Gpio as Port12;
  provides interface HplMsp432Gpio as Port13;
  provides interface HplMsp432Gpio as Port14;
  provides interface HplMsp432Gpio as Port15;
  provides interface HplMsp432Gpio as Port16;
  provides interface HplMsp432Gpio as Port17;

  provides interface HplMsp432Gpio as Port20;
  provides interface HplMsp432Gpio as Port21;
  provides interface HplMsp432Gpio as Port22;
  provides interface HplMsp432Gpio as Port23;
  provides interface HplMsp432Gpio as Port24;
  provides interface HplMsp432Gpio as Port25;
  provides interface HplMsp432Gpio as Port26;
  provides interface HplMsp432Gpio as Port27;

  provides interface HplMsp432Gpio as Port30;
  provides interface HplMsp432Gpio as Port31;
  provides interface HplMsp432Gpio as Port32;
  provides interface HplMsp432Gpio as Port33;
  provides interface HplMsp432Gpio as Port34;
  provides interface HplMsp432Gpio as Port35;
  provides interface HplMsp432Gpio as Port36;
  provides interface HplMsp432Gpio as Port37;

  provides interface HplMsp432Gpio as Port40;
  provides interface HplMsp432Gpio as Port41;
  provides interface HplMsp432Gpio as Port42;
  provides interface HplMsp432Gpio as Port43;
  provides interface HplMsp432Gpio as Port44;
  provides interface HplMsp432Gpio as Port45;
  provides interface HplMsp432Gpio as Port46;
  provides interface HplMsp432Gpio as Port47;

  provides interface HplMsp432Gpio as Port50;
  provides interface HplMsp432Gpio as Port51;
  provides interface HplMsp432Gpio as Port52;
  provides interface HplMsp432Gpio as Port53;
  provides interface HplMsp432Gpio as Port54;
  provides interface HplMsp432Gpio as Port55;
  provides interface HplMsp432Gpio as Port56;
  provides interface HplMsp432Gpio as Port57;

  provides interface HplMsp432Gpio as Port60;
  provides interface HplMsp432Gpio as Port61;
  provides interface HplMsp432Gpio as Port62;
  provides interface HplMsp432Gpio as Port63;
  provides interface HplMsp432Gpio as Port64;
  provides interface HplMsp432Gpio as Port65;
  provides interface HplMsp432Gpio as Port66;
  provides interface HplMsp432Gpio as Port67;

  provides interface HplMsp432Gpio as Port70;
  provides interface HplMsp432Gpio as Port71;
  provides interface HplMsp432Gpio as Port72;
  provides interface HplMsp432Gpio as Port73;
  provides interface HplMsp432Gpio as Port74;
  provides interface HplMsp432Gpio as Port75;
  provides interface HplMsp432Gpio as Port76;
  provides interface HplMsp432Gpio as Port77;

  provides interface HplMsp432Gpio as Port80;
  provides interface HplMsp432Gpio as Port81;
  provides interface HplMsp432Gpio as Port82;
  provides interface HplMsp432Gpio as Port83;
  provides interface HplMsp432Gpio as Port84;
  provides interface HplMsp432Gpio as Port85;
  provides interface HplMsp432Gpio as Port86;
  provides interface HplMsp432Gpio as Port87;

  provides interface HplMsp432Gpio as Port90;
  provides interface HplMsp432Gpio as Port91;
  provides interface HplMsp432Gpio as Port92;
  provides interface HplMsp432Gpio as Port93;
  provides interface HplMsp432Gpio as Port94;
  provides interface HplMsp432Gpio as Port95;
  provides interface HplMsp432Gpio as Port96;
  provides interface HplMsp432Gpio as Port97;

  provides interface HplMsp432Gpio as Port100;
  provides interface HplMsp432Gpio as Port101;
  provides interface HplMsp432Gpio as Port102;
  provides interface HplMsp432Gpio as Port103;
  provides interface HplMsp432Gpio as Port104;
  provides interface HplMsp432Gpio as Port105;

  /*
   * Module functions, will be wired to appropriate pins
   *
   * pins that end with xPM are default Port Mapped pins for the 100 pin
   * part.  If you need them mapped differently then you need a Platform
   * specific override file called HplMsp432GpioC.nc.  ie.
   * tos/platform/<platform>/hardware/pins/HplMsp432GpioC.nc
   *
   * ADC14 is defined in the chip header so we make all the ADC
   * pins ADCx<nn>.
   */
  provides interface HplMsp432Gpio as ADCx00;
  provides interface HplMsp432Gpio as ADCx01;
  provides interface HplMsp432Gpio as ADCx02;
  provides interface HplMsp432Gpio as ADCx03;
  provides interface HplMsp432Gpio as ADCx04;
  provides interface HplMsp432Gpio as ADCx05;
  provides interface HplMsp432Gpio as ADCx06;
  provides interface HplMsp432Gpio as ADCx07;
  provides interface HplMsp432Gpio as ADCx08;
  provides interface HplMsp432Gpio as ADCx09;
  provides interface HplMsp432Gpio as ADCx10;
  provides interface HplMsp432Gpio as ADCx11;
  provides interface HplMsp432Gpio as ADCx12;
  provides interface HplMsp432Gpio as ADCx13;
  provides interface HplMsp432Gpio as ADCx14;
  provides interface HplMsp432Gpio as ADCx15;
  provides interface HplMsp432Gpio as ADCx16;
  provides interface HplMsp432Gpio as ADCx17;
  provides interface HplMsp432Gpio as ADCx18;
  provides interface HplMsp432Gpio as ADCx19;
  provides interface HplMsp432Gpio as ADCx20;
  provides interface HplMsp432Gpio as ADCx21;
  provides interface HplMsp432Gpio as ADCx22;
  provides interface HplMsp432Gpio as ADCx23;

  provides interface HplMsp432Gpio as RTCCLK;
  provides interface HplMsp432Gpio as DMAE0xPM;

  provides interface HplMsp432Gpio as TA0CC0xPM;
  provides interface HplMsp432Gpio as TA0CC1xPM;
  provides interface HplMsp432Gpio as TA0CC2xPM;
  provides interface HplMsp432Gpio as TA0CC3xPM;
  provides interface HplMsp432Gpio as TA0CC4xPM;
  provides interface HplMsp432Gpio as TA0CLKxPM;

  provides interface HplMsp432Gpio as TA1CC0;
  provides interface HplMsp432Gpio as TA1CC1xPM;
  provides interface HplMsp432Gpio as TA1CC2xPM;
  provides interface HplMsp432Gpio as TA1CC3xPM;
  provides interface HplMsp432Gpio as TA1CC4xPM;
  provides interface HplMsp432Gpio as TA1CLKxPM;

  provides interface HplMsp432Gpio as TA2CC0;
  provides interface HplMsp432Gpio as TA2CC1;
  provides interface HplMsp432Gpio as TA2CC2;
  provides interface HplMsp432Gpio as TA2CC3;
  provides interface HplMsp432Gpio as TA2CC4;
  provides interface HplMsp432Gpio as TA2CLK;

  provides interface HplMsp432Gpio as TA3CC0;
  provides interface HplMsp432Gpio as TA3CC1;
  provides interface HplMsp432Gpio as TA3CC2;
  provides interface HplMsp432Gpio as TA3CC3;
  provides interface HplMsp432Gpio as TA3CC4;
  provides interface HplMsp432Gpio as TA3CLK;

  provides interface HplMsp432Gpio as UCA0TXD;
  provides interface HplMsp432Gpio as UCA0RXD;
  provides interface HplMsp432Gpio as UCA0SIMO;
  provides interface HplMsp432Gpio as UCA0SOMI;
  provides interface HplMsp432Gpio as UCA0CLK;
  provides interface HplMsp432Gpio as UCA0STE;

  provides interface HplMsp432Gpio as UCA1TXDxPM;
  provides interface HplMsp432Gpio as UCA1RXDxPM;
  provides interface HplMsp432Gpio as UCA1SIMOxPM;
  provides interface HplMsp432Gpio as UCA1SOMIxPM;
  provides interface HplMsp432Gpio as UCA1CLKxPM;
  provides interface HplMsp432Gpio as UCA1STExPM;

  provides interface HplMsp432Gpio as UCA2TXDxPM;
  provides interface HplMsp432Gpio as UCA2RXDxPM;
  provides interface HplMsp432Gpio as UCA2SIMOxPM;
  provides interface HplMsp432Gpio as UCA2SOMIxPM;
  provides interface HplMsp432Gpio as UCA2CLKxPM;
  provides interface HplMsp432Gpio as UCA2STExPM;

  provides interface HplMsp432Gpio as UCA3TXD;
  provides interface HplMsp432Gpio as UCA3RXD;
  provides interface HplMsp432Gpio as UCA3SIMO;
  provides interface HplMsp432Gpio as UCA3SOMI;
  provides interface HplMsp432Gpio as UCA3CLK;
  provides interface HplMsp432Gpio as UCA3STE;

  provides interface HplMsp432Gpio as UCB0SIMO;
  provides interface HplMsp432Gpio as UCB0SOMI;
  provides interface HplMsp432Gpio as UCB0CLK;
  provides interface HplMsp432Gpio as UCB0STE;
  provides interface HplMsp432Gpio as UCB0SDA;
  provides interface HplMsp432Gpio as UCB0SCL;

  provides interface HplMsp432Gpio as UCB1SIMO;
  provides interface HplMsp432Gpio as UCB1SOMI;
  provides interface HplMsp432Gpio as UCB1CLK;
  provides interface HplMsp432Gpio as UCB1STE;
  provides interface HplMsp432Gpio as UCB1SDA;
  provides interface HplMsp432Gpio as UCB1SCL;

  provides interface HplMsp432Gpio as UCB2SIMOxPM;
  provides interface HplMsp432Gpio as UCB2SOMIxPM;
  provides interface HplMsp432Gpio as UCB2CLKxPM;
  provides interface HplMsp432Gpio as UCB2STExPM;
  provides interface HplMsp432Gpio as UCB2SDAxPM;
  provides interface HplMsp432Gpio as UCB2SCLxPM;

  provides interface HplMsp432Gpio as UCB3SIMO;
  provides interface HplMsp432Gpio as UCB3SOMI;
  provides interface HplMsp432Gpio as UCB3CLK;
  provides interface HplMsp432Gpio as UCB3STE;
  provides interface HplMsp432Gpio as UCB3SDA;
  provides interface HplMsp432Gpio as UCB3SCL;

  provides interface HplMsp432Gpio as UCB3SIMO_10;
  provides interface HplMsp432Gpio as UCB3SOMI_10;
  provides interface HplMsp432Gpio as UCB3CLK_10;
  provides interface HplMsp432Gpio as UCB3STE_10;
  provides interface HplMsp432Gpio as UCB3SDA_10;
  provides interface HplMsp432Gpio as UCB3SCL_10;
}

implementation {
  components new HplMsp432PortP((uint32_t) P1, 1) as xPort1;
  components new HplMsp432PortP((uint32_t) P2, 0) as xPort2;
  components new HplMsp432PortP((uint32_t) P3, 1) as xPort3;
  components new HplMsp432PortP((uint32_t) P4, 0) as xPort4;
  components new HplMsp432PortP((uint32_t) P5, 1) as xPort5;
  components new HplMsp432PortP((uint32_t) P6, 0) as xPort6;
  components new HplMsp432PortP((uint32_t) P7, 1) as xPort7;
  components new HplMsp432PortP((uint32_t) P8, 0) as xPort8;
  components new HplMsp432PortP((uint32_t) P9, 1) as xPort9;
  components new HplMsp432PortP((uint32_t) P10,0) as xPort10;

  Port10        = xPort1.Pin[0];
  Port11        = xPort1.Pin[1];
  Port12        = xPort1.Pin[2];
  Port13        = xPort1.Pin[3];
  Port14        = xPort1.Pin[4];
  Port15        = xPort1.Pin[5];
  Port16        = xPort1.Pin[6];
  Port17        = xPort1.Pin[7];

  UCA0STE       = xPort1.Pin[0];
  UCA0CLK       = xPort1.Pin[1];
  UCA0RXD       = xPort1.Pin[2];
  UCA0SOMI      = xPort1.Pin[2];
  UCA0TXD       = xPort1.Pin[3];
  UCA0SIMO      = xPort1.Pin[3];
  UCB0STE       = xPort1.Pin[4];
  UCB0CLK       = xPort1.Pin[5];
  UCB0SIMO      = xPort1.Pin[6];
  UCB0SDA       = xPort1.Pin[6];
  UCB0SOMI      = xPort1.Pin[7];
  UCB0SCL       = xPort1.Pin[7];

  Port20        = xPort2.Pin[0];
  Port21        = xPort2.Pin[1];
  Port22        = xPort2.Pin[2];
  Port23        = xPort2.Pin[3];
  Port24        = xPort2.Pin[4];
  Port25        = xPort2.Pin[5];
  Port26        = xPort2.Pin[6];
  Port27        = xPort2.Pin[7];

  UCA1STExPM    = xPort2.Pin[0];
  UCA1CLKxPM    = xPort2.Pin[1];
  UCA1RXDxPM    = xPort2.Pin[2];
  UCA1SOMIxPM   = xPort2.Pin[2];
  UCA1TXDxPM    = xPort2.Pin[3];
  UCA1SIMOxPM   = xPort2.Pin[3];
  TA0CC1xPM     = xPort2.Pin[4];
  TA0CC2xPM     = xPort2.Pin[5];
  TA0CC3xPM     = xPort2.Pin[6];
  TA0CC4xPM     = xPort2.Pin[7];

  Port30        = xPort3.Pin[0];
  Port31        = xPort3.Pin[1];
  Port32        = xPort3.Pin[2];
  Port33        = xPort3.Pin[3];
  Port34        = xPort3.Pin[4];
  Port35        = xPort3.Pin[5];
  Port36        = xPort3.Pin[6];
  Port37        = xPort3.Pin[7];

  UCA2STExPM    = xPort3.Pin[0];
  UCA2CLKxPM    = xPort3.Pin[1];
  UCA2RXDxPM    = xPort3.Pin[2];
  UCA2SOMIxPM   = xPort3.Pin[2];
  UCA2TXDxPM    = xPort3.Pin[3];
  UCA2SIMOxPM   = xPort3.Pin[3];
  UCB2STExPM    = xPort3.Pin[4];
  UCB2CLKxPM    = xPort3.Pin[5];
  UCB2SIMOxPM   = xPort3.Pin[6];
  UCB2SDAxPM    = xPort3.Pin[6];
  UCB2SOMIxPM   = xPort3.Pin[7];
  UCB2SCLxPM    = xPort3.Pin[7];

  Port40        = xPort4.Pin[0];
  Port41        = xPort4.Pin[1];
  Port42        = xPort4.Pin[2];
  Port43        = xPort4.Pin[3];
  Port44        = xPort4.Pin[4];
  Port45        = xPort4.Pin[5];
  Port46        = xPort4.Pin[6];
  Port47        = xPort4.Pin[7];

  ADCx13        = xPort4.Pin[0];
  ADCx12        = xPort4.Pin[1];
  TA2CLK        = xPort4.Pin[2];          /* also ACLK */
  ADCx11        = xPort4.Pin[2];
  RTCCLK        = xPort4.Pin[3];          /* also MCLK */
  ADCx10        = xPort4.Pin[3];
  ADCx09        = xPort4.Pin[4];          /* also HSMCLK */
  ADCx08        = xPort4.Pin[5];
  ADCx07        = xPort4.Pin[6];
  ADCx06        = xPort4.Pin[7];

  Port50        = xPort5.Pin[0];
  Port51        = xPort5.Pin[1];
  Port52        = xPort5.Pin[2];
  Port53        = xPort5.Pin[3];
  Port54        = xPort5.Pin[4];
  Port55        = xPort5.Pin[5];
  Port56        = xPort5.Pin[6];
  Port57        = xPort5.Pin[7];

  ADCx05        = xPort5.Pin[0];
  ADCx04        = xPort5.Pin[1];
  ADCx03        = xPort5.Pin[2];
  ADCx02        = xPort5.Pin[3];
  ADCx01        = xPort5.Pin[4];
  ADCx00        = xPort5.Pin[5];
  TA2CC1        = xPort5.Pin[6];          /* Vref+, VeRef+ */
  TA2CC2        = xPort5.Pin[7];          /* Vref-, VeRef- */

  Port60        = xPort6.Pin[0];
  Port61        = xPort6.Pin[1];
  Port62        = xPort6.Pin[2];
  Port63        = xPort6.Pin[3];
  Port64        = xPort6.Pin[4];
  Port65        = xPort6.Pin[5];
  Port66        = xPort6.Pin[6];
  Port67        = xPort6.Pin[7];

  ADCx15        = xPort6.Pin[0];
  ADCx14        = xPort6.Pin[1];
  UCB1STE       = xPort6.Pin[2];
  UCB1CLK       = xPort6.Pin[3];
  UCB1SIMO      = xPort6.Pin[4];
  UCB1SDA       = xPort6.Pin[4];
  UCB1SOMI      = xPort6.Pin[5];
  UCB1SCL       = xPort6.Pin[5];
  TA2CC3        = xPort6.Pin[6];
  UCB3SIMO      = xPort6.Pin[6];          /* also 10.2 */
  UCB3SDA       = xPort6.Pin[6];          /* also 10.2 */
  TA2CC4        = xPort6.Pin[7];
  UCB3SOMI      = xPort6.Pin[7];          /* also 10.3 */
  UCB3SCL       = xPort6.Pin[7];          /* also 10.3 */

  Port70        = xPort7.Pin[0];
  Port71        = xPort7.Pin[1];
  Port72        = xPort7.Pin[2];
  Port73        = xPort7.Pin[3];
  Port74        = xPort7.Pin[4];
  Port75        = xPort7.Pin[5];
  Port76        = xPort7.Pin[6];
  Port77        = xPort7.Pin[7];

  DMAE0xPM      = xPort7.Pin[0];          /* also SMCLKxPM */
  TA0CLKxPM     = xPort7.Pin[1];
  TA1CLKxPM     = xPort7.Pin[2];
  TA0CC0xPM     = xPort7.Pin[3];
  TA1CC4xPM     = xPort7.Pin[4];
  TA1CC3xPM     = xPort7.Pin[5];
  TA1CC2xPM     = xPort7.Pin[6];
  TA1CC1xPM     = xPort7.Pin[7];

  Port80        = xPort8.Pin[0];
  Port81        = xPort8.Pin[1];
  Port82        = xPort8.Pin[2];
  Port83        = xPort8.Pin[3];
  Port84        = xPort8.Pin[4];
  Port85        = xPort8.Pin[5];
  Port86        = xPort8.Pin[6];
  Port87        = xPort8.Pin[7];

  UCB3STE       = xPort8.Pin[0];                /* also 10.0 */
  TA1CC0        = xPort8.Pin[0];
  UCB3CLK       = xPort8.Pin[1];                /* also 10.1 */
  TA2CC0        = xPort8.Pin[1];
  TA3CC2        = xPort8.Pin[2];
  ADCx23        = xPort8.Pin[2];
  TA3CLK        = xPort8.Pin[3];
  ADCx22        = xPort8.Pin[3];
  ADCx21        = xPort8.Pin[4];
  ADCx20        = xPort8.Pin[5];
  ADCx19        = xPort8.Pin[6];
  ADCx18        = xPort8.Pin[7];

  Port90        = xPort9.Pin[0];
  Port91        = xPort9.Pin[1];
  Port92        = xPort9.Pin[2];
  Port93        = xPort9.Pin[3];
  Port94        = xPort9.Pin[4];
  Port95        = xPort9.Pin[5];
  Port96        = xPort9.Pin[6];
  Port97        = xPort9.Pin[7];

  ADCx17        = xPort9.Pin[0];
  ADCx16        = xPort9.Pin[1];
  TA3CC3        = xPort9.Pin[2];
  TA3CC4        = xPort9.Pin[3];
  UCA3STE       = xPort9.Pin[4];
  UCA3CLK       = xPort9.Pin[5];
  UCA3RXD       = xPort9.Pin[6];
  UCA3SOMI      = xPort9.Pin[6];
  UCA3TXD       = xPort9.Pin[7];
  UCA3SIMO      = xPort9.Pin[7];

  Port100       = xPort10.Pin[0];
  Port101       = xPort10.Pin[1];
  Port102       = xPort10.Pin[2];
  Port103       = xPort10.Pin[3];
  Port104       = xPort10.Pin[4];
  Port105       = xPort10.Pin[5];

  UCB3STE_10    = xPort10.Pin[0];         /* duplicate */
  UCB3CLK_10    = xPort10.Pin[1];         /* duplicate */
  UCB3SIMO_10   = xPort10.Pin[2];         /* duplicate */
  UCB3SDA_10    = xPort10.Pin[2];         /* duplicate */
  UCB3SOMI_10   = xPort10.Pin[3];         /* duplicate */
  UCB3SCL_10    = xPort10.Pin[3];         /* duplicate */
  TA3CC0        = xPort10.Pin[4];
  TA3CC1        = xPort10.Pin[5];
}
