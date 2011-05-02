/*
 * Copyright (c) 2011 Lulea University of Technology
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
 * Wiring for the I2CPacket interfaces for M16C/60.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#include "I2C.h"

configuration M16c60I2CC
{
  provides 
  {
    interface I2CPacket<TI2CBasicAddr> as I2CPacket0;
    interface AsyncStdControl as I2CPacket0Control;
    interface I2CPacket<TI2CBasicAddr> as I2CPacket1;
    interface AsyncStdControl as I2CPacket1Control;
    interface I2CPacket<TI2CBasicAddr> as I2CPacket2;
    interface AsyncStdControl as I2CPacket2Control;
  }
}
implementation
{
  components new M16c60I2CP() as I2C0,
             new M16c60I2CP() as I2C1,
             new M16c60I2CP() as I2C2,
             HplM16c60UartC as Uart;
  
  I2C0.HplUart -> Uart.HplUart0;
  I2CPacket0 = I2C0;
  I2CPacket0Control = I2C0;
  
  I2C1.HplUart -> Uart.HplUart1;
  I2CPacket1 = I2C1;
  I2CPacket1Control = I2C1;
  
  I2C2.HplUart -> Uart.HplUart2;
  I2CPacket2 = I2C2;
  I2CPacket2Control = I2C2;
}
