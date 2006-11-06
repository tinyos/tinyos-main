
configuration HplMsp430I2C0C {
  
  provides interface HplMsp430I2C;
  
}

implementation {
  
  components HplMsp430I2C0P as HplI2CP;
  HplMsp430I2C = HplI2CP;
  
  components HplMsp430Usart0P as HplUsartP;
  HplUsartP.HplI2C -> HplI2CP;
  HplI2CP.HplUsart -> HplUsartP;
  
  components HplMsp430GeneralIOC as GIO;
  HplI2CP.SIMO -> GIO.SIMO0;
  HplI2CP.UCLK -> GIO.UCLK0;
  
}
