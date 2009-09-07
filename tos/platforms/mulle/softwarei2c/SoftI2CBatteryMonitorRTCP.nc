/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
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
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * The configuration that takes the underlying software I2C driver 
 * on Mulle and turns it into a shared abstraction for the RTC and battery
 * monitor.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#include "MulleI2C.h"
#include "I2C.h"
configuration SoftI2CBatteryMonitorRTCP
{
  provides interface Resource[uint8_t client];
  provides interface I2CPacket<TI2CBasicAddr>[uint8_t client];
}
implementation
{
  components new SoftI2CMasterP(UQ_MULLE_SOFTI2C_BATTERY_RTC) as I2C,
      new SoftI2CBusP(),
      HplM16c62pGeneralIOC as IOs;
  
  // Init the software I2C bus
  SoftI2CBusP.I2CClk -> IOs.PortP71;
  SoftI2CBusP.I2CData -> IOs.PortP70;
  SoftI2CBusP.I2CCtrl -> IOs.PortP75;

  I2C.SoftI2CBus -> SoftI2CBusP;

  Resource  = I2C.Resource;
  I2CPacket = I2C.I2CPacket;
}

