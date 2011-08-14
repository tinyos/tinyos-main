 
#include "PrintfUART.h"

configuration TestGPIOAppC {}
implementation {
  components MainC, TestGPIOC as App, LedsC;
  App.Leds -> LedsC;
  App.Boot -> MainC.Boot;

  components new TimerMilliC() as TestTimer;
  App.TestTimer -> TestTimer;

  components new TimerMilliC() as OffTimer;
  App.OffTimer -> OffTimer;

  components HplMsp430GeneralIOC as PinMap;
  App.PinTest1 -> PinMap.Port52;  

}


