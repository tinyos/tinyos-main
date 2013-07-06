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

#include <async.h>
#include <resource.h>
#include <pdu.h>

interface CoapResource {

    command error_t initResourceAttributes(coap_resource_t *r);

    //TODO: insert URI or request into call?
    command int getMethod(coap_async_state_t* async_state,
			  coap_pdu_t* request,
			  struct coap_resource_t *resource,
			  unsigned int content_format);

    command int putMethod(coap_async_state_t* async_state,
			  coap_pdu_t* request,
			  struct coap_resource_t *resource,
			  unsigned int content_format);

    command int postMethod(coap_async_state_t* async_state,
			   coap_pdu_t* request,
			   struct coap_resource_t *resource,
			   unsigned int content_format);

    command int deleteMethod(coap_async_state_t* async_state,
			     coap_pdu_t* request,
			     struct coap_resource_t *resource);

    event void methodDone(error_t result,
			  coap_async_state_t* async_state,
			  coap_pdu_t* request,
			  coap_pdu_t* response,
			  struct coap_resource_t* resource);

    event void methodNotDone(coap_async_state_t* async_state,
			     uint8_t responsecode);

    event void methodDoneSeparate(error_t result,
				  coap_async_state_t* async_state,
				  coap_pdu_t* request,
				  coap_pdu_t* response,
				  struct coap_resource_t* resource);

    event void notifyObservers();
}
