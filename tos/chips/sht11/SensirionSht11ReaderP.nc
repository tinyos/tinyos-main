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
 * SensirionSht11ReaderP transforms the HAL-level SensirionSht11
 * interface into a pair of SID Read interfaces, one for the
 * temperature sensor and one for the humidity sensor. It acquires the
 * underlying resource before executing each read, enabling
 * arbitrated access.
 *
 * @author Gilman Tolle <gtolle@archrock.com>
 * @version $Revision: 1.5 $ $Date: 2007-04-13 21:46:18 $
 */

#include <SensirionSht11.h>

generic module SensirionSht11ReaderP() {
  provides interface DeviceMetadata as TemperatureMetadata;
  provides interface Read<uint16_t> as Temperature;
  provides interface DeviceMetadata as HumidityMetadata;
  provides interface Read<uint16_t> as Humidity;
  
  uses interface Resource as TempResource;
  uses interface Resource as HumResource;
  uses interface SensirionSht11 as Sht11Temp;
  uses interface SensirionSht11 as Sht11Hum;
}
implementation {

  command uint8_t TemperatureMetadata.getSignificantBits() { return SHT11_TEMPERATURE_BITS; }

  command error_t Temperature.read() {
    call TempResource.request();
    return SUCCESS;
  }

  event void TempResource.granted() {
    error_t result;
    if ((result = call Sht11Temp.measureTemperature()) != SUCCESS) {
      call TempResource.release();
      signal Temperature.readDone( result, 0 );
    }
  }

  event void Sht11Temp.measureTemperatureDone( error_t result, uint16_t val ) {
    call TempResource.release();
    signal Temperature.readDone( result, val );
  }

  command uint8_t HumidityMetadata.getSignificantBits() { return SHT11_HUMIDITY_BITS; }

  command error_t Humidity.read() {
    call HumResource.request();
    return SUCCESS;
  }

  event void HumResource.granted() {
    error_t result;
    if ((result = call Sht11Hum.measureHumidity()) != SUCCESS) {
      call HumResource.release();
      signal Humidity.readDone( result, 0 );
    }
  }

  event void Sht11Hum.measureHumidityDone( error_t result, uint16_t val ) {
    call HumResource.release();
    signal Humidity.readDone( result, val );
  }

  event void Sht11Temp.resetDone( error_t result ) { }
  event void Sht11Temp.measureHumidityDone( error_t result, uint16_t val ) { }
  event void Sht11Temp.readStatusRegDone( error_t result, uint8_t val ) { }
  event void Sht11Temp.writeStatusRegDone( error_t result ) { }

  event void Sht11Hum.resetDone( error_t result ) { }
  event void Sht11Hum.measureTemperatureDone( error_t result, uint16_t val ) { }
  event void Sht11Hum.readStatusRegDone( error_t result, uint8_t val ) { }
  event void Sht11Hum.writeStatusRegDone( error_t result ) { }

  default event void Temperature.readDone( error_t result, uint16_t val ) { }
  default event void Humidity.readDone( error_t result, uint16_t val ) { }
}
