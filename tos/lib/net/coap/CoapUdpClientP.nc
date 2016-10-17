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

#include <net.h>
#include <pdu.h>
#include <mem.h>
#include <coap_debug.h>

module CoapUdpClientP {
    provides interface CoAPClient;
    uses interface LibCoAP as LibCoapClient;
} implementation {
    coap_context_t *ctx_client;
    coap_queue_t *nextpdu;

    unsigned char msgtype = COAP_MESSAGE_CON; /* usually, requests are sent confirmable */

    coap_pdu_t *new_ack( coap_context_t  *ctx, coap_queue_t *node ) {
	coap_pdu_t *pdu = coap_new_pdu();

	if (pdu) {
	    pdu->hdr->type = COAP_MESSAGE_ACK;
	    pdu->hdr->code = 0;
	    pdu->hdr->id = node->pdu->hdr->id;
	}

	return pdu;
    }

    coap_pdu_t *coap_new_request(coap_context_t *ctx, uint8_t m, coap_list_t *options,
				 uint16_t payload_length, uint8_t* payload_s) {
	coap_pdu_t *pdu;
	coap_list_t *opt;

	if ( ! ( pdu = coap_new_pdu() ) )
	    return NULL;

	pdu->hdr->type = msgtype;
	pdu->hdr->id = coap_new_message_id(ctx);
	pdu->hdr->code = m;

	for (opt = options; opt; opt = opt->next) {
	    coap_add_option(pdu, COAP_OPTION_KEY(*(coap_option *)opt->data),
			    COAP_OPTION_LENGTH(*(coap_option *)opt->data),
			    COAP_OPTION_DATA(*(coap_option *)opt->data));
	}

	if (payload_length) {
	    /* TODO: must handle block */

	    coap_add_data(pdu, payload_length, payload_s);
	}

	return pdu;
    }

    coap_opt_t *
	get_block(coap_pdu_t *pdu, coap_opt_iterator_t *opt_iter) {
	coap_opt_filter_t f;

	//assert(pdu);

	memset(f, 0, sizeof(coap_opt_filter_t));
	coap_option_setb(f, COAP_OPTION_BLOCK1);
	coap_option_setb(f, COAP_OPTION_BLOCK2);

	coap_option_iterator_init(pdu, opt_iter, f);
	return coap_option_next(opt_iter);
    }

    void message_handler(struct coap_context_t  *ctx,
			 const coap_address_t *remote,
			 coap_pdu_t *sent,
			 coap_pdu_t *received,
			 const coap_tid_t id);

    command error_t CoAPClient.setupContext(uint16_t port) {
	ctx_client = (coap_context_t*)coap_malloc( sizeof( coap_context_t ) );
	if ( !ctx_client ) {
	    return FAIL;
	}
	memset(ctx_client, 0, sizeof( coap_context_t ) );
	ctx_client->tinyos_port = port;
	coap_register_response_handler(ctx_client, message_handler);

	return SUCCESS; // CHECK: we are not binding to the port here, only done for server.
    }

    command error_t CoAPClient.request(const coap_address_t *dest,
				       uint8_t method,
				       coap_list_t *optlist,
				       uint16_t len,
				       void * data) {
	coap_pdu_t *pdu;

	if (! (pdu = coap_new_request( ctx_client, method, optlist, len, data ) ) )
	    return FAIL;

	if (call LibCoapClient.send(ctx_client, dest, pdu) == COAP_INVALID_TID) {
	    coap_delete_pdu (pdu);
	    return FAIL;
	}
	return SUCCESS;
    };

    command error_t CoAPClient.streamed_request(struct sockaddr_in6 *dest,
						uint8_t method,
						coap_list_t *optlist) {
	// TODO: implement block'ed data transfer
	return FAIL;
    }

    void message_handler(struct coap_context_t  *ctx,
			 const coap_address_t *remote,
			 coap_pdu_t *sent,
			 coap_pdu_t *received,
			 const coap_tid_t id) {
	//coap_pdu_t *pdu = NULL;
	//coap_opt_t *block;
	//coap_opt_iterator_t opt_iter;
	//unsigned char buf[4];
	//coap_list_t *option;
	size_t len;
	unsigned char *databuf;
	//coap_tid_t tid;

	switch (received->hdr->type) {
	case COAP_MESSAGE_CON:
	    /* acknowledge received response if confirmable (TODO: check Token) */
	    coap_send_ack(ctx, remote, received);
	    break;
	case COAP_MESSAGE_RST:
	    info("got RST\n");
	    return;
	default:
	    ;
	}

	coap_get_data(received, &len, &databuf);
	signal CoAPClient.request_done(received->hdr->code,
				       (uint16_t)len, &databuf);

	//TODO: actually use the code from client.c:

	/* /\* output the received data, if any *\/ */
	/* if (received->hdr->code == COAP_RESPONSE_CODE(205)) { */

	/*     /\* Got some data, check if block option is set. Behavior is undefined if */
	/*      * both, Block1 and Block2 are present. *\/ */
	/*     block = get_block(received, &opt_iter); */
	/*     if ( !block ) { */
	/* 	/\* There is no block option set, just read the data and we are done. *\/ */
	/* 	if (coap_get_data(received, &len, &databuf)) */
	/* 	    append_to_output(databuf, len); */
	/*     } else { */
	/* 	unsigned short blktype = opt_iter.type; */

	/* 	/\* TODO: check if we are looking at the correct block number *\/ */
	/* 	if (coap_get_data(received, &len, &databuf)) */
	/* 	    append_to_output(databuf, len); */

	/* 	if (COAP_OPT_BLOCK_MORE(block)) { */
	/* 	    /\* more bit is set *\/ */
	/* 	    debug("found the M bit, block size is %u, block nr. %u\n", */
	/* 		  COAP_OPT_BLOCK_SZX(block), COAP_OPT_BLOCK_NUM(block)); */

	/* 	    /\* create pdu with request for next block *\/ */
	/* 	    pdu = coap_new_request(ctx, method, NULL); /\* first, create bare PDU w/o any option  *\/ */
	/* 	    if ( pdu ) { */
	/* 		/\* add URI components from optlist *\/ */
	/* 		for (option = optlist; option; option = option->next ) { */
	/* 		    switch (COAP_OPTION_KEY(*(coap_option *)option->data)) { */
	/* 		    case COAP_OPTION_URI_HOST : */
	/* 		    case COAP_OPTION_URI_PORT : */
	/* 		    case COAP_OPTION_URI_PATH : */
	/* 		    case COAP_OPTION_TOKEN : */
	/* 		    case COAP_OPTION_URI_QUERY : */
	/* 			coap_add_option ( pdu, COAP_OPTION_KEY(*(coap_option *)option->data), */
	/* 					  COAP_OPTION_LENGTH(*(coap_option *)option->data), */
	/* 					  COAP_OPTION_DATA(*(coap_option *)option->data) ); */
	/* 			break; */
	/* 		    default: */
	/* 			;			/\* skip other options *\/ */
	/* 		    } */
	/* 		} */

	/* 		/\* finally add updated block option from response, clear M bit *\/ */
	/* 		/\* blocknr = (blocknr & 0xfffffff7) + 0x10; *\/ */
	/* 		debug("query block %d\n", (COAP_OPT_BLOCK_NUM(block) + 1)); */
	/* 		coap_add_option(pdu, blktype, coap_encode_var_bytes(buf, */
	/* 								    ((COAP_OPT_BLOCK_NUM(block) + 1) << 4) | */
	/* 								    COAP_OPT_BLOCK_SZX(block)), buf); */

	/* 		if (received->hdr->type == COAP_MESSAGE_CON) */
	/* 		    tid = coap_send_confirmed(ctx, remote, pdu); */
	/* 		else */
	/* 		    tid = coap_send(ctx, remote, pdu); */

	/* 		if (tid == COAP_INVALID_TID) { */
	/* 		    debug("message_handler: error sending new request"); */
	/* 		    coap_delete_pdu(pdu); */
	/* 		} else */
	/* 		    set_timeout(); */
	/* 		return; */
	/* 	    } */
	/* 	} */
	/*     } */
	/* } else {			/\* no 2.05 *\/ */

	/*     /\* check if an error was signaled and output payload if so *\/ */
	/*     if (COAP_RESPONSE_CLASS(received->hdr->code) >= 4) { */
	/* 	fprintf(stderr, "%d.%02d", */
	/* 		(received->hdr->code >> 5), received->hdr->code & 0x1F); */
	/* 	if (coap_get_data(received, &len, &databuf)) { */
	/* 	    fprintf(stderr, " "); */
	/* 	    while(len--) */
	/* 		fprintf(stderr, "%c", *databuf++); */
	/* 	} */
	/* 	fprintf(stderr, "\n"); */
	/*     } */
	/* } */

    }

    event void LibCoapClient.read(struct sockaddr_in6 *from, void *data,
				  uint16_t len, struct ip6_metadata *meta) {
	printf("CoapUdpClient: LibCoapClient.read()\n");

	// CHECK: lock access to context?
	// copy data into ctx_client
	ctx_client->bytes_read = len;
	memcpy(ctx_client->buf, data, len);
	// copy src into context
	memcpy(&ctx_client->src.addr, from, sizeof (struct sockaddr_in6));
	coap_read(ctx_client);
	coap_dispatch(ctx_client);
    }

 default event void CoAPClient.request_done (uint8_t code, uint16_t len, void *data)
     {
     }
  }
