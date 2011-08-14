/*
 * Copyright (c) 2009 DEXMA SENSORS SL
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
 * @author: Xavier Orduna <xorduna@dexmatech.com>
 * @author: Jordi Soucheiron <jsoucheiron@dexmatech.com>
 */

#include "Msp430Adc12.h"

module BatteryP {
 provides interface DeviceMetadata;
 provides interface AdcConfigure<const msp430adc12_channel_config_t*>;
}
implementation {

 msp430adc12_channel_config_t config = {
   inch: SUPPLY_VOLTAGE_HALF_CHANNEL,
   sref: REFERENCE_VREFplus_AVss,
   ref2_5v: REFVOLT_LEVEL_1_5,
   adc12ssel: SHT_SOURCE_ACLK,
   adc12div: SHT_CLOCK_DIV_1,
   sht: SAMPLE_HOLD_4_CYCLES,
   sampcon_ssel: SAMPCON_SOURCE_SMCLK,
   sampcon_id: SAMPCON_CLOCK_DIV_1
 };

 command uint8_t DeviceMetadata.getSignificantBits() { return 12; }

 async command const msp430adc12_channel_config_t* AdcConfigure.getConfiguration() {
   return &config;
 }
}
