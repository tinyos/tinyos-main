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
* Author: Andras Biro
*/ 

#include "UcminiSensor.h"

configuration UcminiSensorC { }
implementation {
  components UcminiSensorP, MainC, LedsC, new TimerMilliC();
  components new AtmegaTemperatureC(),
             new LightC(),
             new PressureC(), new Ms5607TemperatureC(), new Ms5607CalibrationC(),
             new TemperatureC(), new HumidityC(),
             UserButtonC;
#ifdef SERIAL_SEND
  components SerialActiveMessageC as ActiveMessageC, new SerialAMSenderC(AM_MEASUREMENT) as MeasSend;
#else
  components ActiveMessageC, new AMSenderC(AM_MEASUREMENT) as MeasSend;
#endif

#if !defined(UCMINI_REV) || UCMINI_REV >= 200
  components new VoltageC(), BatterySwitchC;
  UcminiSensorP.VoltageRead -> VoltageC;
  UcminiSensorP.SwitchRead -> BatterySwitchC;
#endif

  UcminiSensorP.Boot -> MainC;
  UcminiSensorP.SplitControl -> ActiveMessageC;
  UcminiSensorP.TempShtRead -> TemperatureC;
  UcminiSensorP.HumiRead -> HumidityC;
  UcminiSensorP.LightRead -> LightC;
  UcminiSensorP.PressRead -> PressureC;
  UcminiSensorP.TempMsRead -> Ms5607TemperatureC;
  UcminiSensorP.TempAtRead -> AtmegaTemperatureC;
  UcminiSensorP.Get -> UserButtonC;
  UcminiSensorP.Timer->TimerMilliC;
  UcminiSensorP.MeasSend->MeasSend;
  UcminiSensorP.Packet->MeasSend;
  UcminiSensorP.Leds -> LedsC;
}

