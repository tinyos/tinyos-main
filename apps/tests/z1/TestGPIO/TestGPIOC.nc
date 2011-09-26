/*
 * Copyright (c) 2011 ZOLERTIA LABS
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Simple application to test the GPIO pins of the Z1 mote, by configuring
 * the pull-up resistors and starting a PWM signal.
 *
 * @author: Antonio Linan <alinan@zolertia.com>
 */

 
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
