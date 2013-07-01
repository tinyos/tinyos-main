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

generic module CoapIpsoDevBatteryResourceP(typedef val_t, uint8_t uri_key) {
    provides interface CoapResource;
    uses interface Timer<TMilli> as PreAckTimer;
    uses interface Read<val_t>;
} implementation {

  unsigned char buf[2];
  coap_pdu_t *temp_request;
  coap_pdu_t *response;
  bool lock = FALSE; //TODO: atomic
  coap_async_state_t *temp_async_state = NULL;
  coap_resource_t *temp_resource = NULL;
  unsigned int temp_content_format;

  command error_t CoapResource.initResourceAttributes(coap_resource_t *r) {

#ifdef COAP_CONTENT_TYPE_PLAIN
    coap_add_attr(r, (unsigned char *)"ct", 2, (unsigned char *)"0", 1, 0);
#endif

    return SUCCESS;
  }

  /////////////////////
  // GET:
  event void PreAckTimer.fired() {
    signal CoapResource.methodNotDone(temp_async_state,
				      COAP_RESPONSE_CODE(0));
  }

  event void Read.readDone(error_t result, val_t val) {
    void *datap;
    int datalen = 0;
    char *cur;
    char databuf[COAP_MAX_PDU_SIZE];
    datap = databuf;
    cur = datap;

    switch(temp_content_format) {
#ifdef COAP_CONTENT_TYPE_PLAIN
    case COAP_MEDIATYPE_TEXT_PLAIN:
#endif
    case COAP_MEDIATYPE_ANY:
    default:
      temp_content_format = COAP_MEDIATYPE_TEXT_PLAIN;
      cur += snprintf(cur, sizeof(databuf), "%d", val);
      datalen = cur - (char *)datap;
    }

    response = coap_new_pdu();
    response->hdr->code = COAP_RESPONSE_CODE(205);

    if (temp_resource->data != NULL) {
      coap_free(temp_resource->data);
    }
    if ((temp_resource->data = (uint8_t *) coap_malloc(datalen)) != NULL) {
      memcpy(temp_resource->data, datap, datalen);
      temp_resource->data_len = datalen;
    } else {
      response->hdr->code = COAP_RESPONSE_CODE(500);
    }

    coap_add_option(response, COAP_OPTION_ETAG,
		    coap_encode_var_bytes(buf, temp_resource->etag), buf);

    coap_add_option(response, COAP_OPTION_CONTENT_TYPE,
		    coap_encode_var_bytes(buf, temp_content_format), buf);

    if (call PreAckTimer.isRunning()) {
      call PreAckTimer.stop();
      signal CoapResource.methodDone(SUCCESS,
				     temp_async_state,
				     temp_request,
				     response,
				     temp_resource);
    } else {
      signal CoapResource.methodDoneSeparate(SUCCESS,
					     temp_async_state,
					     temp_request,
					     response,
					     temp_resource);

    }
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

      call PreAckTimer.startOneShot(COAP_PREACK_TIMEOUT);
      call Read.read();
      return COAP_SPLITPHASE;
    } else {
      return COAP_RESPONSE_503;
    }
  }

  command int CoapResource.putMethod(coap_async_state_t* async_state,
				     coap_pdu_t* request,
				     coap_resource_t *resource,
				     unsigned int content_format) {
    return COAP_RESPONSE_405;
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
