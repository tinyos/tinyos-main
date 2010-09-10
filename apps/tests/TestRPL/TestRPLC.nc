#include "Timer.h"
#include "TestRPL.h"
#include "ip.h"
#include <PrintfUART.h>

module TestRPLC @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Timer<TMilli> as MilliTimer;
    interface Timer<TMilli> as Timer;
    interface RPLRoutingEngine as RPLRoute;
    interface RootControl;
    interface StdControl as RoutingControl;
    interface SplitControl;
    interface IP as RPL;
    interface RPLForwardingEngine;
    interface RPLDAORoutingEngine as RPLDAO;
    interface Random;
  }
}
implementation {

  struct in6_addr dest;

  bool locked;
  uint16_t counter = 0;
  
  event void Boot.booted() {
    if(TOS_NODE_ID == 1){
      call RootControl.setRoot();
    }
    call RoutingControl.start();
    call SplitControl.start();
  }

  event void RPL.recv(void *iph, void *payload, size_t len, struct ip6_metadata *meta){
    //call Leds.led1Toggle();
    uint8_t temp[20];
    memcpy(temp, payload, len);
  }
  
  event void SplitControl.startDone(error_t err){
    call RPLDAO.startDAO();
    if(TOS_NODE_ID != 1)
      call Timer.startOneShot((call Random.rand16()%10)*1024U);
  }

  event void Timer.fired(){
    call MilliTimer.startPeriodic(3*1024U);
  }

  task void sendTask(){
    struct ip6_packet pkt;
    struct ip_iovec v;
    uint16_t destination = 2;
    uint16_t temp[10];
    uint8_t i;

    for(i=0;i<10;i++){
      temp[i] = i;
    }

    v.iov_base = (uint8_t*) &temp;
    v.iov_len = 20;
    v.iov_next = NULL;

    pkt.ip6_data = &v;
    pkt.ip6_hdr.ip6_vfc = IPV6_VERSION;
    pkt.ip6_hdr.ip6_nxt = 49; // NOTHING!! Just Test
    pkt.ip6_hdr.ip6_plen = htons(20);

    memcpy(&pkt.ip6_hdr.ip6_dst, call RPLForwardingEngine.getDefaultDodagId(), sizeof(struct in6_addr));

    if(TOS_NODE_ID != destination){
      pkt.ip6_hdr.ip6_dst.s6_addr16[7] = htons(destination);
      call RPL.send(&pkt);
    }else{
      pkt.ip6_hdr.ip6_dst.s6_addr16[7] = htons(1);
      call RPL.send(&pkt);
    }
  }

  event void MilliTimer.fired(){
    post sendTask();
  }

  event void SplitControl.stopDone(error_t err){}

}
