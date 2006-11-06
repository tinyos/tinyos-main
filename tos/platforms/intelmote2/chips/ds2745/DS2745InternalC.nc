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
 * - Neither the name of the Arched Rock Corporation nor the names of
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
 * 
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @version $Revision: 1.2 $ $Date: 2006-11-06 11:57:19 $
 */

configuration DS2745InternalC {
  provides interface SplitControl;
  provides interface Resource[uint8_t id];
  provides interface HplDS2745[uint8_t id];
}

implementation {
  components new SimpleFcfsArbiterC( "Ds2745.Resource" ) as Arbiter;
  components MainC;
  Resource = Arbiter;
  
  components new HplDS2745LogicP(DS2745_SLAVE_ADDR) as Logic;
  MainC.SoftwareInit -> Logic;

  components new HalPXA27xI2CMasterC(TRUE) as I2CC;
  Logic.I2CPacket -> I2CC;

  components HplPXA27xGPIOC;
  I2CC.I2CSCL -> HplPXA27xGPIOC.HplPXA27xGPIOPin[I2C_SCL];
  I2CC.I2CSDA -> HplPXA27xGPIOC.HplPXA27xGPIOPin[I2C_SDA];

  components DS2745InternalP as Internal;
  HplDS2745 = Internal.HplDS2745;
  Internal.ToHPLC -> Logic.HplDS2745;

  SplitControl = Logic;

}
