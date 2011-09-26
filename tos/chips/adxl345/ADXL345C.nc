/*
 * Copyright (c) 2009 DEXMA SENSORS SL
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
 * Implementation of ADXL345 accelerometer, as a part of Zolertia Z1 mote
 *
 * Credits goes to DEXMA SENSORS SL
 * @author: Xavier Orduna <xorduna@dexmatech.com>
 * @author: Jordi Soucheiron <jsoucheiron@dexmatech.com>
 * @author: Antonio Linan <alinan@zolertia.com>
 * @author: Andre Rodrigues
 */

#include "ADXL345.h"

generic configuration ADXL345C() {
  provides interface SplitControl;
  provides interface Read<uint16_t> as X;
  provides interface Read<uint16_t> as Y;
  provides interface Read<uint16_t> as Z;
  provides interface Read<adxl345_readxyt_t> as XYZ;
  provides interface Read<uint8_t> as IntSource;
  provides interface Read<uint8_t> as Register;
  provides interface ADXL345Control;
  provides interface Notify<adxlint_state_t> as Int1;
  provides interface Notify<adxlint_state_t> as Int2;
}
implementation {
  components ADXL345P;
  X = ADXL345P.X;
  Y = ADXL345P.Y;
  Z = ADXL345P.Z;
  XYZ = ADXL345P.XYZ;
  IntSource = ADXL345P.IntSource;
  SplitControl = ADXL345P;
  ADXL345Control = ADXL345P;
  Register = ADXL345P.Register;

  components new Msp430I2C1C() as I2C;
  ADXL345P.Resource -> I2C;
  ADXL345P.ResourceRequested -> I2C;
  ADXL345P.I2CBasicAddr -> I2C;  

  components HplADXL345C;

  Int1 = ADXL345P.Int1;
  Int2 = ADXL345P.Int2;

  ADXL345P.GpioInterrupt1 ->  HplADXL345C.GpioInterrupt1;
  ADXL345P.GpioInterrupt2 ->  HplADXL345C.GpioInterrupt2;
  ADXL345P.GeneralIO1 -> HplADXL345C.GeneralIO1;
  ADXL345P.GeneralIO2 -> HplADXL345C.GeneralIO2;

  components new TimerMilliC() as TimeoutAlarm;
  ADXL345P.TimeoutAlarm -> TimeoutAlarm;

}
