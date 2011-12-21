/*
 * Copyright (c) 2010 Johns Hopkins University. All rights reserved.
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
 * - Neither the name of the copyright holder nor the names of
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

/**
 * RPLRoutingEngineP.nc
 * @ author JeongGil Ko (John) <jgko@cs.jhu.edu>
 */

#include <lib6lowpan/ip_malloc.h>
#include <lib6lowpan/in_cksum.h>
#include <lib6lowpan/ip.h>

#include "blip_printf.h"
#include "RPL.h"

generic module RPLRoutingEngineP() {
  provides {
    interface RootControl;
    interface StdControl;
    interface RPLRoutingEngine as RPLRouteInfo;
  }
  uses {
    interface IP as IP_DIO;     /* filtered DIO messages from the rank engine */
    interface IP as IP_DIS;     /* DIS messages from the ICMP driver */

    interface Timer<TMilli> as TrickleTimer;
    interface Timer<TMilli> as InitDISTimer;
    interface Timer<TMilli> as IncreaseVersionTimer;
    interface Random;
    interface RPLRank as RPLRankInfo;
    interface IPAddress;
    interface Leds;
    interface StdControl as RankControl;
    interface RPLDAORoutingEngine;
  }
}

implementation{

#define RPL_GLOBALADDR

  /* Declare Global Variables */
  uint32_t tricklePeriod;
  uint32_t randomTime;
  bool sentDIOFlag = FALSE;
  bool I_AM_ROOT = FALSE;
  bool I_AM_LEAF = FALSE;
  bool running = FALSE;
  bool hasDODAG = FALSE;
  bool riskHigh = FALSE;
  uint16_t node_rank = INFINITE_RANK;
  uint16_t LOWRANK = INFINITE_RANK;
  uint8_t GROUND_STATE = 1;

  uint8_t RPLInstanceID = 0;
  struct in6_addr DODAGID;
  uint8_t DODAGVersionNumber = 0;
  uint8_t MOP = RPL_MOP_Storing_No_Multicast;
  uint8_t DAG_PREF = 7;

  uint8_t redunCounter = 0xFF;
  uint8_t doubleCounter = 0;

  uint8_t DIOIntDouble = 10;
  uint8_t DIOIntMin = 8;
  uint8_t DIORedun = 0xFF;
  uint16_t MinHopRankInc = 1;
  uint16_t MaxRankInc = 3;

  uint8_t DTSN = 2;

  uint32_t countdio = 0;
  uint32_t countdis = 0;

  bool UNICAST_DIO = FALSE;

  struct in6_addr DEF_PREFIX;

  struct in6_addr ADDR_MY_IP;
  struct in6_addr ROOT_ADDR;
  struct in6_addr MULTICAST_ADDR;
  struct in6_addr UNICAST_DIO_ADDR;

  /* Define Functions and Tasks */
  void resetTrickleTime();
  void chooseAdvertiseTime();
  void computeTrickleRemaining();	
  void nextTrickleTime();
  void inconsistencyDetected();
  void poison();
  task void sendDIOTask();
  task void sendDISTask();
  task void init();
  task void initDIO();

  /* Start the routing with DIS message probing */
  task void init() {
#ifdef RPL_STORING_MODE
    MOP = RPL_MOP_Storing_No_Multicast;
#else
    MOP = RPL_MOP_No_Storing;
#endif

#ifdef RPL_GLOBALADDR
    call IPAddress.getGlobalAddr(&ADDR_MY_IP);
#else
    call IPAddress.getLLAddr(&ADDR_MY_IP);
#endif

    ROOT_RANK = MinHopRankInc;

    /* SDH : FF02::2 -- link-local all-routers group? */
    memset(MULTICAST_ADDR.s6_addr, 0, 16);
    MULTICAST_ADDR.s6_addr[0] = 0xFF;
    MULTICAST_ADDR.s6_addr[1] = 0x2;
    MULTICAST_ADDR.s6_addr[15] = 0x1A;

    if (I_AM_ROOT) {
#ifdef RPL_GLOBALADDR
      call IPAddress.getGlobalAddr(&DODAGID);
#else
      call IPAddress.getLLAddr(&DODAGID);
#endif
      /* Global recovery every 60 mins */ 
      //call IncreaseVersionTimer.startPeriodic(60*60*1024UL);
      post initDIO();
    } else {
      call InitDISTimer.startPeriodic(DIS_INTERVAL);
    }
  }

  /* When finding a DODAG post initDIO()*/
  task void initDIO() {
    if (I_AM_ROOT) {
      call RPLRouteInfo.resetTrickle();
    }
   }

  task void computeRemaining() {
    computeTrickleRemaining();
  }

  task void sendDIOTask() {
    struct ip6_packet pkt;
    struct ip_iovec   v[1];
    uint8_t data[60];
    struct dio_base_t msg;
    struct dio_body_t body;
    struct dio_metric_header_t metric_header;
    struct dio_etx_t etx_value;
    struct dio_dodag_config_t dodag_config;
    uint16_t length;

/*     struct in6_addr next_hop; */

/*     if ((call RPLRankInfo.nextHop(&DEF_PREFIX, &next_hop)) != SUCCESS) */
/*       return; */

    if ((!running)  || (!hasDODAG) /* || ((redunCounter < DIORedun) && (DIORedun != 0xFF))*/ ) {
      // printf("RPL: NoTxDIO %d %d %d\n", redunCounter, DIORedun, hasDODAG);
      return; 
    }

    //call RPLDAORoutingEngine.startDAO();
    // call IPAddress.setSource(&pkt.ip6_hdr);

    msg.icmpv6.type = ICMP_TYPE_RPL_CONTROL;
    msg.icmpv6.code = ICMPV6_CODE_DIO;
    msg.icmpv6.checksum = 0;
    msg.flags = 0;
    msg.flags = GROUND_STATE << 7;
    msg.flags |= MOP << DIO_MOP_SHIFT;
    msg.flags |= DAG_PREF << 0;
    msg.version = DODAGVersionNumber;
    msg.instance_id.id = RPLInstanceID;
    msg.dtsn = DTSN;
    memcpy(&msg.dodagID, &DODAGID, sizeof(struct in6_addr));
    
    if (I_AM_ROOT) {
#ifdef RPL_GLOBALADDR
      call IPAddress.getGlobalAddr(&DODAGID);
#else
      call IPAddress.getLLAddr(&DODAGID);
#endif
      msg.dagRank = ROOT_RANK;
    } else {
      msg.dagRank = call RPLRankInfo.getRank(&ADDR_MY_IP);
    }
    
    if (!I_AM_LEAF) {
      dodag_config.type = RPL_DODAG_CONFIG_TYPE;
      dodag_config.length = 14;
      dodag_config.flags = 0;
      dodag_config.A = 0; // no auth
      dodag_config.PCS = 0;
#ifdef RPL_OF_MRHOF
      dodag_config.ocp = 1; //MRHOF
#else
      dodag_config.ocp = 0; //OF0
#endif
      dodag_config.default_lifetime = 0xFF;//6;  // six
      dodag_config.lifetime_unit = 0xFFFF;//3600; // hours
      dodag_config.DIOIntDoubl = DIOIntDouble;
      dodag_config.DIOIntMin = DIOIntMin;
      dodag_config.DIORedun = DIORedun;
      dodag_config.MaxRankInc = MaxRankInc;
      dodag_config.MinHopRankInc = MinHopRankInc;
      dodag_config.reserved = 0;

      // For now just go with etx as the only metric
      etx_value.etx = call RPLRankInfo.getEtx();

      metric_header.routing_obj_type = RPL_ROUTE_METRIC_ETX; // for etx
      metric_header.reserved = 0;
      metric_header.R_flag = 0;
      metric_header.G_flag = 1;
      metric_header.A_flag = 0; // aggregate additive!
      metric_header.O_flag = 0;
      metric_header.C_flag = 0;
      metric_header.object_len = 2;

      body.type = RPL_DODAG_METRIC_CONTAINER_TYPE; // metric container
      body.container_len = 6;

      { 
        uint8_t *cur = (uint8_t *)&data;
#define ADD_SECTION(SRC, LEN) ip_memcpy(cur, (uint8_t *)(SRC), LEN);\
 cur += (LEN);
#ifdef RPL_OF_MRHOF
        length = sizeof(struct dio_base_t) + sizeof(struct dio_body_t) + 
          sizeof(struct dio_metric_header_t) + sizeof(struct dio_etx_t) + 
          sizeof(struct dio_dodag_config_t);
        ADD_SECTION(&msg, sizeof(struct dio_base_t));
        ADD_SECTION(&body, sizeof(struct dio_body_t));
        ADD_SECTION(&metric_header, sizeof(struct dio_metric_header_t));
        ADD_SECTION(&etx_value, sizeof(struct dio_etx_t));
        ADD_SECTION(&dodag_config, sizeof(struct dio_dodag_config_t));
#else
        length = sizeof(struct dio_base_t) + sizeof(struct dio_dodag_config_t); 
        ADD_SECTION(&msg, sizeof(struct dio_base_t));
        ADD_SECTION(&dodag_config, sizeof(struct dio_dodag_config_t));
#endif
#undef ADD_SECTION
      }

      // TODO: add prefix info (optional)
      v[0].iov_base = (uint8_t*)&data;
      v[0].iov_len = length;
      v[0].iov_next = NULL;

      pkt.ip6_hdr.ip6_nxt = IANA_ICMP;
      pkt.ip6_hdr.ip6_plen = htons(length);

      pkt.ip6_data = &v[0];		

      //iov_print(&v[0]);

    } else {
      length = sizeof(struct dio_base_t);
      pkt.ip6_hdr.ip6_nxt = IANA_ICMP;
      pkt.ip6_hdr.ip6_plen = htons(length);

      v[0].iov_base = (uint8_t *)&msg;
      v[0].iov_len  = sizeof(struct dio_base_t);
      v[0].iov_next = NULL;

      pkt.ip6_data = &v[0];		
    }
    
    // printf("RPL: \n >>>>>> TxDIO etx %d %d %d %lu \n", 
    //         call RPLRankInfo.getEtx(), 
    //         ntohs(DODAGID.s6_addr16[7]), msg.dagRank, tricklePeriod);
    printf("RPL: TXDIO %d %lu \n", TOS_NODE_ID, ++countdio);
    // printf("RPL: RANK %d %d %d\n", 
    //        call RPLRankInfo.getRank(&ADDR_MY_IP),
    //        call RPLRankInfo.getEtx(), 
    //        call RPLRankInfo.hasParent());

    if (UNICAST_DIO) {
      UNICAST_DIO = FALSE;
      memcpy(&pkt.ip6_hdr.ip6_dst, &UNICAST_DIO_ADDR, 16);
    } else {
      memcpy(&pkt.ip6_hdr.ip6_dst, &MULTICAST_ADDR, 16);
    }

    call IPAddress.getLLAddr(&pkt.ip6_hdr.ip6_src);

    // call IPAddress.getGlobalAddr(&pkt.ip6_hdr.ip6_src);
    // memcpy(&pkt.ip6_hdr.ip6_src, &ADDR_MY_IP, 16);

    call IP_DIO.send(&pkt);
  }

  task void sendDISTask() {
    struct ip6_packet pkt;
    struct ip_iovec v[1];
    struct dis_base_t msg;
    uint16_t length;

    if (!running) 
      return;
    
    length = sizeof(struct dis_base_t);
    msg.icmpv6.type = ICMP_TYPE_RPL_CONTROL;
    msg.icmpv6.code = ICMPV6_CODE_DIS;
    msg.icmpv6.checksum = 0;

    // pkt.ip6_hdr.ip6_vfc = IPV6_VERSION;
    pkt.ip6_hdr.ip6_nxt = IANA_ICMP;
    pkt.ip6_hdr.ip6_plen = htons(length);

    v[0].iov_base = (uint8_t *)&msg;
    v[0].iov_len  = sizeof(struct dis_base_t);
    v[0].iov_next = NULL;
    pkt.ip6_data = &v[0];		

    memcpy(&pkt.ip6_hdr.ip6_dst, &MULTICAST_ADDR, 16);
    call IPAddress.getLLAddr(&pkt.ip6_hdr.ip6_src);
    //call IPAddress.getGlobalAddr(&pkt.ip6_hdr.ip6_src);

    // printf("RPL: \n >>>>>> TxDIS\n");
    // printf("RPL: >> sendDIS %d %lu \n", TOS_NODE_ID, ++countdis);

    call IP_DIS.send(&pkt);
  }

  uint16_t INCONSISTENCY_COUNT = 0;

  void inconsistencyDetected() {
    // when inconsistency detected, reset trickle
    INCONSISTENCY_COUNT ++;

    // inconsistency on my on node detected?
    call RPLRankInfo.inconsistencyDetected(/*&ADDR_MY_IP*/); 

    /* JK: This reaction is TinyRPL specific -- to reduce the amount
       of DIO traffic -- helps when minmal leaf nodes exist */
    call RPLRouteInfo.resetTrickle();
    /* JK: Below is the Spec way of reacting to inconsistencies */
    /*
    if (call RPLRankInfo.hasParent())
      call RPLRouteInfo.resetTrickle();
    else{
      call TrickleTimer.stop();
      call InitDISTimer.startPeriodic(1024);
    }
    */
  }

  void poison() {
    node_rank = INFINITE_RANK;
    call RPLRouteInfo.resetTrickle();
  }

  void resetTrickleTime() {
    call TrickleTimer.stop();
    tricklePeriod = 2 << (DIOIntMin-1);
    redunCounter = 0;
    doubleCounter = 0;
  }

  void chooseAdvertiseTime() {
    if (!running) {
      return;
    }
    call TrickleTimer.stop();
    randomTime = tricklePeriod;
    randomTime /= 2;
    randomTime += call Random.rand32() % randomTime;
    call TrickleTimer.startOneShot(randomTime);
  }

  void computeTrickleRemaining() {
    // start timer for the remainder time (TricklePeriod - randomTime)
    uint32_t remain;
    remain = tricklePeriod - randomTime;
    sentDIOFlag = TRUE;
    call TrickleTimer.startOneShot(remain);
  }

  void nextTrickleTime() {
    sentDIOFlag = FALSE;
    if (doubleCounter < DIOIntDouble) {
      doubleCounter ++;
      tricklePeriod *= 2;
    }
    if (!call TrickleTimer.isRunning())
      chooseAdvertiseTime();
  }

  /********************* RPLRouteInfo *********************/
  command void RPLRouteInfo.inconsistency() {
    inconsistencyDetected();
  }

  command bool RPLRouteInfo.hasDODAG() {
    return hasDODAG;
  }

  command uint8_t RPLRouteInfo.getMOP() {
    return MOP;
  }

  command error_t RPLRouteInfo.getDefaultRoute(struct in6_addr *next) {
    return call RPLRankInfo.getDefaultRoute(next);
  }

  command void RPLRouteInfo.setDODAGConfig(uint8_t IntDouble, 
					   uint8_t IntMin, 
					   uint8_t Redun, 
					   uint8_t RankInc,
					   uint8_t HopRankInc) {
    DIOIntDouble = IntDouble;
    DIOIntMin = IntMin;
    DIORedun = Redun;
    MaxRankInc = RankInc;
    MinHopRankInc = HopRankInc;
    // printf("RPL: Config %d %d %d %d %d \n", 
    //        IntDouble, IntMin, Redun, RankInc, HopRankInc);
  }

  command struct in6_addr* RPLRouteInfo.getDodagId() {
    return &DODAGID;
  }

  command uint8_t RPLRouteInfo.getInstanceID() {
    return RPLInstanceID;
  }

  command bool RPLRouteInfo.validInstance(uint8_t instanceID) {
    return call RPLRankInfo.validInstance(instanceID);
  }

  command void RPLRouteInfo.resetTrickle() {
    resetTrickleTime();
    if (!call TrickleTimer.isRunning())
      chooseAdvertiseTime();
  }

  command uint16_t RPLRouteInfo.getRank() {
    return call RPLRankInfo.getRank(&ADDR_MY_IP);
  }

  command void RPLRouteInfo.setDTSN(uint8_t dtsn) {
    DTSN = dtsn;
  }

  command uint8_t RPLRouteInfo.getDTSN() {
    return DTSN;
  }

  /********************* RootControl *********************/
  command error_t RootControl.setRoot() {
    I_AM_ROOT = TRUE;
    hasDODAG = TRUE;
    call RPLRankInfo.declareRoot();
    return SUCCESS;
  }

  command error_t RootControl.unsetRoot() {
    I_AM_ROOT = FALSE;
    hasDODAG = FALSE;
    call RPLRankInfo.cancelRoot();
    return SUCCESS;
  }

  command bool RootControl.isRoot() {
    return I_AM_ROOT;
  }

  /********************* StdControl *********************/
  command error_t StdControl.start() {
    // printf("RPL: STARTING\n");
    if (!running) {
      post init();
      call RankControl.start();
      running = TRUE;
    }
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    running = FALSE;
    call RankControl.stop();
    call TrickleTimer.stop();
    return SUCCESS;
  }

  event void InitDISTimer.fired() {
    post sendDISTask();
  }

  event void IncreaseVersionTimer.fired() {
    // printf("RPL: >>>> Version Increase!! \n");
    DODAGVersionNumber++;
    call RPLRouteInfo.resetTrickle();
  }

  event void TrickleTimer.fired() {
    if (sentDIOFlag) {
      // DIO is already sent and trickle period has passed 
      // increase tricklePeriod
      nextTrickleTime();
    } else {
      // send DIO, randomly selected time has passed
      // compute the remaining time
      // Change back to DIO
      post sendDIOTask();
      //post sendDISTask();
      post computeRemaining();
    }
  }

  bool compare_ip6_addr(struct in6_addr *node1, struct in6_addr *node2) { //done
    return !memcmp(node1, node2, sizeof(struct in6_addr));
  }

  event void RPLRankInfo.parentRankChange() {
    // type 6 inconsistency
    inconsistencyDetected();
  }

  /* SDH :
   * This is called to process new routing update messages, I think.
   */
  event void IP_DIS.recv(struct ip6_hdr *iph, void *payload, 
                         size_t len, struct ip6_metadata *meta) {
    // printf("RPL: Receiving DIS %d\n", TOS_NODE_ID);
    if (!running) return;
    // I received a DIS
    if (I_AM_LEAF) {
      // I am a leaf so don't do anything
      return;
    }

    if (call IPAddress.isLocalAddress(&iph->ip6_dst)) {
      // This is a multicast message: reset Trickle
      if (iph->ip6_dst.s6_addr[0] == 0xff && 
         ((iph->ip6_dst.s6_addr[1] & 0xf) <= 0x3)) {
        call RPLRouteInfo.resetTrickle();
      } else {
        UNICAST_DIO = TRUE;
        memcpy(&UNICAST_DIO_ADDR, &(iph->ip6_src), sizeof(struct in6_addr));
        post sendDIOTask();
      }
    }
  }

  event void IP_DIO.recv(struct ip6_hdr *iph, void *payload, 
                         size_t len, struct ip6_metadata *meta) {
    struct dio_base_t *dio = (struct dio_base_t *)payload;
    if (!running) return;

    if (I_AM_ROOT) {
      return;
    }

    if (DIORedun != 0xFF) {
      redunCounter ++;
    } else {
      redunCounter = 0xFF;
    }

    /* JK: The if () statement below is TinyRPL specific and ties up
       with the inconsistencyDectect case above */
    if (dio->dagRank == INFINITE_RANK) {
      if ((call RPLRankInfo.getRank(&ADDR_MY_IP) != INFINITE_RANK) && 
          ((call InitDISTimer.getNow()%2) == 1)) { // send DIO if I can help!
	// printf("RPL: Infinite Rank RX %d\n", TOS_NODE_ID);
	post sendDIOTask();
      }
      return;
    }

    if (call RPLRankInfo.hasParent() && call InitDISTimer.isRunning()) {
      call InitDISTimer.stop(); // no need for DIS messages anymore
    }

    // received DIO message
    I_AM_LEAF = call RPLRankInfo.isLeaf();

    if ((I_AM_LEAF && !hasDODAG)
        || !compare_ip6_addr(&DODAGID,&dio->dodagID)) {
      // If I am leaf I do not send any DIO messages
      // assume that this DIO is from the DODAG with the
      // highest preference and is the preferred parent's DIO packet?
      //   OR
      // If a new DODAGID is reported probably the Rank layer
      // already took care of all the operations and decided to switch to the
      // new DODAGID
      // printf("RPL: FOUND new dodag %d %d %d\n", 
      //        I_AM_LEAF, hasDODAG, compare_ip6_addr(&DODAGID,&dio->dodagID));
      hasDODAG = TRUE;
      // assume that this DIO is from the DODAG with the
      // highest preference and is the preferred parent's DIO packet?
      goto accept_dodag;
    }
    
    if (RPLInstanceID == dio->instance_id.id && 
        compare_ip6_addr(&DODAGID, &dio->dodagID) && 
        DODAGVersionNumber != dio->version && 
        hasDODAG) {
      // sequence number has changed - new iteration; restart the
      // trickle timer and configure DIO with new sequence number
      
      // printf("RPL: New iteration %d %d %d\n", 
      //        dio->instance_id.id, dio->version, I_AM_LEAF);
      DODAGVersionNumber = dio->version;
      call RPLRouteInfo.resetTrickle();

      // type 3 inconsistency
    } else if (call RPLRankInfo.getRank(&ADDR_MY_IP) != node_rank && 
               hasDODAG && 
               node_rank != INFINITE_RANK) {
      /*  inconsistency detected! because rank is not what I
          previously advertised */
      // printf("RPL: ICD %d\n", node_rank);
      // DO I Still need this?
      if (call RPLRankInfo.getRank(&ADDR_MY_IP) > LOWRANK + MaxRankInc && 
          node_rank != INFINITE_RANK) {
        hasDODAG = FALSE;
        node_rank = INFINITE_RANK;
      } else {
        if (LOWRANK > call RPLRankInfo.getRank(&ADDR_MY_IP)) {
          LOWRANK = call RPLRankInfo.getRank(&ADDR_MY_IP);
        }
        node_rank = call RPLRankInfo.getRank(&ADDR_MY_IP);
      }
      // type 2 inconsistency
      inconsistencyDetected();
      return;
    }
    
    if (call RPLRankInfo.hasParent() && !hasDODAG) {
      goto accept_dodag;
    } else if (!call RPLRankInfo.hasParent() && !I_AM_ROOT) {
      /*  this else if can lead to errors!! */
      /*  I have no parent at this point! */
      // printf("RPL: noparent %d %d\n", node_rank, call RPLRankInfo.hasParent());
      hasDODAG = FALSE;
      GROUND_STATE = dio->flags & DIO_GROUNDED_MASK;
      //GROUND_STATE = dio->flags.flags_element.grounded;
      call TrickleTimer.stop();
      // new add
      call RPLRouteInfo.resetTrickle();
      call RPLDAORoutingEngine.startDAO();
    }
    return;
  accept_dodag:
    // printf("RPL: new dodag \n");
    // assume that this DIO is from the DODAG with the
    // highest preference and is the preferred parent's DIO packet?
    hasDODAG = TRUE;
    MOP = (dio->flags & DIO_MOP_MASK) >> DIO_MOP_SHIFT;
    DAG_PREF = dio->flags & DIO_PREF_MASK;
    RPLInstanceID = dio->instance_id.id;
    memcpy(&DODAGID, &dio->dodagID, sizeof(struct in6_addr));
    DODAGVersionNumber = dio->version;
    GROUND_STATE = dio->flags & DIO_GROUNDED_MASK;
    //GROUND_STATE = dio->flags.flags_element.grounded;
    call RPLRouteInfo.resetTrickle();
    return;
  }

  event void IPAddress.changed(bool global_valid) {}

}
