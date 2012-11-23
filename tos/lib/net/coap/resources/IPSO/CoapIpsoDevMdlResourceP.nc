/*
 * Copyright (c) 2012 University of Bremen, TZI
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

generic module CoapIpsoDevMdlResourceP(uint8_t uri_key) {
  provides interface CoapResource;
} implementation {


#if defined(PLATFORM_BTNODE3)
#define INITIAL_DEFAULT_DATA_IPSO_MDL "BTNODE3"
#elif defined(PLATFORM_EPIC)
#define INITIAL_DEFAULT_DATA_IPSO_MDL "EPIC"
#elif defined(PLATFORM_EYESIFX)
#define INITIAL_DEFAULT_DATA_IPSO_MDL "EYESIFX"
#elif defined(PLATFORM_INTELMOTE2)
#define INITIAL_DEFAULT_DATA_IPSO_MDL "INTELMOTE2"
#elif defined(PLATFORM_IRIS)
#define INITIAL_DEFAULT_DATA_IPSO_MDL "IRIS"
#elif defined(PLATFORM_MICA)
#define INITIAL_DEFAULT_DATA_IPSO_MDL "MICA"
#elif defined(PLATFORM_MICA2)
#define INITIAL_DEFAULT_DATA_IPSO_MDL "MICA2"
#elif defined(PLATFORM_MICA2DOT)
#define INITIAL_DEFAULT_DATA_IPSO_MDL "MICA2DOT"
#elif defined(PLATFORM_MICAZ)
#define INITIAL_DEFAULT_DATA_IPSO_MDL "MICAZ"
#elif defined(PLATFORM_MULLE)
#define INITIAL_DEFAULT_DATA_IPSO_MDL "MULLE"
#elif defined(PLATFORM_SAM3S_EK)
#define INITIAL_DEFAULT_DATA_IPSO_MDL "SAM3S_EK"
#elif defined(PLATFORM_SAM3U_EK)
#define INITIAL_DEFAULT_DATA_IPSO_MDL "SAM3U_EK"
#elif defined(PLATFORM_SHIMMER)
#define INITIAL_DEFAULT_DATA_IPSO_MDL "SHIMMER"
#elif defined(PLATFORM_SHIMMER2)
#define INITIAL_DEFAULT_DATA_IPSO_MDL "SHIMMER2"
#elif defined(PLATFORM_SHIMMER2R)
#define INITIAL_DEFAULT_DATA_IPSO_MDL "SHIMMER2R"
#elif defined(PLATFORM_SPAN)
#define INITIAL_DEFAULT_DATA_IPSO_MDL "SPAN"
#elif defined(PLATFORM_TELOSA)
#define INITIAL_DEFAULT_DATA_IPSO_MDL "TELOSA"
#elif defined(PLATFORM_TELOSB)
#define INITIAL_DEFAULT_DATA_IPSO_MDL "TELOSB"
#elif defined(PLATFORM_TMOTE)
#define INITIAL_DEFAULT_DATA_IPSO_MDL "TMOTE"
#elif defined(PLATFORM_UCMINI)
#define INITIAL_DEFAULT_DATA_IPSO_MDL "UCMINI"
#elif defined(PLATFORM_Z1)
#define INITIAL_DEFAULT_DATA_IPSO_MDL "Z1"
#endif

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

    if ((r->data = (uint8_t *) coap_malloc(sizeof(INITIAL_DEFAULT_DATA_IPSO_MDL))) != NULL) {
      memcpy(r->data, INITIAL_DEFAULT_DATA_IPSO_MDL, sizeof(INITIAL_DEFAULT_DATA_IPSO_MDL));
      r->data_len = sizeof(INITIAL_DEFAULT_DATA_IPSO_MDL)-1;
    }

    return SUCCESS;
  }

  /////////////////////
  // GET:
  task void getMethod() {
    response = coap_new_pdu();
    response->hdr->code = COAP_RESPONSE_CODE(205);

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
  command int CoapResource.putMethod(coap_async_state_t* async_state,
				     coap_pdu_t* request,
				     coap_resource_t *resource,
				     unsigned int content_format) {
    return COAP_RESPONSE_405;
  }

  /////////////////////
  // POST:
  command int CoapResource.postMethod(coap_async_state_t* async_state,
				      coap_pdu_t* request,
				      struct coap_resource_t *resource,
				      unsigned int content_format) {
    return COAP_RESPONSE_405;
  }

  /////////////////////
  // DELETE:
  command int CoapResource.deleteMethod(coap_async_state_t* async_state,
					coap_pdu_t* request,
					struct coap_resource_t *resource) {
    return COAP_RESPONSE_405;
  }
}
