/*
 * Copyright (c) 2008 Stanford University.
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
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */

#include "thread.h"

generic configuration BlockingSensirionSht11ReaderP() {
  provides interface DeviceMetadata as TemperatureMetadata;
  provides interface BlockingRead<uint16_t> as Temperature;
  provides interface DeviceMetadata as HumidityMetadata;
  provides interface BlockingRead<uint16_t> as Humidity;
  
  uses interface Resource as TempResource;
  uses interface Resource as HumResource;
  uses interface SensirionSht11 as Sht11Temp;
  uses interface SensirionSht11 as Sht11Hum;
}
implementation {
  components new SensirionSht11ReaderP();
  components new BlockingSensirionSht11ReaderImplP();
  
  TemperatureMetadata = SensirionSht11ReaderP.TemperatureMetadata;
  Temperature = BlockingSensirionSht11ReaderImplP.BlockingTemperature;
  HumidityMetadata = SensirionSht11ReaderP.HumidityMetadata;
  Humidity = BlockingSensirionSht11ReaderImplP.BlockingHumidity;
  
  TempResource = SensirionSht11ReaderP.TempResource;
  HumResource = SensirionSht11ReaderP.HumResource;
  Sht11Temp = SensirionSht11ReaderP.Sht11Temp;
  Sht11Hum = SensirionSht11ReaderP.Sht11Hum;
  
  BlockingSensirionSht11ReaderImplP.Temperature -> SensirionSht11ReaderP.Temperature;
  BlockingSensirionSht11ReaderImplP.Humidity -> SensirionSht11ReaderP.Humidity;
  
  components SystemCallC;
  BlockingSensirionSht11ReaderImplP.SystemCall -> SystemCallC;
}
