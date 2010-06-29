/*
 * Copyright (c) 2008 Johns Hopkins University.
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
 * Blink is a simple application used to test the basic functionality of
 * TOSThreads using dynamic threads rather than static threads.
 *
 * Upon a successful burn, you should see LED0 flashing with a period of every
 * 200ms, and LED1 and LED2 flashing in unison with a period of 1000ms.
 *
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

module BlinkC {
  uses {
    interface Boot;
    interface Leds;
    interface DynamicThread;
  }
}

implementation {
  tosthread_t blink1;
  tosthread_t blink2;
  tosthread_t blink3;
  uint16_t a1 = 1;
  uint16_t a2 = 2;
  uint16_t a3 = 3;

  void blink_thread(void* arg)
  {
    uint16_t *a = (uint16_t *)arg;
    
    for (;;) {
      if (*a == 1) {
        call Leds.led0Toggle();
        call DynamicThread.sleep(200);
      } else if (*a == 2) {
        call Leds.led1Toggle();
        call DynamicThread.sleep(1000);
      } else if (*a == 3) {
        call Leds.led2Toggle();
        call DynamicThread.sleep(1000);
      }
    }
  }
    
  event void Boot.booted()
  {
    call DynamicThread.create(&blink1, blink_thread, &a1, 500);
    call DynamicThread.create(&blink2, blink_thread, &a2, 500);
    call DynamicThread.create(&blink3, blink_thread, &a3, 500);
  }
}
