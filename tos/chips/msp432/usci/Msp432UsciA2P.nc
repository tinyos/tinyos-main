/*
 * DO NOT MODIFY: This file cloned from Msp432UsciZ9P.nc for A2
*/
configuration Msp432UsciA2P {
  provides {
    interface HplMsp432Usci    as Usci;
    interface HplMsp432UsciInt as Interrupt;
  }
}
implementation {
  components new HplMsp432UsciC((uint32_t) EUSCI_A2, EUSCIA2_IRQn, 0) as UsciC;
  Usci      = UsciC;

  components HplMsp432UsciIntA2P as IsrP;
  Interrupt = IsrP;
}
