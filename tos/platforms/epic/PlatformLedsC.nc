#include "hardware.h"

configuration PlatformLedsC {
  provides {
    interface GeneralIO as Led0;
    interface GeneralIO as Led1;
    interface GeneralIO as Led2;
  }
  uses {
    interface Init;
  }
}
implementation {
  components HplMsp430GeneralIOC as GeneralIOC;
  components new Msp430GpioC() as Led0Impl;
  components new Msp430GpioC() as Led1Impl;
  components new Msp430GpioC() as Led2Impl;
  components PlatformP;

  Init = PlatformP.LedsInit;

  Led0 = Led0Impl;
  Led0Impl -> GeneralIOC.Port40;

  Led1 = Led1Impl;
  Led1Impl -> GeneralIOC.Port43;

  Led2 = Led2Impl;
  Led2Impl -> GeneralIOC.Port47;
}
