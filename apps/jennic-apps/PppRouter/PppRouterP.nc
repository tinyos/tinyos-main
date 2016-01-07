
#include <stdio.h>
#include <lib6lowpan/ip.h>
#include <lib6lowpan/nwbyte.h>
#include <lib6lowpan/ip_malloc.h>
#include <dhcp6.h>


#include "pppipv6.h"
#include "blip_printf.h"

module PppRouterP {
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

  event void PppControl.startDone (error_t error) {  }
  event void PppControl.stopDone (error_t error) { }

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
    rc = call PppControl.start();
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
    call Leds.led0Toggle();
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
      call Leds.led2Toggle();
      return ENOMEM;
    }

    // copy the header and body into the frame
    memcpy(fp, &msg->ip6_hdr, sizeof(struct ip6_hdr));
    iov_read(msg->ip6_data, 0, len, fp + sizeof(struct ip6_hdr));
    rc = call Ppp.fixOutputFrameLength(key, fp + len);
    if (SUCCESS == rc) {
      rc = call Ppp.sendOutputFrame(key);
    }

    call Leds.led1Toggle();

    return rc;
  }

  event void Ppp.outputFrameTransmitted (frame_key_t key,
                                         error_t err) { }

}
