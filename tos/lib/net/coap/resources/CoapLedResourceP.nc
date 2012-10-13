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
#include <async.h>
#include <mem.h>

generic module CoapLedResourceP(uint8_t uri_key) {
  provides interface CoapResource;
  uses interface Leds;
} implementation {

  bool lock = FALSE;
  coap_async_state_t *temp_async_state = NULL;
  coap_resource_t *temp_resource = NULL;
  unsigned int temp_media_type;

  command error_t CoapResource.initResourceAttributes(coap_resource_t *r) {

#ifdef COAP_CONTENT_TYPE_PLAIN
    coap_add_attr(r, (unsigned char *)"ct", 2, (unsigned char *)"0", 1, 0);
#endif
#ifdef COAP_CONTENT_TYPE_BINARY
    coap_add_attr(r, (unsigned char *)"ct", 2, (unsigned char *)"42", 2, 0);
#endif

    return SUCCESS;
  }

  /////////////////////
  // GET:
  void task getMethod() {
    void *buf;
    int buflen = 0;
    char *cur;
    char buf2[4];
    uint8_t val = call Leds.get();
    buf = buf2;
    cur = buf;

    switch(temp_media_type) {
#ifdef COAP_CONTENT_TYPE_BINARY
    case COAP_MEDIATYPE_APPLICATION_OCTET_STREAM:
      buf = (uint8_t *)&val;
      buflen = sizeof(uint8_t);
      break;
#endif
#ifdef COAP_CONTENT_TYPE_PLAIN
    case COAP_MEDIATYPE_TEXT_PLAIN:
#endif
    case COAP_MEDIATYPE_ANY:
    default:
      cur += snprintf(cur, sizeof(buf2), "%i", val);
      buflen = cur - (char *)buf;
    }

    signal CoapResource.methodDone(SUCCESS, COAP_RESPONSE_CODE(205),
				   temp_async_state,
				   (uint8_t*)buf, buflen,
				   temp_media_type, NULL);
    lock = FALSE;
  };

  command int CoapResource.getMethod(coap_async_state_t* async_state,
				     uint8_t *val, size_t buflen,
				     unsigned int media_type) {
    if (lock == FALSE) {
      lock = TRUE;
      temp_async_state = async_state;
      temp_media_type = media_type;
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
				   temp_media_type,
				   temp_resource);
  };

  command int CoapResource.putMethod(coap_async_state_t* async_state,
				     uint8_t *val, size_t buflen, coap_resource_t *resource,
				     unsigned int media_type) {

    switch(media_type) {
#ifdef COAP_CONTENT_TYPE_BINARY
    case COAP_MEDIATYPE_APPLICATION_OCTET_STREAM:
      break;
#endif
#ifdef COAP_CONTENT_TYPE_PLAIN
    case COAP_MEDIATYPE_TEXT_PLAIN:
#endif
    case COAP_MEDIATYPE_ANY:
    default:
      *val = *val - *(uint8_t *)"0";
    }

    if (buflen == 1 && *val < 8) {
      if (lock == FALSE) {
	lock = TRUE;
	temp_async_state = async_state;
	temp_resource = resource;
	temp_media_type = media_type;

	call Leds.set(*val);
	temp_resource->dirty = 1;
	temp_resource->data_len = buflen;
	if ((resource->data = (uint8_t *) coap_malloc(buflen)) != NULL) {
	  memcpy(resource->data, val, buflen);
	} else {
	  return COAP_RESPONSE_CODE(500);
	}
	post putMethod();
	return COAP_SPLITPHASE;
      } else {
	return COAP_RESPONSE_CODE(503);
      }
    } else {
      return COAP_RESPONSE_CODE(413);
    }
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
