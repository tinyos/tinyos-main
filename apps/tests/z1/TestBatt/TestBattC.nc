 
#include "Timer.h"
#include "PrintfUART.h"

module TestBattC {
  uses {
    interface Leds;
    interface Boot;
    interface Timer<TMilli> as TestTimer;	
    interface Read<uint16_t> as Battery;
  }
}

implementation {  

  uint32_t aux = 0;
  uint16_t battery = 0;

  void printTitles(){
    printfUART("\n\n");
    printfUART("   ###############################\n");
    printfUART("   #         Test Battery        #\n");
    printfUART("   ###############################\n");
    printfUART("\n");
  }
  
  event void Boot.booted() {
    printfUART_init();
    printTitles();
    call TestTimer.startPeriodic(512);
  }
 
  event void TestTimer.fired(){
    call Battery.read();
  }

  event void Battery.readDone(error_t error, uint16_t batt){
    if(error==SUCCESS) {
      aux = batt;
      aux *= 300;
      aux /= 4096;
      battery = aux;
      printfUART("Battery [%d]\n", battery);
    }
  }

}





