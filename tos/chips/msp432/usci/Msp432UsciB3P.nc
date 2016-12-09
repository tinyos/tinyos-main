/*
 * DO NOT MODIFY: This file cloned from Msp432UsciZ9P.nc for B3
*/
configuration Msp432UsciB3P {
  provides {
    interface HplMsp432Usci    as Usci;
    interface HplMsp432UsciInt as Interrupt;
  }
}
implementation {
  components new HplMsp432UsciC((uint32_t) EUSCI_B3, EUSCIB3_IRQn, 1) as UsciC;
  Usci      = UsciC;

  components HplMsp432UsciIntB3P as IsrP;
  Interrupt = IsrP;
}
