/*                                                                      
 * Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
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
 *
 */

/**
 * Configuration representing the SPI device of the CC2420 for the micaZ
 * platform. The basic mapping is this:
 *  <ul>
 *   <li>the platform independent chips/CC2420 maps to HplCC2420SpiC;</li>
 *   <li>HplCC2420SpiC on the micaZ maps to Atm128SpiC;</li>
 *   <li>under TOSSIM Atm128SpiC maps to SimAtm128SpiDeviceC;</li>
 *   <li>SimAtm128SpiDeviceC maps to the actual simulation implementation in micaz/chips/cc2420/sim</li>
 *  </ul>
 *
 * @author Philip Levis
 * @date   November 22 2005
 */

configuration SimAtm128SpiDeviceC {

  provides interface Init;
  provides interface Resource[uint8_t];
  provides interface SPIByte;
  provides interface SPIPacket;

  uses interface Resource as SubResource[uint8_t];
  uses interface ArbiterInfo;
  uses interface McuPowerState;
  
}

implementation {

  components SimCC2420C;

  Init = SimCC2420C;
  Resource = SimCC2420C.SpiResource;
  SPIByte = SimCC2420C;
  SPIPacket = SimCC2420C;

  SubResource = SimCC2420C.SubSpiResource;
  ArbiterInfo = SimCC2420C;
  McuPowerState = SimCC2420C;
  
}
