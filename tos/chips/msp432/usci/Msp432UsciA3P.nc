/*
 * DO NOT MODIFY: This file cloned from Msp432UsciZ9P.nc for A3
*/
configuration Msp432UsciA3P {
  provides {
    interface HplMsp432Usci    as Usci;
    interface HplMsp432UsciInt as Interrupt;
  }
}
implementation {
  components new HplMsp432UsciC((uint32_t) EUSCI_A3, EUSCIA3_IRQn, 0) as UsciC;
  Usci      = UsciC;

  components HplMsp432UsciIntA3P as IsrP;
  Interrupt = IsrP;
}
