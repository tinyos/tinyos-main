configuration Msp432UsciZ9P {
  provides {
    interface HplMsp432Usci    as Usci;
    interface HplMsp432UsciInt as Interrupt;
  }
}
implementation {
  components new HplMsp432UsciC((uint32_t) EUSCI_Z9, EUSCIZ9_IRQn, Z9_TYPE) as UsciC;
  Usci      = UsciC;

  components HplMsp432UsciIntZ9P as IsrP;
  Interrupt = IsrP;
}
