/* $Id: Tsl2561InternalC.nc,v 1.3 2006-11-07 19:31:27 scipio Exp $ */
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
 *
 * @author Kaisen Lin
 * @author Phil Buonadonna
 */
#include "im2sb.h"

configuration Tsl2561InternalC {
  provides interface Resource[uint8_t id];
  provides interface HplTSL256x[uint8_t id];
  provides interface SplitControl;
}

implementation {
  enum { ADV_ID = unique("Tsl2561.HplAccess"),

  };

  components new SimpleFcfsArbiterC( "Tsl2561.Resource" ) as Arbiter;
  components MainC;
  Resource = Arbiter;
  
  components new HplTSL2561LogicP(TSL2561_SLAVE_ADDR) as Logic;
  //MainC.SoftwareInit -> Logic;

  components LedsC;
  Logic.Leds -> LedsC;
  components GeneralIOC;
  Logic.InterruptAlert -> GeneralIOC.GpioInterrupt[GPIO_TSL2561_LIGHT_INT];
  Logic.InterruptPin -> GeneralIOC.GeneralIO[GPIO_TSL2561_LIGHT_INT];

  components new HalPXA27xI2CMasterC(TRUE) as I2CC;
  Logic.I2CPacket -> I2CC;

  components Tsl2561InternalP as Internal;
  HplTSL256x = Internal.HplTSL256x;
  Internal.ToHPLC -> Logic.HplTSL256x;
  Internal.SubInit -> Logic.Init;
  SplitControl = Logic;
  MainC.SoftwareInit -> Internal;

  components HplPXA27xGPIOC;
  I2CC.I2CSCL -> HplPXA27xGPIOC.HplPXA27xGPIOPin[I2C_SCL];
  I2CC.I2CSDA -> HplPXA27xGPIOC.HplPXA27xGPIOPin[I2C_SDA];

  components HalTsl2561ControlP;
  HalTsl2561ControlP.HplTSL256x -> Logic;
}
