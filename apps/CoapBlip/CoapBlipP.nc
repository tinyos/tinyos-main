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

#include <IPDispatch.h>
#include <lib6lowpan/lib6lowpan.h>
#include <lib6lowpan/ip.h>
#ifdef COAP_CLIENT_ENABLED
#include "tinyos_net.h"
#endif

#ifdef PRINTFUART_ENABLED
#include "PrintfUART.h"
#undef dbg
#define dbg(X, fmt, args ...) printfUART(fmt, ## args)
#endif

module CoapBlipP {
  uses {
    interface Boot;
    interface SplitControl as RadioControl;
#ifdef COAP_SERVER_ENABLED
    interface CoAPServer;
#ifdef COAP_RESOURCE_KEY
    interface Mount;
#endif
#endif
#ifdef COAP_CLIENT_ENABLED
    interface CoAPClient;
#endif
    interface Leds;
    interface IPConnectivity;
  }
  provides interface Init;
} implementation {
#ifdef COAP_CLIENT_ENABLED
  uint8_t node_integrate_done = FALSE;
#endif

  command error_t Init.init() {
#ifdef PRINTFUART_ENABLED
    printfUART_init();
#endif
    return SUCCESS;
  }

  event void Boot.booted() {
    uint8_t i;
    call RadioControl.start();
#ifdef PRINTFUART_ENABLED
    dbg("Boot", "booted %i start\n", TOS_NODE_ID);
#endif
#ifdef COAP_SERVER_ENABLED
#ifdef COAP_RESOURCE_KEY
    if (call Mount.mount() == SUCCESS) {

#ifdef PRINTFUART_ENABLED
      dbg("Boot", "CoapBlipP.Mount successful\n");
#endif
    }
#endif
    // needs to be before registerResource to setup context:
    call CoAPServer.bind(COAP_SERVER_PORT);

    for (i=0; i < NUM_URIS+1; i++) {
      call CoAPServer.registerResource(uri_key_map[i].uri,
				       uri_key_map[i].urilen - 1,
				       uri_key_map[i].mediatype,
				       uri_key_map[i].writable,
				       uri_key_map[i].splitphase,
				       uri_key_map[i].immediately);
    }
#endif

  }

#if defined (COAP_SERVER_ENABLED) && defined (COAP_RESOURCE_KEY)
  event void Mount.mountDone(error_t error) {
  }
#endif

  event void RadioControl.startDone(error_t e) {
#ifdef PRINTFUART_ENABLED
    dbg("Boot", "radio startDone: %i\n", TOS_NODE_ID);
#endif
  }

  event void RadioControl.stopDone(error_t e) {
  }

  event void IPConnectivity.prefixAvailable() {
#ifdef COAP_CLIENT_ENABLED
    struct sockaddr_in6 sa6;
    coap_list_t *optlist = NULL;
    uint8_t i;
    uint16_t dest[8] = COAP_CLIENT_DEST;
    for (i = 0; i < 8; i++) {
      dest[i] = htons(dest[i]);
    }

    if (node_integrate_done == FALSE) {
      node_integrate_done = TRUE;

      memset(&sa6, 0, sizeof(struct sockaddr_in6));
      memcpy(sa6.sin6_addr.s6_addr16, dest, 8*sizeof(uint16_t));
      sa6.sin6_port = htons(COAP_CLIENT_PORT);

      coap_insert( &optlist, new_option_node(COAP_OPTION_URI_PATH,
					     sizeof("ni") - 1, "ni"),
                                             order_opts);

      call CoAPClient.request(&sa6, COAP_REQUEST_GET, optlist);
    }
#endif
  }

#ifdef COAP_CLIENT_ENABLED
  event void CoAPClient.request_done() {
    //TODO: handle the request_done
  };
#endif

  }
