/* $Id: HalPXA27xI2CMasterC.nc,v 1.4 2006-12-12 18:23:12 vlahan Exp $ */
/*
 * Copyright (c) 2005 Arch Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arch Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/**
 * This Hal module implements the TinyOS 2.0 I2CPacket interface over
 * the PXA27x I2C Hpl
 *
 * @author Phil Buonadonna
 */

#include <I2C.h>

generic configuration HalPXA27xI2CMasterC(bool fast_mode)
{
  provides interface I2CPacket<TI2CBasicAddr>;

  uses interface HplPXA27xGPIOPin as I2CSCL;
  uses interface HplPXA27xGPIOPin as I2CSDA;
}

implementation
{
  components new HalPXA27xI2CMasterP(fast_mode);
  components HplPXA27xI2CC;
  components PlatformP;

  I2CPacket = HalPXA27xI2CMasterP;

  HalPXA27xI2CMasterP.Init <- PlatformP.InitL2;

  HalPXA27xI2CMasterP.I2C -> HplPXA27xI2CC.I2C;

  I2CSCL = HalPXA27xI2CMasterP.I2CSCL;
  I2CSDA = HalPXA27xI2CMasterP.I2CSDA;
}
