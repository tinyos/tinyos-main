/*
 * Copyright (c) 2007 Stanford University.
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
 * @date July 24, 2007
 */

#include "SensorSample.h"
#include "Storage.h"
generic configuration SamplePeriodicLogC(uint32_t sampling_period, 
                                                        volume_id_t volume) {
  provides{
    interface SampleLogRead<sensor_sample_t>;
  }
}
implementation {

  //Change sensors based on sensorboard........
  components new PeriodicSampleLogger16C(sampling_period, 4) as PeriodicLogger;
  components new SensirionSht11C() as HumidityTempC;
  components new HamamatsuS10871TsrC() as PhotoActiveC;
  components new HamamatsuS1087ParC() as TotalSolarC;
  PeriodicLogger.Sensor[0] -> HumidityTempC.Humidity;
  PeriodicLogger.Sensor[1] -> HumidityTempC.Temperature;
  PeriodicLogger.Sensor[2] -> PhotoActiveC;
  PeriodicLogger.Sensor[3] -> TotalSolarC;
  
  //Don't change........ just copy
  components MainC;
  components new LogStorageC(volume, TRUE);
  components new SampleLogReaderC(sensor_sample_t) as LogReader;
  SampleLogRead = LogReader;
  MainC.Boot <- PeriodicLogger;
  PeriodicLogger.LogWrite -> LogStorageC;
  LogReader.LogRead -> LogStorageC;
  LogReader.LogWrite -> LogStorageC;

}

