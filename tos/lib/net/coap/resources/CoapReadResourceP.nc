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
#include <pdu.h>
#include <resource.h>

generic module CoapReadResourceP(typedef val_t, uint8_t uri_key) {
  provides interface CoapResource;
  uses interface Leds;
  uses interface Timer<TMilli> as PreAckTimer;
  uses interface Read<val_t>;
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
  uses interface LocalIeeeEui64;
#endif
} implementation {
  unsigned int temp_media_type;
  bool lock = FALSE;
  coap_async_state_t *temp_async_state = NULL;

  command error_t CoapResource.initResourceAttributes(coap_resource_t *r) {

#ifdef COAP_CONTENT_TYPE_PLAIN
    coap_add_attr(r, (unsigned char *)"ct", 2, (unsigned char *)"0", 1, 0);
#endif
#ifdef COAP_CONTENT_TYPE_XML
    coap_add_attr(r, (unsigned char *)"ct", 2, (unsigned char *)"41", 2, 0);
#endif
#ifdef COAP_CONTENT_TYPE_BINARY
    coap_add_attr(r, (unsigned char *)"ct", 2, (unsigned char *)"42", 2, 0);
#endif
#ifdef COAP_CONTENT_TYPE_JSON
    coap_add_attr(r, (unsigned char *)"ct", 2, (unsigned char *)"50", 2, 0);
#endif

    return SUCCESS;
  }

  command int CoapResource.getMethod(coap_async_state_t* async_state,
				     uint8_t *val, size_t buflen,
				     unsigned int media_type) {
    if (lock == FALSE) {
      lock = TRUE;
      temp_async_state = async_state;
      temp_media_type = media_type;
      call PreAckTimer.startOneShot(COAP_PREACK_TIMEOUT);
      call Read.read();
      return COAP_SPLITPHASE;
    } else {
      return COAP_RESPONSE_CODE(503);
    }
  }

  event void PreAckTimer.fired() {
    call Leds.led2Toggle();
    signal CoapResource.methodNotDone(temp_async_state,
				      COAP_RESPONSE_CODE(0));
  }

  event void Read.readDone(error_t result, val_t val) {
    void *buf;
    int buflen = 0;
    char *cur;
    char buf2[COAP_MAX_PDU_SIZE];
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
#define LEN (COAP_MAX_PDU_SIZE - (cur - (char *) buf))
    int i;
    ieee_eui64_t id;
    id = call LocalIeeeEui64.getId();
#endif
    buf = buf2;
    cur = buf;

    switch(temp_media_type) {
#ifdef COAP_CONTENT_TYPE_XML
    case COAP_MEDIATYPE_APPLICATION_XML:
      cur += snprintf(cur, LEN, "%s%s", XML_PRE, "bn=\"urn:dev:mac:");
      for (i=0; i<8; i++) {
	cur += snprintf(cur, LEN, "%x", id.data[i]);
      }
      cur += snprintf(cur, LEN, "%s%d%s%s", "\"><e n=\"temperature\" u=\"K\" v=\"", val, "\"/>", XML_POST);
      buflen = cur - (char *)buf;
      break;
#endif
#ifdef COAP_CONTENT_TYPE_BINARY
    case COAP_MEDIATYPE_APPLICATION_OCTET_STREAM:
      buf = (val_t *)&val;
      buflen = sizeof(val_t);
      break;
#endif
#ifdef COAP_CONTENT_TYPE_JSON
    case COAP_MEDIATYPE_APPLICATION_JSON:
      cur += snprintf(cur, LEN, "%s%s%d%s", JSON_PRE,
					"{\"n\":\"temperature\",\"u\":\"K\",\"v\":", val, "}],\"bn\":\"urn:dev:mac:");
      for (i=0; i<8; i++) {
	cur += snprintf(cur, LEN, "%x", id.data[i]);
      }
      cur += snprintf(cur, LEN, "%s", "\"}");
      buflen = cur - (char *)buf;
      break;
#endif
#ifdef COAP_CONTENT_TYPE_PLAIN
    case COAP_MEDIATYPE_TEXT_PLAIN:
#endif
    case COAP_MEDIATYPE_ANY:
    default:
      cur += snprintf(cur, sizeof(buf2), "%d", val);
      buflen = cur - (char *)buf;
    }

    if (call PreAckTimer.isRunning()) {
      call PreAckTimer.stop();
      signal CoapResource.methodDone(result, COAP_RESPONSE_CODE(205),
				     temp_async_state,
				     (uint8_t*)buf, buflen,
				     temp_media_type, NULL);
    } else {
      signal CoapResource.methodDoneSeparate(result, COAP_RESPONSE_CODE(205),
					     temp_async_state,
					     (uint8_t*)&val, sizeof(val_t),
					     temp_media_type);
    }
    lock = FALSE;
  }

  command int CoapResource.putMethod(coap_async_state_t* async_state,
				     uint8_t *val, size_t buflen, coap_resource_t *resource,
				     unsigned int media_type) {
    return COAP_RESPONSE_405;
  }

  command int CoapResource.postMethod(coap_async_state_t* async_state,
				      uint8_t *val, size_t buflen, coap_resource_t *resource,
				      unsigned int media_type) {
    return COAP_RESPONSE_405;
  }

  command int CoapResource.deleteMethod(coap_async_state_t* async_state,
					uint8_t *val, size_t buflen) {
    return COAP_RESPONSE_405;
  }
  }
