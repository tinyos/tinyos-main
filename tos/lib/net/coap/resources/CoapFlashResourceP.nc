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
#include <async.h>

generic module CoapFlashResourceP(uint8_t uri_key) {
    provides interface CoapResource;
    uses interface ConfigStorage;
} implementation {

    unsigned char buf[2];
    coap_pdu_t *temp_request;
    coap_pdu_t *response;
    bool lock = FALSE; //TODO: atomic
    coap_async_state_t *temp_async_state = NULL;
    coap_resource_t *temp_resource = NULL;
    unsigned int temp_content_format;
    config_t conf;

    enum {
	CONFIG_ADDR = 0
    };

    command error_t CoapResource.initResourceAttributes(coap_resource_t *r) {

#ifdef COAP_CONTENT_TYPE_PLAIN
	coap_add_attr(r, (unsigned char *)"ct", 2, (unsigned char *)"0", 1, 0);
#endif

	// default ETAG (ASCII characters)
	r->etag = 0x61;

	return SUCCESS;
    }


    /////////////
    //GET
    /////////////
    event void ConfigStorage.readDone(storage_addr_t addr, void* data,
				      storage_len_t len, error_t err)  {
	if (err == SUCCESS) {
	    memcpy(&conf, data, len);
	} else {
	    //printf("Read flash not successful\n");
	}

	response = coap_new_pdu();
	response->hdr->code = COAP_RESPONSE_CODE(205);

	if (temp_resource->data != NULL) {
	    coap_free(temp_resource->data);
	}
	if ((temp_resource->data = (uint8_t *) coap_malloc(len)) != NULL) {
	    memcpy(temp_resource->data, data, len);
	    temp_resource->data_len = len;
	} else {
	    response->hdr->code = COAP_RESPONSE_CODE(500);
	}


	coap_add_option(response, COAP_OPTION_ETAG,
			coap_encode_var_bytes(buf, temp_resource->etag), buf);

	coap_add_option(response, COAP_OPTION_CONTENT_TYPE,
			coap_encode_var_bytes(buf, temp_content_format), buf);
	//CHECK: COAP_MEDIATYPE_APPLICATION_OCTET_STREAM set?

	signal CoapResource.methodDone(err,
				       temp_async_state,
				       temp_request,
				       response,
				       temp_resource);
	lock = FALSE;
    }

    command int CoapResource.getMethod(coap_async_state_t* async_state,
				       coap_pdu_t* request,
				       coap_resource_t *resource,
				       unsigned int content_format) {
	if (lock == FALSE) {
	    lock = TRUE;
	    temp_async_state = async_state;
	    temp_request = request;
	    temp_resource = resource;
	    temp_content_format = content_format;

	    if (call ConfigStorage.valid() == TRUE) {
		if (call ConfigStorage.read(CONFIG_ADDR, &conf, sizeof(conf)) != SUCCESS) {
		    //printf("Config.read not successful\n");
		    lock = FALSE;
		    return COAP_RESPONSE_500;
		} else {
		    return COAP_SPLITPHASE;
		}
	    } else {
		lock = FALSE;
		return COAP_RESPONSE_500;
	    }
	} else {
	    lock = FALSE;
	    return COAP_RESPONSE_503;
	}
    }

    /////////////
    //PUT
    /////////////

#warning "FIXME: CoAP: PreAck not implemented for put"

    event void ConfigStorage.commitDone(error_t err) {

	response = coap_new_pdu();

	if (err == SUCCESS) {
	    response->hdr->code = COAP_RESPONSE_CODE(204);
	} else {
	    response->hdr->code = COAP_RESPONSE_CODE(500);
	}

	coap_add_option(response, COAP_OPTION_ETAG,
			coap_encode_var_bytes(buf, temp_resource->etag), buf);

	coap_add_option(response, COAP_OPTION_CONTENT_TYPE,
			coap_encode_var_bytes(buf, temp_content_format), buf);

	signal CoapResource.methodDone(err,
				       temp_async_state,
				       temp_request,
				       response,
				       temp_resource);

	lock = FALSE;
    }

    event void ConfigStorage.writeDone(storage_addr_t addr, void *data,
				       storage_len_t len, error_t err) {
	response = coap_new_pdu();
	if (err == SUCCESS) {
	    if (call ConfigStorage.commit() != SUCCESS) {
		response->hdr->code = COAP_RESPONSE_CODE(500);
	    } else {
		// will trigger commit done
		return;
	    }
	} else {
	    response->hdr->code = COAP_RESPONSE_CODE(500);
	}

	lock = FALSE;

	coap_add_option(response, COAP_OPTION_ETAG,
			coap_encode_var_bytes(buf, temp_resource->etag), buf);

	coap_add_option(response, COAP_OPTION_CONTENT_TYPE,
			coap_encode_var_bytes(buf, temp_content_format), buf);

	signal CoapResource.methodDone(err,
				       temp_async_state,
				       temp_request,
				       response,
				       temp_resource);
    }

    command int CoapResource.putMethod(coap_async_state_t* async_state,
				       coap_pdu_t* request,
				       coap_resource_t *resource,
				       unsigned int content_format) {
	size_t size;
	unsigned char *data;

	if (lock == FALSE) {
	    lock = TRUE;

	    temp_async_state = async_state;
	    temp_request = request;
	    temp_resource = resource;
	    temp_content_format = content_format; // FIXME: ANY???

	    coap_get_data(request, &size, &data);
	    //memcpy(&conf, val, buflen);

	    if (resource->data != NULL) {
		coap_free(resource->data);
	    }

	    switch(content_format) {
#ifdef COAP_CONTENT_TYPE_BINARY
	    case COAP_MEDIATYPE_APPLICATION_OCTET_STREAM:
		break;
	    case COAP_MEDIATYPE_ANY:
		temp_content_format = COAP_MEDIATYPE_APPLICATION_OCTET_STREAM;
#endif
	    default:
		return COAP_RESPONSE_500;
	    }

	    if ((resource->data = (uint8_t *) coap_malloc(size)) != NULL) {
		memcpy(resource->data, data, size);
		resource->data_len = size;
		temp_resource->dirty = 1;
		temp_resource->etag++; //ASCII chars

		if (call ConfigStorage.write(CONFIG_ADDR, data, size) != SUCCESS) {
		    //printf("Config.write not successful\n");
		    lock = FALSE;
		    return COAP_RESPONSE_500;
		} else {
		    return COAP_SPLITPHASE;
		}
	    } else {
		return COAP_RESPONSE_500;
	    }
	} else {
	    lock = FALSE;
	    return COAP_RESPONSE_503;
	}
    }

    command int CoapResource.postMethod(coap_async_state_t* async_state,
					coap_pdu_t* request,
					coap_resource_t *resource,
					unsigned int content_format) {
	return COAP_RESPONSE_405;
    }

    command int CoapResource.deleteMethod(coap_async_state_t* async_state,
					  coap_pdu_t* request,
					  coap_resource_t *resource) {
	return COAP_RESPONSE_405;
    }
  }
