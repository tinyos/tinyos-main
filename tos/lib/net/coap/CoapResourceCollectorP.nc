/*
 * Copyright (c) 2011 University of Bremen, TZI
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
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

#include "tinyos_coap_resources.h"

module CoapResourceCollectorP {
  provides interface Read<val_all_t> as ReadAll;
  uses interface Read<uint16_t> as ReadTemp;
  uses interface Read<uint16_t> as ReadHum;
  uses interface Read<uint16_t> as ReadVolt;

} implementation {

  bool temp_finished;
  bool hum_finished;
  bool volt_finished;

  val_all_t val_r;

  command error_t ReadAll.read() {
    val_r.id_t = KEY_TEMP;
    val_r.id_h = KEY_HUM;
    val_r.id_v = KEY_VOLT;
    val_r.temp = SENSOR_NOT_AVAILABLE;
    val_r.hum = SENSOR_NOT_AVAILABLE;
    val_r.volt = SENSOR_NOT_AVAILABLE;

    temp_finished = FALSE;
    hum_finished  = FALSE;
    volt_finished = FALSE;

    call ReadHum.read();
    call ReadTemp.read();
    call ReadVolt.read();
    return SUCCESS;
  }

  void areAllDone() {

    if ((temp_finished == TRUE) &&
	(hum_finished  == TRUE) &&
	(volt_finished == TRUE)
	) {
      signal ReadAll.readDone(SUCCESS, val_r);

    }
  }

  event void ReadTemp.readDone(error_t result, uint16_t val) {
    temp_finished = TRUE;
    if (result == SUCCESS) {
      val_r.length_t = sizeof(val);
      val_r.temp = ntohs(val);
    } else {
      val_r.temp = SENSOR_VALUE_INVALID;
    }
    areAllDone();
  }

  event void ReadHum.readDone(error_t result, uint16_t val) {
    hum_finished  = TRUE;
    if (result == SUCCESS) {
      val_r.length_h = sizeof(val);
      val_r.hum = ntohs(val);
    } else {
      val_r.hum = SENSOR_VALUE_INVALID;
    }
    areAllDone();
  }

  event void ReadVolt.readDone(error_t result, uint16_t val) {
    volt_finished  = TRUE;
    if (result == SUCCESS) {
      val_r.length_v = sizeof(val);
      val_r.volt = ntohs(val);
    } else {
      val_r.volt = SENSOR_VALUE_INVALID;
    }
    areAllDone();
  }
  }
