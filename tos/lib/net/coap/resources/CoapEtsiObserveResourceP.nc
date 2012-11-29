/*
 * Copyright (c) 2011-2012 University of Bremen, TZI
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
#include <resource.h>

generic module CoapEtsiObserveResourceP(uint8_t uri_key) {
  provides interface CoapResource;
  uses interface Leds;
  uses interface Timer<TMilli> as UpdateTimer;
} implementation {

#define INITIAL_DEFAULT_DATA_OBS "obs"

  unsigned char buf[2];
  size_t size;
  uint8_t i = 0;
  unsigned char *payload;
  char data[5];
  coap_pdu_t *temp_request;
  coap_pdu_t *response;
  bool lock = FALSE; //TODO: atomic
  coap_async_state_t *temp_async_state = NULL;
  coap_resource_t *temp_resource = NULL;
  unsigned int temp_content_format;

  unsigned char attr_name_ct[]  = "ct";
  unsigned char attr_value_ct[] = "0";

  command error_t CoapResource.initResourceAttributes(coap_resource_t *r) {
#ifdef COAP_CONTENT_TYPE_PLAIN
    coap_add_attr(r,
		  attr_name_ct, sizeof(attr_name_ct)-1,
		  attr_value_ct, sizeof(attr_value_ct)-1, 0);
#endif

    if ((r->data = (uint8_t *) coap_malloc(sizeof(INITIAL_DEFAULT_DATA_OBS))) != NULL) {
      memcpy(r->data, INITIAL_DEFAULT_DATA_OBS, sizeof(INITIAL_DEFAULT_DATA_OBS));
      r->data_len = sizeof(INITIAL_DEFAULT_DATA_OBS)-1;
    }

    // default ETAG (ASCII characters)
    r->etag = 0x61;

    return SUCCESS;
  }

  /////////////////////
  // GET:
  task void getMethod() {
    response = coap_new_pdu();
    response->hdr->code = COAP_RESPONSE_CODE(205);

#ifndef WITHOUT_OBSERVE
     if (temp_async_state->flags & COAP_ASYNC_OBSERVED){
       coap_add_option(response, COAP_OPTION_SUBSCRIPTION, 0, NULL);
     }
#endif

     coap_add_option(response, COAP_OPTION_ETAG,
		    coap_encode_var_bytes(buf, temp_resource->etag), buf);

     coap_add_option(response, COAP_OPTION_CONTENT_TYPE,
		     coap_encode_var_bytes(buf, temp_content_format), buf);

     if (temp_resource->max_age != COAP_DEFAULT_MAX_AGE)
       coap_add_option(response, COAP_OPTION_MAXAGE,
      	      coap_encode_var_bytes(buf, temp_resource->max_age), buf);

    signal CoapResource.methodDone(SUCCESS,
				   temp_async_state,
				   temp_request,
				   response,
				   temp_resource);
    lock = FALSE;
  }

  event void UpdateTimer.fired() {
    i++;

    temp_resource->dirty = 1;
    temp_resource->etag++; //ASCII chars
    //temp_resource->etag = (temp_resource->etag + 1) << 2; //non-ASCII chars

    temp_resource->seq_num.length = sizeof(i);
    temp_resource->seq_num.s = &i;

    if (temp_resource->data != NULL) {
	coap_free(temp_resource->data);
    }
    if ((temp_resource->data = (uint8_t *) coap_malloc(sizeof(data))) != NULL) {
      sprintf(data, "%s%02u", (char *)INITIAL_DEFAULT_DATA_OBS, i);
      memcpy(temp_resource->data, data, sizeof(data));
      temp_resource->data_len = sizeof(data);
      temp_resource->data_ct = temp_content_format;
    }

    //   if(i >= 5){
    //call UpdateTimer.stop();
    //

    signal CoapResource.notifyObservers();
  }

  command int CoapResource.getMethod(coap_async_state_t* async_state,
				     coap_pdu_t* request,
				     struct coap_resource_t *resource,
				     unsigned int content_format) {
    if (lock == FALSE) {
      lock = TRUE;
      temp_async_state = async_state;
      temp_request = request;
      temp_resource = resource;
      temp_content_format = COAP_MEDIATYPE_TEXT_PLAIN;

      if (!call UpdateTimer.isRunning() && async_state->flags & COAP_ASYNC_OBSERVED) {
	call UpdateTimer.startPeriodic(5120);
	i = 0;
      } else {
	call UpdateTimer.stop();
      }

      post getMethod();

      return COAP_SPLITPHASE;
    } else {
      return COAP_RESPONSE_503;
    }
  }

  /////////////////////
  // PUT:
  task void putMethod() {
    response = coap_new_pdu();
    response->hdr->code = COAP_RESPONSE_CODE(204);

    coap_add_option(response, COAP_OPTION_ETAG,
		    coap_encode_var_bytes(buf, temp_resource->etag), buf);

    coap_add_option(response, COAP_OPTION_CONTENT_TYPE,
		    coap_encode_var_bytes(buf, temp_content_format), buf);

    signal CoapResource.methodDone(SUCCESS,
				   temp_async_state,
				   temp_request,
				   response,
				   temp_resource);

    signal CoapResource.notifyObservers();

    lock = FALSE;
  }

  command int CoapResource.putMethod(coap_async_state_t* async_state,
				     coap_pdu_t* request,
				     coap_resource_t *resource,
				     unsigned int content_format) {

    if (lock == FALSE) {
      lock = TRUE;

      i++;

      temp_async_state = async_state;
      temp_request = request;
      temp_resource = resource;
      temp_content_format = COAP_MEDIATYPE_TEXT_PLAIN;

      coap_get_data(request, &size, &payload);

      temp_resource->dirty = 1;
      temp_resource->etag++; //ASCII chars
      //temp_resource->etag = (temp_resource->etag + 1) << 2; //non-ASCII chars

      temp_resource->seq_num.length = sizeof(i);
      temp_resource->seq_num.s = &i;

      if (resource->data != NULL) {
	coap_free(resource->data);
      }

      if ((resource->data = (uint8_t *) coap_malloc(size)) != NULL) {
	memcpy(resource->data, payload, size);
	resource->data_len = size;
      } else {
	return COAP_RESPONSE_CODE(500);
	//return COAP_RESPONSE_CODE(413); or: too large?
      }
      post putMethod();
      return COAP_SPLITPHASE;
    } else {
      return COAP_RESPONSE_CODE(503);
    }
    //    return COAP_RESPONSE_405;
  }

  command int CoapResource.postMethod(coap_async_state_t* async_state,
				      coap_pdu_t* request,
				      struct coap_resource_t *resource,
				      unsigned int content_format) {
    return COAP_RESPONSE_405;
  }

  command int CoapResource.deleteMethod(coap_async_state_t* async_state,
					coap_pdu_t* request,
					struct coap_resource_t *resource) {
    return COAP_RESPONSE_405;
  }
}
