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

generic module CoapEtsiLinkResourceP(uint8_t uri_key) {
  provides interface CoapResource;
} implementation {

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
  unsigned char attr_value_ct_0[] = "0";
  unsigned char attr_value_ct_40[] = "40";

  unsigned char attr_name_rt[]   = "rt";
  unsigned char attr_value_rt1[] = "\"tc tf\"";
  unsigned char attr_value_rt2[] = "\"tf tk\"";
  unsigned char attr_value_rt3[] = "\"tc tk\"";
  //  unsigned char attr_value_rt4[] = "\"\"";

  unsigned char attr_name_if[]   = "if";
  unsigned char attr_value_if1[] = "\"If1\"";
  unsigned char attr_value_if2[] = "\"If2\"";
  unsigned char attr_value_if3[] = "foo";

  unsigned char attr_name_title[]   = "title";
  unsigned char attr_value_title[] = "\"t\"";

  unsigned char attr_name_size[]   = "sz";
  unsigned char attr_value_size[] = "128";

#define INITIAL_DEFAULT_DATA_LINK "l"
#define INITIAL_DEFAULT_DATA_LINK_PATH "</path/sub1>;ct=0,</path/sub2>;ct=0,</path/sub3>;ct=0"

  command error_t CoapResource.initResourceAttributes(coap_resource_t *r) {

    if (uri_key == INDEX_ETSI_PATH) {
      coap_add_attr(r,
		    attr_name_ct, sizeof(attr_name_ct)-1,
		    attr_value_ct_40, sizeof(attr_value_ct_40)-1, 0);
      if ((r->data = (uint8_t *) coap_malloc(sizeof(INITIAL_DEFAULT_DATA_LINK_PATH))) != NULL) {
	memcpy(r->data, INITIAL_DEFAULT_DATA_LINK_PATH, sizeof(INITIAL_DEFAULT_DATA_LINK_PATH));
	r->data_len = sizeof(INITIAL_DEFAULT_DATA_LINK_PATH)-1;
      }
      return SUCCESS;
    }

#ifdef COAP_CONTENT_TYPE_PLAIN
    coap_add_attr(r,
		  attr_name_ct, sizeof(attr_name_ct)-1,
		  attr_value_ct_0, sizeof(attr_value_ct_0)-1, 0);
#endif

    if (uri_key == INDEX_ETSI_LINK1) {
      coap_add_attr(r,
		    attr_name_rt, sizeof(attr_name_rt)-1,
		    attr_value_rt1, sizeof(attr_value_rt1)-1, 0);
      coap_add_attr(r,
		    attr_name_if, sizeof(attr_name_if)-1,
		    attr_value_if1, sizeof(attr_value_if1)-1, 0);
    } else if (uri_key == INDEX_ETSI_LINK2) {
      coap_add_attr(r,
		    attr_name_rt, sizeof(attr_name_rt)-1,
		    attr_value_rt2, sizeof(attr_value_rt2)-1, 0);
      coap_add_attr(r,
		    attr_name_if, sizeof(attr_name_if)-1,
		    attr_value_if2, sizeof(attr_value_if2)-1, 0);
    } else if (uri_key == INDEX_ETSI_LINK3) {
      coap_add_attr(r,
		    attr_name_rt, sizeof(attr_name_rt)-1,
		    attr_value_rt3, sizeof(attr_value_rt3)-1, 0);
      coap_add_attr(r,
		    attr_name_if, sizeof(attr_name_if)-1,
		    attr_value_if3, sizeof(attr_value_if3)-1, 0);
      //    } else if (uri_key == INDEX_ETSI_LINK4) {
      //coap_add_attr(r,
      //	    attr_name_rt, sizeof(attr_name_rt)-1,
      //	    attr_value_rt4, sizeof(attr_value_rt4)-1, 0);
    } else if (uri_key == INDEX_ETSI_LINK5) {
      coap_add_attr(r,
		    attr_name_size, sizeof(attr_name_size)-1,
		    attr_value_size, sizeof(attr_value_size)-1, 0);
    }
    // link5 is without "rt=" and "if="

    coap_add_attr(r,
		  attr_name_title, sizeof(attr_name_title)-1,
		  attr_value_title, sizeof(attr_value_title)-1, 0);

    if ((r->data = (uint8_t *) coap_malloc(sizeof(INITIAL_DEFAULT_DATA_LINK))) != NULL) {
      memcpy(r->data, INITIAL_DEFAULT_DATA_LINK, sizeof(INITIAL_DEFAULT_DATA_LINK));
      r->data_len = sizeof(INITIAL_DEFAULT_DATA_LINK)-1;
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
      if (uri_key == INDEX_ETSI_PATH)
	temp_content_format = COAP_MEDIATYPE_APPLICATION_LINK_FORMAT;
      else
	temp_content_format = COAP_MEDIATYPE_TEXT_PLAIN;

      post getMethod();
      return COAP_SPLITPHASE;
    } else {
      return COAP_RESPONSE_CODE(503);
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
				      coap_resource_t *resource,
				      unsigned int content_format) {
    return COAP_RESPONSE_405;
  }

  /////////////////////
  // DELETE:
  command int CoapResource.deleteMethod(coap_async_state_t* async_state,
					coap_pdu_t* request,
					coap_resource_t *resource) {
    return COAP_RESPONSE_405;
  }
}
