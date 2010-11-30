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
 * RPLDAORoutingEngineP.nc
 * @ author JeongGil Ko (John) <jgko@cs.jhu.edu>
 */

#include <RPL.h>
#include <lib6lowpan/in_cksum.h>
#include <lib6lowpan/ip.h>
#include <RPL.h>

generic module RPLDAORoutingEngineP(){
  provides {
    interface RPLDAORoutingEngine as RPLDAORouteInfo;
    interface StdControl;
  }
  uses {
    interface Timer<TMilli> as DelayDAOTimer;
    interface Timer<TMilli> as RemoveTimer;
    interface Timer<TMilli> as GenerateDAOTimer;
    interface Random;
    interface IP as IP_DAO;
    interface IPAddress;
    interface Queue<dao_entry_t*> as SendQueue;
    interface Pool<dao_entry_t> as SendPool;
    interface RPLRoutingEngine as RPLRouteInfo;
    interface RootControl;
    interface IPPacket;
    interface ForwardingTable;
    interface Leds;
  }
} implementation {
  uint32_t dao_rate = 20 * 1024U;
  uint32_t delay_dao = 256; // dao batches will be fired 256 ms after the first dao message is scheduled
  // every 100 ms, check if elememts in the entry should be deleted --
  // only for storing nodes
  uint32_t remove_time = 60 * 1024U; 
  uint8_t dao_table_pos = 0;
  uint16_t DTSN = 0;
  uint16_t daoseq = 0;
  uint16_t init_daorank = 1;
  struct in6_addr DEF_PREFIX;

  uint8_t PATH_SEQUENCE = 0;
  uint8_t PATH_CONTROL = 0;

  downwards_table_t downwards_table[ROUTE_TABLE_SZ];
  uint8_t downwards_table_count = 0;
  bool m_running = FALSE;

#undef printfUART
#define printfUART(X, args ...) ;

  command error_t StdControl.start() {
    call RPLDAORouteInfo.startDAO();
    m_running = TRUE;
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    m_running = FALSE;
    return FAIL;
  }

  task void sendDAO() {
    dao_entry_t* dao_msg;
    // struct ieee154_frame_addr addr_struct;

    // for now the next hop for the DAO is ONLY the desired parent on
    // the path to the DODAG root
    struct in6_addr next_hop; 
    struct dao_base_t* dao;

    // post sendDAO again until everything is transmitted
    printfUART("sendDAO\n");

    if (call SendQueue.size() > 0 && call RPLRouteInfo.getMOP() != 0) {
      printfUART("proceeding\n");

      dao_msg = call SendQueue.dequeue();
      // this should be my desired parent for now


#if RPL_STORING_MODE
      /* in storing mode we unicast using LL addresses (9.2) */
      call IPAddress.getLLAddr(&dao_msg->s_pkt.ip6_hdr.ip6_src);
      if (call RPLRouteInfo.getDefaultRoute(&next_hop) != SUCCESS)
        return;
      memcpy(&dao_msg->s_pkt.ip6_hdr.ip6_dst, &next_hop, 
             sizeof(struct in6_addr));
#else 
      /* in non-storing mode we must use global addresses */
      call IPAddress.getGlobalAddr(&dao_msg->s_pkt.ip6_hdr.ip6_src);
      /* and unicast to the DODAG root */
      call RPLRouteInfo.getDodagId(&dao_msg->s_pkt.ip6_hdr.ip6_dst);
#endif
      dao = (struct dao_base_t *) dao_msg->s_pkt.ip6_data->iov_base;

      printfUART("DAO TX\n");
      call IP_DAO.send(&dao_msg->s_pkt);
      call SendPool.put(dao_msg);

      if (call SendQueue.size()) {
	// Once fired, shoot all the DAOs in the current sendqueue;
        // Assume that there is no aggregation on DAO messages.
	post sendDAO();
      }
    }
  }

  command void RPLDAORouteInfo.startDAO() {
    printfUART("START DAO \n");

#ifdef RPL_STORING_MODE
    call RemoveTimer.startPeriodic(remove_time);
#else
    if (call RPLRouteInfo.getRank() != ROOT_RANK) {
    } else {
      call RemoveTimer.startPeriodic(remove_time);
    }
#endif
    if (call RPLRouteInfo.getRank() != ROOT_RANK/*I am not root*/) {
      call GenerateDAOTimer.startPeriodic(dao_rate);
    }
  }

  command bool RPLDAORouteInfo.getStoreState() {
#if RPL_STORING_MODE
    return TRUE;
#else
    return call RootControl.isRoot();
#endif
  }

  event void GenerateDAOTimer.fired() { // Initiate my own DAO messages
    error_t error;
    dao_entry_t* dao_msg;
    uint16_t length = sizeof(struct dao_base_t);

    dao_msg = call SendPool.get();
    if (dao_msg == NULL){
      return;
    }

    if(!call RPLRouteInfo.hasDODAG()){
      call SendPool.put(dao_msg);
      return;
    }

    // call IPAddress.setSource(&dao_msg->s_pkt.ip6_hdr);
    dao_msg->dao_base.icmpv6.type = ICMP_TYPE_ROUTER_ADV; // Is this type correct?
    dao_msg->dao_base.icmpv6.code = ICMPV6_CODE_DAO;
    dao_msg->dao_base.icmpv6.checksum = 0;
    dao_msg->dao_base.DAOsequence = daoseq;
    dao_msg->dao_base.instance_id.id = call RPLRouteInfo.getInstanceID(); // get instance ID from Rtg eng

    dao_msg->dao_base.target_option.type = 5;
    dao_msg->dao_base.target_option.option_length = 18;
    dao_msg->dao_base.target_option.prefix_length = sizeof(struct in6_addr) * 8; // length of my address
    call IPAddress.getGlobalAddr(&dao_msg->dao_base.target_option.target_prefix);
    
    dao_msg->dao_base.transit_info_option.type = 6;
    dao_msg->dao_base.transit_info_option.option_length = 22;
    dao_msg->dao_base.transit_info_option.path_sequence = PATH_SEQUENCE;
    dao_msg->dao_base.transit_info_option.path_control = PATH_CONTROL;
    dao_msg->dao_base.transit_info_option.path_lifetime = DEFAULT_LIFETIME;
    if (call RPLRouteInfo.getDefaultRoute(&dao_msg->dao_base.transit_info_option.parent_address) != SUCCESS)
      return;

    dao_msg->v[0].iov_base = (uint8_t *)&dao_msg->dao_base;
    dao_msg->v[0].iov_len  = length;
    dao_msg->v[0].iov_next = NULL;

    dao_msg->s_pkt.ip6_hdr.ip6_vfc = IPV6_VERSION;
    dao_msg->s_pkt.ip6_hdr.ip6_nxt = IANA_ICMP;
    dao_msg->s_pkt.ip6_hdr.ip6_plen = htons(length);
    dao_msg->s_pkt.ip6_data = &dao_msg->v[0];

    error = call SendQueue.enqueue(dao_msg);

    if (error != SUCCESS) {
      call SendPool.put(dao_msg);
      return;
    } else {
      if (!call DelayDAOTimer.isRunning()) {
	call DelayDAOTimer.startOneShot(delay_dao);
      }
    }
  }

  event void DelayDAOTimer.fired() {
    post sendDAO();
  }

  event void RemoveTimer.fired() {
    // check stored table's life-time
    uint8_t i, j;
    if (!call RPLDAORouteInfo.getStoreState())
      return;

    for (i = 0; i < downwards_table_count; i++) {
      downwards_table[i].lifetime -= delay_dao;
      if (downwards_table[i].lifetime <= delay_dao) {
        /* SDH : expire the route to this destination */
        call ForwardingTable.delRoute(downwards_table[i].key);
	for (j = i; j < downwards_table_count-1; j++) {
	  downwards_table[j] = downwards_table[j+1];
	}
	downwards_table[downwards_table_count-1].lifetime = 0;
	downwards_table_count --;
      }
    }
  }

  event void IP_DAO.recv(struct ip6_hdr *iph, void *payload, 
                          size_t len, struct ip6_metadata *meta) {
    dao_entry_t* dao_msg;
    error_t error;
    // This is where the message is actually cast
    struct dao_base_t *dao = (struct dao_base_t *)payload; 
    struct route_entry *entry;
    route_key_t new_key;

    printfUART("receive DAO: %i\n", call RPLDAORouteInfo.getStoreState());
    if (!m_running) return;

#ifndef RPL_STORING_MODE
    if (!call RPLDAORouteInfo.getStoreState())
      return;
#endif
//     if (dao->target_option.prefix_length == 128)
//       call Leds.led1Toggle();
    /* SDH : the two cases are the same...  */
    entry = call ForwardingTable.lookupRoute(dao->target_option.target_prefix.s6_addr,
                                             dao->target_option.prefix_length);
    if (entry != NULL && entry->prefixlen == dao->target_option.prefix_length) {
      /* exact match in the forwarding table */
      if (memcmp(entry->next_hop.s6_addr, iph->ip6_src.s6_addr, 16) == 0) {
	// same old destination
      } else {
        /* SDH : shouldn't we, like, save the new route? */
	// new next hop for an existing downswards node
	call RPLRouteInfo.setDTSN(call RPLRouteInfo.getDTSN()+1);
      }
    } else {
      /* new prefix */
      if (downwards_table_count == ROUTE_TABLE_SZ) {
        printfUART("Downward table full -- not adding route\n");
        return;
      }

      new_key = call ForwardingTable.addRoute(dao->target_option.target_prefix.s6_addr,
                                              dao->target_option.prefix_length,
                                              &iph->ip6_src,
                                              RPL_IFACE);
      if (new_key == ROUTE_INVAL_KEY) {
        call Leds.led1Toggle();
        return;
      }

      downwards_table[downwards_table_count].lifetime = 
        dao->transit_info_option.path_lifetime;
      downwards_table[downwards_table_count].key = new_key;
      // for next element
      downwards_table_count ++;
      printfUART("DAO RX-- new prefix %d %d %d \n",
                 downwards_table_count, 
                 ntohs(dao->target_option.target_prefix.s6_addr16[7]), 
                 ntohs(iph->ip6_src.s6_addr16[7]));
    }

    /***********************************************************************/
    // FROM THIS POINT, ITS ABOUT FORWARDING THE DAO INFORMATION UPWARDS!!!
    /***********************************************************************/
    if (call RPLRouteInfo.getRank() == ROOT_RANK) {
      // no need to futher process packets
      return;
    }
    dao_msg = call SendPool.get();
    if (dao_msg == NULL) {
      return;
    }

    // NO MODIFICATION TO DAO's RR-LIST NEEDED! -- just make sure I keep what I have and the prefix
    printfUART("Continue! %d \n", ntohs(iph->ip6_plen));
    memcpy(&dao_msg->s_pkt.ip6_hdr, iph, sizeof(struct ip6_hdr));

    // copy new payload information
    memcpy(&dao_msg->dao_base, (uint8_t*)payload, sizeof(struct dao_base_t));
    dao_msg->v[0].iov_base = (uint8_t *)&dao_msg->dao_base;
    dao_msg->v[0].iov_len = ntohs(iph->ip6_plen);
    dao_msg->v[0].iov_next = NULL;
    dao_msg->s_pkt.ip6_data = &dao_msg->v[0];

    error = call SendQueue.enqueue(dao_msg);
    if (error != SUCCESS) {
      call SendPool.put(dao_msg);
      return;
    } else {
      if (!call DelayDAOTimer.isRunning()) {
	call DelayDAOTimer.startOneShot(delay_dao);
      }
    }
  }
  event void IPAddress.changed(bool global_valid) {}
}
