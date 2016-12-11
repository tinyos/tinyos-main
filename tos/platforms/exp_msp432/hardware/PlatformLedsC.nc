/*
 * Copyright (c) 2016 Eric B. Decker
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
 *
 * @author Eric B. Decker <cire831@gmail.com>
 */

#include "hardware.h"

configuration PlatformLedsC {
  provides {
    interface Init;
    interface Leds;
  }
}
implementation {
  components PlatformLedsP;
  Leds = PlatformLedsP;
  Init = PlatformLedsP;

  components HplMsp432GpioC as GpioC;

  /* RED LED (LED2 RED) at P2.0 */
  components new Msp432GpioC() as Led0Impl;
  Led0Impl -> GpioC.Port20;
  PlatformLedsP.Led0 -> Led0Impl;

  /* GREEN LED (LED2 GREEN) at P2.1 */
  components new Msp432GpioC() as Led1Impl;
  Led1Impl -> GpioC.Port21;
  PlatformLedsP.Led1 -> Led1Impl;

  /* BLUE LED (LED2 BLUE) at P2.2 */
  components new Msp432GpioC() as Led2Impl;
  Led2Impl -> GpioC.Port22;
  PlatformLedsP.Led2 -> Led2Impl;
}
