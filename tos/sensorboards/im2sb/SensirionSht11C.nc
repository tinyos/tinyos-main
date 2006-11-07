/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * SensirionSht11C is a top-level access component for the Sensirion
 * SHT11 model humidity and temperature sensor, available on the
 * telosb platform. Because this component represents one physical
 * device, simultaneous calls to read temperature and humidity will be
 * arbitrated and executed in sequential order. Feel free to read both
 * at the same time, just be aware that they'll come back
 * sequentially.
 *
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @author Gilman Tolles <gtolle@archrock.com>
 * @version $Revision: 1.3 $ $Date: 2006-11-07 19:31:27 $
 */

generic configuration SensirionSht11C() {
  provides interface Read<uint16_t> as Temperature;
  provides interface Read<uint16_t> as Humidity;
  //provides interface HalSht11Advanced;
}
implementation {
  components new SensirionSht11ReaderP();

  Temperature = SensirionSht11ReaderP.Temperature;
  Humidity = SensirionSht11ReaderP.Humidity;

  components HalSensirionSht11C;

  enum { TEMP_KEY = unique("Sht11.Resource") };
  enum { HUM_KEY = unique("Sht11.Resource") };

  SensirionSht11ReaderP.TempResource -> HalSensirionSht11C.Resource[ TEMP_KEY ];
  SensirionSht11ReaderP.Sht11Temp -> HalSensirionSht11C.SensirionSht11[ TEMP_KEY ];
  SensirionSht11ReaderP.HumResource -> HalSensirionSht11C.Resource[ HUM_KEY ];
  SensirionSht11ReaderP.Sht11Hum -> HalSensirionSht11C.SensirionSht11[ HUM_KEY ];

  //enum { ADV_KEY = unique("Sht11.Resource") };
  //components HalSht11ControlP;
  //HalSht11Advanced = HalSht11ControlP;
  //HalSht11ControlP.Resource -> HalSensirionSht11C.Resource[ ADV_KEY ];
  //HalSht11ControlP.SensirionSht11 -> HalSensirionSht11C.SensirionSht11[ ADV_KEY ];
}
