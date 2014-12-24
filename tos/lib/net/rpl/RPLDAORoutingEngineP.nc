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
 * @author JeongGil Ko (John) <jgko@cs.jhu.edu>
 * @author Brad Campbell <bradjc@umich.edu>
 */

#include <RPL.h>
#include <lib6lowpan/in_cksum.h>
#include <lib6lowpan/ip.h>

generic module RPLDAORoutingEngineP() {
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
  }
} implementation {

#define INIT_DAO 10000

  uint8_t dao_double_count = 0;
  uint8_t dao_double_limit = 6;
  uint32_t dao_rate = INIT_DAO;
  // dao batches will be fired 256 ms after the first dao message is
  // scheduled every 100 ms, check if elememts in the entry should be
  // deleted -- only for storing nodes
  uint32_t delay_dao = 256;
  uint32_t remove_time = 120 * 1024U;
  uint8_t dao_table_pos = 0;
  uint16_t DTSN = 0;
  uint8_t daoseq = 0;
  uint16_t init_daorank = 1;

  uint8_t PATH_SEQUENCE = 0;
  uint8_t PATH_CONTROL = 0;

  downwards_table_t downwards_table[ROUTE_TABLE_SZ];
  uint8_t downwards_table_count = 0;
  bool m_running = FALSE;

  uint32_t count = 0;

  task void initDAO();


  bool memcmp_rpl(uint8_t* a, uint8_t* b, uint8_t len) {
    uint8_t i;
    for (i = 0 ; i < len ; i++)
      if (a[i] != b[i])
        return FALSE;
    return TRUE;
  }

  command error_t StdControl.start() {
    call RPLDAORouteInfo.startDAO();
    m_running = TRUE;
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    m_running = FALSE;
    return SUCCESS;
  }

  task void sendDAO() {
    dao_entry_t* dao_msg;

    // for now the next hop for the DAO is ONLY the desired parent on
    // the path to the DODAG root
    struct in6_addr next_hop;

    if (call RPLRouteInfo.getRank() == ROOT_RANK) return;

    if (call SendQueue.size() > 0 && call RPLRouteInfo.getMOP() != 0) {
      dao_msg = call SendQueue.dequeue();
      // this should be my desired parent for now

#if RPL_STORING_MODE
      /* in storing mode we unicast using LL addresses (9.2) */
      call IPAddress.getLLAddr(&dao_msg->s_pkt.ip6_hdr.ip6_src);
      if (call RPLRouteInfo.getDefaultRoute(&next_hop) != SUCCESS) {
        call SendPool.put(dao_msg);
        printf("RPL: DAO: sendDAO: no default route\n");
        return;
      }
      ip_memcpy((uint8_t*)&dao_msg->s_pkt.ip6_hdr.ip6_dst,
                (uint8_t*)&next_hop, sizeof(struct in6_addr));
#else
      /* in non-storing mode we must use global addresses */
      call IPAddress.getGlobalAddr(&dao_msg->s_pkt.ip6_hdr.ip6_src);
      /* and unicast to the DODAG root */
      call RPLRouteInfo.getDodagId(&dao_msg->s_pkt.ip6_hdr.ip6_dst);
#endif

      call IP_DAO.send(&dao_msg->s_pkt);
      call SendPool.put(dao_msg);

      if (call SendQueue.size()) {
        // Once fired, shoot all the DAOs in the current sendqueue;
        // Assume that there is no aggregation on DAO messages.
        post sendDAO();
      }
    }
  }

  command error_t RPLDAORouteInfo.startDAO() {

#if RPL_STORING_MODE
    call RemoveTimer.startPeriodic(remove_time);
#else
    if (call RPLRouteInfo.getRank() = ROOT_RANK) {
      call RemoveTimer.startPeriodic(remove_time);
    }
#endif

    // do we need this?
    call DelayDAOTimer.startOneShot(delay_dao + call Random.rand16()%100);

    if (call GenerateDAOTimer.isRunning()) {
      return SUCCESS;
    } else if (call RPLRouteInfo.getRank() == ROOT_RANK) {
      return SUCCESS;
    } else {
      call GenerateDAOTimer.startOneShot(dao_rate +
        ((call Random.rand16()) % (dao_rate / 10)));
    }
    return SUCCESS;
  }

  command bool RPLDAORouteInfo.getStoreState() {
#if RPL_STORING_MODE
    return TRUE;
#else
    return call RootControl.isRoot();
#endif
  }

  event void GenerateDAOTimer.fired() { // Initiate my own DAO messages
    uint32_t dao_next = dao_rate +
      ((call Random.rand16()) % (dao_rate / 10));

    post initDAO();
    call GenerateDAOTimer.startOneShot(dao_next);
  }

  task void initDAO() {
    error_t error;
    dao_entry_t* dao_msg;
    uint16_t length = sizeof(struct dao_full_t);

    if (!call RPLRouteInfo.hasDODAG() ||
        call RPLRouteInfo.getRank() == ROOT_RANK) {
      return;
    }

    dao_msg = call SendPool.get();
    if (dao_msg == NULL) return;

    dao_msg->dao_full.base.icmpv6.type = ICMP_TYPE_RPL_CONTROL;
    dao_msg->dao_full.base.icmpv6.code = ICMPV6_CODE_DAO;
    dao_msg->dao_full.base.icmpv6.checksum = 0;
    dao_msg->dao_full.base.instance_id.id = call RPLRouteInfo.getInstanceID();
    dao_msg->dao_full.base.flags = 0;
    dao_msg->dao_full.base.flags |= (0 << DAO_K_SHIFT);
    dao_msg->dao_full.base.flags |= (1 << DAO_D_SHIFT);
    dao_msg->dao_full.base.reserved = 0;
    dao_msg->dao_full.base.DAOsequence = daoseq;
    memcpy(&dao_msg->dao_full.base.dodagID, call RPLRouteInfo.getDodagId(),
      sizeof(struct in6_addr));

    dao_msg->dao_full.target_option.type = RPL_OPT_TYPE_TARGET;
    dao_msg->dao_full.target_option.option_length = 18;
    dao_msg->dao_full.target_option.flags = 0;
    dao_msg->dao_full.target_option.prefix_length = sizeof(struct in6_addr) * 8;
    call IPAddress.getGlobalAddr(&dao_msg->dao_full.target_option.target_prefix);

    dao_msg->dao_full.transit_info_option.type = RPL_OPT_TYPE_TRANSIT;
    dao_msg->dao_full.transit_info_option.option_length = 20;
    dao_msg->dao_full.transit_info_option.flags = 0;
    dao_msg->dao_full.transit_info_option.flags |= (0 << DAO_TRANSIT_E_SHIFT);
    dao_msg->dao_full.transit_info_option.path_control = PATH_CONTROL;
    dao_msg->dao_full.transit_info_option.path_sequence = PATH_SEQUENCE;
    dao_msg->dao_full.transit_info_option.path_lifetime = DEFAULT_LIFETIME;
    error = call RPLRouteInfo.getDefaultRoute(
      &dao_msg->dao_full.transit_info_option.parent_address);

    if (error != SUCCESS) {
      call SendPool.put(dao_msg);
      return;
    }

    dao_msg->v[0].iov_base = (uint8_t*) &dao_msg->dao_full;
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
      downwards_table[i].lifetime -= remove_time;
      if (downwards_table[i].lifetime <= remove_time) {
        /* SDH : expire the route to this destination */
        call ForwardingTable.delRoute(downwards_table[i].key);
        for (j = i; j < downwards_table_count-1; j++) {
          downwards_table[j] = downwards_table[j+1];
        }
        downwards_table[downwards_table_count-1].lifetime = 0;
        downwards_table_count--;
      }
    }
  }

  event void IP_DAO.recv(struct ip6_hdr *iph, void *payload,
                          size_t len, struct ip6_metadata *meta) {
    dao_entry_t* dao_msg;
    size_t payload_len = len;
    error_t error;
    struct in6_addr my_addr;

    struct dao_base_t* dao = (struct dao_base_t*) payload;
    struct target_option_t* dao_target = NULL;
    struct transit_info_option_t* dao_transit = NULL;

    uint8_t* cur = (uint8_t*) payload;

    struct route_entry* entry;
    route_key_t new_key = ROUTE_INVAL_KEY;

    struct in6_addr target_prefix;

    if (!m_running) return;

#if !RPL_STORING_MODE
    if (!call RPLDAORouteInfo.getStoreState()) return;
#endif

    // Length must be at least the first part of the DAO minus the DODAGID
    if (len < (sizeof(struct dao_base_t) - sizeof(struct in6_addr))) return;

    if ((dao->flags & DAO_D_MASK) >> DAO_D_SHIFT) {
      // there is a DODAGID present
      cur += sizeof(struct dao_base_t);
      len -= sizeof(struct dao_base_t);
    } else {
      // no DODAGID was included
      cur += sizeof(struct dao_base_t) - sizeof(struct in6_addr);
      len -= sizeof(struct dao_base_t) - sizeof(struct in6_addr);
    }

    if (len < 2) return;

    while (len > 2) {
      if (*cur == RPL_OPT_TYPE_TARGET) {
        dao_target = (struct target_option_t*) cur;
        if (len < dao_target->option_length + 2) return;
        cur += dao_target->option_length + 2;
        len -= dao_target->option_length + 2;
      } else if (*cur == RPL_OPT_TYPE_TRANSIT) {
        dao_transit = (struct transit_info_option_t*) cur;
        if (len < dao_transit->option_length + 2) return;
        cur += dao_transit->option_length + 2;
        len -= dao_transit->option_length + 2;
      } else {
        // unknown option
        struct rpl_option_t* rpl_opt = (struct rpl_option_t*) cur;
        if (len < rpl_opt->option_length + 2) return;
        cur += rpl_opt->option_length + 2;
        len -= rpl_opt->option_length + 2;
      }
    }

    if (dao_target == NULL || dao_transit == NULL) return;

    // Get the target prefix, need to pad with zeros if not all was sent
    memset(&target_prefix, 0, sizeof(struct in6_addr));
    memcpy(&target_prefix, &dao_target->target_prefix,
      dao_target->prefix_length/8);

    /* SDH : the two cases are the same...  */
    entry = call ForwardingTable.lookupRoute(
      target_prefix.s6_addr,
      dao_target->prefix_length);

    if (entry != NULL && dao_transit->path_lifetime == 0) {
      // This is a No-Path DAO message indicating loss of reachability to
      // this target. Remove the route we had to this node.
      if (memcmp_rpl((uint8_t*)entry->next_hop.s6_addr,
                     (uint8_t*)iph->ip6_src.s6_addr, 16) == TRUE) {
          printf("RPLDAORoutingEngineP: Dropping route because of No-Path DAO.\n");
          call ForwardingTable.delRoute(entry->key);
      }

    } else {

      if ((entry != NULL) &&
          (entry->prefixlen == dao_target->prefix_length)) {
        /* exact match in the forwarding table */
        if (memcmp_rpl((uint8_t*)entry->next_hop.s6_addr,
                       (uint8_t*)iph->ip6_src.s6_addr, 16) == TRUE) {
          // same old destination with same DTSN
        } else {
          // new next hop for an existing downswards node
          call RPLRouteInfo.setDTSN((call RPLRouteInfo.getDTSN()) + 1);
          if (dao_target->prefix_length > 0) {
            new_key = call ForwardingTable.addRoute(
              target_prefix.s6_addr,
              dao_target->prefix_length,
              &iph->ip6_src,
              RPL_IFACE);
          }
        }
      } else {
        /* new prefix */

        call IPAddress.getGlobalAddr(&my_addr);
        if (downwards_table_count == ROUTE_TABLE_SZ ||
            memcmp_rpl((void*)&my_addr, target_prefix.s6_addr, 16)) {
          // printf("RPL: Downward table full -- not adding route\n");
          // or this is my own address for some wierd reason
          return;
        }
        if (dao_target->prefix_length > 0) {
          new_key = call ForwardingTable.addRoute(
            target_prefix.s6_addr,
            dao_target->prefix_length,
            &iph->ip6_src,
            RPL_IFACE);
        }

        if (new_key != ROUTE_INVAL_KEY) {
          downwards_table[downwards_table_count].key = new_key;
          // for next element
          downwards_table_count++;
        }

      }

      if (new_key != ROUTE_INVAL_KEY) {
        uint8_t i;
        for (i=0;i<downwards_table_count;i++){
          if (downwards_table[i].key == new_key){
            downwards_table[i].lifetime = dao_transit->path_lifetime;
          }
        }
      }

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

    // NO MODIFICATION TO DAO's RR-LIST NEEDED! -- just make sure I
    // keep what I have and the prefix
    ip_memcpy((uint8_t*)&dao_msg->s_pkt.ip6_hdr,
              (uint8_t*)iph, sizeof(struct ip6_hdr));

    // copy new payload information
    ip_memcpy((uint8_t*)&dao_msg->dao_full,
              (uint8_t*)payload, payload_len);
    dao_msg->v[0].iov_base = (uint8_t*) &dao_msg->dao_full;
    dao_msg->v[0].iov_len = ntohs(iph->ip6_plen);
    dao_msg->v[0].iov_next = NULL;
    dao_msg->s_pkt.ip6_data = &dao_msg->v[0];

    error = call SendQueue.enqueue(dao_msg);

    if (error != SUCCESS) {
      call SendPool.put(dao_msg);
      return;
    } else {
      if (!call DelayDAOTimer.isRunning())
        call DelayDAOTimer.startOneShot(delay_dao);
    }
  }

  command void RPLDAORouteInfo.newParent() {
    post initDAO();
  }

  event void IPAddress.changed(bool global_valid) {}
}
