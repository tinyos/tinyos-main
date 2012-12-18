/*
 * Copyright (c) 2012 Sestosenso
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
 * - Neither the name of the Sestosenso nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * SESTOSENSO OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * SensirionSht11C is a top-level access component for the Sensirion
 * SHT11 model humidity and temperature sensor, available on the
 * mda300ca sensorboard. Because this component represents one physical
 * device, simultaneous calls to read temperature and humidity will be
 * arbitrated and executed in sequential order. Feel free to read both
 * at the same time, just be aware that they'll come back
 * sequentially.
 *
 * @author Franco Di Persio <francodipersio@sestosenso.es>
 * @version $Revision: 1.0 $ $Date: February 10, 2012 $
 * for some components look at ...tos\chips\sht11 
 */

generic configuration SensirionSht11C() {
  provides interface Read<uint16_t> as Temperature;
  provides interface DeviceMetadata as TemperatureMetadata;
  provides interface Read<uint16_t> as Humidity;
  provides interface DeviceMetadata as HumidityMetadata;
}
implementation {
  components new SensirionSht11ReaderP();

  Temperature = SensirionSht11ReaderP.Temperature;
  TemperatureMetadata = SensirionSht11ReaderP.TemperatureMetadata;
  Humidity = SensirionSht11ReaderP.Humidity;
  HumidityMetadata = SensirionSht11ReaderP.HumidityMetadata;

  components HalSensirionSht11C;

  enum { TEMP_KEY = unique("Sht11.Resource") };
  enum { HUM_KEY = unique("Sht11.Resource") };

  SensirionSht11ReaderP.TempResource -> HalSensirionSht11C.Resource[ TEMP_KEY ];
  SensirionSht11ReaderP.Sht11Temp -> HalSensirionSht11C.SensirionSht11[ TEMP_KEY ];
  SensirionSht11ReaderP.HumResource -> HalSensirionSht11C.Resource[ HUM_KEY ];
  SensirionSht11ReaderP.Sht11Hum -> HalSensirionSht11C.SensirionSht11[ HUM_KEY ];
}
