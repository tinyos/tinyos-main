/*
 * Copyright (c) 2007 Matus Harvan
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * The name of the author may not be used to endorse or promote
 *       products derived from this software without specific prior
 *       written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#include "printf.h"

#if defined(ENABLE_MICAZ_TEMP_SENSOR) || defined(ENABLE_TELOSB_TEMP_SENSOR)
#define ENABLE_TEMP_SENSOR
#endif /* ENABLE_MICAZ_TEMP_SENSOR || ENABLE_TELOSB_TEMP_SENSOR */

#if defined(ENABLE_MICAZ_LIGHT_SENSOR) || defined(ENABLE_TELOSB_LIGHT_SENSOR)
#define ENABLE_LIGHT_SENSOR
#endif /* ENABLE_MICAZ_LIGHT_SENSOR || ENABLE_TELOSB_LIGHT_SENSOR */

enum {
    AM_IP_MSG = 0x41,
};

configuration CliAppC {}
implementation {
    components CliC as App, LedsC, MainC;
    components IPC;
    
    App.Boot -> MainC.Boot;
    App.Leds -> LedsC;
    App.IPControl -> IPC.IPControl;
    App.IP -> IPC.IP;
    App.UDPClient -> IPC.UDPClient[unique("UDPClient")];

#ifdef ENABLE_SOUNDER
    components SounderC;
    App.Sounder -> SounderC;
#endif /* ENABLE_SOUNDER */

#ifdef ENABLE_MICAZ_TEMP_SENSOR
    components new TempC(); // telosb temp/humidity sensor
    App.TempSensorC -> TempC;
#endif /* ENABLE_MICAZ_TEMP_SENSOR */

#ifdef ENABLE_TELOSB_TEMP_SENSOR
    components new SensirionSht11C(); // telosb temp/humidity sensor
    App.TempSensorC -> SensirionSht11C.Temperature;
#endif /* ENABLE_TELOSB_TEMP_SENSOR */

#ifdef ENABLE_MICAZ_LIGHT_SENSOR
    components new PhotoC();// telosb visible light sensor
    App.LightSensorC -> PhotoC;
#endif /* ENABLE_MICAZ_TEMP_SENSOR */

#ifdef ENABLE_TELOSB_LIGHT_SENSOR
    // total solar radiation sensor
    //new HamamatsuS10871TsrC() as Sensor, // telosb (IR) light sensor
    // photosynthetically-active radiation sensor
    components new HamamatsuS1087ParC();// telosb visible light sensor
    App.LightSensorC -> HamamatsuS1087ParC;
#endif /* ENABLE_TELOSB_TEMP_SENSOR */
}



