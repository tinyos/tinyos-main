/*
 * Copyright (c) 2006 Stanford University.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
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
 * The configuration that takes the underlying I2C driver on the 
 * Atmega128 and turns it into a shared abstraction.
 *
 * @date May 28 2006
 * @author Philip Levis
 */

#include "Atm128I2C.h"



configuration Atm128I2CMasterP {
  provides interface Resource[uint8_t client];
  provides interface I2CPacket<TI2CBasicAddr>[uint8_t client];
}
implementation {
  enum {
    ATM128_I2C_CLIENT_COUNT = uniqueCount(UQ_ATM128_I2CMASTER),
  };
  
  components new FcfsArbiterC(UQ_ATM128_I2CMASTER) as Arbiter;
  components new AsyncPowerManagerP() as Power;
  components new Atm128I2CMasterImplP() as I2C;
  components new Atm128I2CMasterPacketP() as Master;
  components HplAtm128I2CBusC;
  components LedsC, NoLedsC;
    
  Resource  = I2C;
  I2CPacket = I2C;
  
  I2C.SubResource -> Arbiter;
  I2C.SubPacket   -> Master;
  I2C.Atm128I2C -> Master;
  
  Power.AsyncStdControl -> Master;
  Power.ResourceController -> Arbiter;

  Master.I2C -> HplAtm128I2CBusC;
  Master.ReadDebugLeds -> NoLedsC;
  Master.WriteDebugLeds -> NoLedsC;
  
}

