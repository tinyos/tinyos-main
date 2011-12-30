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
 * Simple test application to read individually the axis of the ADLX345
 * Accelerometer built-in Zolertia Z1 motes
 *
 * @author: Antonio Linan <alinan@zolertia.com>
 */
 
#include "PrintfUART.h"

module TestADXL345C {
  uses {
    interface Leds;
    interface Boot;
    interface Timer<TMilli> as TestTimer;	
    interface Read<uint16_t> as Xaxis;
    interface Read<uint16_t> as Yaxis;    
    interface Read<uint16_t> as Zaxis;
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
      call Xaxis.read();
    } else {
      printfUART("Bad Start\n");
    }
  }
  
  event void AccelControl.stopDone(error_t err) {}
  
  event void Xaxis.readDone(error_t result, uint16_t data){
    if (result == SUCCESS){
      call Leds.led0Toggle();
      printfUART("Xaxis: %d\n", data);     
      call Yaxis.read();
    } else {
      printfUART("Bad X\n");
    }
  }

  event void Yaxis.readDone(error_t result, uint16_t data){
    if (result == SUCCESS){
      call Leds.led1Toggle();
      printfUART("Yaxis: %d\n", data);     
      call Zaxis.read();
    } else {
      printfUART("Bad Y\n");
    }
  }

  event void Zaxis.readDone(error_t result, uint16_t data){
    if (result == SUCCESS){
      call Leds.led2Toggle();
      printfUART("Zaxis: %d\n", data);   
    } else {
      printfUART("Bad Z\n");
    }
  }
  
}





