/*
 * DO NOT MODIFY: This file cloned from Msp432UsciZ9P.nc for B1
*/
configuration Msp432UsciB1P {
  provides {
    interface HplMsp432Usci    as Usci;
    interface HplMsp432UsciInt as Interrupt;
  }
}
implementation {
  components new HplMsp432UsciC((uint32_t) EUSCI_B1, EUSCIB1_IRQn, 1) as UsciC;
  Usci      = UsciC;

  components HplMsp432UsciIntB1P as IsrP;
  Interrupt = IsrP;
}
