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

#include "Ms5607.h"

configuration Ms5607C {
  provides interface Read<uint32_t> as ReadPressure;
  provides interface Read<uint32_t> as ReadTemperature;
  //You can't use the following interfaces if you're waiting for any readDone
  //the calibration data stays the same for the same chip, but we do not cache it
  provides interface ReadRef<calibration_t> as ReadCalibration;
  provides interface Set<uint8_t> as SetPrecision;
}
implementation {
  components Ms5607P;

  ReadPressure = Ms5607P.ReadPressure;
  ReadTemperature = Ms5607P.ReadTemperature;
  ReadCalibration = Ms5607P.ReadCalibration;
  SetPrecision = Ms5607P;

  components HplMs5607C, new TimerMilliC(), MainC;
  Ms5607P.I2CPacket -> HplMs5607C;
  Ms5607P.I2CResource -> HplMs5607C.Resource;
  Ms5607P.Timer -> TimerMilliC;
  Ms5607P.BusPowerManager -> HplMs5607C;
  Ms5607P.Init <- MainC.SoftwareInit;
}

