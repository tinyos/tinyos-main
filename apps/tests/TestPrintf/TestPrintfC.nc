/*
 * "Copyright (c) 2006 Washington University in St. Louis.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL WASHINGTON UNIVERSITY IN ST. LOUIS BE LIABLE TO ANY PARTY
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
 * OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF WASHINGTON
 * UNIVERSITY IN ST. LOUIS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * WASHINGTON UNIVERSITY IN ST. LOUIS SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND WASHINGTON UNIVERSITY IN ST. LOUIS HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS."
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
 * @version $Revision: 1.6 $
 * @date $Date: 2007-08-20 06:08:29 $
 */

#include "printf.h"
module TestPrintfC {
  uses {
    interface Boot;  
    interface Leds;
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
  }
}
implementation {
	
  #define NUM_TIMES_TO_PRINT	5
  uint16_t counter=0;
  uint8_t dummyVar1 = 123;
  uint16_t dummyVar2 = 12345;
  uint32_t dummyVar3 = 1234567890;

  event void Boot.booted() {
    call PrintfControl.start();
  }
  
  event void PrintfControl.startDone(error_t error) {
  	printf("Hi I am writing to you from my TinyOS application!!\n");
  	printf("Here is a uint8: %u\n", dummyVar1);
  	printf("Here is a uint16: %u\n", dummyVar2);
  	printf("Here is a uint32: %ld\n", dummyVar3);
  	call PrintfFlush.flush();
  }

  event void PrintfControl.stopDone(error_t error) {
  	counter = 0;
    call Leds.led2Toggle();
  	printf("This should not be printed...");
  	call PrintfFlush.flush();
  }
  
  event void PrintfFlush.flushDone(error_t error) {
  	if(counter < NUM_TIMES_TO_PRINT) {
      printf("I am now iterating: %d\n", counter);
  	  call PrintfFlush.flush();
    }
    else if(counter == NUM_TIMES_TO_PRINT) {
      printf("This is a really short string...\n");
      printf("I am generating this string to have just less than 250\ncharacters since that is the limit of the size I put on my\nmaximum buffer when I instantiated the PrintfC component.\n");
      printf("Only part of this line should get printed because by writing\nthis sentence, I go over my character limit that the internal Printf buffer can hold.\n");
      call PrintfFlush.flush();
    }
    else call PrintfControl.stop();
    counter++;
  }
}

