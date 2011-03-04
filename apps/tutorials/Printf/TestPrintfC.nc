/*
 * Copyright (c) 2006 Washington University in St. Louis.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
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
 
/**
 *
 * This application is used to test the basic functionality of the printf service.  
 * It is initiated by calling the start() command of the SplitControl interface 
 * provided by the PrintfC component.  After starting the printf service, calls to 
 * the standard c-style printf command are made to print various strings of text 
 * over the serial line.  Only upon calling PrintfFlush.flush() does the data 
 * actually get sent out over the serial line.
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.3 $
 * @date $Date: 2010-06-29 22:07:40 $
 */

#include "printf.h"
module TestPrintfC {
  uses {
    interface Boot;
    interface Timer<TMilli>;
  }
}
implementation {
	
  uint8_t dummyVar1 = 123;
  uint16_t dummyVar2 = 12345;
  uint32_t dummyVar3 = 1234567890;

  event void Boot.booted() {
    call Timer.startPeriodic(1000);	
  }

  event void Timer.fired() {
  	printf("Hi I am writing to you from my TinyOS application!!\n");
  	printf("Here is a uint8: %u\n", dummyVar1);
  	printf("Here is a uint16: %u\n", dummyVar2);
  	printf("Here is a uint32: %ld\n", dummyVar3);
  	printfflush();
  }
}

