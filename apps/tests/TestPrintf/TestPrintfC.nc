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
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.2 $
 * @date $Date: 2006-11-06 11:56:51 $
 */

module TestPrintfC {
  uses {
    interface Boot;  
    interface Leds;
    interface SplitControl as PrintfControl;
    interface PrintfFlush;
  }
}
implementation {
	
  #define NUM_TIMES_TO_PRINT	100
  uint16_t counter=0;
  uint32_t dummyVar = 345678;

  event void Boot.booted() {
    call PrintfControl.start();
  }
  
  event void PrintfControl.startDone(error_t error) {
  	printf("Hi my name is Kevin Klues and I am writing to you from my telos mote\n");
  	printf("Here is a uint8: %hd\n", 123);
  	printf("Here is a uint16: %d\n", 12345);
  	printf("Here is a uint32: %ld\n", 1234567890);
  	call PrintfFlush.flush();
  }

  event void PrintfControl.stopDone(error_t error) {
  	counter = 0;
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
      printf("I am generating this string to have just less than 250 characters since that is the limit of the size I put on my maximum buffer when I instantiated the PrintfC component.\n");
      printf("Only part of this line should get printed because by writing this sentence, I go over my character limit that the internal Printf buffer can hold.  If I were to flush before trying to write this, or increase my buffer size when I instantiate my PrintfC component to 1000, we would see this line too\n");
      call PrintfFlush.flush();
    }
    else call PrintfControl.stop();
    counter++;
  }
}

