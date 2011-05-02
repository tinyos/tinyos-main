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
 * The wiring of the I2C bus nr 2 on Mulle and creation of it as a
 * shared resource.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#include "MulleI2C.h"
#include "I2C.h"
configuration MulleI2C2P
{
  provides interface Resource[uint8_t client];
  provides interface I2CPacket<TI2CBasicAddr>[uint8_t client];
  provides interface ResourceDefaultOwner;
}
implementation
{
  components HplM16c60GeneralIOC as IOs,
             new SharedI2CPacketC(UQ_MULLE_I2C_2),
             MulleI2C2ControlP,
             PlatformP,
             new AsyncStdControlPowerManagerC() as PowerManager,
             M16c60I2CC as I2Cs;

  Resource  = SharedI2CPacketC;
  I2CPacket = SharedI2CPacketC.I2CPacket;
  ResourceDefaultOwner = SharedI2CPacketC;
  SharedI2CPacketC -> I2Cs.I2CPacket2;

  // Init the bus
  MulleI2C2ControlP.Pullup -> IOs.PortP75;
  PowerManager.AsyncStdControl -> I2Cs.I2CPacket2Control;
  PowerManager.ResourceDefaultOwner -> SharedI2CPacketC;
  PlatformP.SubInit -> MulleI2C2ControlP;
}

