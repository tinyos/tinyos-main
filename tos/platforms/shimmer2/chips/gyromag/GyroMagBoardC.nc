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
 * @date   March, 2010
 *
 * @author Steve Ayer
 * @date   July, 2010
 * tos-2.x port
 *
 * wiring to msp430 i2c implmentation to flesh out gyro/mag board on shimmer2
 * using direct module because we don't need arbitration for this platform.
 * note gyro implementation is used for everything except mag
 */

configuration GyroMagBoardC {
  provides {
    interface Init;
    interface StdControl;
    interface GyroMagBoard;
  }
}

implementation {
  components GyroMagBoardP;
  Init = GyroMagBoardP;
  StdControl = GyroMagBoardP;
  GyroMagBoard = GyroMagBoardP;

  components LedsC;
  GyroMagBoardP.Leds          -> LedsC;

  components new TimerMilliC() as testTimer;
  GyroMagBoardP.testTimer     -> testTimer;

  enum {
    CLIENT_ID = unique( MSP430_I2CO_BUS ),
  };

  components Msp430I2CP;  // this is mine, ported from tos-1.x; find it in shimmer/chips/msp430
  GyroMagBoardP.I2CPacket -> Msp430I2CP.I2CBasicAddr;
  HplMsp430Usart0P.HplI2C -> HplMsp430I2C0P.HplI2C;

  components HplMsp430I2C0P;
  GyroMagBoardP.HplI2C -> HplMsp430I2C0P.HplI2C;
  Msp430I2CP.HplI2C -> HplMsp430I2C0P.HplI2C;

  components HplMsp430Usart0P;
  HplMsp430I2C0P.HplUsart  -> HplMsp430Usart0P.Usart;
  Msp430I2CP.I2CInterrupts -> HplMsp430Usart0P.I2CInterrupts;

  components HplMsp430GeneralIOC as GIO;
  HplMsp430Usart0P.SIMO -> GIO.SIMO0;
  HplMsp430Usart0P.SOMI -> GIO.SOMI0;
  HplMsp430Usart0P.UCLK -> GIO.UCLK0;
  HplMsp430Usart0P.UTXD -> GIO.UTXD0;
  HplMsp430Usart0P.URXD -> GIO.URXD0;

  HplMsp430I2C0P.SIMO -> GIO.SIMO0;
  HplMsp430I2C0P.UCLK -> GIO.UCLK0;

  components GyroBoardC;  
  GyroMagBoardP.GyroBoard -> GyroBoardC.GyroBoard;
  GyroMagBoardP.GyroInit  -> GyroBoardC.Init;
  GyroMagBoardP.GyroStdControl -> GyroBoardC.StdControl;
}

