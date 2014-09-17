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
 * Simple test application to read Temp & Humidity values from the ZIGTH11
 * Ziglet, based on the SHT1X sensor.  
 *
 * @author: Antonio Linan <alinan@zolertia.com>
 */
 
#include "Timer.h"
#include "PrintfUART.h"

module TestSht11C {
  uses {
    interface Leds;
    interface Boot;
    interface Timer<TMilli> as TestTimer;	
    interface Read<uint16_t> as Temperature;
    interface Read<uint16_t> as Humidity;
  
  }
}
implementation {  

  uint8_t pass;

  void printTitles(){
    printfUART("\n\n");
  	printfUART("   ###############################\n");
  	printfUART("   #           TEST SHT1X        #\n");
  	printfUART("   ###############################\n");
  	printfUART("\n");
  }

  event void Boot.booted() {
    printfUART_init();
	printTitles();
	call TestTimer.startPeriodic(1024);
  }
  
  event void TestTimer.fired(){
    pass++;
    if (pass % 2 == 0){ 
      call Temperature.read();
    } else {
      call Humidity.read();
    }
  }

  event void Temperature.readDone(error_t error, uint16_t data){
    uint16_t temp;
    if (error == SUCCESS){
     call Leds.led2Toggle();
     temp = (data/10) -400;
    	printfUART("Temp: %d.%d\t", temp/10, temp>>2);
    }
  }

  event void Humidity.readDone(error_t error, uint16_t data){
    uint16_t hum;
    if (error == SUCCESS){
      hum = data*0.0367;
      hum -= 2.0468;
      if (hum>100) hum = 100;
	  call Leds.led2Toggle();
      printfUART("Hum: %d\n", hum);
    }
  }
}





