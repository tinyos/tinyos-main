#include <stdio.h>
module TestP {
  uses {
    interface Boot;
    interface Led as LinkUpLed;
    interface Led as LinkDownLed;
    interface Led as PacketRxLed;
    interface SplitControl as Ppp;
    interface LcpAutomaton as Ipv6LcpAutomaton;
    interface PppIpv6;
  }
  
} implementation {

  event void Ipv6LcpAutomaton.transitionCompleted (LcpAutomatonState_e state) { }
  event void Ipv6LcpAutomaton.thisLayerUp () { }
  event void Ipv6LcpAutomaton.thisLayerDown () { }
  event void Ipv6LcpAutomaton.thisLayerStarted () { }
  event void Ipv6LcpAutomaton.thisLayerFinished () { }

  event void Ppp.startDone (error_t error) { }
  event void Ppp.stopDone (error_t error) { }

  event void PppIpv6.linkUp ()
  {
    call LinkDownLed.off();
    call LinkUpLed.on();
  }

  event void PppIpv6.linkDown ()
  {
    call LinkUpLed.off();
    call LinkDownLed.on();
  }

  event error_t PppIpv6.receive (const uint8_t* message,
                                 unsigned int len)
  {
    call PacketRxLed.toggle();
    printf("RX %u octets\n", len);
    return SUCCESS;
  }

  event void Boot.booted() {
    error_t rc;

    call LinkDownLed.on();
    rc = call Ipv6LcpAutomaton.open();
    rc = call Ppp.start();
  }
}
