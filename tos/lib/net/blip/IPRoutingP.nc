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
  uses interface ICMP;
  uses interface Boot;
  uses interface IPAddress;
  uses interface Random;

  uses interface Timer<TMilli> as SortTimer;

  uses interface IP as TGenSend;
  uses interface Timer<TMilli> as TrafficGenTimer;

  uses interface Leds;

} implementation {

  enum {
    SHORT_EPOCH = 0,
    LONG_EPOCH = 1,
  };

  //uint16_t current_epoch;
  //route_statistics_t stats;
  uint16_t last_qual;
  uint8_t last_hops;

  uint8_t num_low_neigh;

  bool soliciting;

  // pointer into the neighbor table of the current entry that is our
  // first choice.
  struct neigh_entry *default_route;
  uint16_t default_route_failures;

  uint32_t traffic_interval;
  bool traffic_sent;

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
    int j;
    for (j = 0; j < N_EPOCHS; j++) {
      r->stats[j].total   = 0;
      r->stats[j].success = 0;
      r->stats[j].receptions = 0;
    }
  }

  void clearEpoch(uint8_t target_epoch) {
    int i;
    for (i = 0; i < N_NEIGH; i++) {
      neigh_table[i].stats[target_epoch].total = 0;
      neigh_table[i].stats[target_epoch].success = 0;
      neigh_table[i].stats[target_epoch].receptions = 0;
    }
  }

  cmpr_ip6_addr_t shortenAddr(ip6_addr_t addr) {
    cmpr_ip6_addr_t shortAddr;
    ip_memcpy(&shortAddr, &addr[14],2);
    return shortAddr;
  } 

  void restartTrafficGen() {
    traffic_interval = TGEN_BASE_TIME;
    // jitter the period by 10% to prevent synchronization
    traffic_interval += (call Random.rand16()) % (TGEN_BASE_TIME);
    if (call TrafficGenTimer.isRunning())
      call TrafficGenTimer.stop();

    call TrafficGenTimer.startOneShot(traffic_interval);
  }

  event void TrafficGenTimer.fired() {
    struct split_ip_msg *msg;
    if (traffic_sent) goto done;
    msg = (struct split_ip_msg *)ip_malloc(sizeof(struct split_ip_msg));
    if (msg == NULL) goto done;

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

  event void Boot.booted() {
    int i;

    for (i = 0; i < N_NEIGH; i++) {
      neigh_table[i].flags = 0;
      clearStats(&neigh_table[i]);
    }

    // current_epoch = 0;
    soliciting = FALSE;
    //reRouting = FALSE;
    default_route_failures = 0;
    default_route = &neigh_table[0];
    // boot with this true so the router will invalidate any state
    // associated from us when it gets the first packet.
    last_qual = 0xffff;
    last_hops = 0xff;
    num_low_neigh = 0;
    call Statistics.clear();
    call SortTimer.startPeriodic(1024L * 60);

    traffic_sent = FALSE;
    restartTrafficGen();
  }
  
  command bool IPRouting.isForMe(struct ip6_hdr *hdr) {
    // the destination prefix is either link-local or global, or
    // multicast (we accept all multicast packets), and the suffix is
    // me.
    struct in6_addr *my_address = call IPAddress.getPublicAddr();
    return (((cmpPfx(my_address->s6_addr, hdr->ip6_dst.s6_addr) || 
              cmpPfx(linklocal_prefix, hdr->ip6_dst.s6_addr)) 
             && cmpPfx(&my_address->s6_addr[8], &hdr->ip6_dst.s6_addr[8])) 
            || cmpPfx(multicast_prefix, hdr->ip6_dst.s6_addr));
  }


  struct neigh_entry *getNeighEntry(cmpr_ip6_addr_t a) {
    int i;
    for (i = 0; i < N_NEIGH; i++) {
      if (neigh_table[i].neighbor == a)
        return &(neigh_table[i]);
    }
    return NULL;
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

    dbg("IPRouting", "Looking for a new default route\n");

    for (i = 1; i < N_NEIGH; i++) {
      if (!(IS_NEIGH_VALID(&(neigh_table[i])))) break;
      if (&neigh_table[i] == default_route) continue;
      if (neigh_table[i].hops < neigh_table[0].hops) 
        numNeigh++;
    }

    // There exist other neighbors with respectable hop counts
    if (numNeigh) {
      chosenNeigh = (call Random.rand16()) % numNeigh;
      for (i = 1; i < N_NEIGH; i++) {
        if (&neigh_table[i] == default_route) continue;
        if (neigh_table[i].hops < neigh_table[0].hops) {
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

    if (!force) goto done;

    numNeigh = 0;
    for (i = 1; i < N_NEIGH; i++) {
      if (!(IS_NEIGH_VALID(&(neigh_table[i])))) break;
      if (&neigh_table[i] == default_route) continue;
      if (neigh_table[i].costEstimate < neigh_table[0].costEstimate)
        numNeigh++;
    }

    if (numNeigh) {
      chosenNeigh = (call Random.rand16()) % numNeigh;
      for (i = 1; i < N_NEIGH; i++) {
        if (&neigh_table[i] == default_route) continue;
        //if (neigh_table[i].costEstimate < getMetric(&(neigh_table[0]))) {
        if (neigh_table[i].costEstimate < neigh_table[0].costEstimate) {
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
  command error_t IPRouting.getNextHop(struct ip6_hdr *hdr, 
                                       struct source_header *sh,
                                       hw_addr_t prev_hop,
                                       send_policy_t *ret) {
    
    int i;
    prev_hop = 0;
    ret->retries = 10;
    ret->delay = 30;
    ret->current = 0;
    ret->nchoices = 0;
 

    // we only use the address in the source header if the record option is not used
    // otherwise, we use normal routing.
    if (hdr->nxt_hdr == NXTHDR_SOURCE && 
        (sh->dispatch & IP_EXT_SOURCE_RECORD_MASK) != IP_EXT_SOURCE_RECORD && 
        (sh->dispatch & IP_EXT_SOURCE_INVAL) != IP_EXT_SOURCE_INVAL) {
      // if it's source routed, grab the next address out of the header.

      // if (sh->current == sh->nentries) return FAIL;

      ret->dest[0] = ntohs(sh->hops[sh->current]);
      ret->nchoices = 1;

      dbg("IPRouting", "source dispatch: 0x%x, next hop: 0x%x, current: 0x%x\n", 
                 sh->dispatch, ntohs(sh->hops[sh->current]), sh->current);

    } else if (hdr->ip6_dst.s6_addr16[0] == htons(0xff02)) {
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
      //     if (getNeighEntry(ntohs(shortenAddr(hdr->dst_addr))) != NULL) {
      //       dbg("IPRouting", "Directly adding next hop of dest: 0x%x\n", ntohs(shortenAddr(hdr->dst_addr)));
      //       ret->dest[ret->nchoices++] = ntohs(shortenAddr(hdr->dst_addr));
      //     }
    
    
    //dbg("IPRouting", "flags: 0x%x neigh: 0x%x\n", r->flags, r->neighbor);
    if (IS_NEIGH_VALID(default_route) && prev_hop != default_route->neighbor) {
      ret->dest[ret->nchoices++] = default_route->neighbor;
    } else {
      dbg("IPRouting", "Invalid default route... quitting\n");
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
  command void IPRouting.reportAdvertisement(hw_addr_t neigh, uint8_t hops, 
                                             uint8_t lqi, uint16_t cost) {
    //int i, place = N_NEIGH;
    //bool mustInsert = FALSE, exists = FALSE;
    //uint8_t maxCost = 0;
    //bool recount = FALSE;
    struct neigh_entry *neigh_slot =  NULL;
    dbg("IPRouting", "report adv: 0x%x 0x%x 0x%x 0x%x\n", neigh, hops, lqi, cost);
    dbg("IPRouting", "my Cost: 0x%x, num_low_neigh: 0x%x, N_LOW_NEIGH: 0x%x\n", 
               getMetric(&(neigh_table[0])), num_low_neigh, N_LOW_NEIGH);
   
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
  command void IPRouting.reportReception(hw_addr_t neigh, uint8_t lqi) {
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
  command void IPRouting.reportTransmission(send_policy_t *policy) {
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
    if (policy->dest[0] != HW_BROADCAST_ADDR) {
      // stats.messages++;
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

  void insertSourceHeader(struct split_ip_msg *msg, struct flow_entry *entry) {
    // these actually need to be static
    static uint8_t source_buf[sizeof(struct source_header) + MAX_PATH_LENGTH * sizeof(uint16_t)];
    static struct generic_header g_sh;
    struct source_header *sh = (struct source_header *)source_buf;
    uint8_t i;

    sh->len = sizeof(struct source_header) + entry->entries[0].pathE->path_len * sizeof(uint16_t);
    sh->current = 0;
    sh->dispatch = IP_EXT_SOURCE_DISPATCH;
    sh->nxt_hdr = msg->hdr.nxt_hdr;
    msg->hdr.nxt_hdr = NXTHDR_SOURCE;
    g_sh.hdr.ext = (struct ip6_ext *)sh;
    g_sh.len = sh->len;
    g_sh.next = msg->headers;
    msg->headers = &g_sh;

    dbg("Install", "Inserted source header with length 0x%x and next hop: 0x%x and dispatch 0x%x\n", 
        entry->entries[0].pathE->path_len, entry->entries[0].pathE->path[0], sh->dispatch);

    for (i = 0; i < entry->entries[0].pathE->path_len; i++) {
      sh->hops[i] = ntohs(entry->entries[0].pathE->path[i]);
    }
  }

  uint8_t convertTo8(uint16_t target) {
    if (target > 0xFF)
      return 0xFF;
    return target;
  }

#ifdef DBG_TRACK_FLOWS
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

  /*
   * Inserts all necessary routing headers for the packet
   * 
   * If packet is going to the root, inserts a topology information
   *  collection header
   *
   * AT: Should move source-routing header insertion to another function
   *  to avoid unnecessary allocation of buffer space
   */
  command void IPRouting.insertRoutingHeaders(struct split_ip_msg *msg) {
    // these actually need to be static
    static uint8_t sh_buf[sizeof(struct topology_header) + 
                          (sizeof(struct topology_entry) * N_NEIGH)];
    static struct generic_header record_route;
    struct topology_header *th = (struct topology_header *)sh_buf;
    int i, j = 0;

    // AT: We theoretically only want to attach this topology header if we're
    //  sending this message to a controller.  Isn't it easier to just check
    //  to see if the dest address matches that of the sink?
    // SDH: how do you know what the address of the sink is?  
    if (msg->hdr.nxt_hdr == IANA_UDP || msg->hdr.nxt_hdr == NXTHDR_UNKNOWN) {
      traffic_sent = TRUE;

      th->len = sizeof(struct topology_header);
      // only add topology information directly behind actual payload
      // headers.
      // SDH : TODO : check that this will not fragment the packet...
      // AT: Why do we care about the number of hops? Debugging purposes?
      th->nxt_hdr = msg->hdr.nxt_hdr;

      // For all these 16-bit values, we're only using 8 bit values
      for (i = 0; i < N_NEIGH; i++) {
        if (IS_NEIGH_VALID(&neigh_table[i]) && j < 4 && 
            (IS_MATURE(&neigh_table[i]) || default_route == &neigh_table[i])) {
          th->topo[j].etx = convertTo8(getLinkCost(&neigh_table[i]));
          th->topo[j].conf = convertTo8(getConfidence(&neigh_table[i]));
          th->topo[j].hwaddr = htons(neigh_table[i].neighbor);
          j++;
          th->len += sizeof(struct topology_entry);
          dbg("Lqi", "link est: 0x%x hops: 0x%x\n", 
              neigh_table[i].linkEstimate, neigh_table[i].hops);
        }
      }
       
      record_route.hdr.ext = (struct ip6_ext *)th;
      record_route.len = th->len;
      record_route.next = msg->headers;
      if (j > 0) {
        msg->hdr.nxt_hdr = NXTHDR_TOPO;
        msg->headers = &record_route;
      }
    }
    
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
#if 0
        // SDH : because of the overflow bug, this was never being
        // triggered.  I'm not sure it's actually a good idea because
        // it seems to increase path lengths for heavily used routes.
        // Let's disable it for now.
        dbg("Evictions", "performing evict: %i\n", i);
        evictNeighbor(&neigh_table[i]);
        i --;
#endif
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
