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
 * Simple test application to test the interruptions (single and 
 * double tap, free fall) of the ADLX345 Accelerometer built-in 
 * Zolertia Z1 motes
 *
 * @author: Antonio Linan <alinan@zolertia.com>
 */

#include "ADXL345.h"
#include "PrintfUART.h"
 
module TestIntADXLC{

  uses interface Boot;
  uses interface Leds;
  uses interface Read<uint8_t> as IntSource; 
  uses interface SplitControl as AccelControl;  
  uses interface Notify<adxlint_state_t> as IntAccel1;
  uses interface Notify<adxlint_state_t> as IntAccel2;
  uses interface ADXL345Control as ADXLControl; 
}

implementation{

  bool source_int2=FALSE;

  void printTitles(){
    printfUART("\n\n");
    printfUART("   ###############################\n");
    printfUART("   #     Z1 ADXL345 Int Test     #\n");
    printfUART("   ###############################\n");
    printfUART("\n");
  }
 
  event void Boot.booted(){
    printfUART_init();
    printTitles();
    call AccelControl.start();
  }
 
  event void IntAccel1.notify(adxlint_state_t val) {
	source_int2=FALSE;
    printfUART("Single tap !!!\n");
	call Leds.led0Toggle();
	call IntSource.read();		//this will clear the interruption
  }
 
  event void IntAccel2.notify(adxlint_state_t val) {
	source_int2=TRUE;
	call IntSource.read();		//this will clear the interruption;
  }
 
  event void AccelControl.startDone(error_t err) {
	call ADXLControl.setInterrups(
		  ADXLINT_DOUBLE_TAP |
		  ADXLINT_SINGLE_TAP | 
		  ADXLINT_FREE_FALL  ); 
  }
 
  event void AccelControl.stopDone(error_t err) { }
 
  event void IntSource.readDone(error_t result, uint8_t data){
    if(source_int2) {
      if(data & ADXLINT_FREE_FALL){
        printfUART("Free-fall !!!\n");
        call Leds.led2Toggle();
      } else {
        printfUART("Double tap !!!\n");
        call Leds.led1Toggle();
      }
    }
  }
 
  event void ADXLControl.setInterruptsDone(error_t error){
    call ADXLControl.setIntMap(ADXLINT_DOUBLE_TAP | ADXLINT_FREE_FALL);
  }
 
  event void ADXLControl.setIntMapDone(error_t error){
    call IntAccel1.enable();
    call IntAccel2.enable();
    call IntSource.read();		//this will clear the interruption
  }
 
  event void ADXLControl.setDurationDone(error_t error) { } //not used
 
  event void ADXLControl.setWindowDone(error_t error) { } //not used
 
  event void ADXLControl.setLatentDone(error_t error) { } //not used
 
  event void ADXLControl.setRegisterDone(error_t error) { } //not used
 
  event void ADXLControl.setRangeDone(error_t error) { }  //not used
 
  event void ADXLControl.setReadAddressDone(error_t error) { }  //not used 
 
}
