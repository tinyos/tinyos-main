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
 * Simple test application to test the TMP102 temperature sensor 
 * built-in Zolertia Z1 motes
 *
 * @author: Antonio Linan <alinan@zolertia.com>
 */
 
 #include "Timer.h"
 #include "PrintfUART.h"

module TestTmp102C {
  uses {
    interface Leds;
    interface Boot;
    interface Timer<TMilli> as TestTimer;	
    interface Read<uint16_t> as TempSensor;
  
  }
}
implementation {  

  void printTitles(){
    printfUART("\n\n");
    printfUART("   ###############################\n");
    printfUART("   #                             #\n");
    printfUART("   #          TMP102 TEST        #\n");
    printfUART("   #                             #\n");
    printfUART("   ###############################\n");
    printfUART("\n");
  }

  event void Boot.booted() {
    printfUART_init();
    printTitles();
    call TestTimer.startPeriodic(1024);
  }
  
  event void TestTimer.fired(){
    call TempSensor.read();
  }

  event void TempSensor.readDone(error_t error, uint16_t data){
    if (error == SUCCESS){
      call Leds.led2Toggle();
      if (data > 2047) data -= (1<<12);
      data *=0.625; 
      printfUART("Temp: %2d.%1.2d\n", data/10, data>>2);
    }
  }
  
}





