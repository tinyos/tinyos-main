/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * All rights reserved.
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.5 $ $Date: 2008-05-21 22:11:57 $
 */

#include <I2C.h>
#include "msp430usart.h"

generic configuration Msp430I2CC() {
  
  provides interface Resource;
  provides interface ResourceRequested;
  provides interface I2CPacket<TI2CBasicAddr> as I2CBasicAddr;
  
  uses interface Msp430I2CConfigure;
  
}

implementation {
  
  enum {
    CLIENT_ID = unique( MSP430_I2C0_BUS ),
  };
  
  components Msp430I2C0P as I2CP;
  Resource = I2CP.Resource[ CLIENT_ID ];
  I2CBasicAddr = I2CP.I2CBasicAddr;
  Msp430I2CConfigure = I2CP.Msp430I2CConfigure[ CLIENT_ID ];
  
  components new Msp430Usart0C() as UsartC;
  ResourceRequested = UsartC;
  I2CP.ResourceConfigure[ CLIENT_ID ] <- UsartC.ResourceConfigure;
  I2CP.UsartResource[ CLIENT_ID ] -> UsartC.Resource;
  I2CP.I2CInterrupts -> UsartC.HplMsp430I2CInterrupts;
  
}
