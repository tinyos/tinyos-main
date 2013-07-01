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

#include <stdio.h>
#include <lib6lowpan/ip.h>
#include <lib6lowpan/nwbyte.h>
#include <lib6lowpan/ip_malloc.h>
//#include <dhcp6.h>

#include "pppipv6.h"
//#include "blip_printf.h"

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

module CoapPppP {
  provides {
    interface IPForward;
  }
  uses {
    interface Boot;
    interface Leds;
    interface SplitControl as IPControl;
    interface SplitControl as PppControl;
    interface LcpAutomaton as Ipv6LcpAutomaton;
    interface PppIpv6;
    interface Ppp;

    interface ForwardingTable;
    //interface RootControl;
    interface Dhcp6Info;
    interface IPPacket;

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

  task void inform(){
    //printf("PPP IP link up\n");
  }


  event void PppIpv6.linkUp() {
    //call Leds.led0On();
    //call Leds.led1On();
    //call Leds.led2On();
    post inform();
  }
  event void PppIpv6.linkDown() {}

  event void Ipv6LcpAutomaton.transitionCompleted (LcpAutomatonState_e state) { }
  event void Ipv6LcpAutomaton.thisLayerUp () { }
  event void Ipv6LcpAutomaton.thisLayerDown () { }
  event void Ipv6LcpAutomaton.thisLayerStarted () { }
  event void Ipv6LcpAutomaton.thisLayerFinished () { }

  event void PppControl.startDone (error_t error) {
  }

  event void PppControl.stopDone (error_t error) { }

  event void IPControl.startDone (error_t error) {
    //struct in6_addr dhcp6_group;

    // add a route to the dhcp group on PPP, not the radio (which is the default)
    //inet_pton6(DH6ADDR_ALLAGENT, &dhcp6_group);
    //call ForwardingTable.addRoute(dhcp6_group.s6_addr, 128, NULL, ROUTE_IFACE_PPP);

    // add a default route through the PPP link
    // TODO: remove this? replace with fec0::100?
    route_key_t route =
	call ForwardingTable.addRoute(NULL, 0, NULL, ROUTE_IFACE_PPP);
    if (route == ROUTE_INVAL_KEY) {
    } else {
    }
  }
  event void IPControl.stopDone (error_t error) { }

  event void Boot.booted() {
    error_t rc;

    rc = call Ipv6LcpAutomaton.open();
    rc = call PppControl.start();

#ifndef IN6_PREFIX
    call Dhcp6Info.useUnicast(FALSE);
#endif

    call IPControl.start();

#ifdef COAP_SERVER_ENABLED
#ifdef COAP_RESOURCE_KEY
    if (call Mount.mount() == SUCCESS) {
	//printf("CoapBlipP.Mount successful\n");
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

  event error_t PppIpv6.receive(const uint8_t* data,
                                unsigned int len) {
    struct ip6_hdr *iph = (struct ip6_hdr *)data;
    void *payload = (iph + 1);
    //printf("IP recv\n");
    signal IPForward.recv(iph, payload, NULL);
    return SUCCESS;
  }

  command error_t IPForward.send(struct in6_addr *next_hop,
                                 struct ip6_packet *msg,
                                 void *data) {
    size_t len = iov_len(msg->ip6_data) + sizeof(struct ip6_hdr);
    error_t rc;
    frame_key_t key;
    const uint8_t* fpe;
    uint8_t* fp;

    if (!call PppIpv6.linkIsUp())
      return EOFF;

    // get an output frame
    fp = call Ppp.getOutputFrame(PppProtocol_Ipv6, &fpe, FALSE, &key);
    if ((! fp) || ((fpe - fp) < len)) {
      if (fp) {
	call Ppp.releaseOutputFrame(key);
      }
      return ENOMEM;
    }

    // copy the header and body into the frame
    memcpy(fp, &msg->ip6_hdr, sizeof(struct ip6_hdr));
    iov_read(msg->ip6_data, 0, len, fp + sizeof(struct ip6_hdr));
    rc = call Ppp.fixOutputFrameLength(key, fp + len);
    if (SUCCESS == rc) {
      rc = call Ppp.sendOutputFrame(key);
    }

    return rc;
  }

  event void Ppp.outputFrameTransmitted (frame_key_t key,
                                         error_t err) { }

#if defined (COAP_SERVER_ENABLED) && defined (COAP_RESOURCE_KEY)
  event void Mount.mountDone(error_t error) {
  }
#endif

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
