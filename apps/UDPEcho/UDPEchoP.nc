/*
 * "Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
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
 */

#include <IPDispatch.h>
#include <lib6lowpan.h>
#include <ip.h>
#include <lib6lowpan.h>
#include <ip.h>

#include "UDPReport.h"
#include "PrintfUART.h"

#define REPORT_PERIOD 45L

module UDPEchoP {
  uses {
    interface Boot;
    interface SplitControl as RadioControl;

    interface UDP as Echo;
    interface UDP as Status;

    interface Leds;
    
    interface Timer<TMilli> as StatusTimer;
   
    interface Statistics<ip_statistics_t> as IPStats;
    interface Statistics<route_statistics_t> as RouteStats;
    interface Statistics<icmp_statistics_t> as ICMPStats;

    interface Random;
  }

} implementation {

  bool timerStarted;
  udp_statistics_t stats;
  struct sockaddr_in6 route_dest;

#ifndef SIM
#define CHECK_NODE_ID
#else
#define CHECK_NODE_ID if (TOS_NODE_ID == BASESTATION_ID) return
#endif

  event void Boot.booted() {
    CHECK_NODE_ID;
    call RadioControl.start();
    timerStarted = FALSE;

    call IPStats.clear();
    call RouteStats.clear();
    call ICMPStats.clear();
    printfUART_init();

    stats.total = 0;
    stats.failed = 0;

#ifdef REPORT_DEST
    route_dest.sin6_port = hton16(7000);
    inet6_aton(REPORT_DEST, &route_dest.sin6_addr);
    call StatusTimer.startOneShot(call Random.rand16() % (1024 * REPORT_PERIOD));
#endif

    dbg("Boot", "booted: %i\n", TOS_NODE_ID);
    call Echo.bind(7);
    call Status.bind(7001);
  }

  event void RadioControl.startDone(error_t e) {

  }

  event void RadioControl.stopDone(error_t e) {

  }

  event void Status.recvfrom(struct sockaddr_in6 *from, void *data, 
                             uint16_t len, struct ip_metadata *meta) {

  }

  event void Echo.recvfrom(struct sockaddr_in6 *from, void *data, 
                           uint16_t len, struct ip_metadata *meta) {
    CHECK_NODE_ID;
    call Echo.sendto(from, data, len);
  }

  enum {
    STATUS_SIZE = // sizeof(ip_statistics_t) + 
    sizeof(route_statistics_t) +
    sizeof(icmp_statistics_t) + sizeof(udp_statistics_t),
  };


  event void StatusTimer.fired() {
    uint8_t status[STATUS_SIZE];
    nx_struct udp_report *payload;
    CHECK_NODE_ID;

    stats.total++;
    
    if (!timerStarted) {
      call StatusTimer.startPeriodic(1024 * REPORT_PERIOD);
      timerStarted = TRUE;
    }

    payload = (nx_struct udp_report *)status;
    
    stats.seqno++;
    stats.sender = TOS_NODE_ID;

    // memcpy(&payload->ip,    call IPStats.get(),    sizeof(ip_statistics_t));
    call RouteStats.get(&payload->route);
    call ICMPStats.get(&payload->icmp);
    memcpy(&payload->udp,   &stats,                sizeof(udp_statistics_t));

    call Status.sendto(&route_dest, status, STATUS_SIZE);
  }
}
