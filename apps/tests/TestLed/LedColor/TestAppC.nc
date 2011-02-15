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

configuration TestAppC {
} implementation {
  components TestP,
      MainC,
      new TimerMilliC() as TimerC,
      LedC;
      
  TestP.Boot -> MainC;
  TestP.Timer -> TimerC;

// Get access to the definitions that enable specific colors */
#include "PlatformLed.h"

#if defined(PLATFORM_LED_GREEN)
  TestP.Green -> LedC.Green;
#endif // GREEN
#if defined(PLATFORM_LED_RED)
  TestP.Red -> LedC.Red;
#endif // RED
#if defined(PLATFORM_LED_WHITE)
  TestP.White -> LedC.White;
#endif // WHITE
#if defined(PLATFORM_LED_YELLOW)
  TestP.Yellow -> LedC.Yellow;
#endif // YELLOW
#if defined(PLATFORM_LED_ORANGE)
  TestP.Orange -> LedC.Orange;
#endif // ORANGE
#if defined(PLATFORM_LED_BLUE)
  TestP.Blue -> LedC.Blue;
#endif // BLUE
  TestP.MultiLed -> LedC;

  components SerialPrintfC;
}
