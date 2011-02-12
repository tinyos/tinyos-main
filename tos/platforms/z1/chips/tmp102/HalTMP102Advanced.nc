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
 * - Neither the name of the Arched Rock Corporation nor the names of
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
 * HalTMP175Advanced is the HAL control interface for the TI TMP175
 * Digital Temperature Sensor. 
 *
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @version $Revision: 1.4 $ $Date: 2006/12/12 18:23:14 $
 */

#include "TMP102.h"

interface HalTMP102Advanced {

  command error_t setThermostatMode(bool useInt);
  event void setThermostatModeDone(error_t error);
  command error_t setPolarity(bool polarity);
  event void setPolarityDone(error_t error);
  command error_t setFaultQueue(tmp102_fqd_t depth);
  event void setFaultQueueDone(error_t error);
  command error_t setTLow(uint16_t val);
  event void setTLowDone(error_t error);
  command error_t setTHigh(uint16_t val);
  event void setTHighDone(error_t error);
  
  //it is not possible to configure sensor resolution
  
  
  event void alertThreshold();
  
  /* We must include following modes for TMP102 */
  //conversion rate
  //extended mode
  command error_t setExtendedMode(bool extendedmode);
  event void setExtendedModeDone(error_t error);
  command error_t setConversionRate(tmp102_cr_t rate);
  event void setConversionRateDone(error_t error);


}
