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

generic module CoapEtsiSegmentResourceP(uint8_t uri_key) {
    provides interface ReadResource;
    provides interface WriteResource;
} implementation {

    bool lock = FALSE;
    coap_async_state_t *temp_async_state = NULL;
    uint8_t temp_val = 0;

    /////////////////////
    // GET:
    task void get() {
	lock = FALSE;
	signal ReadResource.getDone(SUCCESS, temp_async_state,
				    (uint8_t*)&temp_val, sizeof(uint8_t),
				    COAP_MEDIATYPE_APPLICATION_OCTET_STREAM);
    }

    command int ReadResource.get(coap_async_state_t* async_state) {
	if (lock == FALSE) {
	    lock = TRUE;
	    temp_async_state = async_state;
	    post get();

	    return COAP_SPLITPHASE;
	} else {
	    return COAP_RESPONSE_503;
	}
    }

    /////////////////////
    // PUT:
    void task put() {
	lock = FALSE;
	signal WriteResource.putDone(SUCCESS, temp_async_state,
				     NULL, 0,
				     COAP_MEDIATYPE_ANY);
    }

    command int WriteResource.put(coap_async_state_t* async_state, uint8_t *val, size_t buflen) {
	if ( /*1 == 1*/buflen == 1 && val[0] < 8) {
	    if (lock == FALSE) {
		lock = TRUE;
		temp_async_state = async_state;
		temp_val = *val;
		post put();
		return COAP_SPLITPHASE;
	    } else {
		return COAP_RESPONSE_503;
	    }
	} else {
	    return COAP_RESPONSE_500;
	}
    }
}
