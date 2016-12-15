/*
 * DO NOT MODIFY: This file cloned from Msp432UsciZ9P.nc for A0
*/
configuration Msp432UsciA0P {
  provides {
    interface HplMsp432Usci    as Usci;
    interface HplMsp432UsciInt as Interrupt;
  }
}
implementation {
  components new HplMsp432UsciC((uint32_t) EUSCI_A0, EUSCIA0_IRQn, 0) as UsciC;
  Usci      = UsciC;

  components HplMsp432UsciIntA0P as IsrP;
  Interrupt = IsrP;
}
