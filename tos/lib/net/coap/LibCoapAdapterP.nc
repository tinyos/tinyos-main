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

#include "blip_printf.h"

#include <net.h>
#include <pdu.h>

module LibCoapAdapterP {
#ifdef COAP_SERVER_ENABLED
  provides interface LibCoAP as LibCoapServer;
  uses interface UDP as UDPServer;
#endif

#ifdef COAP_CLIENT_ENABLED
  provides interface LibCoAP as LibCoapClient;
  uses interface UDP as UDPClient;
#endif
} implementation {

  // might get called in error cases from libcoap's net.c -> spontaneous.
  coap_tid_t coap_send_impl(coap_context_t *context,
			    struct sockaddr_in6 *dst,
			    coap_pdu_t *pdu,
			    int free_pdu ) @C() @spontaneous() {
    coap_tid_t tid;

#ifndef COAP_SERVER_ENABLED
#ifndef COAP_CLIENT_ENABLED
#error "CoAP without server and client?"
#endif
#endif

    if ( !context || !dst || !pdu )
      return COAP_INVALID_TID;

#ifdef COAP_CLIENT_ENABLED
    if (context->tinyos_port == (int) COAP_CLIENT_PORT)
	call UDPClient.sendto(dst, pdu->hdr, pdu->length);
#endif
#ifdef COAP_SERVER_ENABLED
    if (context->tinyos_port == (int) COAP_SERVER_PORT)
	call UDPServer.sendto(dst, pdu->hdr, pdu->length);
#endif

    tid = pdu->hdr->id;

    if ( free_pdu )
      coap_delete_pdu( pdu );

    return ntohs(tid);
  }

#ifdef COAP_SERVER_ENABLED
  void libcoap_server_read(struct sockaddr_in6 *from, void *data,
			   uint16_t len, struct ip6_metadata *meta) {
    signal LibCoapServer.read(from, data, len, meta);
  }

  event void UDPServer.recvfrom(struct sockaddr_in6 *from, void *data,
				uint16_t len, struct ip6_metadata *meta) {
    printf( "LibCoapAdapter UDPServer.recvfrom()\n");
    libcoap_server_read(from, data, len, meta);
  }

  command coap_tid_t LibCoapServer.send(coap_context_t *context,
					struct sockaddr_in6 *dst,
					coap_pdu_t *pdu,
					int free_pdu) {
    return coap_send_impl(context, dst, pdu, free_pdu);
  }

  command error_t LibCoapServer.bind(uint16_t port) {
    return call UDPServer.bind(port);
  }
#endif

#ifdef COAP_CLIENT_ENABLED
  void libcoap_client_read(struct sockaddr_in6 *from, void *data,
			   uint16_t len, struct ip6_metadata *meta) {
    signal LibCoapClient.read(from, data, len, meta);
  }

  event void UDPClient.recvfrom(struct sockaddr_in6 *from, void *data,
				uint16_t len, struct ip6_metadata *meta) {
    //printf("LibCoapAdapter UDPClient.recvfrom()\n");
    libcoap_client_read(from, data, len, meta);
  }

  command coap_tid_t LibCoapClient.send(coap_context_t *context,
					struct sockaddr_in6 *dst,
					coap_pdu_t *pdu,
					int free_pdu) {
    return coap_send_impl(context, dst, pdu, free_pdu);
  }

  command error_t LibCoapClient.bind(uint16_t port) {
    return call UDPClient.bind(port);
  }
#endif
}
