
#include <stdio.h>
#include <lib6lowpan/ip.h>
#include <lib6lowpan/nwbyte.h>
#include <lib6lowpan/ip_malloc.h>
#include <dhcp6.h>
#include "RPL.h"

#include "blip_printf.h"

module PppRouterP {
  provides { 
    interface IPForward;
  }
  uses {
    interface Boot;
    interface MultiLed;
    interface SplitControl as IPControl;
    interface SplitControl as Ppp;
    interface LcpAutomaton as Ipv6LcpAutomaton;
    interface PppIpv6;

    interface ForwardingTable;
    interface RootControl;
    interface Dhcp6Info;
    interface IPPacket;
  }
  
} implementation {

  event void PppIpv6.linkUp() {}
  event void PppIpv6.linkDown() {}

  event void Ipv6LcpAutomaton.transitionCompleted (LcpAutomatonState_e state) { }
  event void Ipv6LcpAutomaton.thisLayerUp () { }
  event void Ipv6LcpAutomaton.thisLayerDown () { }
  event void Ipv6LcpAutomaton.thisLayerStarted () { }
  event void Ipv6LcpAutomaton.thisLayerFinished () { }

  event void Ppp.startDone (error_t error) {  }
  event void Ppp.stopDone (error_t error) { }

  event void IPControl.startDone (error_t error) {
    struct in6_addr dhcp6_group;

    // add a route to the dhcp group on PPP, not the radio (which is the default)
    inet_pton6(DH6ADDR_ALLAGENT, &dhcp6_group);
    call ForwardingTable.addRoute(dhcp6_group.s6_addr, 128, NULL, ROUTE_IFACE_PPP);

    // add a default route through the PPP link
    call ForwardingTable.addRoute(NULL, 0, NULL, ROUTE_IFACE_PPP);
  }
  event void IPControl.stopDone (error_t error) { }

  event void Boot.booted() {
    error_t rc;

#ifndef PRINTFUART_ENABLED
    rc = call Ipv6LcpAutomaton.open();
    rc = call Ppp.start();
#endif
#ifdef RPL_ROUTING
    call RootControl.setRoot();
#endif
#ifndef IN6_PREFIX
    call Dhcp6Info.useUnicast(FALSE);
#endif

    call IPControl.start();
  }

  event error_t PppIpv6.receive(const uint8_t* data,
                                unsigned int len) {
    struct ip6_hdr *iph = (struct ip6_hdr *)data;
    void *payload = (iph + 1);
    call MultiLed.toggle(0);
    signal IPForward.recv(iph, payload, NULL);
    return SUCCESS;
  }

  command error_t IPForward.send(struct in6_addr *next_hop,
                                 struct ip6_packet *msg,
                                 void *data) {
    unsigned char *buf;
    size_t len = iov_len(msg->ip6_data);
    error_t rv;
    int off;
    uint8_t nxt = IPV6_HOP;

    if (!call PppIpv6.linkIsUp()) 
      return EOFF;

    buf = ip_malloc(len + sizeof(struct ip6_hdr));
    if (!buf)
      return ENOMEM;

    /* remove any RPL options in the hop-by-hop header by converting
       them to a PadN option */
    off = call IPPacket.findHeader(msg->ip6_data, msg->ip6_hdr.ip6_nxt, &nxt);
    if (off < 0) goto done;
    call IPPacket.delTLV(msg->ip6_data, off, RPL_HBH_RANK_TYPE);

  done:
    memcpy(buf, &msg->ip6_hdr, sizeof(struct ip6_hdr));
    iov_read(msg->ip6_data, 0, len, buf + sizeof(struct ip6_hdr));
    call MultiLed.toggle(1);
    rv = call PppIpv6.transmit(buf, len + sizeof(struct ip6_hdr));
    ip_free(buf);

    return rv;
  }
}
