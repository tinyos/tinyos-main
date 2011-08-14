 
#include "Timer.h"
#include "PrintfUART.h"

module TestGPIOC {
  uses {
    interface Leds;
    interface Boot;
    interface Timer<TMilli> as TestTimer;	
    interface Timer<TMilli> as OffTimer;	
    interface HplMsp430GeneralIO as PinTest1;
  }
}
implementation {  
  void printTitles(){
    printfUART("\n\n");
    printfUART("   ###############################\n");
    printfUART("   #          GPIO TEST          #\n");
    printfUART("   ###############################\n");
    printfUART("\n");
  }

  event void Boot.booted() {
    uint8_t state = 0xFF;
    printfUART_init();
    printTitles();

    /* Prints the available states of resistors */
    printfUART("INVALID [%d] OFF [%d] PULLDOWN [%d] PULLUP [%d]\n\n", 
                MSP430_PORT_RESISTOR_INVALID,MSP430_PORT_RESISTOR_OFF, 
                MSP430_PORT_RESISTOR_PULLDOWN, MSP430_PORT_RESISTOR_PULLUP);

    /* Disable resistor */

    call PinTest1.setResistor(MSP430_PORT_RESISTOR_OFF);
    state = call PinTest1.getResistor();
    if (state == MSP430_PORT_RESISTOR_OFF){ 
      printfUART("Resistor disabled -> %d\n", state);
    } else { 
      printfUART("Failed -> %d\n", state);
    }

    /* Enable pullup resistor */    

    call PinTest1.setResistor(MSP430_PORT_RESISTOR_PULLUP);
    state = call PinTest1.getResistor();
    if (state == MSP430_PORT_RESISTOR_PULLUP){ 
      printfUART("Pullup resistor -> %d\n", state);
    } else {
      printfUART("Failed -> %d\n", state);
    }

    /* slow PWM */

    call PinTest1.makeOutput();
    call PinTest1.clr();
    call TestTimer.startPeriodic(2048);
  }  
  
  event void TestTimer.fired(){   
   call Leds.led2Toggle();
   call PinTest1.set();
   call OffTimer.startOneShot(1024);
  }

  event void OffTimer.fired(){
    call PinTest1.clr();
  }

}
