/* $Id: TMP175InternalC.nc,v 1.4 2006/12/12 18:23:45 vlahan Exp $ */
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
//#include "im2sb.h"

configuration TMP102InternalC {
  provides interface Resource[uint8_t id];
  provides interface HplTMP102[uint8_t id];
  provides interface SplitControl;
}

implementation {
  enum {
    ADV_ID = unique("TMP102.HplAccess"),
  };
  
  components new SimpleFcfsArbiterC( "TMP102.Resource" ) as Arbiter;
  components MainC;
  Resource = Arbiter;

  components new HplTMP102LogicP(TMP102_SLAVE_ADDR) as Logic;
  MainC.SoftwareInit -> Logic;

  /* dubtos */
  components GeneralIOC;
  Logic.AlertInterrupt -> GeneralIOC.GpioInterrupt[GPIO_TMP102_TEMP_ALERT];
  Logic.InterruptPin -> GeneralIOC.GeneralIO[GPIO_TMP102_TEMP_ALERT];

  components new Msp430I2CC() as I2CBus;
  Logic.I2CPacket -> I2CBus;

  components TMP102InternalP as Internal;
  HplTMP102 = Internal.HplTMP102;
  Internal.ToHPLC -> Logic.HplTMP102;

  SplitControl = Logic;

  components HalTMP102ControlP;
  HalTMP102ControlP.HplTMP102 -> Logic;
  
}
