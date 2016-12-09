/*
 * DO NOT MODIFY: This file cloned from Msp432UsciI2CB0C.nc for B2
*/
/*
 * Copyright (c) 2012, 2016 Eric B. Decker
 * Copyright (c) 2011 John Hopkins University
 * Copyright (c) 2011 Redslate Ltd.
 * Copyright (c) 2009-2010 People Power Co.
 * All rights reserved.
 *
 * This open source code was developed with funding from People Power Company
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

/**
 * Generic configuration for a dedicated USCI_B2 in I2C mode.
 *
 * @author Peter Bigot    <pabigot@peoplepowerco.com>
 * @author Doug Carlson   <carlson@cs.jhu.edu>
 * @author Derek Baker    <derek@red-slate.com>
 * @author Eric B. Decker <cire831@gmail.com>
 * port to msp432, no arbitration
 */

configuration Msp432UsciI2CB2C {
  provides {
    interface Init;
    interface I2CPacket<TI2CBasicAddr>;
    interface I2CReg;
    interface I2CSlave;
    interface Msp432UsciError;
  }
  uses {
    interface Msp432UsciConfigure;
    interface Panic;
    interface Platform;
    interface HplMsp432Gpio as SCL;
    interface HplMsp432Gpio as SDA;
  }
}
implementation {
  components Msp432UsciI2CB2P as I2CP;
  Init                  = I2CP.Init;
  I2CPacket             = I2CP.I2CPacket;
  I2CReg                = I2CP.I2CReg;
  I2CSlave              = I2CP.I2CSlave;
  Msp432UsciConfigure   = I2CP.Msp432UsciConfigure;
  Msp432UsciError       = I2CP.Msp432UsciError;
  Panic                 = I2CP;
  Platform              = I2CP;
  SCL                   = I2CP.SCL;
  SDA                   = I2CP.SDA;
}
