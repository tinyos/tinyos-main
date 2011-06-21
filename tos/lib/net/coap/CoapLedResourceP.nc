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

generic module CoapLedResourceP(uint8_t uri_key) {
  provides interface ReadResource;
  provides interface WriteResource;
  uses interface Leds;
} implementation {
  coap_tid_t id_t;

  void task getLed() {
    uint8_t val = call Leds.get();
    signal ReadResource.getDone(SUCCESS, id_t, 0, (uint8_t*)&val, sizeof(uint8_t));
  };

  void task setLedDone() {
    signal WriteResource.putDone(SUCCESS, id_t, 0);
  };

  command error_t ReadResource.get(coap_tid_t id) {
    id_t = id;
    post getLed();
    return SUCCESS;
  }

  command error_t WriteResource.put(uint8_t *val, uint8_t buflen, coap_tid_t id) {
    id_t = id;
    if ( *val < 8){
      call Leds.set(*val);
      post setLedDone();
      return SUCCESS;
    }
    return FAIL;
  }
  }
