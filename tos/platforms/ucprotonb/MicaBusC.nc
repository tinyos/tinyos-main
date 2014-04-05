// $Id: MicaBusC.nc,v 1.7 2010/06/15 21:24:16 mmaroti Exp $
/*
 * Copyright (c) 2005-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * A simplistic beginning to providing a standard interface to the
 * mica-family 51-pin bus. Just provides the PW0-PW7 and Int0-3 digital
 * I/O pins and returns the ADC channel number for the ADC pins.
 * @author David Gay
 */

configuration MicaBusC {
  provides {
    interface GeneralIO as PW0;
    interface GeneralIO as PW1;
    interface GeneralIO as PW2;
    interface GeneralIO as PW3;
    interface GeneralIO as PW4;
    interface GeneralIO as PW5;
    interface GeneralIO as PW6;
    interface GeneralIO as PW7;

    interface GeneralIO as Int0;
    interface GeneralIO as Int1;
    interface GeneralIO as Int2;
    interface GeneralIO as Int3;

    /* INT lines used as interrupt source */
    interface GpioInterrupt as Int0_Interrupt;
    interface GpioInterrupt as Int1_Interrupt;
    interface GpioInterrupt as Int2_Interrupt;
    interface GpioInterrupt as Int3_Interrupt;
    
    interface GeneralIO as USART1_CLK;
    interface GeneralIO as USART1_RXD;
    interface GeneralIO as USART1_TXD;

    interface GeneralIO as UART0_RXD;
    interface GeneralIO as UART0_TXD;

    interface GeneralIO as I2C_CLK;
    interface GeneralIO as I2C_DATA;

    interface GeneralIO as Adc1Pin;
    interface GeneralIO as Adc2Pin;
    interface GeneralIO as Adc3Pin;
    interface GeneralIO as Adc4Pin;
    interface GeneralIO as Adc5Pin;
    interface GeneralIO as Adc6Pin;
    interface GeneralIO as Adc7Pin;

    interface GeneralIO as Led1Pin;
    interface GeneralIO as Led2Pin;
    interface GeneralIO as Led3Pin;

    /* Separate interfaces to allow inlining to occur */
    interface MicaBusAdc as Adc0;
    interface MicaBusAdc as Adc1;
    interface MicaBusAdc as Adc2;
    interface MicaBusAdc as Adc3;
    interface MicaBusAdc as Adc4;
    interface MicaBusAdc as Adc5;
    interface MicaBusAdc as Adc6;
    interface MicaBusAdc as Adc7;
  }
}
implementation {
  components HplAtm128GeneralIOC as Pins, MicaBusP;
  components new NoPinC() as NoPW1, new NoPinC() as NoPW7;

  PW0 = Pins.PortE6;
  PW1 = NoPW1;
  PW2 = Pins.PortE7;
  PW3 = Pins.PortG0;
  PW4 = Pins.PortG1;
  PW5 = Pins.PortD4;
  PW6 = Pins.PortE3;//shared with led3
  PW7 = NoPW7; 

  Int0 = Pins.PortE4;
  Int1 = Pins.PortE5;
  Int2 = Pins.PortB7;
  Int3 = Pins.PortB6;
  
  USART1_CLK = Pins.PortD5;
  USART1_RXD = Pins.PortD2;
  USART1_TXD = Pins.PortD3;

  UART0_RXD = Pins.PortE0;
  UART0_TXD = Pins.PortE1;

  I2C_CLK = Pins.PortD0;
  I2C_DATA = Pins.PortD1;

  Adc1Pin = Pins.PortF3;
  Adc2Pin = Pins.PortF2;
  Adc3Pin = Pins.PortF1;
  Adc4Pin = Pins.PortF4;
  Adc5Pin = Pins.PortF5;
  Adc6Pin = Pins.PortF6;
  Adc7Pin = Pins.PortF7;

  Led1Pin = Pins.PortD7;
  Led2Pin = Pins.PortD6;
  Led3Pin = Pins.PortE2;

  components AtmegaExtInterruptC, AtmegaPinChange0C;
  Int0_Interrupt=AtmegaExtInterruptC.GpioInterrupt[4];
  Int1_Interrupt=AtmegaExtInterruptC.GpioInterrupt[5];
  Int2_Interrupt = AtmegaPinChange0C.GpioInterrupt[7];
  Int3_Interrupt = AtmegaPinChange0C.GpioInterrupt[6];

  Adc0 = MicaBusP.Adc0;
  Adc1 = MicaBusP.Adc1;
  Adc2 = MicaBusP.Adc2;
  Adc3 = MicaBusP.Adc3;
  Adc4 = MicaBusP.Adc4;
  Adc5 = MicaBusP.Adc5;
  Adc6 = MicaBusP.Adc6;
  Adc7 = MicaBusP.Adc7;
}
