/*
 * DO NOT MODIFY: This file cloned from Msp432UsciZ9P.nc for B2
*/
configuration Msp432UsciB2P {
  provides {
    interface HplMsp432Usci    as Usci;
    interface HplMsp432UsciInt as Interrupt;
  }
}
implementation {
  components new HplMsp432UsciC((uint32_t) EUSCI_B2, EUSCIB2_IRQn, 1) as UsciC;
  Usci      = UsciC;

  components HplMsp432UsciIntB2P as IsrP;
  Interrupt = IsrP;
}
