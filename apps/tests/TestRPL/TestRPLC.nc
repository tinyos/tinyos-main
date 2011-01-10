// $Id: RadioCountToLedsC.nc,v 1.6 2008/06/24 05:32:31 regehr Exp $

/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
 
#include "Timer.h"
#include "TestRPL.h"
//#include "ip.h"
#include <PrintfUART.h>
/**
 * Implementation of the RadioCountToLeds application. RadioCountToLeds 
 * maintains a 4Hz counter, broadcasting its value in an AM packet 
 * every time it gets updated. A RadioCountToLeds node that hears a counter 
 * displays the bottom three bits on its LEDs. This application is a useful 
 * test to show that basic AM communication and timers work.
 *
 * @author Philip Levis
 * @date   June 6 2005
 */

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
    //interface RPLForwardingEngine;
    interface RPLDAORoutingEngine as RPLDAO;
    interface Random;
  }
}
implementation {

  //uint8_t payload[10];
  struct in6_addr dest;
  struct in6_addr MULTICAST_ADDR;

  bool locked;
  uint16_t counter = 0;
  
  event void Boot.booted() {

    memset(MULTICAST_ADDR.s6_addr, 0, 16);
    MULTICAST_ADDR.s6_addr[0] = 0xFF;
    MULTICAST_ADDR.s6_addr[1] = 0x2;
    MULTICAST_ADDR.s6_addr[15] = 0x1A;

    if(TOS_NODE_ID == 1){
      call RootControl.setRoot();
    }
    call RoutingControl.start();
    //call RoutingControl.start();
    call SplitControl.start();
  }

  uint32_t countrx = 0;
  uint32_t counttx = 0;

  event void RPL.recv(struct ip6_hdr *hdr, void *packet, 
		      size_t len, struct ip6_metadata *meta){
    uint8_t i;
    uint8_t temp[20];
    memcpy(temp, (uint8_t*)packet, len);
    call Leds.led2Toggle();
    printfUART("<><><><><><><> len: %d %lu <><><><><><> \n", len, countrx++);
    for(i=0; i<len; i++){
      printfUART("%d ",temp[i]);
    }
    printfUART("\n");
  }
  
  event void SplitControl.startDone(error_t err){
    //call RoutingControl.start();
    while( call RPLDAO.startDAO() != SUCCESS );
    
    call Timer.startOneShot((call Random.rand16()%2)*1024U);
  }

  event void Timer.fired(){
    call MilliTimer.startPeriodic(256);
  }

  task void sendTask(){
    struct ip6_packet pkt;
    struct ip_iovec v;
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
    pkt.ip6_hdr.ip6_nxt = 49; // NOTHING!!
    pkt.ip6_hdr.ip6_plen = htons(20);

    memcpy(&pkt.ip6_hdr.ip6_dst, call RPLRoute.getDodagId(), sizeof(struct in6_addr));

    if(TOS_NODE_ID == 1){
      //pkt.ip6_hdr.ip6_dst.s6_addr[12] = 0x50;
      //pkt.ip6_hdr.ip6_dst.s6_addr[13] = 0xed;
      //pkt.ip6_hdr.ip6_dst.s6_addr[14] = 0x2f;
      pkt.ip6_hdr.ip6_dst.s6_addr[15] = 0x03;
    }

    //pkt.ip6_hdr.ip6_dst.s6_addr[15] = 0x04;
    printfUART(">>>>>>>>>>>> TX %lu \n", counttx++);

    printfUART("\nsend to ");
    for(i=0;i<16;i++){
      printfUART("%x ", pkt.ip6_hdr.ip6_dst.s6_addr[i]);
    }
    printfUART("\n");

    //fe80::12:6d45:50ed:2f04

    //pkt.ip6_hdr.ip6_dst.s6_addr16[7] = htons(0xAF);
    //memcpy(&pkt.ip6_hdr.ip6_dst, &MULTICAST_ADDR, sizeof(struct in6_addr));
    call Leds.led0Toggle();
    call RPL.send(&pkt);
  }

  event void MilliTimer.fired(){
    //call Leds.led1Toggle();
    post sendTask();
  }

  event void SplitControl.stopDone(error_t err){}

}
