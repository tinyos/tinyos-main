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
 * App to read the Battery level of Zolertia Z1 motes
 *
 * @author: Antonio Linan <alinan@zolertia.com>
 */

 
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





