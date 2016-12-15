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
 */

#include "msp432usci.h"

/*
 *
 * Connect the appropriate pins for USCI support on a msp432
 *
 * @author Eric B. Decker <cire831@gmail.com>
 */

configuration PlatformUsciMapC {
} implementation {
  components HplMsp432GpioC as GIO;
  components PanicC, PlatformC;

#ifdef notdef
  components Msp432UsciUartA0P as UartA0C;
  UartA0C.URXD    -> GIO.UCA0RXD;
  UartA0C.UTXD    -> GIO.UCA0TXD;
#endif
  /* main uart port */

  components UsciConfP as Conf;

  components Msp432UsciUartA0C as Uart;
  Uart.TXD                      -> GIO.UCA0TXD;
  Uart.RXD                      -> GIO.UCA0RXD;
  Uart.Panic                    -> PanicC;
  Uart.Platform                 -> PlatformC;
  PlatformC.PeripheralInit      -> Uart;
  Uart                          -> Conf.UartConf;

  components Msp432UsciI2CB1C as I2C;
  I2C.SDA                       -> GIO.UCB1SDA;
  I2C.SCL                       -> GIO.UCB1SCL;
  I2C.Panic                     -> PanicC;
  I2C.Platform                  -> PlatformC;
  PlatformC.PeripheralInit      -> I2C;
  I2C                           -> Conf.I2CConf;

  /* master */
  components Msp432UsciSpiB0C as Master;
  Master.SIMO                   -> GIO.UCB0SIMO;
  Master.SOMI                   -> GIO.UCB0SOMI;
  Master.CLK                    -> GIO.UCB0CLK;
  Master.Panic                  -> PanicC;
  Master.Platform               -> PlatformC;
  PlatformC.PeripheralInit      -> Master;
  Master                        -> Conf.MasterConf;

  /* slave */
  components Msp432UsciSpiB2C as Slave;
  Slave.SIMO                    -> GIO.UCB2SIMOxPM;
  Slave.SOMI                    -> GIO.UCB2SOMIxPM;
  Slave.CLK                     -> GIO.UCB2CLKxPM;
  Slave.Panic                   -> PanicC;
  Slave.Platform                -> PlatformC;
  PlatformC.PeripheralInit      -> Slave;
  Slave                         -> Conf.SlaveConf;
}
