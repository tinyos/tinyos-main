configuration HplADXL345C {
  provides interface GeneralIO as GeneralIO1;
  provides interface GeneralIO as GeneralIO2;
  provides interface GpioInterrupt as GpioInterrupt1;
  provides interface GpioInterrupt as GpioInterrupt2;
}
implementation {
  components HplMsp430GeneralIOC as GeneralIOC;
  components HplMsp430InterruptC as InterruptC;

  components new Msp430GpioC() as ADXL345Int1C;
  ADXL345Int1C -> GeneralIOC.Port16;
  GeneralIO1 = ADXL345Int1C;

  components new Msp430GpioC() as ADXL345Int2C;
  ADXL345Int2C -> GeneralIOC.Port17;
  GeneralIO2 = ADXL345Int2C;

  components new Msp430InterruptC() as InterruptAccel1C;
  InterruptAccel1C.HplInterrupt -> InterruptC.Port16;
  GpioInterrupt1 = InterruptAccel1C.Interrupt;

  components new Msp430InterruptC() as InterruptAccel2C;
  InterruptAccel2C.HplInterrupt -> InterruptC.Port17;
  GpioInterrupt2 = InterruptAccel2C.Interrupt;
  

}