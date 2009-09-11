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

#include "IPDispatch.h"
#include "PrintfUART.h"

module IPRoutingP {
  provides interface IPRouting;
  provides interface Statistics<route_statistics_t>;

  uses interface IPExtensions;
  uses interface TLVHeader as DestinationExt;
  uses interface ICMP;
  uses interface Boot;
  uses interface IPAddress;
  uses interface Random;

  uses interface Timer<TMilli> as SortTimer;

  uses interface IP as TGenSend;
  uses interface Timer<TMilli> as TrafficGenTimer;

  uses interface Leds;

} implementation {

#ifdef PRINTFUART_ENABLED
// #undef dbg
// #define dbg(X, fmt, args...)  printfUART(fmt, ## args)
#endif

  enum {
    SHORT_EPOCH = 0,
    LONG_EPOCH = 1,
  };

  //uint16_t current_epoch;
  //route_statistics_t stats;
  uint16_t last_qual;
  uint8_t last_hops;
  uint16_t reportSeqno;

  bool soliciting;

  // pointer into the neighbor table of the current entry that is our
  // first choice.
  struct neigh_entry *default_route;
  uint16_t default_route_failures;

  uint32_t traffic_interval;
  bool traffic_sent;

#ifdef CENTRALIZED_ROUTING
  // this is the routing table (k parents);
  struct flow_path full_path_entries[N_FULL_PATH_ENTRIES];
  struct flow_entry flow_table[N_FLOW_ENT];
#endif
  struct neigh_entry neigh_table[N_NEIGH];

  void printTable();
  error_t freeFullPath(struct flow_path* path);
  void updateFlowCounts(struct flow_entry *target);
  void updateRankings();
  void swapNodes(struct neigh_entry *highNode, struct neigh_entry *lowNode);
  uint8_t checkThresh(uint32_t firstVal, uint32_t secondVal, uint16_t thresh);
  void evictNeighbor(struct neigh_entry *neigh);
  uint16_t getMetric(struct neigh_entry *neigh);

  uint16_t adjustLQI(uint8_t val) {
    uint16_t result = (80 - (val - 50));
    result = (((result * result) >> 3) * result) >> 3;  // result = (result ^ 3) / 64
    dbg("Lqi", "adjustLqi in: 0x%x out: 0x%x\n", val, result);
    return result;
  }

  void clearStats(struct neigh_entry *r) {
    ip_memclr((uint8_t *)r->stats, sizeof(struct epoch_stats) * N_EPOCHS);
#if 0
    int j;
    for (j = 0; j < N_EPOCHS; j++) {
      r->stats[j].total   = 0;
      r->stats[j].success = 0;
      r->stats[j].receptions = 0;
    }
#endif
  }

  void clearEpoch(uint8_t target_epoch) {
    int i;
    for (i = 0; i < N_NEIGH; i++) {
      neigh_table[i].stats[target_epoch].total = 0;
      neigh_table[i].stats[target_epoch].success = 0;
      neigh_table[i].stats[target_epoch].receptions = 0;
    }
  }

  void restartTrafficGen() {
    traffic_interval = TGEN_BASE_TIME;
    // jitter the period by 10% to prevent synchronization
    traffic_interval += (call Random.rand16()) % (TGEN_BASE_TIME);
    if (call TrafficGenTimer.isRunning())
      call TrafficGenTimer.stop();
    traffic_sent = FALSE;

    call TrafficGenTimer.startOneShot(traffic_interval);
  }

  event void TrafficGenTimer.fired() {
    struct split_ip_msg *msg;
    if (traffic_sent) goto done;
    msg = (struct split_ip_msg *)ip_malloc(sizeof(struct split_ip_msg));
    if (msg == NULL) {
      printfUART("malloc fail\n");
      goto done;
    }
    traffic_sent = FALSE;

    ip_memclr((uint8_t *)&msg->hdr, sizeof(struct ip6_hdr));
    inet_pton6("ff05::1", &msg->hdr.ip6_dst);
    call IPAddress.getIPAddr(&msg->hdr.ip6_src);
    msg->data = NULL;
    msg->data_len = 0;
    msg->headers = NULL;

    dbg("IPRouting", "Sending generated message\n");
    call TGenSend.send(msg);
    ip_free(msg);
  done:
    // restart timer
    dbg("IPRouting", "Done checking for tgen\n");
    traffic_sent = FALSE;
    traffic_interval *= 2;
    if (traffic_interval > TGEN_MAX_INTERVAL)
      traffic_interval = TGEN_MAX_INTERVAL;
    call TrafficGenTimer.startOneShot(traffic_interval);
  }

  event void TGenSend.recv(struct ip6_hdr *iph,
                           void *payload, 
                           struct ip_metadata *meta) {

  }

  command void IPRouting.reset() {
    int i;

    for (i = 0; i < N_NEIGH; i++) {
      neigh_table[i].flags = 0;
      clearStats(&neigh_table[i]);
    }

#ifdef CENTRALIZED_ROUTING
    call IPRouting.clearFlows();
    for (i = 0; i < N_FULL_PATH_ENTRIES; i++) {
      full_path_entries[i].path_len = 0;
    }
#endif

    // current_epoch = 0;
    if (!soliciting) {
      call ICMP.sendSolicitations();
      soliciting = TRUE;
    }
    //reRouting = FALSE;
    default_route_failures = 0;
    default_route = &neigh_table[0];
    // boot with this true so the router will invalidate any state
    // associated from us when it gets the first packet.
    last_qual = 0xffff;
    last_hops = 0xff;

    traffic_sent = FALSE;
    restartTrafficGen();
  }

  event void Boot.booted() {
    call IPRouting.reset();
    reportSeqno = call Random.rand16();

    call Statistics.clear();
    call SortTimer.startPeriodic(1024L * 60);

  }
  
  command bool IPRouting.isForMe(struct ip6_hdr *hdr) {
    // the destination prefix is either link-local or global, or
    // multicast (we accept all multicast packets), and the suffix is
    // me.
    struct in6_addr *my_address = call IPAddress.getPublicAddr();
    return (((cmpPfx(my_address->s6_addr, hdr->ip6_dst.s6_addr) || 
              cmpPfx(linklocal_prefix, hdr->ip6_dst.s6_addr)) &&
             cmpPfx(&my_address->s6_addr[8], &hdr->ip6_dst.s6_addr[8])) ||
            (hdr->ip6_dst.s6_addr[0] == 0xff && 
             (hdr->ip6_dst.s6_addr[1] & 0x0f) <= 3))
;
  }

#ifdef CENTRALIZED_ROUTING
  void print_rinstall(struct rinstall_header *rih) {
    uint8_t i;
    dbg("Install", "rinstall header:\n");
    dbg_clear("Install", "\tnxt_header\t0x%x\n", rih->ext.nxt_hdr);
    dbg_clear("Install", "\tlen\t0x%x\n", rih->ext.len);
    dbg_clear("Install", "\tflags\t0x%x\n", rih->flags);
    dbg_clear("Install", "\tmatch_src\t0x%x\n", ntohs(rih->match.src));
    dbg_clear("Install", "\tmatch_prev\t0x%x\n", ntohs(rih->match.prev_hop));
    dbg_clear("Install", "\tmatch_dest\t0x%x\n", ntohs(rih->match.dest));
    dbg_clear("Install", "\tpath_len\t0x%x\n", rih->path_len);
    dbg_clear("Install", "\tcurrent\t0x%x\n", rih->current);
    for(i = 0; i < rih->path_len; i++)
      dbg_clear("Install", "\thop[%u]\t0x%x\n", i, ntohs(rih->path[i]));
  }

  struct flow_entry *getFlowEntry(cmpr_ip6_addr_t a) {
    int i;
    dbg("IPRouting", "getFlowEntry called for 0x%x\n", a);
    for (i = 0; i < N_FLOW_ENT; i++) {
      if (IS_VALID_SLOT(&flow_table[i]) && flow_table[i].match.dest == a) {
        dbg("IPRouting", "Match found in slot [%u]\n", i);
        return &(flow_table[i]);
      }
    }
    return NULL;
  }

  //  Add this extra layer of indirection to allow us to do
  //   more extensive 5-tuple lookups.
  struct flow_entry *getFlowEntry_Header(struct ip6_hdr* hdr) {
   if (hdr == NULL)
     //return &flow_table[T_DEF_PARENT_SLOT]; 
     return NULL;
   return getFlowEntry(ntohs(hdr->ip6_dst.s6_addr16[7]));
  }

  struct flow_entry *getFlowEntry_Match(struct flow_match *match) {
    dbg("IPRouting", "getFlowEntry_Match called for 0x%x\n", ntohs(match->dest));
    return getFlowEntry(ntohs(match->dest));
  }

  struct flow_entry *getNewEntry(struct flow_match *match) {
    uint8_t i;
    uint8_t place = N_FLOW_ENT;
    for (i = 0; i < N_FLOW_ENT; i++) {
      if (!IS_VALID_SLOT(&(flow_table[i]))) {
        flow_table[i].match.src = ntohs(match->src);
        flow_table[i].match.dest = ntohs(match->dest);

        dbg("IPRouting", "New flow entry slot provided in slot [%u]\n", i);
        return &(flow_table[i]);
      }
      if (flow_table[i].count == (N_FLOW_ENT - 1))
        place = i;
    }
 
    if (place == N_FLOW_ENT) {
      dbg("IPRouting", "The correct value of place doesn't exist!!\n");
      return NULL;
    }

    dbg("IPRouting", "Conflicted flow entry slot. Dest: 0x%x, slot 0x%x\n", flow_table[place].match.dest, place);
    for (i = 0; i < N_FLOW_CHOICES; i++) {
      if(IS_VALID_ENTRY(flow_table[place].entries[i])) {
        SET_INVALID_ENTRY(flow_table[place].entries[i]);
        if (IS_FULL_TYPE(flow_table[place].entries[i]))
          freeFullPath(flow_table[place].entries[i].pathE);
      }
    }
    SET_INVALID_SLOT(&(flow_table[place]));
    updateFlowCounts(&(flow_table[place]));
    ip_memclr((uint8_t *)(&(flow_table[place])), sizeof(struct flow_entry));
    return &(flow_table[place]);
  }
#endif

  struct neigh_entry *getNeighEntry(cmpr_ip6_addr_t a) {
    int i;
    for (i = 0; i < N_NEIGH; i++) {
      if (neigh_table[i].neighbor == a)
        return &(neigh_table[i]);
    }
    return NULL;
  }

#ifdef CENTRALIZED_ROUTING
  cmpr_ip6_addr_t nextHop_Flow(struct f_entry *fEntry) {
    if (IS_VALID_ENTRY(*fEntry)) {
      if (IS_HOP_TYPE(*fEntry)) return fEntry->nextHop;
      return fEntry->pathE->path[0];
    }
    return T_INVAL_NEIGH;
  }

  struct flow_path *getNewFlowPath() {
    uint8_t i;
    for (i = 0; i < N_FULL_PATH_ENTRIES; i++) {
      if (full_path_entries[i].path_len == 0)
        return &(full_path_entries[i]);
    }
    return NULL;
  }
  
  error_t freeFullPath(struct flow_path* path) {
    path->path_len = 0;
    return SUCCESS;
  }

  void reverseFlowMatch(struct rinstall_header *orig, 
                        struct flow_match *reverse,
                        struct ip6_hdr *iph) {

    printfUART("reverseFlowMatch: %i %i\n", ntohs(iph->ip6_dst.s6_addr16[7]),
               ntohs(iph->ip6_src.s6_addr16[7]));

    if (orig->match.src == htons(T_INVAL_NEIGH))
      reverse->src = htons(T_INVAL_NEIGH);
    else
      reverse->src = iph->ip6_src.s6_addr16[7];

    if (orig->match.dest == htons(T_INVAL_NEIGH)) // Shouldn't happen
      reverse->dest = htons(T_INVAL_NEIGH);
    else
      reverse->dest = iph->ip6_dst.s6_addr16[7];
  }  
  
  /*
   * Function takes the set of choices within a single flow_entry slot and arranges
   *  them in order of addition/modification.
   *
   * @entry_index - The index of the entry that is being uninstalled, or moved to
   *  the top of the stack. (Set this to N_FLOW_CHOICES to indicate that a new
   *  entry is being installed).
   * @install - Whether an entry is being installed or moved to the top of the stack
   *
   * TODO: Implement explicit flow entry removal
   */
  void sortFlowEntries(struct flow_entry *target, uint8_t entry_index, bool install) {
    struct f_entry f_temp;
    uint8_t i;
   
    dbg("IPRouting", "sortFlowEntries: Index: 0x%x, Install: 0x%x\n", entry_index, install);

    if (install && (entry_index < N_FLOW_CHOICES)) {
      ip_memcpy(&f_temp, &(target->entries[entry_index]), sizeof(struct f_entry));
    }

    for (i = ((entry_index < N_FLOW_CHOICES)? (entry_index):(N_FLOW_CHOICES - 1)); i > 0; i--) {
      ip_memcpy(&(target->entries[i]), &(target->entries[i-1]), sizeof(struct f_entry));
    }

    if (install && (entry_index < N_FLOW_CHOICES))
      ip_memcpy(&(target->entries[0]), &f_temp, sizeof(struct f_entry));
    else
      ip_memclr((uint8_t *)(&(target->entries[0])), sizeof(struct f_entry));
  }

  void updateFlowCounts(struct flow_entry *target) {
    uint8_t i;
    if (target == NULL) return;
    dbg("IPRouting", "updateFlowCounts\n");
    
    // Just used or installed something
    if (IS_VALID_SLOT(target)) {
      for(i = 0; i < N_FLOW_ENT; i++) {
        if (!(IS_VALID_SLOT(&(flow_table[i])))) continue;
        if (flow_table[i].count < target->count) flow_table[i].count++;
      }
      target->count = 0;
    } else {
      for (i = 0; i < N_FLOW_ENT; i++) {
        if (!(IS_VALID_SLOT(&(flow_table[i])))) continue;
        if (flow_table[i].count > target->count) flow_table[i].count--;
      }
      target->count = N_FLOW_ENT;
    }
  }

  // Helper Functions
  error_t installEntry(struct ip6_hdr *iph, struct rinstall_header *rih, struct ip6_route *route) {
    struct flow_entry *entry;
    struct flow_match reverse_match;
    uint16_t current, path_len, 
      reverse = 0,
      fullPath = (rih->flags & HYDRO_INSTALL_METHOD_MASK) == HYDRO_METHOD_SOURCE;
    cmpr_ip6_addr_t *path;
    uint8_t i;

    // if this is a METHOD_SOURCE install, and the path is carried in
    // the routing header we must be on the far end of the install,
    // and so need to reverse everything.


    if (fullPath && rih->path_len == 0) reverse = 1;
    if (!fullPath) {
      printfUART("not fp, route: %p  rip: %i\n", route, rih->path_len);
      reverse = rih->flags & HYDRO_INSTALL_REVERSE;
      if (!reverse && route && route->segs_remain == 0 && rih->path_len == 0) return SUCCESS;
      if (reverse && rih->path_len > 0) return SUCCESS;
    }

    printfUART("install rev: %i fp: %i\n", reverse, fullPath)

    if (rih->path_len == 0) {
      if (route == NULL) return FAIL;
      current = ROUTE_NENTRIES(route) - route->segs_remain;
      path = route->hops;
      path_len = ROUTE_NENTRIES(route);
    } else {
      current = reverse ? rih->path_len - 1 : 0;
      path = rih->path;
      path_len = rih->path_len;
    }
    
    dbg("Install", "installEntry: flags: 0x%x\n", rih->flags);
    
    if (!reverse && 
        ((entry = getFlowEntry_Match(&(rih->match))) == NULL) && 
        ((entry = getNewEntry(&(rih->match))) == NULL)) {
      dbg("Install", "installEntry: forward path has no match and no room in flow table\n");
      return FAIL;
    } else if (reverse) {
      reverseFlowMatch(rih, &reverse_match, iph);
      if (((entry = getFlowEntry_Match(&(reverse_match))) == NULL) && 
          ((entry = getNewEntry(&(reverse_match))) == NULL)) {
        dbg("Install", "installEntry: reverse path has no match and no room in flow table\n");
        return FAIL;
       }
    }

    //Inefficient duplicate detection
    for (i = 0; i < N_FLOW_CHOICES; i++) {
      printfUART("checking dup %i %i\n", nextHop_Flow(&entry->entries[i]),
                 ntohs(path[reverse ? (current - 1) : current]));
      if (IS_VALID_ENTRY(entry->entries[i]) && 
          (nextHop_Flow(&entry->entries[i]) == 
           ntohs(path[reverse ? (current - 1) : current])) && 
          !fullPath) { 
        dbg("Install", "This choice already exists in flow table!\n");
        // Since order indicates order of arrival, need to move this one up higher
        if (i != 0) {
          sortFlowEntries(entry, i, TRUE);
        }
        return SUCCESS;
      }
      if (IS_VALID_ENTRY(entry->entries[i]) && IS_FULL_TYPE(entry->entries[i])) {
        dbg("Install", "Removing exiting source choice\n");
        entry->entries[0].pathE->path_len = 0;
        SET_INVALID_ENTRY(entry->entries[0]);        
      }
    }
    

    if (IS_VALID_ENTRY(entry->entries[0]))
      sortFlowEntries(entry, N_FLOW_CHOICES, TRUE);
    if (fullPath) {
      if ((entry->entries[0].pathE = getNewFlowPath()) == NULL) {
        dbg("Install", "No room available for new full path entry\n");
        return FAIL;
      }
      for (i = 0; i < path_len; i++) {
        entry->entries[0].pathE->path[i] = ntohs(path[(reverse ? (path_len - i - 1): i)]);
        dbg("Install", "Put node 0x%x as hop [%u]\n", entry->entries[0].pathE->path[i], (i));
      }
      entry->entries[0].pathE->path_len = path_len;
    } else {
      entry->entries[0].nextHop = ntohs(path[(reverse? (current - 1) : current)]);
      dbg("Install", "Put node 0x%x as next hop\n", entry->entries[0].nextHop);
    }
    SET_VALID_ENTRY((entry->entries[0]));
    SET_VALID_SLOT(entry);
    (fullPath? (SET_FULL_TYPE(entry->entries[0])) : (SET_HOP_TYPE(entry->entries[0])));
   
    updateFlowCounts(entry); 
    printTable();
    return SUCCESS;
  }

  error_t uninstallEntry(struct rinstall_header *rih) {
    struct flow_entry *entry;
    //struct neigh_entry *neigh;
    uint8_t i;

    // don't support reverse install
    if (rih->flags & HYDRO_INSTALL_REVERSE) return FAIL;
    // only work for source installs
    if ((rih->flags & HYDRO_INSTALL_METHOD_MASK) != HYDRO_METHOD_SOURCE) return FAIL;
    if ((entry = getFlowEntry_Match(&(rih->match))) == NULL)
      return FAIL;
    
    for (i = 0; i < N_FLOW_CHOICES; i++) {
      if (IS_VALID_ENTRY(entry->entries[i])) {
        SET_INVALID_ENTRY(entry->entries[i]);
        SET_INVALID_SLOT(entry);
        freeFullPath(entry->entries[i].pathE);
      }
    }
    return SUCCESS;
  }
#endif


  event void IPExtensions.handleExtensions(uint8_t label,
                                           struct ip6_hdr *iph,
                                           struct ip6_ext *hop,
                                           struct ip6_ext *dst,
                                           struct ip6_route *route,
                                           uint8_t nxt_hdr) {
#ifdef CENTRALIZED_ROUTING
    struct tlv_hdr *tlv = NULL;
    struct rinstall_header *rih;
    uint8_t method;
    bool forMe = call IPRouting.isForMe(iph), isHop = FALSE;

    printfUART("handling extension header!\n");

    if (dst != NULL) tlv = call IPExtensions.findTlv(dst, TLV_TYPE_INSTALL);
    if (tlv == NULL && hop != NULL) { tlv = call IPExtensions.findTlv(hop, TLV_TYPE_INSTALL); isHop = TRUE; }
    if (tlv == NULL) return;
    rih = (struct rinstall_header *)(tlv + 1);
    // first, install the entry if it's for me
    method = (rih->flags & HYDRO_INSTALL_METHOD_MASK);


    if (!forMe) {
      if (method == HYDRO_METHOD_HOP    && !isHop) return;
      if (method == HYDRO_METHOD_SOURCE) return;
    }
    if (!(rih->flags & HYDRO_INSTALL_UNINSTALL_MASK)) {
      installEntry(iph, rih, route);
    } else {
      // uninstall only returns
      uninstallEntry(rih);
      return;
    }

    if (method == HYDRO_METHOD_HOP && (rih->flags & HYDRO_INSTALL_REVERSE)) {
      // a little clunky, perhaps, but this is sort of how
      // installEntry expects things to work.
      rih->flags &= ~HYDRO_INSTALL_REVERSE;
      installEntry(iph, rih, route);
      rih->flags |= HYDRO_INSTALL_REVERSE;
    }

    if ( (forMe && rih->path_len > 0 && rih->path_len < 10) && 

         // if it's a source install, we don't need to generate a new
         // message unless the command is for us to also install the reverse path.
         ((method == HYDRO_METHOD_SOURCE &&
           rih->flags & HYDRO_INSTALL_REVERSE) ||
          // if it's a hop-by-hop install, we always need to generate a
          // new message to do the install.  however, only want this to
          // happen once, and since along the path the route install will be
          // carried as a hop-by-hop options, this check is sufficient.
          (method == HYDRO_METHOD_HOP && !isHop))) {
      
      // in either case the actual route to install must be in the
      // route install header
      uint16_t plen = sizeof(struct ip6_route) + (sizeof(cmpr_ip6_addr_t) * rih->path_len) +
        sizeof(struct ip6_ext) + sizeof(struct tlv_hdr) + 
        sizeof(struct rinstall_header);
      struct uint8_t *buf = ip_malloc(sizeof(struct split_ip_msg) + plen);
      struct split_ip_msg *ipmsg;
      struct ip6_ext   *newext;
      struct tlv_hdr   *newtlv;
      struct rinstall_header *newrih;
      struct ip6_route *iproute;
      printfUART("installing reverse path to 0x%x\n", rih->match.dest);

      if (buf == NULL) return;
      ip_memclr((void *)buf, sizeof(struct split_ip_msg) + plen);

      ipmsg = (struct split_ip_msg *)buf;
      newext = (struct ip6_ext *)(ipmsg + 1);
      newtlv = (struct tlv_hdr *)(newext + 1);
      newrih = (struct rinstall_header *)(newtlv + 1);
      iproute = (struct ip6_route *)(newrih + 1);
      
      ipmsg->hdr.nxt_hdr = (method == HYDRO_METHOD_SOURCE) ? IPV6_DEST : IPV6_HOP;
      ipmsg->hdr.plen = htons(plen);
      ipmsg->data = (uint8_t *)(ipmsg  + 1);
      ipmsg->data_len = plen;
      ipmsg->headers = NULL;
      call IPAddress.getIPAddr(&ipmsg->hdr.ip6_src);
      call IPAddress.getIPAddr(&ipmsg->hdr.ip6_dst);
      ipmsg->hdr.ip6_src.s6_addr16[7] = rih->match.dest;

      newext->nxt_hdr = IPV6_ROUTING;
      newext->len = sizeof(struct ip6_ext) + sizeof(struct tlv_hdr) + 
        sizeof(struct rinstall_header);
      newtlv->type = TLV_TYPE_INSTALL;
      newtlv->len = sizeof(struct tlv_hdr) + sizeof(struct rinstall_header);

      ip_memcpy(&newrih->match, &rih->match, sizeof(struct flow_match));
      newrih->flags = rih->flags;
      newrih->path_len = 0;

      iproute->nxt_hdr = IPV6_NONEXT;
      iproute->len = sizeof(struct ip6_route) + (sizeof(cmpr_ip6_addr_t) * rih->path_len);
      iproute->type = IP6ROUTE_TYPE_SOURCE;
      iproute->segs_remain = rih->path_len;
      ip_memcpy(iproute->hops, rih->path, sizeof(cmpr_ip6_addr_t) * rih->path_len);
      
      call TGenSend.bareSend(ipmsg, iproute, IP_NOHEADERS);
      ip_free(buf);
      // we should be all set up now.  
    }
#endif
  }

  
  uint16_t getConfidence(struct neigh_entry *neigh) {
    //uint8_t i;
    uint16_t conf = 0;
    if (neigh != NULL && IS_NEIGH_VALID(neigh)) {
      //for (i = 0; i < N_EPOCHS_COUNTED; i++) {
      //conf += neigh->stats[(current_epoch + N_EPOCHS - i) % N_EPOCHS].total;
        //}
      conf = neigh->stats[LONG_EPOCH].total;
    }
    return conf;
  }

  uint16_t getReceptions(struct neigh_entry *neigh) {
    //uint8_t i;
    uint16_t receptions = 0;
    if ((neigh != NULL) && (IS_NEIGH_VALID(neigh))) {
      //for (i = 0; i < N_EPOCHS_COUNTED; i++) {
      //receptions += neigh->stats[(current_epoch + N_EPOCHS - i) % N_EPOCHS].receptions;
        //}
      receptions += neigh->stats[receptions].receptions;
    }
    return receptions;
  }

  uint16_t getSuccess(struct neigh_entry *neigh) {
    //uint8_t i;
    uint16_t succ = 0;
    if ((neigh != NULL) && (IS_NEIGH_VALID(neigh))) {
      //for (i = 0; i < N_EPOCHS_COUNTED; i++) {
      //succ += neigh->stats[(current_epoch + N_EPOCHS - i) % N_EPOCHS].success;
      //}
      succ += neigh->stats[LONG_EPOCH].success;
    }
    return succ;
  }

  uint16_t getLinkCost(struct neigh_entry *neigh) {
    uint16_t conf, succ;
    conf = getConfidence(neigh);
    succ = getSuccess(neigh);
    // we can return a real confidence if we have enough data
    if (succ == 0 || conf == 0) return 0xff;
    return ((conf * 10) / succ);
  }
        

  void printTable() {
#ifdef PRINTFUART_ENABLED
    uint8_t i;
#ifdef CENTRALIZED_ROUTING
    uint8_t j, k;
#endif
    dbg("Table", "----------------------------------------___\n");
    dbg("Table", "ind\tvalid\tmature\tneigh\thops\tconf\trecep\tcost\tetx\tlqi\tmetric\n");
    for (i = 0; i < N_NEIGH; i++) {
      if (&neigh_table[i] == default_route)
        dbg("Table", "-- default --\n");
      dbg("Table", "0x%x\t0x%x\t0x%x\t0x%x\t0x%x\t0x%x\t0x%x\t0x%x\t0x%x\t0x%x\t0x%x\n", i, 
          (neigh_table[i].flags & T_VALID_MASK), (IS_MATURE(&(neigh_table[i]))),
          neigh_table[i].neighbor, neigh_table[i].hops, getConfidence(&(neigh_table[i])), 
          getReceptions(&(neigh_table[i])), neigh_table[i].costEstimate, 
          getLinkCost(&(neigh_table[i])), neigh_table[i].linkEstimate, 
          getMetric(&(neigh_table[i])));
    }
#ifdef CENTRALIZED_ROUTING
    dbg("Table", "------ Valid Flow Tables -------\n");
    dbg("Table", "valid\ttype\tnext\n");
    for (j = 0; j < N_FLOW_ENT; j++) {
      if (!(IS_VALID_SLOT(&(flow_table[j])))) continue;
      dbg("Table", "\n -- Flow Table Slot [%u] , Dest: [0x%x] , Count: [0x%x] --\n", 
          j, flow_table[j].match.dest, flow_table[j].count);
      for (i = 0; i < N_FLOW_CHOICES; i++) {
        if (IS_VALID_ENTRY(flow_table[j].entries[i]) && 
            IS_FULL_TYPE(flow_table[j].entries[i])) {
          dbg("Table", "0x%x\t0x%x\t", 
              IS_VALID_ENTRY(flow_table[j].entries[i]), 
              IS_FULL_TYPE(flow_table[j].entries[i]));
          for (k = 0; k < flow_table[j].entries[i].pathE->path_len; k++)
            dbg("Table", "0x%x\t", 
                flow_table[j].entries[i].pathE->path[k]);
          dbg("Table", "\n");
        } else {
          dbg("Table", "0x%x\t0x%x\t0x%x\n", 
              IS_VALID_ENTRY(flow_table[j].entries[i]), 
              IS_FULL_TYPE(flow_table[j].entries[i]),
              nextHop_Flow(&(flow_table[j].entries[i])));
        }
      }
    }
#endif
    dbg("Table", "----------------------------------------\n");
#endif
  }

  uint16_t getMetric(struct neigh_entry *r) {
    return (((r == NULL) || (!(IS_NEIGH_VALID(r)))) ? 
            0xffff : (r->costEstimate + getLinkCost(r)));
  }

  // Selects a potential neighbor that is not the current default route
  void chooseNewRandomDefault(bool force) {
    uint8_t i;
    uint8_t numNeigh = 0;
    uint8_t chosenNeigh;
    bool useHops = TRUE;

    dbg("IPRouting", "Looking for a new default route\n");
  retry:
    for (i = 1; i < N_NEIGH; i++) {
      if (!(IS_NEIGH_VALID(&(neigh_table[i])))) break;
      if (&neigh_table[i] == default_route) continue;
      if ((useHops && neigh_table[i].hops < neigh_table[0].hops) ||
          (!useHops && neigh_table[i].costEstimate < neigh_table[0].costEstimate)) {
        numNeigh++;
      }
    }

    // There exist other neighbors with respectable hop counts
    if (numNeigh) {
      chosenNeigh = (call Random.rand16()) % numNeigh;
      for (i = 1; i < N_NEIGH; i++) {
        if (&neigh_table[i] == default_route) continue;
        if ((useHops && neigh_table[i].hops < neigh_table[0].hops)
            || (!useHops && neigh_table[i].costEstimate < neigh_table[0].costEstimate)) {
          if (chosenNeigh) {
            chosenNeigh--;
          } else {
            default_route = &neigh_table[i];
            default_route_failures = 0;
            return;
          }
        }
      }
    }

    if (!force || !useHops) goto done;
    numNeigh = 0;
    useHops = FALSE;
  goto retry;

  done:
    dbg("IPRouting", "No random route found\n");
    default_route = &neigh_table[0];
    default_route_failures = 0;
  }
  /*
   * return: a send policy for a given attempt, including destination and one-hop neighbor.
   *        if no default route is available, returns FAIL unless the
   *        packet is destined to a link-local address, or a
   *        all-node/all-routers local multicast group.
   *
   */
  command error_t IPRouting.getNextHop(struct ip6_hdr   *hdr, 
                                       struct ip6_route *sh,
                                       ieee154_saddr_t prev_hop,
                                       send_policy_t *ret) {
    
    int i;
#ifdef CENTRALIZED_ROUTING
    struct flow_entry *r = getFlowEntry_Header(hdr);
#endif
    prev_hop = 0;
    ret->retries = BLIP_L2_RETRIES;
    ret->delay = (BLIP_L2_DELAY % (call Random.rand16())) + BLIP_L2_DELAY;
    ret->current = 0;
    ret->nchoices = 0;
 
/*     printfUART("determining next hop for message bound to: 0x%x (sh: %p)\n",  */
/*                ntohs(hdr->ip6_dst.s6_addr16[7]), sh); */

    if (sh != NULL) {
      printfUART(" type: 0x%x, next hop: 0x%x, remain: 0x%x\n",
          sh->type, ntohs(sh->hops[ROUTE_NENTRIES(sh) - sh->segs_remain]), sh->segs_remain);
    }


    // we only use the address in the source header if the record option is not used
    // otherwise, we use normal routing.
    if (sh != NULL && ((sh->type & ~IP6ROUTE_FLAG_MASK) == IP6ROUTE_TYPE_SOURCE)) {
      // if it's source routed, grab the next address out of the header.


      if (sh->segs_remain == 0) return FAIL;

      ret->dest[0] = ntohs(sh->hops[ROUTE_NENTRIES(sh) - sh->segs_remain]);
      ret->nchoices = 1;

    } else if (hdr->ip6_dst.s6_addr[0] == 0xff &&
               (hdr->ip6_dst.s6_addr[1] & 0xf) <= 0x03) {
      //hdr->dst_addr[0] == 0xff && (hdr->dst_addr[1] & 0xf) == 0x2) {
      // if it's multicast, for now, we send it to the local broadcast
      ret->dest[0] = 0xffff;
      ret->nchoices = 1;
      ret->retries = 0;
      ret->delay = 0;
      return SUCCESS;
    } else if (cmpPfx(hdr->ip6_dst.s6_addr, linklocal_prefix)) {
      ret->dest[0] = ntohs(hdr->ip6_dst.s6_addr16[7]); //  (hdr->dst_addr[14] << 8) | hdr->dst_addr[15];
      ret->nchoices = 1;
      return SUCCESS; // Currently only want one choice for broadcast
    } 

    if (getNeighEntry(ntohs(hdr->ip6_dst.s6_addr16[7])) != NULL) {
        dbg("IPRouting", "Directly adding next hop of dest: 0x%x\n", ntohs(hdr->ip6_dst.s6_addr16[7]));
        ret->dest[ret->nchoices++] = ntohs(hdr->ip6_dst.s6_addr16[7]);
    }
    
#ifdef CENTRALIZED_ROUTING
    if (r != NULL)
      updateFlowCounts(r);
     
    for (i = 0; i < N_FLOW_CHOICES; i++) {
      ieee154_saddr_t next_choice;
      if (r == NULL || 
          !IS_VALID_ENTRY(r->entries[i]) || 
          (IS_FULL_TYPE(r->entries[i]) && 
           r->entries[i].pathE->path_len > 1)) break;
      next_choice = nextHop_Flow(&(r->entries[i]));
      if (next_choice != prev_hop) {
        ret->dest[ret->nchoices++] = next_choice;
        dbg("Install", "Match: Neighbor 0x%x provided as choice 0x%x\n", 
            ret->dest[i], ret->nchoices - 1);
      }
    }
#endif

    //dbg("IPRouting", "flags: 0x%x neigh: 0x%x\n", r->flags, r->neighbor);
    if (IS_NEIGH_VALID(default_route) && prev_hop != default_route->neighbor) {
      ret->dest[ret->nchoices++] = default_route->neighbor;
    } else {
      dbg("IPRouting", "Invalid default route... quitting\n");
      /*
       * if we failed because the default route is invalid, we want to
       * trigger a routing update whenever we manage to reattach.
       */
      traffic_sent = FALSE;
      return FAIL;
    }
    i = 0;
    while (ret->nchoices < N_PARENT_CHOICES && i < N_NEIGH) {
      if (IS_NEIGH_VALID(&neigh_table[i]) &&
          &neigh_table[i] != default_route &&
          neigh_table[i].neighbor != prev_hop) {
        ret->dest[ret->nchoices++] = neigh_table[i].neighbor;
      }
      i++;
    }
    
    if (ret->nchoices == 0)
      return FAIL;
    
    dbg("IPRouting", "getNextHop: nchoices: 0x%x\n", ret->nchoices);
    
    return SUCCESS;
  }

  command uint8_t IPRouting.getHopLimit() {
    // advertise our best path to the root
    if (IS_NEIGH_VALID(&(neigh_table[0])))// && IS_MATURE(&neigh_table[0]))
      return neigh_table[0].hops + 1;
    else return 0xf0;
  }

  command uint16_t IPRouting.getQuality() {
    if (IS_NEIGH_VALID(&(neigh_table[0])))
      return getMetric(&(neigh_table[0]));
    else return 0xffff;
  }

  
  /*
   * An advertisement was received from a neighboring node
   *
   * Processing steps:
   * 1) First must check to see if the neighbor already exists in the table
   *  a) If so, we are just updating its information
   * 2) If not in table, check to make sure that the lqi passes the low-filter bar.
   *  a) If not, return
   * 3) If there is an empty space
   *  a) Insert it in the open space
   *  b) (Do we then want to move it up to where it belongs based on total path cost?)
   * 4) If there is no open space
   *  a) If the last entry doesn't meet the confidence threshold (CONF_EVICT_THRESHOLD), do nothing
   *  b) Otherwise, replace last entry if:
   *    i) Advertised Path Cost difference is greater than PATH_COST_DIFF_THRESH
   *    ii) Advertised Path Cost difference is within PATH_COST_DIFF_THRESH, 
   *         and Link estimate is lower by at least LQI_DIFF_THRESH
   * 5) Make sure to update the receptions statistic
   */ 
  command void IPRouting.reportAdvertisement(ieee154_saddr_t neigh, uint8_t hops, 
                                             uint8_t lqi, uint16_t cost) {
    //int i, place = N_NEIGH;
    //bool mustInsert = FALSE, exists = FALSE;
    //uint8_t maxCost = 0;
    //bool recount = FALSE;
    struct neigh_entry *neigh_slot =  NULL;
    dbg("IPRouting", "report adv: 0x%x 0x%x 0x%x 0x%x\n", neigh, hops, lqi, cost);
    dbg("IPRouting", "my Cost: 0x%x\n", getMetric(&(neigh_table[0])));
   
    // If neighbor does not exist in table 
    if ((neigh_slot = getNeighEntry(neigh)) == NULL) {
      dbg("IPRouting", "Advertisement from new neighbor 0x%x!\n", neigh);
      if (adjustLQI(lqi) > LQI_ADMIT_THRESH || cost == 0xffff) {
        dbg("IPRouting", "Poor Link.  Rejecting\n");
        return;
      }
      // free spots in the table.
      if(!(IS_NEIGH_VALID(&(neigh_table[N_NEIGH - 1])))) {
        
        dbg("IPRouting", "Neighbor being inserted in empty slot: 0x%x\n", N_NEIGH - 1);
        for (neigh_slot = &(neigh_table[N_NEIGH - 1]); 
             neigh_slot > &(neigh_table[0]); neigh_slot--) {
          // we might go ahead of other neighbors if we haven't heard
          // from them either and our cost is better.
          if (IS_NEIGH_VALID(neigh_slot - 1) &&
              getConfidence(neigh_slot - 1) == 0 &&
              (((struct neigh_entry *)(neigh_slot - 1))->costEstimate > cost)) {
            swapNodes((neigh_slot - 1), neigh_slot);
          } else if (IS_NEIGH_VALID(neigh_slot - 1)) {
            // if we didn't catch on the first check and the next
            // highest guy in the table is valid, we'll just go at the
            // end.  If this never catches, the loop will terminate
            // with neigh_slot == &neigh_table[0].
            break;
          }
        }
        ip_memclr((void *)neigh_slot, sizeof(struct neigh_entry));
      } else {
        // evict the bottom guy?
        dbg("IPRouting", "No empty slots...looking to replace bottom entry\n");
        //if (getConfidence(&(neigh_table[N_NEIGH - 1])) >= CONF_EVICT_THRESHOLD) {
        if (IS_MATURE(&(neigh_table[N_NEIGH - 1])) ||
            hops <= neigh_table[N_NEIGH - 1].hops) {
          dbg("IPRouting", "Bottom entry evictable\n");
          // we're a lot better,
          if ((checkThresh(neigh_table[N_NEIGH - 1].costEstimate, cost, 
                           PATH_COST_DIFF_THRESH) == BELOW_THRESH) || 
              // or we're about equal and the link estimate is better
              ((checkThresh(neigh_table[N_NEIGH - 1].costEstimate, cost, 
                            PATH_COST_DIFF_THRESH) == WITHIN_THRESH) && 
               (checkThresh(neigh_table[N_NEIGH - 1].linkEstimate, adjustLQI(lqi), 
                            LQI_DIFF_THRESH) == BELOW_THRESH))) {
            dbg("Evictions", "evict: bottom entry\n");

            // use evict to correctly handle the case when we evict
            // the default route.
            evictNeighbor(&neigh_table[N_NEIGH - 1]);
            neigh_slot = &(neigh_table[N_NEIGH - 1]);
          }
        }
      }
    } else {
      if (cost == 0xffff) {
        dbg("Evictions", "evict with cost 0xffff\n");
        evictNeighbor(neigh_slot);
        return;
      }
      // Do this to prevent double counting because of reportReception
      neigh_slot->stats[SHORT_EPOCH].receptions--; 
    }
      
    if (neigh_slot != NULL) {
      SET_NEIGH_VALID(neigh_slot);
      neigh_slot->neighbor = neigh;
      neigh_slot->hops = hops;
      neigh_slot->costEstimate = cost;
      neigh_slot->linkEstimate = adjustLQI(lqi);
      neigh_slot->stats[SHORT_EPOCH].receptions++;
      dbg("IPRouting", "currentEpoch: 0x%x, Receptions in epoch: 0x%x, Total Receptions: 0x%x\n", 
                 SHORT_EPOCH, neigh_slot->stats[SHORT_EPOCH].receptions, getReceptions(neigh_slot));
    }
    printTable();
  }

  /*
   * Reports packet reception
   *
   * Updates the link estimate, as well as the number of receptions
   */
  command void IPRouting.reportReception(ieee154_saddr_t neigh, uint8_t lqi) {
    struct neigh_entry *e = getNeighEntry(neigh);
    dbg("IPRouting", "Packet received from 0x%x lqi: %u\n", neigh, lqi);
    //if (e == NULL) e = addNeighEntry(neigh);
    if (e != NULL) {
      e->linkEstimate = adjustLQI(lqi);
      // e->stats[current_epoch].receptions++;
      //if (e == &(neigh_table[0]))
        //resetNeighLow();
      //else if (getMetric(e) < getMetric(&(neigh_table[0]))) {
        //sortFlowTable();
        //resetNeighLow();
      //}
    }
  }

  // Updates success (and failure) statistics
  // Also needs to reroute if the number of failures hits the threshold 
  event void IPExtensions.reportTransmission(uint8_t label, send_policy_t *policy) {
    int i;
    struct neigh_entry *e = NULL;
    
    // If not a broadcast address:
    //  1. If none of the provided addresses worked, then we should send out a solicitation
    //  2. All the failed nodes should have their totals increased by the max number of retries
    //  3. The successful node should update both its total and success by one
    //  4. If the successful node meets one of the following two conditions, it should be moved up one spot:
    //   a) It has a lower path cost and higher confidence than the above entry
    //   b) It has a similar path cost and confidence above a threshold (CONF_PROM_THRESHOLD)
    //  5. If we have had too many consecutive losses (MAX_CONSEC_FAILURES) toggle ReRouting
    if (policy->dest[0] != IEEE154_BROADCAST_ADDR) {
      // BLIP_STATS_INCR(stats.messages);
      dbg("IPRouting", "reportTransmission: current: 0x%x, nchoices: 0x%x, retries: 0x%x\n", 
                 policy->current, policy->nchoices, policy->actRetries); 

      // update the failed neighbor statistics
      for (i = 0; i < policy->current; i++) {
        e = getNeighEntry(policy->dest[i]);
        if (e != NULL) {
          // SDH : presumably retries == actRetries
          e->stats[SHORT_EPOCH].total += policy->retries;
          
          if (e == default_route) {
            default_route_failures++;
          }

          dbg("IPRouting", "reportTransmissions: 0x%x failed\n", e->neighbor);

          // stats.transmissions += policy->retries;
        }
      }

      if (default_route_failures > MAX_CONSEC_FAILURES) {
        dbg("IPRouting", "Too many consecutive failures!\n");
        chooseNewRandomDefault(TRUE);
      }
      
      // if we succeeded sending the packet, increment the success on that one.
      e = getNeighEntry(policy->dest[policy->current]);
      if ((policy->current < policy->nchoices) && e != NULL) {
        e->stats[SHORT_EPOCH].success += 1;
        e->stats[SHORT_EPOCH].total += policy->actRetries;

        dbg("IPRouting", "Success: 0x%x, Total: 0x%x, ETX: 0x%x (addr 0x%x)\n", 
                   getSuccess(e), getConfidence(e), getLinkCost(e), e->neighbor);
        dbg("IPRouting", "Actual attempts was 0x%x\n", policy->actRetries);

        if (e == default_route)
          default_route_failures++;


        if ((e != &(neigh_table[0])) && 
            // we have higher confidence and lower cost
            (((getConfidence(e) > CONF_PROM_THRESHOLD) && // getConfidence(e - 1)) && 
              (checkThresh(getMetric(e), getMetric(e-1), PATH_COST_DIFF_THRESH) == BELOW_THRESH)) || 
             // we have similar cost and sufficient confidenceIP
             ((checkThresh(getMetric(e), getMetric(e-1), PATH_COST_DIFF_THRESH) == WITHIN_THRESH) && 
              (getConfidence(e) > CONF_PROM_THRESHOLD)))) {

          dbg("IPRouting", "Promoting node 0x%x over node 0x%x\n", e->neighbor, (e-1)->neighbor);
          swapNodes((e - 1), e);
        }

        // stats.successes += 1;
        // stats.transmissions += policy->actRetries;
      } else {
        dbg("IPRouting", "FAILURE!!!!!\n");
      }
    }
  }

  /*
   * @returns TRUE if the routing engine has established a default route.
   */
  command bool IPRouting.hasRoute() {    
    return (IS_NEIGH_VALID(&(neigh_table[0])));
  }

  struct ip6_route *insertSourceHeader(struct split_ip_msg *msg, struct flow_entry *entry) {
    // these actually need to be static
    static uint8_t source_buf[sizeof(struct ip6_route) + MAX_PATH_LENGTH * sizeof(uint16_t)];
    static struct generic_header g_sh;
    struct ip6_route *sh = (struct ip6_route *)source_buf;
    uint8_t i;

    sh->nxt_hdr = msg->hdr.nxt_hdr;
    msg->hdr.nxt_hdr = IPV6_ROUTING;

    sh->len = sizeof(struct ip6_route) + entry->entries[0].pathE->path_len * sizeof(uint16_t);
    sh->type = IP6ROUTE_TYPE_SOURCE;
    sh->segs_remain = entry->entries[0].pathE->path_len;

    g_sh.hdr.ext = (struct ip6_ext *)sh;
    g_sh.len = sh->len;
    g_sh.next = msg->headers;
    msg->headers = &g_sh;

    dbg("Install", "Inserted source header with length 0x%x and next hop: 0x%x\n", 
        entry->entries[0].pathE->path_len, entry->entries[0].pathE->path[0]);

    for (i = 0; i < entry->entries[0].pathE->path_len; i++) {
      sh->hops[i] = ntohs(entry->entries[0].pathE->path[i]);
    }
    return sh;
  }

#ifdef CENTRALIZED_ROUTING
  command void IPRouting.clearFlows() {
    int i, j;
    for (i = 0; i < N_FLOW_ENT; i++) {
      SET_INVALID_SLOT((&(flow_table[i])));
      flow_table[i].count = N_FLOW_ENT;
      for (j = 0; j < N_FLOW_CHOICES; j++) {
        SET_INVALID_ENTRY(flow_table[i].entries[j]);
      }
    }

    for (i = 0; i < N_FULL_PATH_ENTRIES; i++) {
      full_path_entries[i].path_len = 0;
    }
  }
#endif

#define convertTo8(X)  ((X) > 0xff ? 0xff : (X))

  /*
   * Inserts all necessary routing headers for the packet
   * 
   * If packet is going to the root, inserts a topology information
   *  collection header
   *  XXX : SDH : the detection of weather it's going to the root is 
   *              very broken...
   *
   */

  event struct tlv_hdr *DestinationExt.getHeader(int label,int nxt_hdr,
                                                 struct ip6_hdr *iph) {
    static uint8_t sh_buf[sizeof(struct tlv_hdr) + 
                          sizeof(struct topology_header) +
                          (sizeof(struct topology_entry) * N_NEIGH)];
    struct tlv_hdr *tlv =    (struct tlv_hdr *)sh_buf;
    struct topology_header *th = (struct topology_header *)(tlv + 1);

    tlv->len = sizeof(struct tlv_hdr) + sizeof(struct topology_header);
    tlv->type = TLV_TYPE_TOPOLOGY;

    if (iph->ip6_dst.s6_addr[0] == 0xff &&
        (iph->ip6_dst.s6_addr[1] & 0xf) <= 3) {
      return NULL;
    }

    printfUART("inserting destination options header\n");

    // AT: We theoretically only want to attach this topology header if we're
    //  sending this message to a controller.  Isn't it easier to just check
    //  to see if the dest address matches that of the sink?
    // SDH: how do you know what the address of the sink is?  
    // some how we need to check if we're using a default route and
    // only attach the topology information if we are.  This still isn't
    // perfect since somebody further down the tree may have a route and the
    // packet might not get to the controller.
    if (iph->nxt_hdr == IANA_UDP || 
        iph->nxt_hdr == IPV6_NONEXT) {
      int i,j = 0;
      if (iph->ip6_dst.s6_addr16[0] == htons(0xff02)) return NULL;
      if (traffic_sent) return NULL;
      
      traffic_sent = TRUE;

      // only add topology information directly behind actual payload
      // headers.
      // SDH : TODO : check that this will not fragment the packet...
      // AT: Why do we care about the number of hops? Debugging purposes?
      th->seqno = reportSeqno++;
      th->seqno = htons(th->seqno);

      // For all these 16-bit values, we're only using 8 bit values
      for (i = 0; i < N_NEIGH; i++) {
        if (IS_NEIGH_VALID(&neigh_table[i]) && j < 4 && 
            (IS_MATURE(&neigh_table[i]) || default_route == &neigh_table[i])) {
          th->topo[j].etx = convertTo8(getLinkCost(&neigh_table[i]));
          th->topo[j].conf = convertTo8(getConfidence(&neigh_table[i]));
          th->topo[j].hwaddr = htons(neigh_table[i].neighbor);
          j++;
          tlv->len += sizeof(struct topology_entry);
          dbg("Lqi", "link est: 0x%x hops: 0x%x\n", 
              neigh_table[i].linkEstimate, neigh_table[i].hops);
        }
      }
      if (j > 0) {
        return tlv;
      }
    }
    return NULL;
  }

  event void DestinationExt.free() {

  }

  command struct ip6_route *IPRouting.insertRoutingHeader(struct split_ip_msg *msg) {
    // these actually need to be static
#ifdef CENTRALIZED_ROUTING
    struct flow_entry *entry;

    // Need to source route this packet
    //  Put this last because theoretically we could have a source
    //  routed packet to the root, in which case it would have a topo
    //  header, but the source header must always be the first in the
    //  header list
    if (((entry = getFlowEntry_Header(&msg->hdr)) != NULL) &&
        IS_FULL_TYPE(entry->entries[0]) &&
        entry->entries[0].pathE->path_len > 1) {
      dbg("IPRouting", "Inserting a source routing header for a full path!\n");
      updateFlowCounts(entry);
      return insertSourceHeader(msg, entry);
    }

#endif
    return NULL;
  }

  /*
   * Sort timer will no longer be used only for sorting, but rather to expire an epoch and
   *  change entry statistics
   */
  event void SortTimer.fired() {
    dbg("IPRouting", "Epoch ended!\n");
    printTable();

    if (!call IPRouting.hasRoute() && !soliciting) {
      call ICMP.sendSolicitations();
      soliciting = TRUE;
    }

    if (checkThresh(call IPRouting.getQuality(), last_qual, 5) != WITHIN_THRESH ||
        last_hops != call IPRouting.getHopLimit()) {
      call ICMP.sendAdvertisements();
      last_qual = call IPRouting.getQuality();
      last_hops = call IPRouting.getHopLimit();
    }

    updateRankings();

    if (call Random.rand16() % 32 < 8) {
      dbg("IPRouting", "Attemting exploration\n");
      chooseNewRandomDefault(FALSE);
    } else {
      // default_route = &neigh_table[0];
      default_route_failures = 0;
    }
  }

  
  /*
   * This is called when the ICMP engine finishes sending out router solicitations.
   *
   * We will keep sending solicitations so long as we have not
   * established a default route.
   *
   */
  event void ICMP.solicitationDone() {
    //int i;

    dbg("IPRouting", "done soliciting\n");

    soliciting = FALSE;

    if (!call IPRouting.hasRoute()) {
      call ICMP.sendSolicitations();
      soliciting = TRUE;
    }
  }

  command void Statistics.get(route_statistics_t *statistics) {
    //struct neigh_entry *p = getNeighEntry((getFlowEntry_Header(NULL))->entries[0].nextHop);
    // struct neigh_entry *p = &(neigh_table[0]);
    // stats.hop_limit = call IPRouting.getHopLimit();
//    if (p != NULL) {
//      ip_memcpy(&stats.parent, p, sizeof(struct neigh_entry));
      // stats.parentmetric = getMetric(p);
//    }
    statistics->hop_limit = call IPRouting.getHopLimit();
    statistics->parent = (uint16_t) default_route->neighbor; 
    statistics->parent_metric = call IPRouting.getQuality(); 
    statistics->parent_etx = getMetric(default_route);
  }

  command void Statistics.clear() {
    // ip_memclr((uint8_t *)&stats, sizeof(route_statistics_t));
  }

  void evictNeighbor(struct neigh_entry *neigh) {
    struct neigh_entry *iterator;
    bool reset_default = FALSE;

    dbg("IPRouting", "Evicting neighbor 0x%x\n", neigh->neighbor);
    dbg("Evictions", "evict: 0x%x\n", neigh->neighbor);

    SET_NEIGH_INVALID(neigh);

    if (neigh == default_route) {
      reset_default = TRUE;
    }

    ip_memclr((uint8_t *)(neigh), sizeof(struct neigh_entry));
    for (iterator = neigh; iterator < &(neigh_table[N_NEIGH - 1]); iterator++) {
      if (!IS_NEIGH_VALID(iterator + 1)) break;
      swapNodes(iterator, iterator + 1);
    }

    if (reset_default) {
      // send new topology updates quickly to let an edge router know
      // that something happened.
      restartTrafficGen();
      default_route = &neigh_table[0];
      default_route_failures = 0;
    }

    printTable();
  }

  // Typically called after an epoch change
  void updateRankings() {
    uint8_t i;
    bool evicted = FALSE;

    for (i = 0; i < N_NEIGH; i++) {
      UNSET_EVICT(neigh_table[i]);
      if (!IS_NEIGH_VALID(&neigh_table[i])) continue;
      neigh_table[i].stats[LONG_EPOCH].total += neigh_table[i].stats[SHORT_EPOCH].total;
      neigh_table[i].stats[LONG_EPOCH].receptions += neigh_table[i].stats[SHORT_EPOCH].receptions;
      neigh_table[i].stats[LONG_EPOCH].success += neigh_table[i].stats[SHORT_EPOCH].success;
      
      if (neigh_table[i].stats[LONG_EPOCH].total & (0xf000)) {
        // if we're this big, the etx computation might overflow.
        // Make it smaller by dividing top and bottom by 2.
        neigh_table[i].stats[LONG_EPOCH].total >>= 1;
        neigh_table[i].stats[LONG_EPOCH].success >>= 1;
      }
      
      if (neigh_table[i].stats[LONG_EPOCH].total > CONF_EVICT_THRESHOLD) 
        SET_MATURE(&neigh_table[i]);

      if (IS_MATURE(&(neigh_table[i]))) {
        uint16_t cost;
        // if we didn't try the link, don't evict it            
        if (neigh_table[i].stats[SHORT_EPOCH].total == 0) goto done_iter;
        if (neigh_table[i].stats[SHORT_EPOCH].success == 0) {
          cost = 0xff;
        } else {
          cost = (10 * neigh_table[i].stats[SHORT_EPOCH].total) / 
            neigh_table[i].stats[SHORT_EPOCH].success;
        }
        if (cost > LINK_EVICT_THRESH) {
          dbg("Evictions", "cost: 0x%x, slot %i\n", cost, i);
          SET_EVICT(neigh_table[i]);
        }
      }
    done_iter:
      neigh_table[i].stats[SHORT_EPOCH].total = 0;
      neigh_table[i].stats[SHORT_EPOCH].receptions = 0;
      neigh_table[i].stats[SHORT_EPOCH].success = 0;
    }
    for (i = 0; i < N_NEIGH; i++) {
      if (IS_NEIGH_VALID(&neigh_table[i]) &&
          SHOULD_EVICT(neigh_table[i])) {
// #if 0
        // SDH : because of the overflow bug, this was never being
        // triggered.  I'm not sure it's actually a good idea because
        // it seems to increase path lengths for heavily used routes.
        // Let's disable it for now.
        dbg("Evictions", "performing evict: %i\n", i);
        evictNeighbor(&neigh_table[i]);
        i --;
// #endif
        evicted = TRUE;
      }
    }
    if (evicted)
      call ICMP.sendSolicitations();
  }

  void swapNodes(struct neigh_entry *highNode, struct neigh_entry *lowNode) {
    struct neigh_entry tempNode;
    if (highNode == NULL || lowNode == NULL) return;
    ip_memcpy(&tempNode, highNode, sizeof(struct neigh_entry));
    ip_memcpy(highNode, lowNode, sizeof(struct neigh_entry));
    ip_memcpy(lowNode, &tempNode, sizeof(struct neigh_entry));

    if (highNode == default_route) default_route = lowNode;
    else if (lowNode == default_route) default_route = highNode;
  }

  uint8_t checkThresh(uint32_t firstVal, uint32_t secondVal, uint16_t thresh) {
    if (((firstVal > secondVal) && ((firstVal - secondVal) <= thresh)) || 
        ((secondVal >= firstVal) && (secondVal - firstVal) <= thresh)) return WITHIN_THRESH;
    if (((firstVal > secondVal) && ((firstVal - secondVal) > thresh))) return ABOVE_THRESH;
    return BELOW_THRESH;
  }
}
