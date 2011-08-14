/*
 * Copyright (c) 2009 DEXMA SENSORS SL
 * Copyright (c) 20011 ZOLERTIA LABS
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
 * Implementation of ADXL345 accelerometer, as a part of Zolertia Z1 mote
 *
 * Credits goes to DEXMA SENSORS SL
 * @author: Xavier Orduna <xorduna@dexmatech.com>
 * @author: Jordi Soucheiron <jsoucheiron@dexmatech.com>
 * @author: Antonio Linan <alinan@zolertia.com>
 */

configuration HplADXL345C {
  provides interface GeneralIO as GeneralIO1;
  provides interface GeneralIO as GeneralIO2;
  provides interface GpioInterrupt as GpioInterrupt1;
  provides interface GpioInterrupt as GpioInterrupt2;
}

implementation {
  components HplMsp430GeneralIOC as GeneralIOC;
  components HplMsp430InterruptC as InterruptC;

  components new Msp430GpioC() as ADXL345Int1C;
  ADXL345Int1C -> GeneralIOC.Port16;
  GeneralIO1 = ADXL345Int1C;

  components new Msp430GpioC() as ADXL345Int2C;
  ADXL345Int2C -> GeneralIOC.Port17;
  GeneralIO2 = ADXL345Int2C;

  components new Msp430InterruptC() as InterruptAccel1C;
  InterruptAccel1C.HplInterrupt -> InterruptC.Port16;
  GpioInterrupt1 = InterruptAccel1C.Interrupt;

  components new Msp430InterruptC() as InterruptAccel2C;
  InterruptAccel2C.HplInterrupt -> InterruptC.Port17;
  GpioInterrupt2 = InterruptAccel2C.Interrupt;
}
