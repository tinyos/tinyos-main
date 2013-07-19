configuration HplDs2411C {
  provides {
    interface GeneralIO as Gpio;
  }
}
implementation {
  components HplMsp430GeneralIOC as Hpl;
  components new Msp430GpioC() as MspGpio;
  MspGpio.HplGeneralIO -> Hpl.Port56;

  Gpio = MspGpio.GeneralIO;
}
