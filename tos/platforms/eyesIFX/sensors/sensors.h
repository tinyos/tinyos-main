/*
 * Copyright (c) 2006, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2006-12-12 18:23:41 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#ifndef SENSORS_H
#define SENSORS_H

#include <Msp430Adc12.h>

enum {
  PHOTO_SENSOR_LOW_FREQ,
  PHOTO_SENSOR_HIGH_FREQ,
  PHOTO_SENSOR_DEFAULT,
  PHOTO_SENSOR_VCC,
  
  TEMP_SENSOR_LOW_FREQ,
  TEMP_SENSOR_HIGH_FREQ,
  TEMP_SENSOR_DEFAULT,
  
  RSSI_SENSOR_VCC,
  RSSI_SENSOR_REF_1_5V,
  RSSI_SENSOR_DEFAULT,

  INTERNAL_VOLTAGE_REF_2_5V,
  INTERNAL_TEMP_HIGH_FREQ,

  // add more entries here

  // last entry
  SENSOR_SENTINEL
};

const msp430adc12_channel_config_t sensorconfigurations[] = {
    /* PHOTO_SENSOR_LOW_FREQ */
    { INPUT_CHANNEL_A2, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5,
      SHT_SOURCE_ACLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_4_CYCLES,
      SAMPCON_SOURCE_ACLK, SAMPCON_CLOCK_DIV_1
    },
    /* PHOTO_SENSOR_HIGH_FREQ  */
    {
        INPUT_CHANNEL_A2, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5,
        SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_64_CYCLES,
        SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1 
    },
    /* PHOTO_SENSOR_DEFAULT */
    {
        INPUT_CHANNEL_A2, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5,
        SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_64_CYCLES,
        SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1
    },
    /* PHOTO_SENSOR_VCC */
    {
        INPUT_CHANNEL_A2, REFERENCE_AVcc_AVss, REFVOLT_LEVEL_NONE,
        SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_64_CYCLES,
        SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1
    },
    /* TEMP_SENSOR_LOW_FREQ */
    {
        INPUT_CHANNEL_A0, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5,
        SHT_SOURCE_ACLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_4_CYCLES,
        SAMPCON_SOURCE_ACLK, SAMPCON_CLOCK_DIV_1
    },
    /* TEMP_SENSOR_HIGH_FREQ */
    {
        INPUT_CHANNEL_A0, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5,
        SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_16_CYCLES,
        SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1
    },
    /* TEMP_SENSOR_DEFAULT */
    {
        INPUT_CHANNEL_A0, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5,
        SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_16_CYCLES,
        SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1
    },
    /* RSSI_SENSOR_VCC */
    {
        INPUT_CHANNEL_A3, REFERENCE_AVcc_AVss, REFVOLT_LEVEL_NONE,
        SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_4_CYCLES,
        SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1
    },
    /* RSSI_SENSOR_REF_1_5V */
    {
        INPUT_CHANNEL_A3, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5,
        SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_4_CYCLES,
        SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1
    },
    /* RSSI_SENSOR_DEFAULT */
    {
        INPUT_CHANNEL_A3, REFERENCE_AVcc_AVss, REFVOLT_LEVEL_NONE,
        SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_4_CYCLES,
        SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1
    },
    /* INTERNAL_VOLTAGE_REF_2_5V */
    {
        SUPPLY_VOLTAGE_HALF_CHANNEL, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_2_5,
        SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_32_CYCLES,
        SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1
    },
    /* INTERNAL_TEMP_HIGH_FREQ */
    {
        TEMPERATURE_DIODE_CHANNEL, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5,
        SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_32_CYCLES,
        SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1
    },
    /* your stuff here */
    /* SENSOR_SENTINEL */
    {
        INPUT_CHANNEL_NONE,0,0,0,0,0,0,0
    }
};


#endif

