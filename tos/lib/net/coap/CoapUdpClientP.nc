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
#include <tinyos_net.h>
#include <pdu.h>
#include <mem.h>

module CoapUdpClientP {
  provides interface CoAPClient;
  provides interface Init;
  uses interface Random;
  uses interface LibCoAP as LibCoapClient;
} implementation {
  coap_context_t *ctx_client;
  coap_queue_t *nextpdu;
  unsigned short tid;

  //generate random transaction id
  unsigned short get_tid(){
    if (!tid)
      tid = call Random.rand16();
    tid++;
    return ntohs(tid);
  }

  coap_pdu_t *
  coap_new_ack(coap_pdu_t *pdu)
  {
    coap_pdu_t *ack = coap_new_pdu();

    if (!ack)
      return NULL;

    ack->hdr->type = COAP_MESSAGE_ACK;
    ack->hdr->id = pdu->hdr->id;
    ack->hdr->code = 0;

    return ack;
  }

  coap_pdu_t *
  coap_new_request(method_t m, coap_list_t *options, uint16_t len, void *data) {
    coap_pdu_t *pdu;
    coap_list_t *opt;

    if ( ! ( pdu = coap_new_pdu() ) )
      return NULL;

    pdu->hdr->type = COAP_MESSAGE_CON;
    pdu->hdr->id = get_tid();
    pdu->hdr->code = m;

    for (opt = options; opt; opt = opt->next) {
      coap_add_option( pdu, COAP_OPTION_KEY(*(coap_option *)opt->data),
		       COAP_OPTION_LENGTH(*(coap_option *)opt->data),
		       COAP_OPTION_DATA(*(coap_option *)opt->data) );
    }

    if (len && data)
      coap_add_data( pdu, len, data);

    return pdu;
  }

  void message_handler(coap_context_t *ctx, coap_queue_t *node, void *data);

  command error_t Init.init() {

    ctx_client = (coap_context_t*)coap_malloc( sizeof( coap_context_t ) );
    if ( !ctx_client ) {
      return FAIL;
    }
    memset(ctx_client, 0, sizeof( coap_context_t ) );
    ctx_client->tinyos_port = COAP_CLIENT_PORT;
    coap_register_message_handler( ctx_client, message_handler );
    return SUCCESS;
  }

  command error_t CoAPClient.request(struct sockaddr_in6 *dest,
				     method_t method,
				     coap_list_t *optlist,
				     uint16_t len,
				     void * data) {
    coap_pdu_t *pdu;

    if (! (pdu = coap_new_request( method, optlist, len, data ) ) )
      return FAIL;

    if (call LibCoapClient.send(ctx_client, dest, pdu, 1) == COAP_INVALID_TID)
    {
        coap_delete_pdu (pdu);
        return FAIL;
    }
    return SUCCESS;
  };

  command error_t CoAPClient.streamed_request(struct sockaddr_in6 *dest,
					      method_t method,
					      coap_list_t *optlist) {
    // TODO: implement block'ed data transfer
    return FAIL;
  }

  void message_handler(coap_context_t *ctx, coap_queue_t *node, void *data) {
    unsigned int len = 0;
    unsigned char *payload = NULL;
    bool more = FALSE;
    uint8_t mediatype = COAP_MEDIATYPE_TEXT_PLAIN;

    if (node->pdu->hdr->version != COAP_DEFAULT_VERSION)
      return;

    if (node->pdu->hdr->type == COAP_MESSAGE_CON)
    {
      coap_pdu_t *ack = coap_new_ack(node->pdu);
      // TODO: maybe move this to a separate task?
      if (call LibCoapClient.send(ctx_client, &node->remote, ack, 1) ==
          COAP_INVALID_TID)
      {
        coap_delete_pdu (ack);
      }
    }

    if (node->pdu->hdr->code == COAP_RESPONSE_200)
    {
      coap_opt_t *ct, *block;

      ct = coap_check_option (node->pdu, COAP_OPTION_CONTENT_TYPE);
      if (ct)
        mediatype = *COAP_OPT_VALUE(*ct);

      block = coap_check_option (node->pdu, COAP_OPTION_BLOCK);
      if (!block)
      {
        if (!coap_get_data (node->pdu, &len, &payload))
          return;
      }
      else
      {
         // TODO: implement requesting of next response block
        return;
      }
    }
    if (node->pdu->hdr->code != 0)
      signal CoAPClient.request_done (
        node->pdu->hdr->code, mediatype, (uint16_t)len, data, more);
  }

  event void LibCoapClient.read(struct sockaddr_in6 *from, void *data,
				uint16_t len, struct ip6_metadata *meta) {
    coap_read(ctx_client, from, data, len, meta);
    coap_dispatch(ctx_client);
  }

  default event void CoAPClient.request_done (
        uint8_t code, uint8_t mediatype, uint16_t len, void *data, bool more)
  {
  }
}
