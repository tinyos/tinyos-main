/*
 * Copyright (c) 2011 Lulea University of Technology
 * All rights reserved.
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
 */

/**
 * Wiring for the Spi interfaces for M16C/60.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

configuration M16c60SpiC
{
  provides interface SpiPacket as SpiPacket0;
  provides interface SpiByte as SpiByte0;
  provides interface FastSpiByte as FastSpiByte0;
  provides interface SpiPacket as SpiPacket1;
  provides interface SpiByte as SpiByte1;
  provides interface FastSpiByte as FastSpiByte1;
  provides interface SpiPacket as SpiPacket2;
  provides interface SpiByte as SpiByte2;
  provides interface FastSpiByte as FastSpiByte2;
}
implementation
{
  components HplM16c60UartC as Uarts,
             new M16c60SpiP() as Spi0,
             new M16c60SpiP() as Spi1,
             new M16c60SpiP() as Spi2;


  Spi0 -> Uarts.HplUart0;
  SpiPacket0 = Spi0;
  SpiByte0 = Spi0;
  FastSpiByte0 = Spi0;
  
  Spi1 -> Uarts.HplUart1;
  SpiPacket1 = Spi1;
  SpiByte1 = Spi1;
  FastSpiByte1 = Spi1;

  Spi2 -> Uarts.HplUart2;
  SpiPacket2 = Spi2;
  SpiByte2 = Spi2;
  FastSpiByte2 = Spi2;
}
