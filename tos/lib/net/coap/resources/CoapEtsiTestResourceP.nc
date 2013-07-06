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
#include <mem.h>
#include <resource.h>

generic module CoapEtsiTestResourceP(uint8_t uri_key) {
  provides interface CoapResource;
  uses interface CoAPServer;
  uses interface Leds;
} implementation {

#define INITIAL_DEFAULT_DATA_TEST "test"

  unsigned char buf[2];
  size_t size;
  unsigned char *data;
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

    if ((r->data = (uint8_t *) coap_malloc(sizeof(INITIAL_DEFAULT_DATA_TEST))) != NULL) {
      memcpy(r->data, INITIAL_DEFAULT_DATA_TEST, sizeof(INITIAL_DEFAULT_DATA_TEST));
      r->data_len = sizeof(INITIAL_DEFAULT_DATA_TEST)-1;
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

    coap_add_option(response, COAP_OPTION_ETAG,
		    coap_encode_var_bytes(buf, temp_resource->etag), buf);

    coap_add_option(response, COAP_OPTION_CONTENT_TYPE,
		    coap_encode_var_bytes(buf, temp_content_format), buf);

    signal CoapResource.methodDone(SUCCESS,
				   temp_async_state,
				   temp_request,
				   response,
				   temp_resource);
    lock = FALSE;
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
    lock = FALSE;
  }

  command int CoapResource.putMethod(coap_async_state_t* async_state,
				     coap_pdu_t* request,
				     coap_resource_t *resource,
				     unsigned int content_format) {

    if (lock == FALSE) {
      lock = TRUE;

      temp_async_state = async_state;
      temp_request = request;
      temp_resource = resource;
      temp_content_format = COAP_MEDIATYPE_TEXT_PLAIN;

      coap_get_data(request, &size, &data);

      temp_resource->dirty = 1;
      temp_resource->etag++; //ASCII chars
      //temp_resource->etag = (temp_resource->etag + 1) << 2; //non-ASCII chars

      if (resource->data != NULL) {
	coap_free(resource->data);
      }

      if ((resource->data = (uint8_t *) coap_malloc(size)) != NULL) {
	memcpy(resource->data, data, size);
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
  }

  /////////////////////
  // POST:
  task void postMethod() {
    response = coap_new_pdu();
    response->hdr->code = COAP_RESPONSE_CODE(201);

    coap_add_option(response, COAP_OPTION_LOCATION_PATH,
		    sizeof("location1")-1, (unsigned char *)"location1");
    coap_add_option(response, COAP_OPTION_LOCATION_PATH,
		    sizeof("location2")-1, (unsigned char *)"location2");
    coap_add_option(response, COAP_OPTION_LOCATION_PATH,
		    sizeof("location3")-1, (unsigned char *)"location3");

    if (temp_resource->data_len != 0)
      coap_add_option(response, COAP_OPTION_CONTENT_TYPE,
		      coap_encode_var_bytes(buf, temp_content_format), buf);

    signal CoapResource.methodDone(SUCCESS,
				   temp_async_state,
				   temp_request,
				   response,
				   temp_resource);
    lock = FALSE;
  }

  command int CoapResource.postMethod(coap_async_state_t* async_state,
				      coap_pdu_t* request,
				      struct coap_resource_t *resource,
				      unsigned int content_format) {

    coap_resource_t* r;

    if (lock == FALSE) {
      lock = TRUE;

      r = call CoAPServer.registerDynamicResource((unsigned char*)"location1/location2/location3",
						  sizeof("location1/location2/location3"),
						  GET_SUPPORTED|PUT_SUPPORTED|POST_SUPPORTED|DELETE_SUPPORTED);

      coap_get_data(request, &size, &data);

      if ((r->data = (uint8_t *) coap_malloc(size)) != NULL) {
	memcpy(r->data, data, size);
	r->data_len = size;
      } else {
	return COAP_RESPONSE_CODE(500);
	//return COAP_RESPONSE_CODE(413); or: too large?
      }

      temp_async_state = async_state;
      temp_request = request;
      temp_resource = r;
      temp_content_format = content_format;

      post postMethod();
      return COAP_SPLITPHASE;
    } else {
      return COAP_RESPONSE_503;
    }
  }

  /////////////////////
  // DELETE:
  task void deleteMethod() {

    error_t rc = call CoAPServer.deregisterDynamicResource(temp_resource);

    response = coap_new_pdu();

    if (rc == SUCCESS)
      response->hdr->code = COAP_RESPONSE_CODE(202);
    else
      response->hdr->code = COAP_RESPONSE_CODE(500);

    signal CoapResource.methodDone(SUCCESS,
				   temp_async_state,
				   temp_request,
				   response,
				   NULL);
    lock = FALSE;
  }

  command int CoapResource.deleteMethod(coap_async_state_t* async_state,
					coap_pdu_t* request,
					struct coap_resource_t *resource) {
    if (lock == FALSE) {
      lock = TRUE;
      temp_async_state = async_state;
      temp_request = request;
      temp_resource = resource;
      post deleteMethod();
      return COAP_SPLITPHASE;
    } else {
      return COAP_RESPONSE_503;
    }
  }
}
