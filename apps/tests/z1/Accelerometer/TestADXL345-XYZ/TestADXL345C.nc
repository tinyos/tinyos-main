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
 * Simple test application to read at the same time all axis of the 
 * ADXL345 Accelerometer built-in Zolertia Z1 motes
 *
 * @author: Antonio Linan <alinan@zolertia.com>
 */

#include "PrintfUART.h"
#include "ADXL345.h"

module TestADXL345C {
  uses {
    interface Leds;
    interface Boot;
    interface Timer<TMilli> as TestTimer;	
    interface Read<adxl345_readxyt_t> as axis;
    interface HplMsp430GeneralIO as PinTest1;
    interface HplMsp430GeneralIO as PinTest2;
    interface SplitControl as AccelControl;
  }
}
implementation {  
  void printTitles(){
    printfUART("\n\n");
    printfUART("   ###############################\n");
    printfUART("   #       Z1 ADXL345 Test       #\n");
    printfUART("   ###############################\n");
    printfUART("\n");
  }

  event void Boot.booted() {
    uint8_t state = 0;
    printfUART_init();
    printTitles();
    call TestTimer.startPeriodic(1024);
  }
  
  event void TestTimer.fired(){
    call AccelControl.start();
  }

  event void AccelControl.startDone(error_t err) {
    if (err == SUCCESS){
      call axis.read();
    } else {
      printfUART("Bad start\n");
    }
  }
  
  event void AccelControl.stopDone(error_t err) {}
  
  event void axis.readDone(error_t result, adxl345_readxyt_t data){
    if (result == SUCCESS){
      call Leds.led0Toggle();
      printfUART("X [%d] Y [%d] Z [%d]\n", data.x_axis, data.y_axis, data.z_axis);     
    } else {
      printfUART("Error reading axis\n");
    }
  }
  
}





