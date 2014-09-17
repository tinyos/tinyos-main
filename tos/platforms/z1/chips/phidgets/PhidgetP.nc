/*
 * Copyright (c) 2014 ZOLERTIA LABS
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
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

/*
 * Basic analog driver to read data from a Phidget sensor
 * http://www.phidgets.com
 *
 * @author: Antonio Linan <alinan@zolertia.com>
 */

#include "Msp430Adc12.h"
#include "phidgets.h"

module PhidgetP {
  provides {
    interface Phidgets;
    interface AdcConfigure<const msp430adc12_channel_config_t*>;
  }

  uses {
    interface Read<uint16_t> as ReadFromPhidget;
    interface Read<uint16_t> as Battery;
  }
}

implementation {

#ifdef DEBUG_PHIDGET
  #define printf_phidget printfUART
#else
  #define printf_phidget(...)
#endif

  bool configured, powered_ext= FALSE;
  uint16_t selected = NO_PHIDGET;
  uint16_t batt;

  // Default template

  msp430adc12_channel_config_t config = {
    inch: INPUT_CHANNEL_A7,
    sref: REFERENCE_AVcc_AVss,
    ref2_5v: REFVOLT_LEVEL_NONE,
    adc12ssel: SHT_SOURCE_ACLK,
    adc12div: SHT_CLOCK_DIV_1,
    sht: SAMPLE_HOLD_4_CYCLES,
    sampcon_ssel: SAMPCON_SOURCE_SMCLK,
    sampcon_id: SAMPCON_CLOCK_DIV_1
  };

  uint16_t processData(uint16_t data){
    uint32_t aux = data;
    int64_t auxSigned = 0;

    // Convert to mV
    aux *= batt;
    aux = (aux >> 12); // Divide 4096

    if (powered_ext){
      aux *= EXTERNAL_VREF;
      aux /= EXTERNAL_VREF_CROSSVAL;
    }

    printf_phidget("Phidget: raw %u %umV\n", data, (uint16_t) aux);

    switch (selected){
      case PHIDGET_RAW:
        // Do nothing
        break;

      case PHIDGET_ROTATION:
        // The 1109 can be rotated 300 degrees and outputs a number between 0 
        // and 1000 based on the shaft position
        aux /= 30;
        aux *= 10;
        break;

      case PHIDGET_TOUCH:
        // The 1129 changes its output from 0 to Vin (max), spurious values
        // close to zero are treated as no touch (zero)
        if (aux > 10) aux = (powered_ext) ? EXTERNAL_VREF : INTERNAL_VREF;
        else aux = 0;
        break;

      case PHIDGET_FLEXIFORCE:
        // Calibration is outside the scope of the driver (at the moment)
        // Caution: this sensor is normally powered at 5VDC
        break;

      case PHIDGET_MAGNETIC:
        // TODO: convert to Gauss
        break;

      case PHIDGET_SHARP_DISTANCE_3520:
        // TODO: convert to cms
        break;

      case PHIDGET_SHARP_DISTANCE_3522:
        // TODO: convert to cms
        break;

      case PHIDGET_CURRENT_ACDC_30A:
          // TODO: convert to mA
        break;

      case PHIDGET_PH_3550:
        // TODO: test the following
        // pH = 0.0178 x SensorValue - 1.889 @25ºC
        break;

      case PHIDGET_ORP_3550:
        // TODO: convert to mV
        break;

      case PHIDGET_VOLT_30VDC:
        aux += EXTERNAL_VREF_OFFSET;
        auxSigned = (uint64_t) EXTERNAL_VREF_HALF - aux;
        printf_phidget("Phidget: %lldmV (w/offset %d)\n", auxSigned, EXTERNAL_VREF_OFFSET);

        // The following is based on measurements, you can adjust to your setup
        auxSigned *= 14516;
        auxSigned -= 14411;
        auxSigned /= 1000;

        printf_phidget("Phidget:  %lld\n", auxSigned);
        return (uint16_t) auxSigned;
        break;
    }

    return (uint16_t) aux;
  }

  command error_t Phidgets.enable (uint8_t port, uint16_t phidget){
    if (configured) return EALREADY;
    if (phidget > PHIDGET_MAX) return EINVAL;
    if (port > INPUT_CHANNEL_A7) return EINVAL;

    configured = TRUE;
    config.inch = port;
    selected = phidget;

    powered_ext = ((port == INPUT_CHANNEL_A0) || (port == INPUT_CHANNEL_A3)) ? TRUE : FALSE;

    printf_phidget("Phidget: %s -> ADC%u (%sV)\n\n", phidgetFromVal(phidget), port, powered_ext ? "ext" : "3");

    return SUCCESS;
  }

  command error_t Phidgets.disable (uint8_t port){
    if (!configured) return EALREADY;
    configured = FALSE;
    return SUCCESS;
  }

  command error_t Phidgets.read (void){
    if (!configured) return EOFF;
    if (selected == NO_PHIDGET) return EINVAL;

    call Battery.read();
    return SUCCESS;
  }

  event void ReadFromPhidget.readDone (error_t error, uint16_t data){
    uint16_t output = 0;
    if (error == SUCCESS) output = processData(data);
    signal Phidgets.readDone(error, selected, output);
  }

  async command const msp430adc12_channel_config_t* AdcConfigure.getConfiguration() {
    return &config;
  }

  event void Battery.readDone(error_t error, uint16_t data){
    uint32_t aux;
    if(error == SUCCESS) {
      aux = data;
      aux *= INTERNAL_VREF;
      aux = aux >> 12;
      batt = aux + INTERNAL_VREF_OFFSET;
      printf_phidget("Phidget: ref %umV (w/offset %d)\n", batt, INTERNAL_VREF_OFFSET);
      call ReadFromPhidget.read();
    }
  }
}
