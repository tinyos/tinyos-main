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
#include <coap_time.h>

module LibCoapAdapterP {
#ifdef COAP_SERVER_ENABLED
  provides interface LibCoAP as LibCoapServer;
  uses interface UDP as UDPServer;
#endif

#ifdef COAP_CLIENT_ENABLED
  provides interface LibCoAP as LibCoapClient;
  uses interface UDP as UDPClient;
#endif

  uses interface LocalTime<TSecond> as LocalTime;
  uses interface Timer<TMilli> as RetransmissionTimerMilli;
  uses interface Random;
  uses interface Leds;
} implementation {

  /*
    //debugging help for C code:

  void allLedsOn() @C() @spontaneous() {
    call Leds.led0On();
    call Leds.led1On();
    call Leds.led2On();
  }

  void led0On() @C() @spontaneous() {
    call Leds.led0On();
  }

  void led1On() @C() @spontaneous() {
    call Leds.led1On();
  }

  void led2On() @C() @spontaneous() {
    call Leds.led2On();
  }
  */

    coap_context_t *retransmit_ctx = NULL;

  // gets called from libcoap's net.c in error cases or when sending confirmable messages -> spontaneous.
  coap_tid_t coap_send_impl(coap_context_t *context,
			    const coap_address_t *dst,
			    coap_pdu_t *pdu) @C() @spontaneous() {

    coap_tid_t id = COAP_INVALID_TID;

#ifndef COAP_SERVER_ENABLED
#ifndef COAP_CLIENT_ENABLED
#error "CoAP without server and client?"
#endif
#endif

    if ( !context || !dst || !pdu )
      return COAP_INVALID_TID;

#ifdef COAP_CLIENT_ENABLED
    if (context->tinyos_port == (uint16_t)COAP_CLIENT_PORT) {
      call UDPClient.sendto(&(dst->addr), pdu->hdr, pdu->length);
    }
#endif
#ifdef COAP_SERVER_ENABLED
    if (context->tinyos_port == (uint16_t)COAP_SERVER_PORT) {
      call UDPServer.sendto(&(dst->addr), pdu->hdr, pdu->length);
    }
#endif
    else {
    }

    coap_transaction_id(dst, pdu, &id);

    return id;
  }

  /////////////////////////////
  // Provide timing for libcoap
  inline void tinyos_clock_init_impl(void) @C() @spontaneous() {
    //TODO: Do we need to do something here? If not, remove and have
    //      it in coap_time.h
  }

  inline void tinyos_ticks_impl(coap_tick_t *t) @C() @spontaneous() {
    uint32_t time = call LocalTime.get();
    *t = time;
  }

  ///////////////////////////
  // Provide PRNG for libcoap
  inline int tinyos_prng_impl(unsigned char *buf, size_t len) @C() @spontaneous() {
    uint16_t v = call Random.rand16();

    while (len > sizeof(v)) {
	memcpy(buf, &v, sizeof(v));
	len -= sizeof(v);
	buf += sizeof(v);
    }

    memcpy(buf, &v, len);
    return 1;
  }

  //TODO: test retransmissions
  ////////////////////////////////////////////
  // Provide retransmission timing for libcoap
  inline void tinyos_retransmission_impl(coap_context_t *ctx, coap_tick_t t) @C() @spontaneous() {
      // TODO: for the moment there is just one context (the server context).
      // adapt retransmission timer handling, if there are more contexts...
      retransmit_ctx = ctx;

      call RetransmissionTimerMilli.startOneShot(((uint32_t)t)<<10); //*1024
  }

  void retransmit(coap_context_t* ctx) {
      coap_tick_t now;
      coap_queue_t *nextpdu;

      nextpdu = coap_peek_next(ctx);

      coap_ticks(&now);
      while (nextpdu && nextpdu->t <= now) {
	  coap_retransmit(ctx, coap_pop_next(ctx));
	  nextpdu = coap_peek_next(ctx);
      }

      /* need to set timer to some value even if no nextpdu is available */
      if (nextpdu) {
	  tinyos_retransmission_impl(ctx, nextpdu->t - now);
      }

      //TODO: notification
      /*
	if (etimer_expired(&the_coap_context.notify_timer)) {
	coap_check_notify(&the_coap_context);
	etimer_reset(&the_coap_context.notify_timer);
	}
	}*/
  }

  event void RetransmissionTimerMilli.fired() {
      if (retransmit_ctx != NULL) {
	  retransmit(retransmit_ctx);
      }
  }

  /////////////////////////////////////////////////
  // Provide sending/receiving interface to libcoap
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
					const coap_address_t *dst,
					coap_pdu_t *pdu) {
    return coap_send_impl(context, dst, pdu);
  }

  command error_t LibCoapServer.setupContext(uint16_t port) {
    return call UDPServer.bind(port);
  }
#endif

  /////////////////////////////////////////////////
  // Provide sending/receiving interface to libcoap
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
					const coap_address_t *dst,
					coap_pdu_t *pdu) {
    return coap_send_impl(context, dst, pdu);
  }

  command error_t LibCoapClient.setupContext(uint16_t port) {
    return call UDPClient.bind(port);
  }
#endif
}
