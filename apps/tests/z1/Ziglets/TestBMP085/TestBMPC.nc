 
#include "Timer.h"
#include "PrintfUART.h"

module TestBMPC {
  uses {
    interface Leds;
    interface Boot;
    interface SplitControl as BMPSwitch;
    interface Timer<TMilli> as TestTimer;	
    interface Timer<TMilli> as StartTimer;
    interface Read<uint16_t> as Pressure;
  }
}
implementation {  
  void printTitles(){
    printfUART("\n\n");
    printfUART("   ###############################\n");
    printfUART("   #        BMP085 TEST          #\n");
    printfUART("   ###############################\n");
    printfUART("\n");
  }
 
  event void Boot.booted() {
    printfUART_init();
    printTitles();
    call StartTimer.startOneShot(1024);
  }  
  
  event void StartTimer.fired(){
    call BMPSwitch.start();
  }

  event void BMPSwitch.startDone(error_t err){
    if (err != SUCCESS){
      printfUART("failed XXX\n");
      call BMPSwitch.stop();
    } else {
      call Leds.led0On();
      call TestTimer.startPeriodic(1024);
    }
  }
  
  event void TestTimer.fired(){
    call Pressure.read();
  }
  
  event void BMPSwitch.stopDone(error_t err){
    call StartTimer.startOneShot(1024);
  }
  
  event void Pressure.readDone(error_t error, uint16_t data){
    if (error == SUCCESS){
      int16_t buff = (int16_t) data;
      printfUART("Pressure: %d.%2d\n", data/10, data>>2);
    } else {
      call BMPSwitch.start();
    }
  }

  // event void Temp.readDone(error_t error, int16_t data){ }
  // event void Altitude.readDone(error_t error, uint16_t data){ }
}
