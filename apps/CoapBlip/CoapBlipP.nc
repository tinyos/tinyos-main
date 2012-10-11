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
#include "blip_printf.h"

#include "net.h"
#include "resource.h"

#ifdef COAP_CLIENT_ENABLED
#include "tinyos_net.h"
#include "option.h"
#include "address.h"
#endif

#ifndef COAP_SERVER_PORT
#define COAP_SERVER_PORT COAP_DEFAULT_PORT
#endif

module CoapBlipP {
  uses {
    interface Boot;
    interface SplitControl as RadioControl;
    interface Leds;

#ifdef COAP_SERVER_ENABLED
    interface CoAPServer;
#ifdef COAP_RESOURCE_KEY
    interface Mount;
#endif
#endif

#ifdef COAP_CLIENT_ENABLED
    interface CoAPClient;
    interface ForwardingTableEvents;
#endif
  }

} implementation {
#ifdef COAP_CLIENT_ENABLED
  uint8_t node_integrate_done = FALSE;
#endif

  event void Boot.booted() {

    call RadioControl.start();
    printf("booted %i start\n", TOS_NODE_ID);
#ifdef COAP_SERVER_ENABLED
#ifdef COAP_RESOURCE_KEY
    if (call Mount.mount() == SUCCESS) {
      printf("CoapBlipP.Mount successful\n");
    }
#endif

    // needs to be before registerResource to setup context:
    call CoAPServer.setupContext(COAP_SERVER_PORT);
    call CoAPServer.registerResources();

#endif

#ifdef COAP_CLIENT_ENABLED
    // needs to be before registerResource to setup context:
    call CoAPClient.setupContext(COAP_CLIENT_PORT);
#endif

  }

#if defined (COAP_SERVER_ENABLED) && defined (COAP_RESOURCE_KEY)
  event void Mount.mountDone(error_t error) {
  }
#endif

  event void RadioControl.startDone(error_t e) {
    printf("radio startDone: %i\n", TOS_NODE_ID);
  }

  event void RadioControl.stopDone(error_t e) {
  }

#ifdef COAP_CLIENT_ENABLED
  event void ForwardingTableEvents.defaultRouteAdded() {
      //struct sockaddr_in6 sa6;
      coap_address_t dest;
      coap_list_t *optlist = NULL;

      if (node_integrate_done == FALSE) {
	  node_integrate_done = TRUE;

	  inet_pton6(COAP_CLIENT_DEST, &dest.addr.sin6_addr);
	  dest.addr.sin6_port = htons(COAP_CLIENT_PORT);

	  coap_insert( &optlist, new_option_node(COAP_OPTION_URI_PATH, sizeof("ni") - 1, "ni"), order_opts);

	  // this stuff should most likely be POST!
	  call CoAPClient.request(&dest, COAP_REQUEST_PUT, optlist, 0, NULL);
      }
  }

  event void ForwardingTableEvents.defaultRouteRemoved() {
  }

  event error_t CoAPClient.streamed_next_block (uint16_t blockno, uint16_t *len, void **data)
  {
    return FAIL;
  }

  event void CoAPClient.request_done(uint8_t code, uint16_t len, void *data) {
      //event void CoAPClient.request_done(uint8_t code, uint8_t mediatype, uint16_t len, void *data, bool more) {
    //TODO: handle the request_done
  };
#endif

  }
