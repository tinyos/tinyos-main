 
#include "PrintfUART.h"

configuration TestBattAppC {}
implementation {
  components MainC, TestBattC as App, LedsC;
  App.Leds -> LedsC;
  App.Boot -> MainC.Boot;

  components new TimerMilliC() as TestTimer;
  App.TestTimer -> TestTimer;

  components new BatteryC();
  App.Battery -> BatteryC.Read;
}


