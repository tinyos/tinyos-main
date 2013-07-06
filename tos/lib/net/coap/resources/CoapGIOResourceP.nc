/*
 * Copyright (c) 2012 University of Patras and
 * Research Academic Computer Technology Institute & Press Diophantus (CTI)
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

/*
 * @author: Constantinos Marios Angelopoulos
 * @contact: aggeloko@ceid.upatras.gr
 * Adaptation to coap-08:
 * @author: Markus Becker
 */

generic module CoapGIOResourceP(uint8_t uri_key) {
  provides interface CoapResource;
  uses interface HplMsp430GeneralIO as GIO0;
  uses interface HplMsp430GeneralIO as GIO1;
  uses interface HplMsp430GeneralIO as GIO2;
  uses interface HplMsp430GeneralIO as GIO3;
} implementation {

  bool lock = FALSE;
  coap_async_state_t *temp_async_state = NULL;

  /////////////////////
  // GET:
  void task getMethod() {
    bool val = call Pin.get();
    lock = FALSE;
    signal CoapResource.methodDone(SUCCESS, COAP_RESPONSE_CODE(205),
				   temp_async_state,
				   (uint8_t*)&val, sizeof(bool),
				   COAP_MEDIATYPE_APPLICATION_OCTET_STREAM);
  };

  void task getMethod() {
    uint8_t val;
    atomic {
      val = 0;
      if (call GIO0.get()) {
	val = val | 1 ;
      }
      if (call GIO1.get()) {
	val = val | 2;
      }
      if (call GIO2.get()) {
	val = val | 4;
      }
      if (call GIO3.get()) {
	val = val | 8;
      }
    }
    signal CoapResource.methodDone(SUCCESS, COAP_RESPONSE_CODE(205),
				   temp_async_state,
				   (uint8_t*)&val, sizeof(uint8_t),
				   COAP_MEDIATYPE_APPLICATION_OCTET_STREAM);
  };

  command int CoapResource.getMethod(coap_async_state_t* async_state,
				     uint8_t *val, size_t buflen) {
    if (lock == FALSE) {
      lock = TRUE;
      temp_async_state = async_state;
      post getMethod();
      return COAP_SPLITPHASE;
    } else {
      return COAP_RESPONSE_503;
    }
  }

  /////////////////////
  // PUT:
  void task putMethod() {
    lock = FALSE;
    signal CoapResource.methodDone(SUCCESS, COAP_RESPONSE_CODE(204),
				   temp_async_state,
				   NULL, 0,
				   COAP_MEDIATYPE_ANY);
  };

  command int CoapResource.putMethod(coap_async_state_t* async_state,
				     uint8_t *val, size_t buflen) {
    if (lock == FALSE) {
      lock = TRUE;
      temp_async_state = async_state;

      if ( *val & 1 ) {
	call GIO0.set();
      } else {
	call GIO0.clr();
      }

      if ( *val & 2 ) {
	call GIO1.set();
      } else {
	call GIO1.clr();
      }

      if ( *val & 4 ) {
	call GIO2.set();
      } else {
	call GIO2.clr();
      }

      if ( *val & 8 ) {
	call GIO3.set();
      } else {
	call GIO3.clr();
      }
      post putMethod();
      return COAP_SPLITPHASE;
    } else {
      return COAP_RESPONSE_503;
    }
  } else {
    return COAP_RESPONSE_500;
  }

  command int CoapResource.postMethod(coap_async_state_t* async_state,
				      uint8_t *val, size_t buflen) {
    return COAP_RESPONSE_405; // or _501?
  }

  command int CoapResource.deleteMethod(coap_async_state_t* async_state,
					uint8_t *val, size_t buflen) {
    return COAP_RESPONSE_405; // or _501?
  }
}
