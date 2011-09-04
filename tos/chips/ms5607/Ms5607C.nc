/*
* Copyright (c) 2011, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Zsolt Szabo
*/


generic configuration Ms5607C(bool isMostPrecise) {
  provides interface Read<uint32_t> as Pressure;
  provides interface Read<int16_t> as Temperature;
  provides interface SplitControl;
}
implementation {
  components Ms5607P, new RomReaderP(isMostPrecise);
  components new TimerMilliC() as Timer0;

  Pressure = Ms5607P.Pressure;
  Temperature = Ms5607P.Temperature;
  Ms5607P.Timer -> Timer0;
  RomReaderP.Timer -> Timer0;
  Ms5607P.RawTemp -> RomReaderP.RawTemperature;
  Ms5607P.RawPress -> RomReaderP.RawPressure;
  Ms5607P.Cal -> RomReaderP;

  components HplMs5607C;
  RomReaderP.I2CPacket -> HplMs5607C;
  RomReaderP.I2CResource -> HplMs5607C.Resource;

  SplitControl = Ms5607P;

  components LedsC;
  Ms5607P.Leds -> LedsC;
}
