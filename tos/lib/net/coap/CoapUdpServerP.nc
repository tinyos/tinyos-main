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
#include <tinyos_net.h>

#include <pdu.h>
#include <subscribe.h>  // for resource_t
#include <encode.h>
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
  provides interface Init;
  uses interface LibCoAP as LibCoapServer;
  uses interface Random;
  uses interface Leds;
  uses interface ReadResource[uint8_t uri];
  uses interface WriteResource[uint8_t uri];
} implementation {
  coap_context_t *ctx_server;
  unsigned short tid; //has to be static to ensure continuous increase for asyn responses

  // unlink a given node from the queue
  int
  coap_extract_node(coap_queue_t **queue, coap_queue_t *node)
  {
    coap_queue_t *q;
    if (!queue)
      return 0;

    q = *queue;
    if (q == node)
    {
      *queue = node->next;
      return 1;
    }

    for (;q; q = q->next)
    {
      if (q->next == node)
      {
        q->next = node->next;
        return 1;
      }
    }
    return 0;
  }

  //get uri (char) from key (int)
  //defined in tinyos_coap_ressources.h
  char* get_uri(uint8_t key) {
    if (key < NUM_URIS) {
      return uri_key_map[key].uri;
    }
    return "";
  }

  //get key (int) from uri (char)
  //defined in tinyos_coap_ressources.h
  uint8_t get_key(uint8_t* uri, uint8_t len) {
    uint8_t i;

    for (i=0; i < NUM_URIS; i++) {
      if (strncmp(uri_key_map[i].uri, (const char*) uri, len) == 0)
	return uri_key_map[i].key;
    }
    return COAP_NO_SUCH_RESOURCE;
  }

  //generate new transaction id for async response
  unsigned short get_new_tid(){
    if (!tid)
      tid = call Random.rand16();
    tid++;
    return ntohs(tid);
  }

  int resource_splitphase(coap_uri_t *uri,
			  coap_tid_t *id,
			  unsigned char *mediatype,
			  unsigned int offset,
			  unsigned char *buf,
			  unsigned int *buflen,
			  int *finished,
			  unsigned int method);

  int coap_save_splitphase(coap_context_t *ctx, coap_queue_t *node);

  void message_handler(coap_context_t *ctx, coap_queue_t *node, void *data);

  command error_t Init.init() {

    ctx_server = (coap_context_t*)coap_malloc( sizeof( coap_context_t ) );
    if ( !ctx_server ) {
      return FAIL;
    }
    memset(ctx_server, 0, sizeof( coap_context_t ) );
    ctx_server->tinyos_port = COAP_SERVER_PORT;
    printf("init: port %u\n", ctx_server->tinyos_port);
    coap_register_message_handler( ctx_server, message_handler );

    return SUCCESS;
  }

  command error_t CoAPServer.bind(uint16_t port) {
    return call LibCoapServer.bind(port);
  }

#ifdef INCLUDE_WELLKNOWN
  ///////////////////
  // wellknown resources
  int print_link(coap_resource_t *resource, unsigned char *buf, size_t buflen) {
      size_t n = 0;

      //assert(resource);
      //assert(buf);
      if (resource == NULL || buf == NULL) {
	  return -1;
      }

      if (buflen < resource->uri->path.length + 3)
	  return -1;

      /* FIXME: calculate maximum length and return if longer than buflen */
      buf[n++] = '<'; buf[n++] = '/';

      memcpy(buf + n, resource->uri->path.s, resource->uri->path.length);

      n += resource->uri->path.length;
      buf[n++] = '>';

      if (resource->mediatype != COAP_MEDIATYPE_ANY) {
	  if (buflen - n < 7) 	/* mediatype is at most 3 digits */
	      return -1;
	  n += snprintf((char *)(buf + n), buflen - n, ";ct=%d",
			resource->mediatype);
      }

      if (resource->name) {
	  if (buflen - n < resource->name->length + 5) /* include trailing quote */
	      return -1;

	  memcpy(buf + n, ";n=\"", 4);
	  n += 4;
	  memcpy(buf + n, resource->name->s, resource->name->length);
	  n += resource->name->length;

	  if (!resource->writable) {
	      if (buflen - n < 12)
		  return -1;

	      n += snprintf((char *)(buf + n), buflen - n, " (read-only)");
	  }

	  buf[n++] = '"';
      }

      return  n;
  }

  int resource_wellknown(coap_uri_t *uri,
			 coap_tid_t *id,
			 unsigned char *mediatype,
			 unsigned int offset,
			 unsigned char *buf,
			 unsigned int *buflen,
			 int *finished,
			 unsigned int method) {
#define RESOURCE_BUFLEN 1000
      static unsigned char resources[RESOURCE_BUFLEN];
      size_t maxlen = 0;
      int n;
      coap_list_t *node;

      //assert(ctx_server);
      //assert(resource);
      if (ctx_server == NULL) {
	  return COAP_RESPONSE_500;
      }

      /* first, update the link-set */
      for (node = ctx_server->resources; node; node = node->next) {
	  n = print_link(COAP_RESOURCE(node), resources + maxlen,
			 RESOURCE_BUFLEN - maxlen);
	  if (n <= 0) { 			/* error */
	      //debug("resource description too long, truncating\n");
	      resources[maxlen] = '\0';
	      break;
	  }
	  maxlen += n;

	  if (node->next) 		/* check if another entry follows */
	      resources[maxlen++] = ',';
	  else 			/* no next, terminate string */
	      resources[maxlen] = '\0';
      }

      *finished = 1;

      switch (*mediatype) {
      case COAP_MEDIATYPE_ANY :
      case COAP_MEDIATYPE_APPLICATION_LINK_FORMAT :
	  *mediatype = COAP_MEDIATYPE_APPLICATION_LINK_FORMAT;
	  break;
      default :
	  *buflen = 0;
	  return COAP_RESPONSE_415;
      }

      if ( offset > maxlen ) {
	  *buflen = 0;
	  return COAP_RESPONSE_400;
      } else if ( offset + *buflen > maxlen )
	  *buflen = maxlen - offset;

      memcpy(buf, resources + offset, *buflen);

      *finished = offset + *buflen == maxlen;
      return COAP_RESPONSE_200;
  }
#endif

  //register wellknown resource
  command error_t CoAPServer.registerWellknownCore() {
#ifdef INCLUDE_WELLKNOWN
    coap_resource_t *r;

    if ( !(r = coap_malloc( sizeof(coap_resource_t) ))) {
	return FAIL;
    }

    r->uri = coap_new_uri((const unsigned char *) COAP_DEFAULT_URI_WELLKNOWN,
			  sizeof(COAP_DEFAULT_URI_WELLKNOWN));
    r->mediatype = COAP_MEDIATYPE_APPLICATION_LINK_FORMAT;
    r->dirty = 0;
    r->writable = 0;
    r->splitphase = 0;
    r->immediately = 1;
    r->data = resource_wellknown;
    coap_add_resource( ctx_server, r );
    return SUCCESS;
#else

#warning "CoAP Resource .wellknown/core disabled. Add CFLAGS += -DINCLUDE_WELLKNOWN to Makefile, if you want it included."
    return FAIL;

#endif
  }

  ///////////////////
  // register resources
  command error_t CoAPServer.registerResource(char uri[MAX_URI_LENGTH],
					      unsigned int uri_length,
					      unsigned char mediatype,
					      unsigned int writable,
					      unsigned int splitphase,
					      unsigned int immediately) {
    coap_resource_t *r;
    coap_key_t k;
    if ( !(r = coap_malloc( sizeof(coap_resource_t) )))
      return FAIL;

    r->uri = coap_new_uri((const unsigned char*) uri, uri_length);
    r->mediatype = mediatype;
    r->dirty = 0; // CHECK
    r->writable = writable;
    r->splitphase = splitphase;
    r->immediately = immediately;
    r->data = resource_splitphase;

    k = coap_add_resource( ctx_server, r );

    if (k == COAP_INVALID_HASHKEY) {
      return FAIL;
    }
    return SUCCESS;
  }

  ///////////////////
  // splitphase resources
  int resource_splitphase(coap_uri_t *uri,
			  coap_tid_t  *id,
			  unsigned char *mediatype,
			  unsigned int offset,
			  unsigned char *buf,
			  unsigned int *buflen,
			  int *finished,
			  unsigned int method) {

    if ( method == COAP_REQUEST_GET) {
      return call ReadResource.get[get_key(uri->path.s, uri->path.length)](*id);
    } else if ( method == COAP_REQUEST_PUT) {
      return call WriteResource.put[get_key(uri->path.s, uri->path.length)](buf, *buflen, *id);
    } else {
      //when the method is neither GET nor PUT, i.e. POST & DELETE -> 405
      return COAP_RESPONSE_405;
    }
  }

  event void LibCoapServer.read(struct sockaddr_in6 *from, void *data,
				uint16_t len, struct ip6_metadata *meta) {
    printf("CoapUdpServer: LibCoapServer.read()\n");
    coap_read(ctx_server, from, data, len, meta);
    coap_dispatch(ctx_server);
  }

  //////////////////////
  // some standard PDU's
  coap_pdu_t *new_ack( coap_context_t  *ctx, coap_queue_t *node ) {
    coap_pdu_t *pdu;
    //printf("** coap: new_ack\n");
    GENERATE_PDU(pdu,COAP_MESSAGE_ACK,0,node->pdu->hdr->id,0);

    return pdu;
  }

  coap_pdu_t *new_rst( coap_context_t  *ctx, coap_queue_t *node,
		       unsigned int code ) {
    coap_pdu_t *pdu;
    GENERATE_PDU(pdu,COAP_MESSAGE_RST,code,node->pdu->hdr->id,1);
    return pdu;
  }

  coap_pdu_t *new_response( coap_context_t  *ctx, coap_queue_t *node,
			    unsigned int code ) {
    coap_pdu_t *pdu;
    //printf("** coap: new_response %i\n", code);
    GENERATE_PDU(pdu,COAP_MESSAGE_ACK,code,node->pdu->hdr->id,1);

    return pdu;
  }

  coap_pdu_t *new_asynresponse( coap_context_t  *ctx, coap_queue_t *node) {
    coap_pdu_t *pdu;
    //printf("** coap: new_asynresponse\n");
    GENERATE_PDU(pdu,COAP_MESSAGE_CON,COAP_RESPONSE_200,node->pdu->hdr->id,1);

    return pdu;
  }

  //add default data in case of empty uri path. (for testing purposes only)
  void add_contents( coap_pdu_t *pdu, unsigned char mediatype,
		     unsigned int len, unsigned char *data ) {

    unsigned char ct = COAP_MEDIATYPE_APPLICATION_LINK_FORMAT;
    if (!pdu)
      return;

    /* add content-encoding */
    coap_add_option(pdu, COAP_OPTION_CONTENT_TYPE, 1, &ct);

    coap_add_data(pdu, len, data);
  }

  coap_opt_t* coap_next_option(coap_pdu_t *pdu, coap_opt_t *opt) {
    coap_opt_t *next;
    if ( !pdu || !opt )
      return NULL;

    next = (coap_opt_t *)( (unsigned char *)opt + COAP_OPT_SIZE(*opt) );
    return (unsigned char *)next < pdu->data && COAP_OPT_DELTA(*next) == 0 ? next : NULL;
  }

  int mediatype_matches(coap_pdu_t *pdu, unsigned char mediatype) {
    coap_opt_t *ct;

    if ( mediatype == COAP_MEDIATYPE_ANY )
      return 1;

    for (ct = coap_check_option(pdu, COAP_OPTION_CONTENT_TYPE); ct; ct = coap_next_option(pdu, ct)) {
      if ( *COAP_OPT_VALUE(*ct) == mediatype )
	return 1;
    }

    return 0;
  }

  ///////////////////
  // GET method
  coap_pdu_t *handle_get(coap_context_t *ctx, coap_queue_t *node, void *data) {
    coap_pdu_t *pdu;
    coap_uri_t uri;
    coap_resource_t *resource;
    coap_opt_t *block, *ct;
    unsigned int blklen, blk;
    int code, finished = 1;
    unsigned char mediatype = COAP_MEDIATYPE_ANY;
    static unsigned char buf[COAP_MAX_PDU_SIZE];

    if ( !coap_get_request_uri( node->pdu, &uri ) )
      return NULL;

    //printf("** coap: handle_get: uri %s \n", uri.path.s);
    //send default test response if no URI is given
    if ( !uri.path.length ) {
      pdu = new_response(ctx, node, COAP_RESPONSE_200);

      if ( !pdu )
	return NULL;

      add_contents( pdu, COAP_MEDIATYPE_TEXT_PLAIN, sizeof(INDEX) - 1, (unsigned char *)INDEX );
      return pdu;
    }

    // any other resource
    if ( !(resource = coap_get_resource(ctx, &uri)) )
      return new_response(ctx, node, COAP_RESPONSE_404);

    /* check if requested mediatypes match */
    if ( coap_check_option(node->pdu, COAP_OPTION_CONTENT_TYPE)
	 && !mediatype_matches(node->pdu, resource->mediatype) )
      return new_response(ctx, node, COAP_RESPONSE_415);

    block = coap_check_option(node->pdu, COAP_OPTION_BLOCK);
    if ( block ) {
      blk = coap_decode_var_bytes(COAP_OPT_VALUE(*block),
				  COAP_OPT_LENGTH(*block));
      blklen = 16 << (blk & 0x07);
    } else {
      blklen = 512; // default block size
      blk = coap_fls(blklen >> 4) - 1;
    }

    /* invoke callback function to get data representation of requested
       resource */
    if ( resource->data ) {
      if ( resource->mediatype == COAP_MEDIATYPE_ANY
	   && (ct = coap_check_option(node->pdu, COAP_OPTION_CONTENT_TYPE)) ) {
	mediatype = *COAP_OPT_VALUE(*ct);
      }

      //printf("handle_get: data()\n");
      code = resource->data(&uri,
			    &(node->pdu->hdr->id),
			    &mediatype,
			    (blk & ~0x0f) << (blk & 0x07),
			    buf,
			    &blklen,
			    &finished,
			    COAP_REQUEST_GET);
      //printf("handle_get: data()~ %u %u\n", resource->splitphase, code);

      if (resource->splitphase) {
	if (code == COAP_SPLITPHASE) {
	  //printf("handle_get: save()\n");
	  /* handle subscription */
#warning "FIXME: CoAP: subscriptions not yet implemented"
	  //FIXME: SAVE before calling data()?
	  coap_save_splitphase(ctx, node);
	  // this is a split-phase resource, no PDU ready yet, created in getDone
	  return NULL;
	} else {
	  //printf("** handle_get: splitphase not successful\n");

	  return new_response(ctx, node, code);
	}
      } else {

	  //not splitphase -> resource_wellknown
	  pdu = new_response(ctx, node, code);

	  if ( !pdu )
	      return NULL;

	  // Add buffer value to the PDU
	  if (!coap_add_data(pdu, blklen, buf)) {
	      coap_delete_pdu(pdu);
	      if ( !(pdu = new_response(ctx_server, node, COAP_RESPONSE_500)) ) {
		  //printf("** coap: return PDU Null for 500 response\n");
	      }
	  }

	  return pdu;
      }
    } else {
      // no callback available
      return new_response(ctx, node, COAP_RESPONSE_500);
    }
  }

 default command int ReadResource.get[uint8_t uri_key](coap_tid_t id) {
   //printf("** coap: default (get not available for this resource)....... %i\n", uri_key);
   return FAIL;
 }

 event void ReadResource.getDone[uint8_t uri_key](error_t result,
						  coap_tid_t id,
						  uint8_t asyn_message,
						  uint8_t* val_buf,
						  size_t buflen) {
   coap_queue_t *node;
   coap_pdu_t *pdu;
   coap_opt_t *ct;

   //printf("** coap: getDone.... %i %u %u\n", uri_key, id, ntohs(id));

   // assuming more than one entry is in splitphasequeue
   if (!(node = coap_find_transaction(ctx_server->splitphasequeue, id))) {
     //printf("** coap: getDone: node in splitphasequeue not found %u\n", id);
     return;
   }

   if (result != SUCCESS) {
     //printf("** coap: sensor retrival failed\n");

     if ( !(pdu = new_response(ctx_server, node, COAP_RESPONSE_500)) ) {
	 //printf("** coap: return PDU Null for COAP_RESPONSE_500 \n");
     }
     //FIXME
     memcpy(val_buf, "Sensor not found", 16);
     buflen = 16;
   } else {
     //printf("** coap: sensor retrival successful\n");
     if (asyn_message){
       node->pdu->hdr->id = get_new_tid();

       if ( !(pdu = new_asynresponse(ctx_server, node)) ) {
	 //printf("** coap: return PDU Null for Asyn response\n");
       }
     } else {
       //normal response
       if ( !(pdu = new_response(ctx_server, node, COAP_RESPONSE_200)) ) {
	 //printf("** coap: return PDU Null for normal response\n");
       }
     }
   }

   // Add content-encoding
   // TODO: this should come from the resource, not the request!
   ct = coap_check_option( node->pdu, COAP_OPTION_CONTENT_TYPE );
   if ( ct ) {
     coap_add_option( pdu, COAP_OPTION_CONTENT_TYPE, COAP_OPT_LENGTH(*ct),COAP_OPT_VALUE(*ct) );
   }

   // Add buffer value to the PDU
   if (!coap_add_data(pdu, buflen, val_buf)) {
     coap_delete_pdu(pdu);
     if ( !(pdu = new_response(ctx_server, node, COAP_RESPONSE_500)) ) {
       //printf("** coap: return PDU Null for 500 response\n");
     }
   }

   // sending pdu
   printf("getDone(): send PDU %u\n", ntohs(node->pdu->hdr->id));
   if (pdu && (call LibCoapServer.send(ctx_server, &node->remote, pdu, 1) == COAP_INVALID_TID )) {
     //printf("** coap:error sending response\n");
     coap_delete_pdu(pdu);
   }

   /* remove node from splitphasequeue */
   //printf("getDone(): remove %u\n", ntohs(id));
   //coap_remove_transaction(&ctx_server->splitphasequeue, id);

   coap_extract_node (&ctx_server->splitphasequeue, node);
   node->next = NULL;
   coap_delete_node( node );
   //printf("getDone(): delete node details kept for splitphase response\n");
 }

 event void ReadResource.getDoneDeferred[uint8_t uri_key](coap_tid_t id) {
   coap_queue_t *node;
   coap_pdu_t *pdu;
   uint8_t reqtoken = 0;

   printf("getDoneDeferred ##\n");

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
     /* remove node from splitphasequeue */
     coap_extract_node (&ctx_server->splitphasequeue, node);
     node->next = NULL;
     coap_delete_node(node);
     printf("** coap: delete node deferred\n");
   } else {
     printf("** coap: PreACK sent!\n");
   }
 }

 ///////////////////
 // PUT method
 coap_pdu_t * handle_put(coap_context_t  *ctx, coap_queue_t *node, void *data) {
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

   /* we do not want to create the resource if not available */
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
     blklen = 512; /* default block size is set to 512 Bytes locally */
     blk = coap_fls(blklen >> 4) - 1;
   }

   tok = coap_check_option(node->pdu, COAP_OPTION_CONTENT_TYPE);
   resource->mediatype = tok ? *COAP_OPT_VALUE(*tok) : COAP_MEDIATYPE_ANY;
   resource->dirty = 1;          /* mark for notification of observers */

   /* invoke callback function to put data representation of requested resource */
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
 }

 default command int WriteResource.put[uint8_t uri_key](uint8_t* val, size_t buflen, coap_tid_t id) {
   //printf("** coap: default (put not available for this resource)....... %i\n", uri_key);
   return FAIL;
 }

 event void WriteResource.putDone[uint8_t uri_key](error_t result,
						   coap_tid_t id,
						   uint8_t asyn_message) {

   coap_queue_t *node;
   coap_pdu_t *pdu;
   coap_opt_t *ct;

   //printf("** coap: putDone.... %i\n", uri_key);
   // assuming more than one entry is in splitphasequeue
   if (!(node = coap_find_transaction(ctx_server->splitphasequeue, id))){
     //printf("** coap: puttDone: node in splitphasequeue not found, quit\n");
     return;
   }

   if (result){
     //printf("** coap: sensor retrival failed\n");
     if ( !(pdu = new_response(ctx_server, node, COAP_RESPONSE_500)) ) {
       // printf("** coap: return PDU Null for COAP_RESPONSE_500 \n");
     }
     //FIXME
     //memcpy(val_buf, "Sensor not found", 16);
     //buflen = 16;
   } else {
     //printf("** coap: sensor retrival successful\n");
     if (asyn_message){
       node->pdu->hdr->id = get_new_tid();
       if ( !(pdu = new_asynresponse(ctx_server, node)) ) {
	 //printf("** coap: return PDU Null for Asyn response\n");
       }
     } else {
       if ( !(pdu = new_response(ctx_server, node, COAP_RESPONSE_200)) ) {
	 //printf("** coap: return PDU Null for normal response\n");
       }
     }
   }

   // Add content-encoding
   ct = coap_check_option( node->pdu, COAP_OPTION_CONTENT_TYPE );
   if ( ct ) {
     coap_add_option( pdu, COAP_OPTION_CONTENT_TYPE, COAP_OPT_LENGTH(*ct),COAP_OPT_VALUE(*ct) );
   }

   // sending pdu
   if (pdu && (call LibCoapServer.send(ctx_server, &node->remote, pdu, 1) == COAP_INVALID_TID )) {
     //printf("** coap:asyn Res: error sending response\n");
     coap_delete_pdu(pdu);
   }

   /* remove node from asynresqueue */
   coap_extract_node (&ctx_server->splitphasequeue, node);
   node->next = NULL;
   coap_delete_node( node );
   //printf("** coap: delete node details kept for Asyn response\n");
 }

 event void WriteResource.putDoneDeferred[uint8_t uri_key](coap_tid_t id) {
#warning "FIXME: CoAP: putDoneDeferred not yet implemented"
 }

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

 //////////////
 // message handler for incoming messages
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

 //////////////
 // save details for splitphase operation for later
 int coap_save_splitphase(coap_context_t *ctx,
			  coap_queue_t *node) {
   coap_queue_t *new_node;
   coap_opt_t *opt;

   printf("coap_save_split %u\n", ntohs(node->pdu->hdr->id));

   new_node = coap_new_node();
   if ( !new_node ) {
     printf("coap_split ret 1\n");
     return -1;
   }

   new_node->pdu = coap_new_pdu();
   if ( !new_node->pdu ) {
     printf("coap_split ret 2 del_node\n");
     coap_delete_node( new_node );
     return -1;
   }

   memcpy( &new_node->remote, &node->remote, sizeof( struct sockaddr_in6 ) );
   printf("** coap: saving ctx and node details to send splitphase later\n");

   /* "parse" received PDU by filling pdu structure */
   memcpy(new_node->pdu->hdr, node->pdu->hdr, node->pdu->length );
   new_node->pdu->length = node->pdu->length;

   /* finally calculate beginning of data block */
   options_end( new_node->pdu, &opt );

   if ( (unsigned char *)new_node->pdu->hdr + new_node->pdu->length <
	(unsigned char *)opt )
     new_node->pdu->data = (unsigned char *)new_node->pdu->hdr + new_node->pdu->length;
   else
     new_node->pdu->data = (unsigned char *)opt;

   /* and add new node to splitphasequeue */
   //printf("coap_split ins id %u\n", ntohs(new_node->pdu->hdr->id));
   coap_insert_node( &ctx->splitphasequeue, new_node, order_transaction_id );

#ifndef NDEBUG
   coap_show_pdu( new_node->pdu );
#endif

   return 0;
  }
}
