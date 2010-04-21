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
 *
 * @author Philip Levis
 */
 
/**
 * The module implements the logic when creating a I2C bus with 7-bit addressing
 * into a shared abstraction.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */
#include "I2C.h"
generic module SharedI2CPacketP()
{
  provides interface Resource[uint8_t client];
  provides interface I2CPacket<TI2CBasicAddr>[uint8_t client];
  uses interface Resource as SubResource[uint8_t];
  uses interface I2CPacket<TI2CBasicAddr> as SubPacket;
}
implementation
{
  enum
  {
    NO_CLIENT = 0xff
  };
  
  uint8_t currentClient = NO_CLIENT;

  async command error_t Resource.request[uint8_t id]()
  {
    return call SubResource.request[id]();
  }

  async command error_t Resource.immediateRequest[uint8_t id]()
  {
    error_t rval = call SubResource.immediateRequest[id]();
    if (rval == SUCCESS)
    {
      atomic currentClient = id;
    }
    return rval;
  }

  event void SubResource.granted[uint8_t id]()
  {
    atomic currentClient = id;
    signal Resource.granted[id]();
  }

  async command error_t Resource.release[uint8_t id]()
  {
    return call SubResource.release[id]();
  }

  async command bool Resource.isOwner[uint8_t id]()
  {
    return call SubResource.isOwner[id]();
  }
  
  async command error_t I2CPacket.write[uint8_t id](i2c_flags_t flags,
                                                        uint16_t addr,
                                                        uint8_t len,
                                                        uint8_t* data)
  {
    atomic
    {
      if (currentClient != id)
      {
	return FAIL;
      }
    }
    return call SubPacket.write(flags, addr, len, data);
  }
  
  async command error_t I2CPacket.read[uint8_t id](i2c_flags_t flags,
                                                       uint16_t addr,
                                                       uint8_t len,
                                                       uint8_t* data)
  {
    atomic
    {
      if (currentClient != id)
      {
	return FAIL;
      }
    }
    return call SubPacket.read(flags, addr, len, data);
  }

  default event void Resource.granted[uint8_t id]() {}

  async event void  SubPacket.readDone(
      error_t error, uint16_t addr, uint8_t length, uint8_t* data)
  {
    signal  I2CPacket.readDone[currentClient](error, addr, length, data);
  }

  async event void SubPacket.writeDone(
      error_t error, uint16_t addr, uint8_t length, uint8_t* data)
  {
    signal I2CPacket.writeDone[currentClient]( error, addr, length,  data);
  }

  default async event void  I2CPacket.readDone[uint8_t id](
      error_t error, uint16_t addr, uint8_t length, uint8_t* data) {  }

  default async event void I2CPacket.writeDone[uint8_t id](
      error_t error, uint16_t addr, uint8_t length, uint8_t* data) {  }

}
