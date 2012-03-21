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
#include <debug.h>
#include <pdu.h>
#include <subscribe.h>  // for resource_t
#include <encode.h>
#include <debug.h>

#include "tinyos_coap_resources.h"
#include "blip_printf.h"

#define INDEX "CoAPUdpServer: It works!!"

#define GENERATE_PDU(var,t,c,i,copy_token) {	\
    var = coap_new_pdu();			\
    if (var) {					\
      coap_opt_t *tok;				\
      var->hdr->type = (t);			\
      var->hdr->code = (c);			\
      var->hdr->id = (i);			\
      tok = coap_check_option(node->pdu, COAP_OPTION_TOKEN); \
      if (tok && copy_token)			\
        coap_add_option(			\
          pdu, COAP_OPTION_TOKEN, COAP_OPT_LENGTH(*tok), COAP_OPT_VALUE(*tok));\
    }						\
  }

module CoapUdpServerP {
  provides interface CoAPServer;
  uses interface LibCoAP as LibCoapServer;
  uses interface Random;
  uses interface Leds;
  uses interface CoapResource[uint8_t uri];
  /*  uses interface ReadResource[uint8_t uri];
  uses interface WriteResource[uint8_t uri];
  uses interface PostDeleteResource[uint8_t uri];*/
} implementation {
  coap_context_t *ctx_server;

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

  //TODO: unify the handlers?
  /*
  void hnd_get_coap_async_tinyos(coap_context_t  *ctx,
				 struct coap_resource_t *resource,
				 coap_address_t *peer,
				 coap_pdu_t *request,
				 str *token,
				 coap_pdu_t *response);
  void hnd_put_coap_async_tinyos(coap_context_t  *ctx,
				 struct coap_resource_t *resource,
				 coap_address_t *peer,
				 coap_pdu_t *request,
				 str *token,
				 coap_pdu_t *response);
  void hnd_post_coap_async_tinyos(coap_context_t  *ctx,
				 struct coap_resource_t *resource,
				 coap_address_t *peer,
				 coap_pdu_t *request,
				 str *token,
				 coap_pdu_t *response);
  void hnd_delete_coap_async_tinyos(coap_context_t  *ctx,
				 struct coap_resource_t *resource,
				 coap_address_t *peer,
				 coap_pdu_t *request,
				 str *token,
				 coap_pdu_t *response);
  */
  int coap_save_splitphase(coap_context_t *ctx, coap_queue_t *node);

  command error_t CoAPServer.bind(uint16_t port) {
      coap_address_t listen_addr;

      coap_address_init(&listen_addr);
      listen_addr.addr.sin6_port = port;
      //TODO: address needed?

      ctx_server = coap_new_context(&listen_addr);

      if (!ctx_server) {
	  coap_log(LOG_CRIT, "cannot create CoAP context\r\n");
	  return FAIL;
      }

      return call LibCoapServer.bind(port);
  }

  ///////////////////
  // register resources
  command error_t CoAPServer.registerResource(const unsigned char uri[MAX_URI_LENGTH],
					      unsigned int uri_length,
					      const unsigned char contenttype[MAX_CONTENT_TYPE_LENGTH],
					      unsigned int contenttype_length,
					      unsigned int supported_methods) {
    coap_resource_t *r;

    if (ctx_server == NULL)
      return FAIL;

    r = coap_resource_init((unsigned char *)uri, uri_length);
    if (r == NULL)
      return FAIL;

    //TODO: check whether the handlers can be unified? code duplication...
    if ((supported_methods & GET_SUPPORTED) == GET_SUPPORTED)
	coap_register_handler(r, COAP_REQUEST_GET, hnd_coap_async_tinyos);
    if ((supported_methods & POST_SUPPORTED) == POST_SUPPORTED)
	coap_register_handler(r, COAP_REQUEST_POST, hnd_coap_async_tinyos);
    if ((supported_methods & PUT_SUPPORTED) == PUT_SUPPORTED)
	coap_register_handler(r, COAP_REQUEST_PUT, hnd_coap_async_tinyos);
    if ((supported_methods & DELETE_SUPPORTED) == DELETE_SUPPORTED)
	coap_register_handler(r, COAP_REQUEST_DELETE, hnd_coap_async_tinyos);
    /*
    if ((supported_methods & GET_SUPPORTED) == GET_SUPPORTED)
	coap_register_handler(r, COAP_REQUEST_GET, hnd_get_coap_async_tinyos);
    if ((supported_methods & POST_SUPPORTED) == POST_SUPPORTED)
	coap_register_handler(r, COAP_REQUEST_POST, hnd_post_coap_async_tinyos);
    if ((supported_methods & PUT_SUPPORTED) == PUT_SUPPORTED)
	coap_register_handler(r, COAP_REQUEST_PUT, hnd_put_coap_async_tinyos);
    if ((supported_methods & DELETE_SUPPORTED) == DELETE_SUPPORTED)
    coap_register_handler(r, COAP_REQUEST_DELETE, hnd_delete_coap_async_tinyos);*/

    coap_add_attr(r, (unsigned char *)"ct", 2, (unsigned char *)contenttype, contenttype_length);
    //TODO:
    //coap_add_attr(r, (unsigned char *)"title", 5, (unsigned char *)"\"Internal Clock\"", 16);
    //coap_add_attr(r, (unsigned char *)"rt", 2, (unsigned char *)"\"Ticks\"", 7);
    //coap_add_attr(r, (unsigned char *)"obs", 3, NULL, 0, 0);
    //coap_add_attr(r, (unsigned char *)"if", 2, (unsigned char *)"\"clock\"", 7);

    coap_add_resource(ctx_server, r);

    return SUCCESS;
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

  ///////////////////
  // all TinyOS CoAP requests have to go through this
  void hnd_coap_async_tinyos(coap_context_t  *ctx,
			     struct coap_resource_t *resource,
			     coap_address_t *peer,
			     coap_pdu_t *request,
			     str *token,
			     coap_pdu_t *response) {
      //unsigned char buf[2];
      int rc;
      size_t size;
      unsigned char *data;

      coap_async_state_t *async_state = NULL;

      /*
	call Leds.led0On();
	call Leds.led1On();
	call Leds.led2On();
      */

      /* response->hdr->code = COAP_RESPONSE_CODE(205); */
      /* coap_add_option(response, COAP_OPTION_CONTENT_TYPE, */
      /*                 coap_encode_var_bytes(buf, COAP_MEDIATYPE_TEXT_PLAIN), buf); */

      /* if (token->length) */
      /*   coap_add_option(response, COAP_OPTION_TOKEN, token->length, token->s); */

      /* response->length += snprintf((char *)response->data, */
      /* 				 response->max_size - response->length, */
      /* 				 "%u", 42); */

      async_state = coap_register_async(ctx, peer, request,
					COAP_ASYNC_CONFIRM,
					(void *)NULL);

      coap_get_data(request, &size, &data);

      if (request->hdr->code == COAP_REQUEST_GET)
	  rc = call CoapResource.getMethod[get_index_for_key(resource->key)](async_state,
									     data,
									     size);
      else if (request->hdr->code == COAP_REQUEST_POST)
	  rc = call CoapResource.postMethod[get_index_for_key(resource->key)](async_state,
									      data,
									      size);
      else if (request->hdr->code == COAP_REQUEST_PUT)
	  rc = call CoapResource.putMethod[get_index_for_key(resource->key)](async_state,
									     data,
									     size);
      else if (request->hdr->code == COAP_REQUEST_DELETE)
	  rc = call CoapResource.deleteMethod[get_index_for_key(resource->key)](async_state,
										data,
										size);
      else
	  rc = COAP_RESPONSE_405;

      if (rc == FAIL) {
	  /* default handler returns FAIL -> Resource not available -> Response: 404 */
	  response->hdr->code = COAP_RESPONSE_CODE(404);

	  //TODO: set hdr->type?

	  if (token->length)
	      coap_add_option(response, COAP_OPTION_TOKEN, token->length, token->s);

      } else if (rc == COAP_SPLITPHASE) {
	  /* TinyOS is split-phase, only in error case an immediate response
	     is set. Otherwise set type to COAP_MESSAGE_NON, so that net.c
	     is not sending it. */
	  response->hdr->type = COAP_MESSAGE_NON;
      } else {
	  response->hdr->code = rc;

	  //TODO: set hdr->type?

	  if (token->length)
	      coap_add_option(response, COAP_OPTION_TOKEN, token->length, token->s);
      }
  }

  default command int CoapResource.getMethod[uint8_t uri_key](coap_async_state_t* async_state,
							      uint8_t* val, size_t vallen) {
    //printf("** coap: default (get not available for this resource)....... %i\n", uri_key);
    return FAIL;
  }
  default command int CoapResource.putMethod[uint8_t uri_key](coap_async_state_t* async_state,
							      uint8_t* val, size_t vallen) {
    //printf("** coap: default (put not available for this resource)....... %i\n", uri_key);
    return FAIL;
  }
  default command int CoapResource.postMethod[uint8_t uri_key](coap_async_state_t* async_state,
							       uint8_t* val, size_t vallen) {
    //printf("** coap: default (post not available for this resource)....... %i\n", uri_key);
    return FAIL;
  }
  default command int CoapResource.deleteMethod[uint8_t uri_key](coap_async_state_t* async_state,
								 uint8_t* val, size_t vallen) {
    //printf("** coap: default (delete not available for this resource)....... %i\n", uri_key);
    return FAIL;
  }

  event void CoapResource.methodDone[uint8_t uri_key](error_t result,
						      uint8_t responsecode,
						      coap_async_state_t* async_state,
						      uint8_t* val,
						      size_t vallen,
						      uint8_t contenttype) {
      unsigned char buf[2];
      coap_pdu_t *response;
      coap_async_state_t *tmp;

      size_t size = sizeof(coap_hdr_t) + 8;
      size += async_state->tokenlen;


      response = coap_pdu_init(async_state->flags & COAP_ASYNC_CONFIRM
  			       ? COAP_MESSAGE_ACK
  			       : COAP_MESSAGE_NON, // CHECK answer NON with NON?
  			       responsecode, 0, size);
      if (!response) {
  	  debug("check_async: insufficient memory, we'll try later\n");
  	  //TODO: handle error...
      }

      response->hdr->id = async_state->message_id;

      if (contenttype != COAP_MEDIATYPE_ANY)
  	  coap_add_option(response, COAP_OPTION_CONTENT_TYPE,
  			  coap_encode_var_bytes(buf, contenttype), buf);

      if (async_state->tokenlen)
  	  coap_add_option(response, COAP_OPTION_TOKEN, async_state->tokenlen, async_state->token);

      if (vallen != 0)
  	  coap_add_data(response, vallen, val);

      if (coap_send(ctx_server, &async_state->peer, response) == COAP_INVALID_TID) {
  	  debug("check_async: cannot send response for message %d\n",
  		response->hdr->id);
  	  coap_delete_pdu(response);
      }

      coap_remove_async(ctx_server, async_state->id, &tmp);
      coap_free_async(async_state);

  }

  event void CoapResource.methodNotDone[uint8_t uri_key](coap_async_state_t* async_state,
							 uint8_t responsecode) {
      coap_pdu_t *response;
      size_t size = sizeof(coap_hdr_t) + 8;
      //size += async_state->tokenlen; //CHECK: include token in preACK?

      response = coap_pdu_init(COAP_MESSAGE_ACK,
  			       responsecode, async_state->id, size);

      if (!response) {
  	  debug("check_async: insufficient memory, we'll try later\n");
  	  //TODO: handle error...
      }

      response->hdr->id = async_state->message_id;

      //CHECK: include token in preACK?
      /*if (async_state->tokenlen)
  	coap_add_option(response, COAP_OPTION_TOKEN, async_state->tokenlen, async_state->token);*/

      if (coap_send(ctx_server, &async_state->peer, response) == COAP_INVALID_TID) {
  	  debug("check_async: cannot send response for message %d\n",
  		response->hdr->id);
  	  coap_delete_pdu(response);
      }
  }

  event void CoapResource.methodDoneSeparate[uint8_t uri_key](error_t result,
							      uint8_t responsecode,
							      coap_async_state_t* async_state,
							      uint8_t* val, size_t vallen,
							      uint8_t contenttype) {
      unsigned char buf[2];
      coap_pdu_t *response;
      coap_async_state_t *tmp;

      size_t size = sizeof(coap_hdr_t) + 8;
      size += async_state->tokenlen;

      response = coap_pdu_init(async_state->flags & COAP_ASYNC_CONFIRM
  			       ? COAP_MESSAGE_CON
  			       : COAP_MESSAGE_NON, // CHECK answer NON with NON?
  			       responsecode, 0, size);
      if (!response) {
  	  debug("check_async: insufficient memory, we'll try later\n");
  	  //TODO: handle error...
      }

      response->hdr->id = coap_new_message_id(ctx_server); // SEPARATE requires new message id

      if (contenttype != COAP_MEDIATYPE_ANY)
  	  coap_add_option(response, COAP_OPTION_CONTENT_TYPE,
  			  coap_encode_var_bytes(buf, contenttype), buf);

      if (async_state->tokenlen)
  	  coap_add_option(response, COAP_OPTION_TOKEN, async_state->tokenlen, async_state->token);

      if (vallen != 0)
	  coap_add_data(response, vallen, val);

      if (coap_send(ctx_server, &async_state->peer, response) == COAP_INVALID_TID) {
  	  debug("check_async: cannot send response for message %d\n",
  		response->hdr->id);
  	  coap_delete_pdu(response);
      }

      coap_remove_async(ctx_server, async_state->id, &tmp);
      coap_free_async(async_state);
  }

  /* /////////////////// */
  /* // all TinyOS CoAP GET have to go through this */
  /* void hnd_get_coap_async_tinyos(coap_context_t  *ctx, */
  /* 				 struct coap_resource_t *resource, */
  /* 				 coap_address_t *peer, */
  /* 				 coap_pdu_t *request, */
  /* 				 str *token, */
  /* 				 coap_pdu_t *response) { */
  /*     //unsigned char buf[2]; */
  /*     int rc; */
  /*     coap_async_state_t *async_state = NULL; */

  /*     /\* */
  /* 	call Leds.led0On(); */
  /* 	call Leds.led1On(); */
  /* 	call Leds.led2On(); */
  /*     *\/ */

  /*     /\* response->hdr->code = COAP_RESPONSE_CODE(205); *\/ */
  /*     /\* coap_add_option(response, COAP_OPTION_CONTENT_TYPE, *\/ */
  /*     /\*                 coap_encode_var_bytes(buf, COAP_MEDIATYPE_TEXT_PLAIN), buf); *\/ */

  /*     /\* if (token->length) *\/ */
  /*     /\*   coap_add_option(response, COAP_OPTION_TOKEN, token->length, token->s); *\/ */

  /*     /\* response->length += snprintf((char *)response->data, *\/ */
  /*     /\* 				 response->max_size - response->length, *\/ */
  /*     /\* 				 "%u", 42); *\/ */

  /*     async_state = coap_register_async(ctx, peer, request, */
  /* 					COAP_ASYNC_CONFIRM, */
  /* 					(void *)NULL); */

  /*     rc = call ReadResource.get[get_index_for_key(resource->key)](async_state); */
  /*     //rc = call ReadResource.get[INDEX_ETSI_SEGMENT](async_state); */
  /*     if (rc == FAIL) { */
  /* 	  /\* default handler returns FAIL -> Resource not available -> Response: 404 *\/ */
  /* 	  response->hdr->code = COAP_RESPONSE_CODE(404); */

  /* 	  //TODO: set hdr->type? */

  /* 	  if (token->length) */
  /* 	      coap_add_option(response, COAP_OPTION_TOKEN, token->length, token->s); */

  /*     } else if (rc == COAP_SPLITPHASE) { */
  /* 	  /\* TinyOS is split-phase, only in error case an immediate response */
  /* 	     is set. Otherwise set type to COAP_MESSAGE_NON, so that net.c */
  /* 	     is not sending it. *\/ */
  /* 	  response->hdr->type = COAP_MESSAGE_NON; */
  /*     } else { */
  /* 	  response->hdr->code = rc; */

  /* 	  //TODO: set hdr->type? */

  /* 	  if (token->length) */
  /* 	      coap_add_option(response, COAP_OPTION_TOKEN, token->length, token->s); */
  /*     } */
  /* } */

  /* default command int ReadResource.get[uint8_t uri_key](coap_async_state_t* async_state) { */
  /*   //printf("** coap: default (get not available for this resource)....... %i\n", uri_key); */
  /*   return FAIL; */
  /* } */

  /* event void ReadResource.getDone[uint8_t uri_key](error_t result, */
  /* 						   coap_async_state_t* async_state, */
  /* 						   uint8_t* val_buf, */
  /* 						   size_t buflen, */
  /* 						   uint8_t contenttype) { */

  /*     unsigned char buf[2]; */
  /*     coap_pdu_t *response; */
  /*     coap_async_state_t *tmp; */

  /*     size_t size = sizeof(coap_hdr_t) + 8; */
  /*     size += async_state->tokenlen; */

  /*     response = coap_pdu_init(async_state->flags & COAP_ASYNC_CONFIRM */
  /* 			       ? COAP_MESSAGE_ACK */
  /* 			       : COAP_MESSAGE_NON, // CHECK answer NON with NON? */
  /* 			       COAP_RESPONSE_CODE(205), 0, size); */
  /*     if (!response) { */
  /* 	  debug("check_async: insufficient memory, we'll try later\n"); */
  /* 	  //TODO: handle error... */
  /*     } */

  /*     response->hdr->id = async_state->message_id; */

  /*     if (contenttype != COAP_MEDIATYPE_ANY) */
  /* 	  coap_add_option(response, COAP_OPTION_CONTENT_TYPE, */
  /* 			  coap_encode_var_bytes(buf, contenttype), buf); */

  /*     if (async_state->tokenlen) */
  /* 	  coap_add_option(response, COAP_OPTION_TOKEN, async_state->tokenlen, async_state->token); */

  /*     if (buflen != 0) */
  /* 	  coap_add_data(response, buflen, val_buf); */

  /*     if (coap_send(ctx_server, &async_state->peer, response) == COAP_INVALID_TID) { */
  /* 	  debug("check_async: cannot send response for message %d\n", */
  /* 		response->hdr->id); */
  /* 	  coap_delete_pdu(response); */
  /*     } */

  /*     coap_remove_async(ctx_server, async_state->id, &tmp); */
  /*     coap_free_async(async_state); */
  /* } */

  /* event void ReadResource.getNotDone[uint8_t uri_key](coap_async_state_t* async_state) { */
  /*     coap_pdu_t *response; */

  /*     size_t size = sizeof(coap_hdr_t) + 8; */

  /*     //size += async_state->tokenlen; //CHECK: include token in preACK? */

  /*     response = coap_pdu_init(COAP_MESSAGE_ACK, */
  /* 			       COAP_RESPONSE_CODE(0), async_state->id, size); */

  /*     if (!response) { */
  /* 	  debug("check_async: insufficient memory, we'll try later\n"); */
  /* 	  //TODO: handle error... */
  /*     } */

  /*     response->hdr->id = async_state->message_id; */

  /*     //CHECK: include token in preACK? */
  /*     /\*if (async_state->tokenlen) */
  /* 	coap_add_option(response, COAP_OPTION_TOKEN, async_state->tokenlen, async_state->token);*\/ */

  /*     if (coap_send(ctx_server, &async_state->peer, response) == COAP_INVALID_TID) { */
  /* 	  debug("check_async: cannot send response for message %d\n", */
  /* 		response->hdr->id); */
  /* 	  coap_delete_pdu(response); */
  /*     } */
  /* } */

  /* event void ReadResource.getDoneSeparate[uint8_t uri_key](error_t result, */
  /* 							   coap_async_state_t* async_state, */
  /* 							   uint8_t* val_buf, */
  /* 							   size_t buflen, */
  /* 							   uint8_t contenttype) { */
  /*     unsigned char buf[2]; */
  /*     coap_pdu_t *response; */
  /*     coap_async_state_t *tmp; */

  /*     size_t size = sizeof(coap_hdr_t) + 8; */

  /*     size += async_state->tokenlen; */

  /*     response = coap_pdu_init(async_state->flags & COAP_ASYNC_CONFIRM */
  /* 			       ? COAP_MESSAGE_CON */
  /* 			       : COAP_MESSAGE_NON, // CHECK answer NON with NON? */
  /* 			       COAP_RESPONSE_CODE(205), 0, size); */
  /*     if (!response) { */
  /* 	  debug("check_async: insufficient memory, we'll try later\n"); */
  /* 	  //TODO: handle error... */
  /*     } */

  /*     response->hdr->id = coap_new_message_id(ctx_server); // SEPARATE requires new message id */

  /*     if (contenttype != COAP_MEDIATYPE_ANY) */
  /* 	  coap_add_option(response, COAP_OPTION_CONTENT_TYPE, */
  /* 			  coap_encode_var_bytes(buf, contenttype), buf); */

  /*     if (async_state->tokenlen) */
  /* 	  coap_add_option(response, COAP_OPTION_TOKEN, async_state->tokenlen, async_state->token); */

  /*     coap_add_data(response, buflen, val_buf); */

  /*     if (coap_send(ctx_server, &async_state->peer, response) == COAP_INVALID_TID) { */
  /* 	  debug("check_async: cannot send response for message %d\n", */
  /* 		response->hdr->id); */
  /* 	  coap_delete_pdu(response); */
  /*     } */

  /*     coap_remove_async(ctx_server, async_state->id, &tmp); */
  /*     coap_free_async(async_state); */
  /* } */

  /* /////////////////// */
  /* // all TinyOS CoAP PUT have to go through this */
  /* void hnd_put_coap_async_tinyos(coap_context_t  *ctx, */
  /* 				 struct coap_resource_t *resource, */
  /* 				 coap_address_t *peer, */
  /* 				 coap_pdu_t *request, */
  /* 				 str *token, */
  /* 				 coap_pdu_t *response) { */
  /*     //unsigned char buf[2]; */
  /*     size_t size; */
  /*     unsigned char *data; */
  /*     int rc; */
  /*     coap_async_state_t *async_state = NULL; */

  /*     call Leds.led0On(); */
  /*     call Leds.led1On(); */
  /*     call Leds.led2On(); */

  /*     /\* response->hdr->code = COAP_RESPONSE_CODE(205); *\/ */
  /*     /\* coap_add_option(response, COAP_OPTION_CONTENT_TYPE, *\/ */
  /*     /\*                 coap_encode_var_bytes(buf, COAP_MEDIATYPE_TEXT_PLAIN), buf); *\/ */

  /*     /\* if (token->length) *\/ */
  /*     /\*   coap_add_option(response, COAP_OPTION_TOKEN, token->length, token->s); *\/ */

  /*     /\* response->length += snprintf((char *)response->data, *\/ */
  /*     /\* 				 response->max_size - response->length, *\/ */
  /*     /\* 				 "%u", 42); *\/ */

  /*     async_state = coap_register_async(ctx, peer, request, */
  /* 					COAP_ASYNC_CONFIRM, */
  /* 					(void *)NULL); */


  /*     coap_get_data(request, &size, &data); */

  /*     rc = call WriteResource.put[get_index_for_key(resource->key)](async_state, */
  /* 								    data, */
  /* 								    size); */
  /*     if (rc == FAIL) { */
  /* 	  /\* default handler returns FAIL -> Resource not available -> Response: 404 *\/ */
  /* 	  response->hdr->code = COAP_RESPONSE_CODE(404); */

  /* 	  //TODO: set hdr->type? */

  /* 	  if (token->length) */
  /* 	      coap_add_option(response, COAP_OPTION_TOKEN, token->length, token->s); */

  /*     } else if (rc == COAP_SPLITPHASE) { */
  /* 	  /\* TinyOS is split-phase, only in error case an immediate response */
  /* 	     is set. Otherwise set type to COAP_MESSAGE_NON, so that net.c */
  /* 	     is not sending it. *\/ */
  /* 	  response->hdr->type = COAP_MESSAGE_NON; */
  /*     } else { */

  /* 	  if (rc == COAP_RESPONSE_503) { */
  /* 	      call Leds.led0Off(); */
  /* 	  } else if (rc == COAP_RESPONSE_500) { */
  /* 	      call Leds.led1Off(); */
  /* 	  } else { */
  /* 	      call Leds.led2Off(); */
  /* 	  } */

  /* 	  response->hdr->code = rc; */

  /* 	  //TODO: set hdr->type */

  /* 	  if (token->length) */
  /* 	      coap_add_option(response, COAP_OPTION_TOKEN, token->length, token->s); */
  /*     } */
  /* } */

  /* default command int WriteResource.put[uint8_t uri_key](coap_async_state_t* async_state, */
  /* 							 uint8_t* val, size_t buflen) { */
  /*     //printf("** coap: default (put not available for this resource)....... %i\n", uri_key); */
  /*     return FAIL; */
  /* } */

  /* event void WriteResource.putDone[uint8_t uri_key](error_t result, */
  /* 						    coap_async_state_t* async_state, */
  /* 						    uint8_t* val_buf, size_t buflen, */
  /* 						    uint8_t contenttype) { */
  /*     unsigned char buf[2]; */
  /*     coap_pdu_t *response; */
  /*     coap_async_state_t *tmp; */

  /*     size_t size = sizeof(coap_hdr_t) + 8; */
  /*     size += async_state->tokenlen; */

  /*     //TODO: check for result == SUCCESS */
  /*     response = coap_pdu_init(async_state->flags & COAP_ASYNC_CONFIRM */
  /* 			       ? COAP_MESSAGE_ACK */
  /* 			       : COAP_MESSAGE_NON, // CHECK answer NON with NON? */
  /* 			       COAP_RESPONSE_CODE(204), 0, size); */
  /*     if (!response) { */
  /* 	  debug("check_async: insufficient memory, we'll try later\n"); */
  /* 	  //TODO: handle error... */
  /*     } */

  /*     response->hdr->id = async_state->message_id; */

  /*     if (contenttype != COAP_MEDIATYPE_ANY) */
  /* 	  coap_add_option(response, COAP_OPTION_CONTENT_TYPE, */
  /* 			  coap_encode_var_bytes(buf, contenttype), buf); */

  /*     if (async_state->tokenlen) */
  /* 	  coap_add_option(response, COAP_OPTION_TOKEN, async_state->tokenlen, async_state->token); */

  /*     if (buflen != 0) */
  /* 	  coap_add_data(response, buflen, val_buf); */

  /*     if (coap_send(ctx_server, &async_state->peer, response) == COAP_INVALID_TID) { */
  /* 	  debug("check_async: cannot send response for message %d\n", */
  /* 		response->hdr->id); */
  /* 	  coap_delete_pdu(response); */
  /*     } */

  /*     coap_remove_async(ctx_server, async_state->id, &tmp); */
  /*     coap_free_async(async_state); */
  /* } */

  /* event void WriteResource.putNotDone[uint8_t uri_key](coap_async_state_t* async_state) { */
  /*     coap_pdu_t *response; */

  /*     size_t size = sizeof(coap_hdr_t) + 8; */

  /*     //size += async_state->tokenlen; //CHECK: include token in preACK? */

  /*     response = coap_pdu_init(COAP_MESSAGE_ACK, */
  /* 			       COAP_RESPONSE_CODE(0), async_state->id, size); */

  /*     if (!response) { */
  /* 	  debug("check_async: insufficient memory, we'll try later\n"); */
  /* 	  //TODO: handle error... */
  /*     } */

  /*     response->hdr->id = async_state->message_id; */

  /*     //CHECK: include token in preACK? */
  /*     /\*if (async_state->tokenlen) */
  /* 	coap_add_option(response, COAP_OPTION_TOKEN, async_state->tokenlen, async_state->token);*\/ */

  /*     if (coap_send(ctx_server, &async_state->peer, response) == COAP_INVALID_TID) { */
  /* 	  debug("check_async: cannot send response for message %d\n", */
  /* 		response->hdr->id); */
  /* 	  coap_delete_pdu(response); */
  /*     } */
  /* } */

  /* event void WriteResource.putDoneSeparate[uint8_t uri_key](error_t result, */
  /* 							    coap_async_state_t* async_state, */
  /* 							    uint8_t* val_buf, */
  /* 							    size_t buflen, */
  /* 							    uint8_t contenttype) { */
  /*     unsigned char buf[2]; */
  /*     coap_pdu_t *response; */
  /*     coap_async_state_t *tmp; */

  /*     size_t size = sizeof(coap_hdr_t) + 8; */

  /*     size += async_state->tokenlen; //CHECK: include token in preACK? */

  /*     response = coap_pdu_init(async_state->flags & COAP_ASYNC_CONFIRM */
  /* 			       ? COAP_MESSAGE_CON */
  /* 			       : COAP_MESSAGE_NON, // CHECK answer NON with NON? */
  /* 			       COAP_RESPONSE_CODE(204), 0, size); // 2.05??? */
  /*     /\*response = coap_pdu_init(COAP_MESSAGE_ACK, */
  /* 	COAP_RESPONSE_CODE(0), async_state->id, size);*\/ */

  /*     if (!response) { */
  /* 	  debug("check_async: insufficient memory, we'll try later\n"); */
  /* 	  //TODO: handle error... */
  /*     } */

  /*     response->hdr->id = coap_new_message_id(ctx_server); // SEPARATE requires new message id */

  /*     // TODO: set code!!!! */

  /*     if (contenttype != COAP_MEDIATYPE_ANY) */
  /* 	  coap_add_option(response, COAP_OPTION_CONTENT_TYPE, */
  /* 			  coap_encode_var_bytes(buf, contenttype), buf); */

  /*     if (async_state->tokenlen) */
  /* 	  coap_add_option(response, COAP_OPTION_TOKEN, async_state->tokenlen, async_state->token); */

  /*     if (coap_send(ctx_server, &async_state->peer, response) == COAP_INVALID_TID) { */
  /* 	  debug("check_async: cannot send response for message %d\n", */
  /* 		response->hdr->id); */
  /* 	  coap_delete_pdu(response); */
  /*     } */

  /*     coap_remove_async(ctx_server, async_state->id, &tmp); */
  /*     coap_free_async(async_state); */
  /* } */

  /* /////////////////// */
  /* // all TinyOS CoAP POST have to go through this */
  /* void hnd_post_coap_async_tinyos(coap_context_t  *ctx, */
  /* 				 struct coap_resource_t *resource, */
  /* 				 coap_address_t *peer, */
  /* 				 coap_pdu_t *request, */
  /* 				 str *token, */
  /* 				 coap_pdu_t *response) { */
  /*     //unsigned char buf[2]; */
  /*     size_t size; */
  /*     unsigned char *data; */
  /*     int rc; */
  /*     coap_async_state_t *async_state = NULL; */

  /*     call Leds.led0On(); */
  /*     call Leds.led1On(); */
  /*     call Leds.led2On(); */

  /*     /\* response->hdr->code = COAP_RESPONSE_CODE(205); *\/ */
  /*     /\* coap_add_option(response, COAP_OPTION_CONTENT_TYPE, *\/ */
  /*     /\*                 coap_encode_var_bytes(buf, COAP_MEDIATYPE_TEXT_PLAIN), buf); *\/ */

  /*     /\* if (token->length) *\/ */
  /*     /\*   coap_add_option(response, COAP_OPTION_TOKEN, token->length, token->s); *\/ */

  /*     /\* response->length += snprintf((char *)response->data, *\/ */
  /*     /\* 				 response->max_size - response->length, *\/ */
  /*     /\* 				 "%u", 42); *\/ */

  /*     async_state = coap_register_async(ctx, peer, request, */
  /* 					COAP_ASYNC_CONFIRM, */
  /* 					(void *)NULL); */


  /*     coap_get_data(request, &size, &data); */

  /*     rc = call PostDeleteResource.postMethod[get_index_for_key(resource->key)](async_state, */
  /* 									  data, */
  /* 									  size); */
  /*     if (rc == FAIL) { */
  /* 	  /\* default handler returns FAIL -> Resource not available -> Response: 404 *\/ */
  /* 	  response->hdr->code = COAP_RESPONSE_CODE(404); */

  /* 	  //TODO: set hdr->type? */

  /* 	  if (token->length) */
  /* 	      coap_add_option(response, COAP_OPTION_TOKEN, token->length, token->s); */

  /*     } else if (rc == COAP_SPLITPHASE) { */
  /* 	  /\* TinyOS is split-phase, only in error case an immediate response */
  /* 	     is set. Otherwise set type to COAP_MESSAGE_NON, so that net.c */
  /* 	     is not sending it. *\/ */
  /* 	  response->hdr->type = COAP_MESSAGE_NON; */
  /*     } else { */

  /* 	  if (rc == COAP_RESPONSE_503) { */
  /* 	      call Leds.led0Off(); */
  /* 	  } else if (rc == COAP_RESPONSE_500) { */
  /* 	      call Leds.led1Off(); */
  /* 	  } else { */
  /* 	      call Leds.led2Off(); */
  /* 	  } */

  /* 	  response->hdr->code = rc; */

  /* 	  //TODO: set hdr->type */

  /* 	  if (token->length) */
  /* 	      coap_add_option(response, COAP_OPTION_TOKEN, token->length, token->s); */
  /*     } */
  /* } */

  /* default command int PostDeleteResource.postMethod[uint8_t uri_key](coap_async_state_t* async_state, */
  /* 								     uint8_t* val, size_t buflen) { */
  /*     //printf("** coap: default (put not available for this resource)....... %i\n", uri_key); */
  /*     return FAIL; */
  /* } */

  /* event void PostDeleteResource.postDone[uint8_t uri_key](error_t result, */
  /* 							  coap_async_state_t* async_state, */
  /* 							  uint8_t* val_buf, size_t buflen, */
  /* 							  uint8_t contenttype) { */
  /*     unsigned char buf[2]; */
  /*     coap_pdu_t *response; */
  /*     coap_async_state_t *tmp; */

  /*     size_t size = sizeof(coap_hdr_t) + 8; */
  /*     size += async_state->tokenlen; */

  /*     //TODO: check for result == SUCCESS */
  /*     response = coap_pdu_init(async_state->flags & COAP_ASYNC_CONFIRM */
  /* 			       ? COAP_MESSAGE_ACK */
  /* 			       : COAP_MESSAGE_NON, // CHECK answer NON with NON? */
  /*      		       COAP_RESPONSE_CODE(201), 0, size); */
  /*     // or 204 for already present resource */

  /*     if (!response) { */
  /* 	  debug("check_async: insufficient memory, we'll try later\n"); */
  /* 	  //TODO: handle error... */
  /*     } */

  /*     response->hdr->id = async_state->message_id; */

  /*     if (contenttype != COAP_MEDIATYPE_ANY) */
  /* 	  coap_add_option(response, COAP_OPTION_CONTENT_TYPE, */
  /* 			  coap_encode_var_bytes(buf, contenttype), buf); */

  /*     if (async_state->tokenlen) */
  /* 	  coap_add_option(response, COAP_OPTION_TOKEN, async_state->tokenlen, async_state->token); */

  /*     //TODO: add option Location-Path? */

  /*     if (buflen != 0) */
  /* 	  coap_add_data(response, buflen, val_buf); */

  /*     if (coap_send(ctx_server, &async_state->peer, response) == COAP_INVALID_TID) { */
  /* 	  debug("check_async: cannot send response for message %d\n", */
  /* 		response->hdr->id); */
  /* 	  coap_delete_pdu(response); */
  /*     } */

  /*     coap_remove_async(ctx_server, async_state->id, &tmp); */
  /*     coap_free_async(async_state); */
  /* } */

  /* void hnd_delete_coap_async_tinyos(coap_context_t  *ctx, */
  /* 				    struct coap_resource_t *resource, */
  /* 				    coap_address_t *peer, */
  /* 				    coap_pdu_t *request, */
  /* 				    str *token, */
  /* 				    coap_pdu_t *response) { */
  /*     //unsigned char buf[2]; */
  /*     size_t size; */
  /*     unsigned char *data; */
  /*     int rc; */
  /*     coap_async_state_t *async_state = NULL; */

  /*     call Leds.led0On(); */
  /*     call Leds.led1On(); */
  /*     call Leds.led2On(); */

  /*     /\* response->hdr->code = COAP_RESPONSE_CODE(205); *\/ */
  /*     /\* coap_add_option(response, COAP_OPTION_CONTENT_TYPE, *\/ */
  /*     /\*                 coap_encode_var_bytes(buf, COAP_MEDIATYPE_TEXT_PLAIN), buf); *\/ */

  /*     /\* if (token->length) *\/ */
  /*     /\*   coap_add_option(response, COAP_OPTION_TOKEN, token->length, token->s); *\/ */

  /*     /\* response->length += snprintf((char *)response->data, *\/ */
  /*     /\* 				 response->max_size - response->length, *\/ */
  /*     /\* 				 "%u", 42); *\/ */

  /*     async_state = coap_register_async(ctx, peer, request, */
  /* 					COAP_ASYNC_CONFIRM, */
  /* 					(void *)NULL); */


  /*     coap_get_data(request, &size, &data); */

  /*     rc = call PostDeleteResource.deleteMethod[get_index_for_key(resource->key)](async_state, */
  /* 										  data, */
  /* 										  size); */
  /*     if (rc == FAIL) { */
  /* 	  /\* default handler returns FAIL -> Resource not available -> Response: 404 *\/ */
  /* 	  response->hdr->code = COAP_RESPONSE_CODE(404); */

  /* 	  //TODO: set hdr->type? */

  /* 	  if (token->length) */
  /* 	      coap_add_option(response, COAP_OPTION_TOKEN, token->length, token->s); */

  /*     } else if (rc == COAP_SPLITPHASE) { */
  /* 	  /\* TinyOS is split-phase, only in error case an immediate response */
  /* 	     is set. Otherwise set type to COAP_MESSAGE_NON, so that net.c */
  /* 	     is not sending it. *\/ */
  /* 	  response->hdr->type = COAP_MESSAGE_NON; */
  /*     } else { */

  /* 	  if (rc == COAP_RESPONSE_503) { */
  /* 	      call Leds.led0Off(); */
  /* 	  } else if (rc == COAP_RESPONSE_500) { */
  /* 	      call Leds.led1Off(); */
  /* 	  } else { */
  /* 	      call Leds.led2Off(); */
  /* 	  } */

  /* 	  response->hdr->code = rc; */

  /* 	  //TODO: set hdr->type */

  /* 	  if (token->length) */
  /* 	      coap_add_option(response, COAP_OPTION_TOKEN, token->length, token->s); */
  /*     } */
  /* } */

  /* default command int PostDeleteResource.deleteMethod[uint8_t uri_key](coap_async_state_t* async_state, */
  /* 							       uint8_t* val, size_t buflen) { */
  /*     //printf("** coap: default (put not available for this resource)....... %i\n", uri_key); */
  /*     return FAIL; */
  /* } */

  /* event void PostDeleteResource.deleteDone[uint8_t uri_key](error_t result, */
  /* 							  coap_async_state_t* async_state, */
  /* 							  uint8_t* val_buf, size_t buflen, */
  /* 							  uint8_t contenttype) { */
  /*     unsigned char buf[2]; */
  /*     coap_pdu_t *response; */
  /*     coap_async_state_t *tmp; */

  /*     size_t size = sizeof(coap_hdr_t) + 8; */
  /*     size += async_state->tokenlen; */

  /*     //TODO: check for result == SUCCESS */
  /*     response = coap_pdu_init(async_state->flags & COAP_ASYNC_CONFIRM */
  /* 			       ? COAP_MESSAGE_ACK */
  /* 			       : COAP_MESSAGE_NON, // CHECK answer NON with NON? */
  /*      		       COAP_RESPONSE_CODE(202), 0, size); */

  /*     if (!response) { */
  /* 	  debug("check_async: insufficient memory, we'll try later\n"); */
  /* 	  //TODO: handle error... */
  /*     } */

  /*     response->hdr->id = async_state->message_id; */

  /*     if (contenttype != COAP_MEDIATYPE_ANY) */
  /* 	  coap_add_option(response, COAP_OPTION_CONTENT_TYPE, */
  /* 			  coap_encode_var_bytes(buf, contenttype), buf); */

  /*     if (async_state->tokenlen) */
  /* 	  coap_add_option(response, COAP_OPTION_TOKEN, async_state->tokenlen, async_state->token); */

  /*     if (buflen != 0) */
  /* 	  coap_add_data(response, buflen, val_buf); */

  /*     if (coap_send(ctx_server, &async_state->peer, response) == COAP_INVALID_TID) { */
  /* 	  debug("check_async: cannot send response for message %d\n", */
  /* 		response->hdr->id); */
  /* 	  coap_delete_pdu(response); */
  /*     } */

  /*     coap_remove_async(ctx_server, async_state->id, &tmp); */
  /*     coap_free_async(async_state); */
  /* } */

  // event void WriteResource.putDone[uint8_t uri_key](error_t result) {
 /* event void WriteResource.putDone[uint8_t uri_key](error_t result, */
 /* 						   coap_tid_t id, */
 /* 						   uint8_t asyn_message) { */

   /* coap_queue_t *node; */
   /* coap_pdu_t *pdu; */
   /* coap_opt_t *ct; */

   /* //printf("** coap: putDone.... %i\n", uri_key); */
   /* // assuming more than one entry is in splitphasequeue */
   /* if (!(node = coap_find_transaction(ctx_server->splitphasequeue, id))){ */
   /*   //printf("** coap: puttDone: node in splitphasequeue not found, quit\n"); */
   /*   return; */
   /* } */

   /* if (result){ */
   /*   //printf("** coap: sensor retrival failed\n"); */
   /*   if ( !(pdu = new_response(ctx_server, node, COAP_RESPONSE_500)) ) { */
   /*     // printf("** coap: return PDU Null for COAP_RESPONSE_500 \n"); */
   /*   } */
   /*   //FIXME */
   /*   //memcpy(val_buf, "Sensor not found", 16); */
   /*   //buflen = 16; */
   /* } else { */
   /*   //printf("** coap: sensor retrival successful\n"); */
   /*   if (asyn_message){ */
   /*     node->pdu->hdr->id = get_new_tid(); */
   /*     if ( !(pdu = new_asynresponse(ctx_server, node)) ) { */
   /* 	 //printf("** coap: return PDU Null for Asyn response\n"); */
   /*     } */
   /*   } else { */
   /*     if ( !(pdu = new_response(ctx_server, node, COAP_RESPONSE_200)) ) { */
   /* 	 //printf("** coap: return PDU Null for normal response\n"); */
   /*     } */
   /*   } */
   /* } */

   /* // Add content-encoding */
   /* ct = coap_check_option( node->pdu, COAP_OPTION_CONTENT_TYPE ); */
   /* if ( ct ) { */
   /*   coap_add_option( pdu, COAP_OPTION_CONTENT_TYPE, COAP_OPT_LENGTH(*ct),COAP_OPT_VALUE(*ct) ); */
   /* } */

   /* // sending pdu */
   /* if (pdu && (call LibCoapServer.send(ctx_server, &node->remote, pdu, 1) == COAP_INVALID_TID )) { */
   /*   //printf("** coap:asyn Res: error sending response\n"); */
   /*   coap_delete_pdu(pdu); */
   /* } */

   /* /\* remove node from asynresqueue *\/ */
   /* coap_extract_node (&ctx_server->splitphasequeue, node); */
   /* node->next = NULL; */
   /* coap_delete_node( node ); */
   /* //printf("** coap: delete node details kept for Asyn response\n"); */
  // }



  /* //add default data in case of empty uri path. (for testing purposes only) */
  /* void add_contents( coap_pdu_t *pdu, unsigned char mediatype, */
  /* 		     unsigned int len, unsigned char *data ) { */

  /*   unsigned char ct = COAP_MEDIATYPE_APPLICATION_LINK_FORMAT; */
  /*   if (!pdu) */
  /*     return; */

  /*   /\* add content-encoding *\/ */
  /*   coap_add_option(pdu, COAP_OPTION_CONTENT_TYPE, 1, &ct); */

  /*   coap_add_data(pdu, len, data); */
  /* } */

  /* coap_opt_t* coap_next_option(coap_pdu_t *pdu, coap_opt_t *opt) { */
  /*   coap_opt_t *next; */
  /*   if ( !pdu || !opt ) */
  /*     return NULL; */

  /*   next = (coap_opt_t *)( (unsigned char *)opt + COAP_OPT_SIZE(*opt) ); */
  /*   return (unsigned char *)next < pdu->data && COAP_OPT_DELTA(*next) == 0 ? next : NULL; */
  /* } */

  /* int mediatype_matches(coap_pdu_t *pdu, unsigned char mediatype) { */
  /*   coap_opt_t *ct; */

  /*   if ( mediatype == COAP_MEDIATYPE_ANY ) */
  /*     return 1; */

  /*   for (ct = coap_check_option(pdu, COAP_OPTION_CONTENT_TYPE); ct; ct = coap_next_option(pdu, ct)) { */
  /*     if ( *COAP_OPT_VALUE(*ct) == mediatype ) */
  /* 	return 1; */
  /*   } */

  /*   return 0; */
  /* } */



 //event void ReadResource.getDoneDeferred[uint8_t uri_key]() {
   /* coap_queue_t *node; */
   /* coap_pdu_t *pdu; */
   /* uint8_t reqtoken = 0; */

   /* printf("getDoneDeferred ##\n"); */

   /*
   // assuming more than one entry is in splitphasequeue
   if (!(node = coap_find_transaction(ctx_server->splitphasequeue, id))){
     //printf("** coap: getPreACK: node in splitphasequeue not found, quit\n");
     return;
   }

   //check for token
   if (!coap_check_option(node->pdu, COAP_OPTION_TOKEN)) {
     //printf("** coap: token required --> send COAP_RESPONSE_240\n");
     reqtoken = 1;
     if ( !(pdu = new_response(ctx_server, node, COAP_RESPONSE_X_240)) ) {
       //printf("** coap: return PDU Null for COAP_RESPONSE_240 \n");
     }
   } else {
     //printf("** coap: send PreACK\n");
     if ( !(pdu = new_ack(ctx_server, node)) ) {
       //printf("** coap: return PDU Null for PreACK response\n");
     }
   }

   // sending pdu
   if (pdu && (call LibCoapServer.send(ctx_server, &node->remote, pdu, 1) == COAP_INVALID_TID )) {
     //printf("** coap: error sending response\n");
   }

   if (reqtoken) {
     // remove node from splitphasequeue
     coap_extract_node (&ctx_server->splitphasequeue, node);
     node->next = NULL;
     coap_delete_node(node);
     printf("** coap: delete node deferred\n");
   } else {
     printf("** coap: PreACK sent!\n");
   }
   */
 // }

 ///////////////////
 // PUT method
 coap_pdu_t * handle_put(coap_context_t  *ctx, coap_queue_t *node, void *data) {
   /*
   coap_pdu_t *pdu;
   coap_uri_t uri;
   coap_opt_t *tok;
   coap_resource_t *resource;
   unsigned char mediatype = COAP_MEDIATYPE_ANY;
   coap_opt_t  *ct,*block;
   unsigned int blklen, blk;
   int code, finished = 1;
   unsigned int len;
   unsigned char *databuf;

   //printf("** coap: handle put\n");
   if ( !coap_get_request_uri( node->pdu, &uri ) )
     return NULL;

   //send default test response
   if ( !uri.path.length ) {
     pdu = new_response(ctx, node, COAP_RESPONSE_200);

     if ( !pdu )
       return NULL;

     add_contents( pdu, COAP_MEDIATYPE_TEXT_PLAIN, sizeof(INDEX) - 1, (unsigned char *)INDEX );
     return pdu;
   }

   // we do not want to create the resource if not available
   if ( !(resource = coap_get_resource(ctx, &uri)) )
     return new_response(ctx, node, COAP_RESPONSE_404);

   if (!resource->writable)
     return new_response(ctx, node, COAP_RESPONSE_400);

   //check and get payload length
   coap_get_data(node->pdu, &len, &databuf);
   if (len == 0)
     return new_response(ctx, node, COAP_RESPONSE_201);

   block = coap_check_option(node->pdu, COAP_OPTION_BLOCK);
   if ( block ) {
     blk = coap_decode_var_bytes(COAP_OPT_VALUE(*block),
				 COAP_OPT_LENGTH(*block));
     blklen = 16 << (blk & 0x07);
   } else {
     blklen = 512; // default block size is set to 512 Bytes locally
     blk = coap_fls(blklen >> 4) - 1;
   }

   tok = coap_check_option(node->pdu, COAP_OPTION_CONTENT_TYPE);
   resource->mediatype = tok ? *COAP_OPT_VALUE(*tok) : COAP_MEDIATYPE_ANY;
   resource->dirty = 1;          // mark for notification of observers

   // invoke callback function to put data representation of requested resource
   if ( resource->data ) {
     if ( resource->mediatype == COAP_MEDIATYPE_ANY
	  && (ct = coap_check_option(node->pdu, COAP_OPTION_CONTENT_TYPE)) ) {
       mediatype = *COAP_OPT_VALUE(*ct);
     }

     code = resource->data(&uri,
			   &(node->pdu->hdr->id),
			   &mediatype,
			   (blk & ~0x0f) << (blk & 0x07),
			   node->pdu->data,
			   &len,
			   &finished,
			   COAP_REQUEST_PUT);

     if (resource->splitphase) {
       if (code == COAP_SPLITPHASE) {
	 //printf("** coap: splitphase resource, save context and node details, send async response \n");
	 coap_save_splitphase(ctx, node);
	 return NULL;
       } else {
	 return new_response(ctx, node, COAP_RESPONSE_400);
       }
     } else {
       //no splitphase, handle this case
       return new_response(ctx, node, COAP_RESPONSE_500);
     }
   } else {
     // no callback available
     return new_response(ctx, node, COAP_RESPONSE_500);
   }
*/
 }


 /* event void WriteResource.putDoneDeferred[uint8_t uri_key]() {
#warning "FIXME: CoAP: putDoneDeferred not yet implemented"
}*/

 /*
 ///////////////////
 // POST method
 coap_pdu_t *handle_post(coap_context_t  *ctx, coap_queue_t *node, void *data) {
#warning "FIXME: CoAP: POST method not yet implemented"
   return NULL;
 }

 ///////////////////
 // DELETE method
 coap_pdu_t *handle_delete(coap_context_t  *ctx, coap_queue_t *node, void *data) {
#warning "FIXME: CoAP: DELETE method not yet implemented"
   return NULL;
 }
 */
 //////////////
 // message handler for incoming messages
 /*
 void message_handler(coap_context_t *ctx, coap_queue_t *node, void *data) {
   coap_pdu_t *pdu = NULL;
   coap_uri_t uri;
   coap_resource_t *resource;
#ifndef NDEBUG
   coap_show_pdu( node->pdu );
#endif

   if ( node->pdu->hdr->version != COAP_DEFAULT_VERSION ) {
     //printf("dropped packet with unknown version %u\n", node->pdu->hdr->version);
     return;
   }
   //printf("message handler\n");

   if ( !coap_get_request_uri( node->pdu, &uri ) )
     return;

   resource = coap_get_resource(ctx, &uri);

   switch (node->pdu->hdr->code) {
   case COAP_REQUEST_GET:
     pdu = handle_get(ctx, node, data);

     if ( !pdu && node->pdu->hdr->type == COAP_MESSAGE_CON ){
       if (resource && resource->splitphase) {
	 break;
       }
       pdu = new_rst( ctx, node, COAP_RESPONSE_500 );
     }
     break;
   case COAP_REQUEST_PUT:
     pdu = handle_put(ctx, node, data);

     if ( !pdu && node->pdu->hdr->type == COAP_MESSAGE_CON ){
       if (resource && resource->splitphase) {
	 break;
       }
       pdu = new_rst( ctx, node, COAP_RESPONSE_500 );
     }
     break;
   case COAP_REQUEST_POST:
     pdu = handle_post(ctx, node, data);
     if ( !pdu && node->pdu->hdr->type == COAP_MESSAGE_CON )
       pdu = new_response( ctx, node, COAP_RESPONSE_400 );
     break;
   case COAP_REQUEST_DELETE:
     pdu = handle_delete(ctx, node, data);
     if ( !pdu && node->pdu->hdr->type == COAP_MESSAGE_CON )
       pdu = new_response( ctx, node, COAP_RESPONSE_400 );
     break;
   default:
     if ( node->pdu->hdr->type == COAP_MESSAGE_CON ) {
       if ( node->pdu->hdr->code >= COAP_RESPONSE_100 )
	 pdu = new_rst( ctx, node, COAP_RESPONSE_500 );
       else {
	 pdu = new_rst( ctx, node, COAP_RESPONSE_405 );
       }
     }
   }

   if (pdu && (call LibCoapServer.send(ctx, &node->remote, pdu, 1) == COAP_INVALID_TID )) {
     //printf("message_handler: error sending response");
     coap_delete_pdu(pdu);
   }
 }
 */
 //////////////
 // save details for splitphase operation for later
/*  int coap_save_splitphase(coap_context_t *ctx, */
/* 			  coap_queue_t *node) { */
/*    coap_queue_t *new_node; */
/*    coap_opt_t *opt; */

/*    printf("coap_save_split %u\n", ntohs(node->pdu->hdr->id)); */

/*    new_node = coap_new_node(); */
/*    if ( !new_node ) { */
/*      printf("coap_split ret 1\n"); */
/*      return -1; */
/*    } */

/*    new_node->pdu = coap_new_pdu(); */
/*    if ( !new_node->pdu ) { */
/*      printf("coap_split ret 2 del_node\n"); */
/*      coap_delete_node( new_node ); */
/*      return -1; */
/*    } */

/*    memcpy( &new_node->remote, &node->remote, sizeof( struct sockaddr_in6 ) ); */
/*    printf("** coap: saving ctx and node details to send splitphase later\n"); */

/*    /\* "parse" received PDU by filling pdu structure *\/ */
/*    memcpy(new_node->pdu->hdr, node->pdu->hdr, node->pdu->length ); */
/*    new_node->pdu->length = node->pdu->length; */

/*    /\* finally calculate beginning of data block *\/ */
/*    options_end( new_node->pdu, &opt ); */

/*    if ( (unsigned char *)new_node->pdu->hdr + new_node->pdu->length < */
/* 	(unsigned char *)opt ) */
/*      new_node->pdu->data = (unsigned char *)new_node->pdu->hdr + new_node->pdu->length; */
/*    else */
/*      new_node->pdu->data = (unsigned char *)opt; */

/*    /\* and add new node to splitphasequeue *\/ */
/*    //printf("coap_split ins id %u\n", ntohs(new_node->pdu->hdr->id)); */
/*    coap_insert_node( &ctx->splitphasequeue, new_node, order_transaction_id ); */

/* #ifndef NDEBUG */
/*    coap_show_pdu( new_node->pdu ); */
/* #endif */

/*    return 0; */
/*   } */
}
