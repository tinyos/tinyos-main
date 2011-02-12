#include "hardware.h"
 
configuration PlatformLedsC {
  provides interface GeneralIO as Led0;
  provides interface GeneralIO as Led1;
  provides interface GeneralIO as Led2;
  uses interface Init;
}
implementation
{
  components
    HplMsp430GeneralIOC as GeneralIOC
    , new Msp430GpioC() as Led0Impl
    , new Msp430GpioC() as Led1Impl
    , new Msp430GpioC() as Led2Impl
    ;
  components PlatformP;
 
  Init = PlatformP.LedsInit;
 
  Led0 = Led0Impl;
  //THIS IS FOR THE ZOLERTIA OR TMOTE, CHANGED FOR THE FET LED
  //Led0Impl -> GeneralIOC.Port54;
  Led0Impl -> GeneralIOC.Port54;
  
  Led1 = Led1Impl;
  Led1Impl -> GeneralIOC.Port56;

  Led2 = Led2Impl;
  Led2Impl -> GeneralIOC.Port55;
 
}
