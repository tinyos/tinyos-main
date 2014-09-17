/*
 * Copyright (c) 2010-2011 DEXMA SENSORS SL
 * Copyright (c) 2011-2014 ZOLERTIA LABS
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
 * Simple test application to test analog phidget sensors
 * http://www.phidgets.com
 *
 * @author: Antonio Linan <alinan@zolertia.com>
 */
 
#include "Timer.h"
#include "PrintfUART.h"

module TestPhidgetC {
  uses {
    interface Leds;
    interface Boot;
    interface Timer<TMilli> as TestTimer;	
    interface Phidgets;
  }
}

implementation {

  void printTitles(){
    printfUART("\n\n");
    printfUART("   ###############################\n");
    printfUART("   #         TEST PHIDGET        #\n");
    printfUART("   ###############################\n");
    printfUART("\n");
  }

  event void Boot.booted() {
    printfUART_init();
    printTitles();

    if (call Phidgets.enable(INPUT_CHANNEL_A7, PHIDGET_TOUCH) != SUCCESS){
      printfUART("Phidget config failed\n");
      return;
    }

    call TestTimer.startPeriodic(512L);
  }

  event void TestTimer.fired(void){
    call Phidgets.read();
  }

  // Print specific sensor information, readable values
  void printPhidgetVal(uint8_t phidget, uint16_t val){
    if (phidget == PHIDGET_VOLT_30VDC){
      printfUART("[Z1] Value: %d\n", (int16_t) val);
      return;
    }

    if (phidget == PHIDGET_TOUCH){
      printfUART("[Z1] %s\n", (val) ? "You touched me\n" : "No touch\n");
      return;
    }

    printfUART("[Z1] Value: %u\n", val);
  }

  event void Phidgets.readDone(error_t error, uint8_t phidget, uint16_t data){
    if (error == SUCCESS){
      printPhidgetVal(phidget, data);
    } else {
      printfUART("[Z1] Error reading the phidget\n");
    }
  }

}





