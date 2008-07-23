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
 * This is the PrintfC component.  It provides the printf service for printing
 * data over the serial interface using the standard c-style printf command.  
 * Data printed using printf are buffered and only sent over the serial line after
 * the buffer is half full or an explicit call to printfflush() is made.  This 
 * buffer has a maximum size of 250 bytes at present.  This component is wired
 * to a shadowed MainC component so that printf statements can be made anywhere 
 * throughout your code, so long as you include the "printf.h" header file in 
 * every file you wish to use it.  Take a look at the printf tutorial (lesson 15)
 * for more details.
 *
 * The printf service is currently only available for msp430 based motes 
 * (i.e. telos, eyes) and atmega128x based motes (i.e. mica2, micaz, iris).  On the
 * atmega platforms, avr-libc version 1.4 or above must be used.
 */
 
/**
 * @author Kevin Klues <klueska@cs.stanford.edu>
 * @date September 18, 2007
 */
#include "printf.h"

configuration PrintfC {
  provides {
    interface Boot;
  }
  uses interface Boot as MainBoot @exactlyonce();
}
implementation {
  components SerialActiveMessageC;
  components new SerialAMSenderC(AM_PRINTF_MSG);
  components new PrintfQueueC(uint8_t, PRINTF_BUFFER_SIZE) as QueueC;

  components PrintfP;
  components LedsC;
  
  MainBoot = PrintfP.MainBoot;
  Boot = PrintfP.Boot;
  
  PrintfP.SerialControl -> SerialActiveMessageC;
  PrintfP.Queue -> QueueC;
  PrintfP.AMSend -> SerialAMSenderC;
  PrintfP.Packet -> SerialAMSenderC;
  //PrintfP.Leds -> LedsC;
}

