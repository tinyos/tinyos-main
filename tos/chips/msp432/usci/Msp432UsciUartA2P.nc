/*
 * DO NOT MODIFY: This file cloned from Msp432UsciUartA0P.nc for A2
*/
configuration Msp432UsciUartA2P {
  provides {
    interface UartStream[uint8_t client];
    interface UartByte[uint8_t client];
    interface Msp432UsciError[uint8_t client];
  }
  uses {
    interface Msp432UsciConfigure[ uint8_t client ];
    interface HplMsp432GeneralIO as URXD;
    interface HplMsp432GeneralIO as UTXD;
  }
}
implementation {

  components Msp432UsciA2P as UsciC;
  components new Msp432UsciUartP() as UartC;

  UartC.Usci -> UsciC;
  UartC.Interrupts -> UsciC.Interrupts[MSP432_USCI_UART];
  UartC.ArbiterInfo -> UsciC;

  Msp432UsciConfigure = UartC;
  ResourceConfigure = UartC;
  UartStream = UartC;
  UartByte = UartC;
  Msp432UsciError = UartC;
  URXD = UartC.URXD;
  UTXD = UartC.UTXD;

  components LocalTimeMilliC;
  UartC.LocalTime_bms -> LocalTimeMilliC;
}
