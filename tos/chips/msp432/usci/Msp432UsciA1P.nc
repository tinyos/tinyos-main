/*
 * DO NOT MODIFY: This file cloned from Msp432UsciZ9P.nc for A1
*/
configuration Msp432UsciA1P {
  provides {
    interface HplMsp432Usci    as Usci;
    interface HplMsp432UsciInt as Interrupt;
  }
}
implementation {
  components new HplMsp432UsciC((uint32_t) EUSCI_A1, EUSCIA1_IRQn, 0) as UsciC;
  Usci      = UsciC;

  components HplMsp432UsciIntA1P as IsrP;
  Interrupt = IsrP;
}
