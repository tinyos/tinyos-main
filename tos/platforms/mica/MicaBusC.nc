// $Id: MicaBusC.nc,v 1.7 2010-06-15 21:24:16 mmaroti Exp $
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
  components HplAtm128InterruptC;

  PW0 = Pins.PortC0;
  PW1 = Pins.PortC1;
  PW2 = Pins.PortC2;
  PW3 = Pins.PortC3;
  PW4 = Pins.PortC4;
  PW5 = Pins.PortC5;
  PW6 = Pins.PortC6;
  PW7 = Pins.PortC7;
  Int0 = Pins.PortE4;
  Int1 = Pins.PortE5;
  Int2 = Pins.PortE6;
  Int3 = Pins.PortE7;
  
  USART1_CLK = Pins.PortD5;
  USART1_RXD = Pins.PortD2;
  USART1_TXD = Pins.PortD3;

  components new Atm128GpioInterruptC() as Atm128GpioInterrupt0C;
  Atm128GpioInterrupt0C.Atm128Interrupt->HplAtm128InterruptC.Int4;
  Int0_Interrupt=Atm128GpioInterrupt0C.Interrupt;

  components new Atm128GpioInterruptC() as Atm128GpioInterrupt1C;
  Atm128GpioInterrupt1C.Atm128Interrupt->HplAtm128InterruptC.Int5;
  Int1_Interrupt=Atm128GpioInterrupt1C.Interrupt;

  components new Atm128GpioInterruptC() as Atm128GpioInterrupt2C;
  Atm128GpioInterrupt2C.Atm128Interrupt->HplAtm128InterruptC.Int6;
  Int2_Interrupt=Atm128GpioInterrupt2C.Interrupt;

  components new Atm128GpioInterruptC() as Atm128GpioInterrupt3C;
  Atm128GpioInterrupt3C.Atm128Interrupt->HplAtm128InterruptC.Int7;
  Int3_Interrupt=Atm128GpioInterrupt3C.Interrupt;

  Adc0 = MicaBusP.Adc0;
  Adc1 = MicaBusP.Adc1;
  Adc2 = MicaBusP.Adc2;
  Adc3 = MicaBusP.Adc3;
  Adc4 = MicaBusP.Adc4;
  Adc5 = MicaBusP.Adc5;
  Adc6 = MicaBusP.Adc6;
  Adc7 = MicaBusP.Adc7;
}
