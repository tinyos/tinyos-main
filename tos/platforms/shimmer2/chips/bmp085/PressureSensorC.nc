/*
 * Copyright (c) 2010, Shimmer Research, Ltd.
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of Shimmer Research, Ltd. nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Steve Ayer
 * @date   November, 2010
 */


configuration PressureSensorC {
  provides {
    interface Init;
    interface StdControl;
    interface PressureSensor;
  }
}

implementation {
  components Bmp085P;
  Init           = Bmp085P;
  StdControl     = Bmp085P;
  PressureSensor = Bmp085P;

  enum {
    CLIENT_ID = unique( MSP430_I2CO_BUS ),
  };

  components Msp430I2CP;        // this is mine, ported from tos-1.x; find it in shimmer/chips/msp430
  Bmp085P.I2CPacket -> Msp430I2CP.I2CBasicAddr;
  Bmp085P.I2CInit   -> Msp430I2CP.I2CInit;

  components HplMsp430I2C0C;
  Bmp085P.HplI2C -> HplMsp430I2C0C;
  Msp430I2CP.HplI2C -> HplMsp430I2C0C;

  components HplMsp430Usart0C;
  Msp430I2CP.I2CInterrupts -> HplMsp430Usart0C;

  components HplMsp430InterruptP;
  Bmp085P.EOCInterrupt -> HplMsp430InterruptP.Port13;

  components HplMsp430GeneralIOC as GpioC; 
  Bmp085P.Msp430GeneralIO -> GpioC.Port13;
}

