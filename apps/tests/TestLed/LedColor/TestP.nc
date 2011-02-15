/* 
 * Copyright (c) 2009-2010 People Power Company
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the People Power Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * PEOPLE POWER CO. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/** Colored LED test.
 *
 * The LEDs supported by the platform will be lit, one at a time for a
 * duration of two seconds, in their spectrum order.  Verify that the
 * color of the lit LED matches the color printed to the serial port.
 *
 * TESTS: MultiLed interface
 * TESTS: Led color interfaces
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com> */

#include <stdio.h>
#include "PlatformLed.h"

module TestP {
  uses {
    interface Boot;
    interface Timer<TMilli> as Timer;
#if defined(PLATFORM_LED_GREEN)
    interface Led as Green;
#endif // GREEN
#if defined(PLATFORM_LED_RED)
    interface Led as Red;
#endif // RED
#if defined(PLATFORM_LED_WHITE)
    interface Led as White;
#endif // WHITE
#if defined(PLATFORM_LED_YELLOW)
    interface Led as Yellow;
#endif // YELLOW
#if defined(PLATFORM_LED_ORANGE)
    interface Led as Orange;
#endif // ORANGE
#if defined(PLATFORM_LED_BLUE)
    interface Led as Blue;
#endif // BLUE
    interface MultiLed;
  }
} implementation {

   enum {
     LC_Red,
     LC_Orange,
     LC_Yellow,
     LC_Green,
     LC_Blue,
     LC_White,
     LC_LIMIT
   };

   enum {
     TIMER_DELAY_BMS = 2048,
   };

   unsigned int color_index;

   task void showColor_task ()
   {
     int delay = TIMER_DELAY_BMS;
     call MultiLed.set(0);
     switch (color_index) {
#if defined(PLATFORM_LED_RED)
       case LC_Red:
         call Red.on();
         printf("Red\r\n");
         break;
#endif // RED
#if defined(PLATFORM_LED_ORANGE)
       case LC_Orange:
         call Orange.on();
         printf("Orange\r\n");
         break;
#endif // ORANGE
#if defined(PLATFORM_LED_YELLOW)
       case LC_Yellow:
         call Yellow.on();
         printf("Yellow\r\n");
         break;
#endif // YELLOW
#if defined(PLATFORM_LED_GREEN)
       case LC_Green:
         call Green.on();
         printf("Green\r\n");
         break;
#endif // GREEN
#if defined(PLATFORM_LED_BLUE)
       case LC_Blue:
         call Blue.on();
         printf("Blue\r\n");
         break;
#endif // BLUE
#if defined(PLATFORM_LED_WHITE)
       case LC_White:
         call White.on();
         printf("White\r\n");
         break;
#endif // WHITE
       default:
         printf("Color index %d not supported on this platform\r\n", color_index);
         delay = 0;
         break;
     }
     if (++color_index == LC_LIMIT) {
       color_index = 0;
     }
     call Timer.startOneShot(delay);
   }

   event void Boot.booted() {
     color_index = 0;
     post showColor_task();
   }
  
   event void Timer.fired() {
     post showColor_task();
   }
  
}
