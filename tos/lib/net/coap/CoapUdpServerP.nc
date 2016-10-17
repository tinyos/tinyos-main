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

#include <lib6lowpan/lib6lowpan.h>

#include <net.h>

#include <async.h>
#include <resource.h>
#include <uri.h>
#include <coap_debug.h>
#include <pdu.h>
#include <subscribe.h>  // for resource_t
#include <encode.h>
#include <mem.h>
#include <block.h>

#include "tinyos_coap_resources.h"
#include "blip_printf.h"

//#define INDEX "CoAPUdpServer: It works!!"
#define COAP_MEDIATYPE_NOT_SUPPORTED 0xfe

module CoapUdpServerP {
    provides interface CoAPServer;
    uses interface LibCoAP as LibCoapServer;
    uses interface Leds;
    uses interface CoapResource[uint8_t uri];
} implementation {
    coap_context_t *ctx_server;
    coap_resource_t *r;
    unsigned char buf[2]; //used for coap_encode_var_bytes()

    //get index (int) from uri_key (char[4])
    //defined in tinyos_coap_resources.h
    uint8_t get_index_for_key(coap_key_t uri_key) {
	uint8_t i = 0;
	for (; i < COAP_LAST_RESOURCE; i++) {
	    if (memcmp(uri_index_map[i].uri_key, uri_key, sizeof(coap_key_t)) == 0)
		return uri_index_map[i].index;
	}
	return COAP_NO_SUCH_RESOURCE;
    }

    void hnd_coap_async_tinyos(coap_context_t  *ctx,
			       struct coap_resource_t *resource,
			       coap_address_t *peer,
			       coap_pdu_t *request,
			       str *token,
			       coap_pdu_t *response);

    int coap_save_splitphase(coap_context_t *ctx, coap_queue_t *node);

    command error_t CoAPServer.setupContext(uint16_t port) {
	coap_address_t listen_addr;

	coap_address_init(&listen_addr);
	listen_addr.addr.sin6_port = port;
	//TODO: address needed?

	ctx_server = coap_new_context(&listen_addr);

	if (!ctx_server) {
	    return FAIL;
	}

#ifndef WITHOUT_BLOCK
	coap_register_option(ctx_server, COAP_OPTION_BLOCK2);
#endif
	coap_register_option(ctx_server, COAP_OPTION_IF_MATCH);
	coap_register_option(ctx_server, COAP_OPTION_IF_NONE_MATCH);

	return call LibCoapServer.setupContext(port);
    }

    ///////////////////
    // register resources
    command error_t CoAPServer.registerResources() {
      int i;

      if (ctx_server == NULL)
	return FAIL;

      r = call CoAPServer.registerDynamicResource((unsigned char*)"test", sizeof("test"),
						  GET_SUPPORTED|PUT_SUPPORTED|POST_SUPPORTED|DELETE_SUPPORTED);

      for (i=0; i < COAP_LAST_RESOURCE; i++) {
	// set the hash for the URI
	coap_hash_path(uri_index_map[i].uri,
		       uri_index_map[i].uri_len - 1,
		       uri_index_map[i].uri_key);

	r = coap_resource_init((unsigned char *)uri_index_map[i].uri,
			       uri_index_map[i].uri_len-1, 0);
	if (r == NULL)
	  return FAIL;

	r->data = NULL;

	if ((uri_index_map[i].supported_methods & GET_SUPPORTED) == GET_SUPPORTED)
	  coap_register_handler(r, COAP_REQUEST_GET, hnd_coap_async_tinyos);
	if ((uri_index_map[i].supported_methods & POST_SUPPORTED) == POST_SUPPORTED)
	  coap_register_handler(r, COAP_REQUEST_POST, hnd_coap_async_tinyos);
	if ((uri_index_map[i].supported_methods & PUT_SUPPORTED) == PUT_SUPPORTED)
	  coap_register_handler(r, COAP_REQUEST_PUT, hnd_coap_async_tinyos);
	if ((uri_index_map[i].supported_methods & DELETE_SUPPORTED) == DELETE_SUPPORTED)
	  coap_register_handler(r, COAP_REQUEST_DELETE, hnd_coap_async_tinyos);

#ifndef WITHOUT_OBSERVE
	r->observable = uri_index_map[i].observable;
#endif

	r->max_age = uri_index_map[i].max_age;

	call CoapResource.initResourceAttributes[i](r);

	coap_add_resource(ctx_server, r);
      }

      return SUCCESS;
    }

    command coap_resource_t* CoAPServer.registerDynamicResource(unsigned char* uri, unsigned int uri_len,
						       unsigned int supported_methods) {
      if (ctx_server == NULL)
	return NULL;

      /*coap_hash_path(uri,
		     uri_len - 1,
		     uri_key);*/ // will be handled by default dynamic resource anyway

      r = coap_resource_init(uri, uri_len-1, 0);
      if (r == NULL)
	return NULL;

      r->data = NULL;

      if ((supported_methods & GET_SUPPORTED) == GET_SUPPORTED)
	coap_register_handler(r, COAP_REQUEST_GET, hnd_coap_async_tinyos);
      if ((supported_methods & POST_SUPPORTED) == POST_SUPPORTED)
	coap_register_handler(r, COAP_REQUEST_POST, hnd_coap_async_tinyos);
      if ((supported_methods & PUT_SUPPORTED) == PUT_SUPPORTED)
	coap_register_handler(r, COAP_REQUEST_PUT, hnd_coap_async_tinyos);
      if ((supported_methods & DELETE_SUPPORTED) == DELETE_SUPPORTED)
	coap_register_handler(r, COAP_REQUEST_DELETE, hnd_coap_async_tinyos);

#ifndef WITHOUT_OBSERVE
      //r->observable = uri_index_map[i].observable; //TODO
#endif
#ifdef COAP_RESOURCE_DEFAULT
      call CoapResource.initResourceAttributes[INDEX_DEFAULT](r);//TODO
#endif

      coap_add_resource(ctx_server, r);
      return r;
    }

    command error_t CoAPServer.deregisterDynamicResource(coap_resource_t* resource) {
      if (ctx_server == NULL || resource == NULL)
	return FAIL;

      if (coap_delete_resource(ctx_server, resource->key))
	return SUCCESS;
      else
	return FAIL;
    }

    command error_t CoAPServer.findResource(coap_key_t key) {
      if (coap_get_resource_from_key(ctx_server, key))
	return SUCCESS;

      return FAIL;
    }

    event void LibCoapServer.read(struct sockaddr_in6 *from, void *data,
				  uint16_t len, struct ip6_metadata *meta) {

	printf("CoapUdpServer: LibCoapServer.read()\n");
	/*call Leds.led0On();
	  call Leds.led1On();
	  call Leds.led2On();*/

	// CHECK: lock access to context?
	// copy data into ctx_server
	ctx_server->bytes_read = len;
	memcpy(ctx_server->buf, data, len);
	// copy src into context
	memcpy(&ctx_server->src.addr, from, sizeof (struct sockaddr_in6));

	coap_read(ctx_server);
	coap_dispatch(ctx_server);
    }

#ifdef COAP_RESOURCE_DEFAULT
    ///////////////////
    // PUT/POST default handler for TinyOS fo non-existing resources
    void hnd_coap_default_tinyos(coap_context_t  *ctx,
				 struct coap_resource_t *resource,
				 coap_address_t *peer,
				 coap_pdu_t *request,
				 str *token,
				 coap_pdu_t *response) @C() @spontaneous() {
      coap_async_state_t *async_state = NULL;
      int rc;
      coap_pdu_t *temp_request;
      unsigned int media_type = COAP_MEDIATYPE_TEXT_PLAIN;

      async_state = coap_register_async(ctx, peer, request,
					COAP_ASYNC_CONFIRM,
					(void *)NULL);

      temp_request =  coap_clone_pdu(request);

      response->hdr->type = COAP_MESSAGE_NON;
      rc = call CoapResource.postMethod[INDEX_DEFAULT](async_state,
					     temp_request,
					     resource,
					     media_type);
    }
#endif

    ///////////////////
    // all TinyOS CoAP requests have to go through this
    void hnd_coap_async_tinyos(coap_context_t  *ctx,
			       struct coap_resource_t *resource,
			       coap_address_t *peer,
			       coap_pdu_t *request,
			       str *token,
			       coap_pdu_t *response) {

	coap_opt_iterator_t opt_iter;
	coap_opt_t *option;
	int rc;
	uint8_t rk;
	coap_async_state_t *tmp;
	coap_async_state_t *async_state = NULL;
	coap_pdu_t *temp_request;
	unsigned int media_type = COAP_MEDIATYPE_NOT_SUPPORTED;
	coap_attr_t *attr = NULL;
	coap_option_iterator_init(request, &opt_iter, COAP_OPT_ALL);

#ifndef WITHOUT_OBSERVE
	//handler has been called by check_notify() //thp: move above media type stuff
	if (request == NULL){

	  //TODO: check options
	  coap_add_option(response, COAP_OPTION_SUBSCRIPTION,
			  resource->seq_num.length, resource->seq_num.s);

	  coap_add_option(response, COAP_OPTION_CONTENT_TYPE,
			  coap_encode_var_bytes(buf, resource->data_ct), buf);

	  if (resource->max_age != COAP_DEFAULT_MAX_AGE)
	    coap_add_option(response, COAP_OPTION_MAXAGE,
			    coap_encode_var_bytes(buf, resource->max_age), buf);


	  if (token->length)
	    coap_add_token(response, token->length, token->s);

	  if (resource->data_len != 0) {
	    coap_add_data(response, resource->data_len, resource->data);
	    response->hdr->code = COAP_RESPONSE_CODE(205);
	  } else
	    response->hdr->code = COAP_RESPONSE_CODE(500);

	  return;
	}
#endif

	/* set content_format if available */
	if (((option = coap_check_option(request, COAP_OPTION_ACCEPT, &opt_iter)) && request->hdr->code == COAP_REQUEST_GET) ||
	    ((option = coap_check_option(request, COAP_OPTION_CONTENT_TYPE, &opt_iter)) && (request->hdr->code & (COAP_REQUEST_PUT & COAP_REQUEST_POST)))) {
	  do {
	    while ((attr = coap_find_attr(resource, attr, (unsigned char*)"ct", 2))){
	      if (atoi((const char *)attr->value.s) == coap_decode_var_bytes(COAP_OPT_VALUE(option),
									     COAP_OPT_LENGTH(option))) {
		media_type = coap_decode_var_bytes(COAP_OPT_VALUE(option),
						   COAP_OPT_LENGTH(option));
		break;
	      }
	    }
	  } while (coap_option_next(&opt_iter) && (attr == NULL));
	} else {
	  media_type = COAP_MEDIATYPE_ANY;
	}

	if (media_type == COAP_MEDIATYPE_NOT_SUPPORTED) {
	  response->hdr->code = (request->hdr->code == COAP_REQUEST_GET
				 ? COAP_RESPONSE_CODE(406)
				 : COAP_RESPONSE_CODE(415));
	  if (token->length)
	    coap_add_token(response, token->length, token->s);
	  goto cleanup;
	}

	//ETAG
	if ((option = coap_check_option(request, COAP_OPTION_ETAG, &opt_iter)) && request->hdr->code == COAP_REQUEST_GET) {
	  if (resource->etag == coap_decode_var_bytes(COAP_OPT_VALUE(option), COAP_OPT_LENGTH(option))) {
	    coap_add_option(response, COAP_OPTION_ETAG,
			    coap_encode_var_bytes(buf, resource->etag), buf);
	    if (token->length)
		coap_add_token(response, token->length, token->s);
	    response->hdr->code = COAP_RESPONSE_CODE(203);
	    return;
	  }
	}

	//If-None-Match
	//
	if ((option = coap_check_option(request, COAP_OPTION_IF_NONE_MATCH, &opt_iter)) && request->hdr->code == COAP_REQUEST_PUT) {
	  if (token->length)
	    coap_add_token(response, token->length, token->s);
	  response->hdr->code = COAP_RESPONSE_CODE(412);
	  return;
	}

	//If-Match
	if ((option = coap_check_option(request, COAP_OPTION_IF_MATCH, &opt_iter)) && request->hdr->code == COAP_REQUEST_PUT) {
	  if (resource->etag != coap_decode_var_bytes(COAP_OPT_VALUE(option),COAP_OPT_LENGTH(option))) {
	    if (token->length)
	      coap_add_token(response, token->length, token->s);
	    response->hdr->code = COAP_RESPONSE_CODE(412);
	    return;
	  }
	}

#ifndef WITHOUT_OBSERVE
	if (coap_check_option(request, COAP_OPTION_SUBSCRIPTION, &opt_iter)){
	  coap_add_observer(resource, peer, token);
	  async_state = coap_register_async(ctx, peer, request,
					    COAP_ASYNC_OBSERVED,
					    (void *)NULL);
	} else {
	  //remove client from observer list, if already registered
	  if (coap_find_observer(resource, peer, NULL) && request->hdr->code == COAP_REQUEST_GET) {
	    coap_delete_observer(resource, peer, NULL);
	  }
#endif
	  async_state = coap_register_async(ctx, peer, request,
					    COAP_ASYNC_CONFIRM,
					    (void *)NULL);

#ifndef WITHOUT_OBSERVE
	}
#endif
	temp_request =  coap_clone_pdu(request);

	/*
	  call Leds.led0On();
	  call Leds.led1On();
	  call Leds.led2On();
	*/

	/* if (token->length) */
	/*   coap_add_option(response, COAP_OPTION_TOKEN, token->length, token->s); */

	/* response->length += snprintf((char *)response->data, */
	/* 				 response->max_size - response->length, */
	/* 				 "%u", 42); */

	// coap_get_data(request, &size, &data);

	rk = get_index_for_key(resource->key);

#ifdef COAP_RESOURCE_DEFAULT
	if (rk == COAP_NO_SUCH_RESOURCE)
	  rk = INDEX_DEFAULT;
#endif

	if (request->hdr->code == COAP_REQUEST_GET)
	    rc = call CoapResource.getMethod[rk](async_state,
						 temp_request,
						 resource,
						 media_type);
	else if (request->hdr->code == COAP_REQUEST_POST)
	    rc = call CoapResource.postMethod[rk](async_state,
						  temp_request,
						  resource,
						  media_type);
	else if (request->hdr->code == COAP_REQUEST_PUT)
	    rc = call CoapResource.putMethod[rk](async_state,
						 temp_request,
						 resource,
						 media_type);
	else if (request->hdr->code == COAP_REQUEST_DELETE)
	    rc = call CoapResource.deleteMethod[rk](async_state,
						    temp_request,
						    resource);
	else {
	  rc = COAP_RESPONSE_CODE(405);
	}

	if (rc == FAIL) {
	    /* default handler returns FAIL -> Resource not available -> Response: 404 */
	    response->hdr->code = COAP_RESPONSE_CODE(404);

	    //TODO: set hdr->type?

	    if (token->length)
		coap_add_token(response, token->length, token->s);

	} else if (request->hdr->type == COAP_MESSAGE_NON) {
	    /* don't reply with ACK to NON's. Set response type to
	       COAP_MESSAGE_NON, so that net.c is not sending it.  */
	    response->hdr->type = COAP_MESSAGE_NON;
	    response->hdr->code = 0x0;
	} else if (rc == COAP_SPLITPHASE) {
	    /* TinyOS is split-phase, only in error case an immediate response
	       is set. Otherwise set type to COAP_MESSAGE_NON, so that net.c
	       is not sending it. */
	    response->hdr->type = COAP_MESSAGE_NON;
	    return;
	} else {
	    response->hdr->code = rc;
	    //CHECK: set hdr->type?

	    if (token->length)
		coap_add_token(response, token->length, token->s);
	}

	//we don't have split-phase -> do some cleanup
	cleanup:
	coap_remove_async(ctx, async_state->id, &tmp);
	coap_free_async(async_state);
	async_state = NULL;
    }

 default command error_t CoapResource.initResourceAttributes[uint8_t uri_key](coap_resource_t *resource) {
   return FAIL;
 }

 default command int CoapResource.getMethod[uint8_t uri_key](coap_async_state_t* async_state,
							     coap_pdu_t* request,
							     coap_resource_t *resource,
							     unsigned int media_type) {
   return FAIL;
 }
 default command int CoapResource.putMethod[uint8_t uri_key](coap_async_state_t* async_state,
							     coap_pdu_t* request,
							     coap_resource_t *resource,
							     unsigned int media_type) {
   return FAIL;
 }
 default command int CoapResource.postMethod[uint8_t uri_key](coap_async_state_t* async_state,
							      coap_pdu_t* request,
							      coap_resource_t *resource,
							      unsigned int media_type) {
   return FAIL;
 }
 default command int CoapResource.deleteMethod[uint8_t uri_key](coap_async_state_t* async_state,
								coap_pdu_t* request,
								coap_resource_t *resource) {
   return FAIL;
 }

 event void CoapResource.methodDone[uint8_t uri_key](error_t result,
						     coap_async_state_t* async_state,
						     coap_pdu_t* request,
						     coap_pdu_t* response,
						     coap_resource_t *resource) {
     coap_async_state_t *tmp;
#ifndef WITHOUT_BLOCK
     int res;
     coap_block_t block;
#endif

     if (!response) {
       //debug("check_async: insufficient memory, we'll try later\n");
       //TODO: handle error...
       return;
     }

     response->hdr->type = async_state->flags & COAP_ASYNC_CONFIRM
     			      ? COAP_MESSAGE_ACK
     			      : COAP_MESSAGE_NON;
     response->hdr->id = async_state->flags & COAP_ASYNC_CONFIRM
			      ? async_state->message_id
			      : coap_new_message_id(ctx_server);

     if (async_state->tokenlen)
       coap_add_token(response, async_state->tokenlen, async_state->token);

#ifndef WITHOUT_BLOCK
     if (coap_get_block(request, COAP_OPTION_BLOCK2, &block)) {
       res = coap_write_block_opt(&block, COAP_OPTION_BLOCK2,
				  response, resource->data_len);

       switch (res) {
       case -2:			/* illegal block */
	 response->hdr->code = COAP_RESPONSE_CODE(400);
	 break;
       case -1:			/* should really not happen */
	 assert(0);
	 /* fall through if assert is a no-op */
       case -3:			/* cannot handle request */
	 response->hdr->code = COAP_RESPONSE_CODE(500);
	 break;
       default:			/* everything is good */
	 coap_add_block(response, resource->data_len, resource->data, block.num, block.szx);
       }
     } else {
#endif
       if (resource != NULL && resource->data_len != 0) {
	 if (!coap_add_data(response, resource->data_len, resource->data)) {
#ifndef WITHOUT_BLOCK
	   //payload is to large, so lets try to do block spontaneously

	   /* set default block size */
	   block.szx = 0;
	   coap_write_block_opt(&block, COAP_OPTION_BLOCK2,
				response, resource->data_len);

	   coap_add_block(response, resource->data_len, resource->data,
			  block.num, block.szx);
#else
	   response->hdr->code = COAP_RESPONSE_CODE(500); // or RESPONSE_ENTITY_TOO_LARGE?
#endif
	 }
       }
#ifndef WITHOUT_BLOCK
     }
#endif

     if (coap_send(ctx_server, &async_state->peer, response) == COAP_INVALID_TID) {
	 debug("check_async: cannot send response for message %d\n",
	       response->hdr->id);
     }

     coap_delete_pdu(request);
     coap_delete_pdu(response);
     coap_remove_async(ctx_server, async_state->id, &tmp);
     coap_free_async(async_state);
     async_state = NULL;

     //if (resource != NULL && resource->data != NULL)
     //  coap_free(resource->data);// mab: really free it????
 }

 event void CoapResource.methodNotDone[uint8_t uri_key](coap_async_state_t* async_state,
							uint8_t responsecode) {
     coap_pdu_t *response;
     size_t size = sizeof(coap_hdr_t) + 8;
     //size += async_state->tokenlen; //CHECK: include token in preACK?

     // for NON request, no ACK
     if (async_state->flags & COAP_ASYNC_CONFIRM) {
	 response = coap_pdu_init(COAP_MESSAGE_ACK,
				  responsecode, 0, size);

	 if (!response) {
	     debug("check_async: insufficient memory, we'll try later\n");
	     //TODO: handle error...
	     return;
	 }

	 response->hdr->id = async_state->message_id;

	 if (coap_send(ctx_server, &async_state->peer, response) == COAP_INVALID_TID) {
	     debug("check_async: cannot send response for message %d\n",
		   response->hdr->id);
	     coap_delete_pdu(response);
	 }
     }
 }

 event void CoapResource.methodDoneSeparate[uint8_t uri_key](error_t result,
							     coap_async_state_t* async_state,
							     coap_pdu_t* request,
							     coap_pdu_t* response,
							     struct coap_resource_t* resource) {
     coap_async_state_t *tmp;

     if (!response) {
       //debug("check_async: insufficient memory, we'll try later\n");
       //TODO: handle error...
       return;
     }
     response->hdr->id = coap_new_message_id(ctx_server); // SEPARATE requires new message id

     if (async_state->tokenlen)
       coap_add_token(response, async_state->tokenlen, async_state->token);

     //TODO: observe on separate?

     if (resource != NULL && resource->data_len != 0) {
       coap_add_data(response, resource->data_len, resource->data);
     }

     if (async_state->flags & COAP_ASYNC_CONFIRM ) {
       response->hdr->type = COAP_MESSAGE_CON;
       coap_send_confirmed(ctx_server, &async_state->peer, response);
     } else {
       response->hdr->type = COAP_MESSAGE_NON;
       coap_send(ctx_server, &async_state->peer, response);
     }

     coap_delete_pdu(request);
     coap_delete_pdu(response);
     coap_remove_async(ctx_server, async_state->id, &tmp);
     coap_free_async(async_state);
     async_state = NULL;
 }

 event void CoapResource.notifyObservers[uint8_t uri_key]() {
#ifndef WITHOUT_OBSERVE
   coap_check_notify(ctx_server);
#endif
 }

}
