 
#include "PrintfUART.h"

configuration TestBMPAppC {}
implementation {
  components MainC, TestBMPC as App, LedsC;
  App.Leds -> LedsC;
  App.Boot -> MainC.Boot;
  
  components new TimerMilliC() as TestTimer;
  App.TestTimer -> TestTimer;

  components new TimerMilliC() as StartTimer;
  App.StartTimer -> StartTimer;

  components BMP085C;
  App.BMPSwitch -> BMP085C.BMPSwitch;
  App.Pressure -> BMP085C.Pressure;

}


