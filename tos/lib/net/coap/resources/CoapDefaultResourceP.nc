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
#include <uri.h>

generic module CoapDefaultResourceP(uint8_t uri_key) {
  provides interface CoapResource;
  uses interface CoAPServer;
  uses interface Leds;
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
  int temp_rc;
  bool temp_created;

  command error_t CoapResource.initResourceAttributes(coap_resource_t *r) {
#ifdef COAP_CONTENT_TYPE_PLAIN
    coap_add_attr(r, (unsigned char *)"ct", 2, (unsigned char *)"0", 1, 0);
#endif

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

      if (resource->data != NULL) {
	coap_free(resource->data);
      }

      if ((resource->data = (uint8_t *) coap_malloc(size)) != NULL) {
	memcpy(resource->data, data, size);
	resource->data_len = size;
      temp_resource->dirty = 1;
      temp_resource->etag++; //ASCII chars
      //temp_resource->etag = (temp_resource->etag + 1) << 2; //non-ASCII chars
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
    response->hdr->code = temp_rc;

    coap_add_option(response, COAP_OPTION_ETAG,
		    coap_encode_var_bytes(buf, temp_resource->etag), buf);

    if (temp_created) {
	coap_add_option(response, COAP_OPTION_LOCATION_PATH,
			sizeof("location1")-1, (unsigned char *)"location1");
	coap_add_option(response, COAP_OPTION_LOCATION_PATH,
			sizeof("location2")-1, (unsigned char *)"location2");
	coap_add_option(response, COAP_OPTION_LOCATION_PATH,
			sizeof("location3")-1, (unsigned char *)"location3");
    }

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

    coap_resource_t *r = NULL;
    coap_opt_iterator_t opt_iter;
    coap_opt_filter_t filter;
    coap_opt_t *option;
    //coap_uri_t *uri;
    //coap_dynamic_uri_t *uri;
    size_t pathlen;
    str path;
    coap_key_t key;

    if (lock == FALSE) {
	lock = TRUE;

	if (resource == NULL) {

	    coap_option_filter_clear(filter);
	    coap_option_setb(filter, COAP_OPTION_URI_PATH);

	    coap_option_iterator_init((coap_pdu_t *)request, &opt_iter, filter);

	    pathlen = 0;
	    if ((option = coap_option_next(&opt_iter))) {
		pathlen = COAP_OPT_LENGTH(option);

		while ((option = coap_option_next(&opt_iter))) {
		    pathlen += COAP_OPT_SIZE(option);
		}
	    }

	    if (pathlen > 0) {
		//path.s = coap_new_string(pathlen);

		coap_option_iterator_init((coap_pdu_t *)request, &opt_iter, filter);

		option = coap_option_next(&opt_iter);
		path.s = COAP_OPT_VALUE(option); //CHECK: does this include /'s?
		path.length = pathlen;

		r = call CoAPServer.registerDynamicResource(path.s, path.length+1, //+1??
							    GET_SUPPORTED|PUT_SUPPORTED|
							    POST_SUPPORTED|DELETE_SUPPORTED);
	    } else {
		return COAP_RESPONSE_CODE(500);
	    }
	    temp_rc = COAP_RESPONSE_CODE(201);
	} else {
	    memset(key, 0, 4);
	    coap_hash((unsigned char*)"location1",
		      sizeof("location1")-1, key);
	    coap_hash((unsigned char*)"location2",
		      sizeof("location2")-1, key);
	    coap_hash((unsigned char*)"location3",
		      sizeof("location2")-1, key);

	    if (call CoAPServer.findResource(key) == SUCCESS) {
		// resource does exist -> update
		temp_created = TRUE;//FALSE
		temp_rc = COAP_RESPONSE_CODE(201);//204
	    } else {
		// resource does not exist -> create
		r = call CoAPServer.registerDynamicResource((unsigned char*)"location1/location2/location3",
							    sizeof("location1/location2/location3"),
							    GET_SUPPORTED|PUT_SUPPORTED|POST_SUPPORTED|DELETE_SUPPORTED);

		temp_created = TRUE;
		temp_rc = COAP_RESPONSE_CODE(201);
	    }
	}

	coap_get_data(request, &size, &data);

	temp_resource->dirty = 1;
	temp_resource->etag++; //ASCII chars
	//temp_resource->etag = (temp_resource->etag + 1) << 2; //non-ASCII chars

	if (resource->data != NULL) {
	    coap_free(resource->data);
	}

	if ((r->data = (uint8_t *) coap_malloc(size)) != NULL) {
	    memcpy(r->data, data, size);
	    r->data_len = size;
	} else {
	    return COAP_RESPONSE_CODE(500);
	    //return COAP_RESPONSE_CODE(413); or: too large?
	}

	temp_async_state = async_state;
	temp_resource = r;
	temp_request = request;
	temp_content_format = COAP_MEDIATYPE_TEXT_PLAIN;

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
