/* $Id: LinkEstimatorP.nc,v 1.14 2009-12-05 02:59:49 gnawali Exp $ */
/*
 * "Copyright (c) 2006 University of Southern California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * SOUTHERN CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE,
 * SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/*
 @ author Omprakash Gnawali
 @ Created: April 24, 2006
 */

#include "LinkEstimator.h"

module LinkEstimatorP {
  provides {
    interface StdControl;
    interface AMSend as Send;
    interface Receive;
    interface LinkEstimator;
    interface Init;
    interface Packet;
    interface CompareBit;
  }

  uses {
    interface AMSend;
    interface AMPacket as SubAMPacket;
    interface Packet as SubPacket;
    interface Receive as SubReceive;
    interface LinkPacketMetadata;
    interface Random;
  }
}

implementation {

  // configure the link estimator and some constants
  enum {
    // If the eetx estimate is below this threshold
    // do not evict a link
    EVICT_EETX_THRESHOLD = 55,
    // if received sequence number if larger than the last sequence
    // number by this gap, we reinitialize the link
    MAX_PKT_GAP = 10,
    BEST_EETX = 0,
    INVALID_RVAL = 0xff,
    INVALID_NEIGHBOR_ADDR = 0xff,
    // if we don't know the link quality, we need to return a value so
    // large that it will not be used to form paths
    VERY_LARGE_EETX_VALUE = 0xff,
    // decay the link estimate using this alpha
    // we use a denominator of 10, so this corresponds to 0.2
    ALPHA = 9,
    // number of packets to wait before computing a new
    // DLQ (Data-driven Link Quality)
    DLQ_PKT_WINDOW = 5,
    // number of beacons to wait before computing a new
    // BLQ (Beacon-driven Link Quality)
    BLQ_PKT_WINDOW = 3,
    // largest EETX value that we feed into the link quality EWMA
    // a value of 60 corresponds to having to make six transmissions
    // to successfully receive one acknowledgement
    LARGE_EETX_VALUE = 60
  };

  // keep information about links from the neighbors
  neighbor_table_entry_t NeighborTable[NEIGHBOR_TABLE_SIZE];
  // link estimation sequence, increment every time a beacon is sent
  uint8_t linkEstSeq = 0;
  // if there is not enough room in the packet to put all the neighbor table
  // entries, in order to do round robin we need to remember which entry
  // we sent in the last beacon
  uint8_t prevSentIdx = 0;

  // get the link estimation header in the packet
  linkest_header_t* getHeader(message_t* m) {
    return (linkest_header_t*)call SubPacket.getPayload(m, sizeof(linkest_header_t));
  }

  // get the link estimation footer (neighbor entries) in the packet
  linkest_footer_t* getFooter(message_t* m, uint8_t len) {
    // To get a footer at offset "len", the payload must be len + sizeof large.
    return (linkest_footer_t*)(len + (uint8_t *)call Packet.getPayload(m,len + sizeof(linkest_footer_t)));
  }

  // add the link estimation header (seq no) and link estimation
  // footer (neighbor entries) in the packet. Call just before sending
  // the packet.
  uint8_t addLinkEstHeaderAndFooter(message_t *msg, uint8_t len) {
    uint8_t newlen;
    linkest_header_t * ONE hdr;
    linkest_footer_t * ONE footer;
    uint8_t i, j, k;
    uint8_t maxEntries, newPrevSentIdx;
    dbg("LI", "newlen1 = %d\n", len);
    hdr = getHeader(msg);
    footer = getFooter(msg, len);

    maxEntries = ((call SubPacket.maxPayloadLength() - len - sizeof(linkest_header_t))
		  / sizeof(linkest_footer_t));

    // Depending on the number of bits used to store the number
    // of entries, we can encode up to NUM_ENTRIES_FLAG using those bits
    if (maxEntries > NUM_ENTRIES_FLAG) {
      maxEntries = NUM_ENTRIES_FLAG;
    }
    dbg("LI", "Max payload is: %d, maxEntries is: %d\n", call SubPacket.maxPayloadLength(), maxEntries);

    j = 0;
    newPrevSentIdx = 0;
    for (i = 0; i < NEIGHBOR_TABLE_SIZE && j < maxEntries; i++) {
      uint8_t neighborCount;
      neighbor_stat_entry_t * COUNT(neighborCount) neighborLists;
      if(maxEntries <= NEIGHBOR_TABLE_SIZE)
        neighborCount = maxEntries;
      else
        neighborCount = NEIGHBOR_TABLE_SIZE;
      
      neighborLists = TCAST(neighbor_stat_entry_t * COUNT(neighborCount), footer->neighborList);
      k = (prevSentIdx + i + 1) % NEIGHBOR_TABLE_SIZE;
      if ((NeighborTable[k].flags & VALID_ENTRY) &&
	  (NeighborTable[k].flags & MATURE_ENTRY)) {
	neighborLists[j].ll_addr = NeighborTable[k].ll_addr;
	neighborLists[j].inquality = NeighborTable[k].inquality;
	newPrevSentIdx = k;
	dbg("LI", "Loaded on footer: %d %d %d\n", j, neighborLists[j].ll_addr,
	    neighborLists[j].inquality);
	j++;
      }
    }
    prevSentIdx = newPrevSentIdx;

    hdr->seq = linkEstSeq++;
    hdr->flags = 0;
    hdr->flags |= (NUM_ENTRIES_FLAG & j);
    newlen = sizeof(linkest_header_t) + len + j*sizeof(linkest_footer_t);
    dbg("LI", "newlen2 = %d\n", newlen);
    return newlen;
  }


  // initialize the given entry in the table for neighbor ll_addr
  void initNeighborIdx(uint8_t i, am_addr_t ll_addr) {
    neighbor_table_entry_t *ne;
    ne = &NeighborTable[i];
    ne->ll_addr = ll_addr;
    ne->lastseq = 0;
    ne->rcvcnt = 0;
    ne->failcnt = 0;
    ne->flags = (INIT_ENTRY | VALID_ENTRY);
    ne->inquality = 0;
    ne->eetx = 0;
  }

  // find the index to the entry for neighbor ll_addr
  uint8_t findIdx(am_addr_t ll_addr) {
    uint8_t i;
    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      if (NeighborTable[i].flags & VALID_ENTRY) {
	if (NeighborTable[i].ll_addr == ll_addr) {
	  return i;
	}
      }
    }
    return INVALID_RVAL;
  }

  // find an empty slot in the neighbor table
  uint8_t findEmptyNeighborIdx() {
    uint8_t i;
    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      if (NeighborTable[i].flags & VALID_ENTRY) {
      } else {
	return i;
      }
    }
      return INVALID_RVAL;
  }

  // find the index to the worst neighbor if the eetx
  // estimate is greater than the given threshold
  uint8_t findWorstNeighborIdx(uint8_t thresholdEETX) {
    uint8_t i, worstNeighborIdx;
    uint16_t worstEETX, thisEETX;

    worstNeighborIdx = INVALID_RVAL;
    worstEETX = 0;
    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      if (!(NeighborTable[i].flags & VALID_ENTRY)) {
	dbg("LI", "Invalid so continuing\n");
	continue;
      }
      if (!(NeighborTable[i].flags & MATURE_ENTRY)) {
	dbg("LI", "Not mature, so continuing\n");
	continue;
      }
      if (NeighborTable[i].flags & PINNED_ENTRY) {
	dbg("LI", "Pinned entry, so continuing\n");
	continue;
      }
      thisEETX = NeighborTable[i].eetx;
      if (thisEETX >= worstEETX) {
	worstNeighborIdx = i;
	worstEETX = thisEETX;
      }
    }
    if (worstEETX >= thresholdEETX) {
      return worstNeighborIdx;
    } else {
      return INVALID_RVAL;
    }
  }


  // find the index to a random entry that is
  // valid but not pinned
  uint8_t findRandomNeighborIdx() {
    uint8_t i;
    uint8_t cnt;
    uint8_t num_eligible_eviction;

    num_eligible_eviction = 0;
    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      if (NeighborTable[i].flags & VALID_ENTRY) {
        if (NeighborTable[i].flags & PINNED_ENTRY ||
            NeighborTable[i].flags & MATURE_ENTRY) {
        }  else {
          num_eligible_eviction++;
        }
      }
    }

    if (num_eligible_eviction == 0) {
      return INVALID_RVAL;
    }

    cnt = call Random.rand16() % num_eligible_eviction;

    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      if (!NeighborTable[i].flags & VALID_ENTRY)
        continue;
      if (NeighborTable[i].flags & PINNED_ENTRY ||
          NeighborTable[i].flags & MATURE_ENTRY)
        continue;
      if (cnt-- == 0)
        return i;
    }
    return INVALID_RVAL;
  }


  // update the EETX estimator
  // called when new beacon estimate is done
  // also called when new DEETX estimate is done
  void updateEETX(neighbor_table_entry_t *ne, uint16_t newEst) {
    ne->eetx = (ALPHA * ne->eetx + (10 - ALPHA) * newEst + 5)/10;
  }


  // update data driven EETX
  void updateDEETX(neighbor_table_entry_t *ne) {
    uint16_t estETX;

    if (ne->data_success == 0) {
      // if there were no successful packet transmission in the
      // last window, our current estimate is the number of failed
      // transmissions
      estETX = (ne->data_total - 1)* 10;
    } else {
      estETX = (10 * ne->data_total) / ne->data_success - 10;
      ne->data_success = 0;
      ne->data_total = 0;
    }
    updateEETX(ne, estETX);
  }


  // EETX (Extra Expected number of Transmission)
  // EETX = ETX - 1
  // computeEETX returns EETX*10
  uint8_t computeEETX(uint8_t q1) {
    uint16_t q;
    if (q1 > 0) {
      q =  2550 / q1 - 10;
      if (q > 255) {
	q = VERY_LARGE_EETX_VALUE;
      }
      return (uint8_t)q;
    } else {
      return VERY_LARGE_EETX_VALUE;
    }
  }

  // update the inbound link quality by
  // munging receive, fail count since last update
  void updateNeighborTableEst(am_addr_t n) {
    uint8_t i, totalPkt;
    neighbor_table_entry_t *ne;
    uint8_t newEst;
    uint8_t minPkt;

    minPkt = BLQ_PKT_WINDOW;
    dbg("LI", "%s\n", __FUNCTION__);
    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      ne = &NeighborTable[i];
      if (ne->ll_addr == n) {
	if (ne->flags & VALID_ENTRY) {
	  dbg("LI", "Making link: %d mature\n", i);
	  ne->flags |= MATURE_ENTRY;
	  totalPkt = ne->rcvcnt + ne->failcnt;
	  dbg("LI", "MinPkt: %d, totalPkt: %d\n", minPkt, totalPkt);
	  if (totalPkt < minPkt) {
	    totalPkt = minPkt;
	  }
	  if (totalPkt == 0) {
	    ne->inquality = (ALPHA * ne->inquality) / 10;
	  } else {
	    newEst = (255UL * ne->rcvcnt) / totalPkt;
	    dbg("LI,LITest", "  %hu: %hhu -> %hhu", ne->ll_addr, ne->inquality, (ALPHA * ne->inquality + (10-ALPHA) * newEst + 5)/10);
	    ne->inquality = (ALPHA * ne->inquality + (10-ALPHA) * newEst + 5)/10;
	  }
	  ne->rcvcnt = 0;
	  ne->failcnt = 0;
	  updateEETX(ne, computeEETX(ne->inquality));
	} else {
	  dbg("LI", " - entry %i is invalid.\n", (int)i);
	}
      }
    }
  }


  // we received seq from the neighbor in idx
  // update the last seen seq, receive and fail count
  // refresh the age
  void updateNeighborEntryIdx(uint8_t idx, uint8_t seq) {
    uint8_t packetGap;

    if (NeighborTable[idx].flags & INIT_ENTRY) {
      dbg("LI", "Init entry update\n");
      NeighborTable[idx].lastseq = seq;
      NeighborTable[idx].flags &= ~INIT_ENTRY;
    }
    
    packetGap = seq - NeighborTable[idx].lastseq;
    dbg("LI", "updateNeighborEntryIdx: prevseq %d, curseq %d, gap %d\n",
	NeighborTable[idx].lastseq, seq, packetGap);
    NeighborTable[idx].lastseq = seq;
    NeighborTable[idx].rcvcnt++;
    if (packetGap > 0) {
      NeighborTable[idx].failcnt += packetGap - 1;
    }

    // The or with packetGap >= BLQ_PKT_WINDOW is needed in case
    // failcnt gets reset above

    if (((NeighborTable[idx].rcvcnt + NeighborTable[idx].failcnt) >= BLQ_PKT_WINDOW)
	|| (packetGap >= BLQ_PKT_WINDOW)) {
      updateNeighborTableEst(NeighborTable[idx].ll_addr);
    }

    if (packetGap > MAX_PKT_GAP) {
      initNeighborIdx(idx, NeighborTable[idx].ll_addr);
      NeighborTable[idx].lastseq = seq;
      NeighborTable[idx].rcvcnt = 1;
    }
  }



  // print the neighbor table. for debugging.
  void print_neighbor_table() {
    uint8_t i;
    neighbor_table_entry_t *ne;
    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      ne = &NeighborTable[i];
      if (ne->flags & VALID_ENTRY) {
	dbg("LI,LITest", "%d:%d inQ=%d, rcv=%d, fail=%d, Q=%d\n",
	    i, ne->ll_addr, ne->inquality, 
	    ne->rcvcnt, ne->failcnt, computeEETX(ne->inquality));
      }
    }
  }

  // print the packet. for debugging.
  void print_packet(message_t* msg, uint8_t len) {
    uint8_t i;
    uint8_t* b;

    b = (uint8_t *)msg->data;
    for(i=0; i<len; i++)
      dbg_clear("LI", "%x ", b[i]);
    dbg_clear("LI", "\n");
  }

  // initialize the neighbor table in the very beginning
  void initNeighborTable() {
    uint8_t i;

    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      NeighborTable[i].flags = 0;
    }
  }

  command error_t StdControl.start() {
    dbg("LI", "Link estimator start\n");
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    return SUCCESS;
  }

  // initialize the link estimator
  command error_t Init.init() {
    dbg("LI", "Link estimator init\n");
    initNeighborTable();
    return SUCCESS;
  }

  // return bi-directional link quality to the neighbor
  command uint16_t LinkEstimator.getLinkQuality(am_addr_t neighbor) {
    uint8_t idx;
    idx = findIdx(neighbor);
    if (idx == INVALID_RVAL) {
      return VERY_LARGE_EETX_VALUE;
    } else {
      if (NeighborTable[idx].flags & MATURE_ENTRY) {
	return NeighborTable[idx].eetx;
      } else {
	return VERY_LARGE_EETX_VALUE;
      }
    }
  }

  // insert the neighbor at any cost (if there is a room for it)
  // even if eviction of a perfectly fine neighbor is called for
  command error_t LinkEstimator.insertNeighbor(am_addr_t neighbor) {
    uint8_t nidx;

    nidx = findIdx(neighbor);
    if (nidx != INVALID_RVAL) {
      dbg("LI", "insert: Found the entry, no need to insert\n");
      return SUCCESS;
    }

    nidx = findEmptyNeighborIdx();
    if (nidx != INVALID_RVAL) {
      dbg("LI", "insert: inserted into the empty slot\n");
      initNeighborIdx(nidx, neighbor);
      return SUCCESS;
    } else {
      nidx = findWorstNeighborIdx(BEST_EETX);
      if (nidx != INVALID_RVAL) {
	dbg("LI", "insert: inserted by replacing an entry for neighbor: %d\n",
	    NeighborTable[nidx].ll_addr);
	signal LinkEstimator.evicted(NeighborTable[nidx].ll_addr);
	initNeighborIdx(nidx, neighbor);
	return SUCCESS;
      }
    }
    return FAIL;
  }

  // pin a neighbor so that it does not get evicted
  command error_t LinkEstimator.pinNeighbor(am_addr_t neighbor) {
    uint8_t nidx = findIdx(neighbor);
    if (nidx == INVALID_RVAL) {
      return FAIL;
    }
    NeighborTable[nidx].flags |= PINNED_ENTRY;
    return SUCCESS;
  }

  // pin a neighbor so that it does not get evicted
  command error_t LinkEstimator.unpinNeighbor(am_addr_t neighbor) {
    uint8_t nidx = findIdx(neighbor);
    if (nidx == INVALID_RVAL) {
      return FAIL;
    }
    NeighborTable[nidx].flags &= ~PINNED_ENTRY;
    return SUCCESS;
  }


  // called when an acknowledgement is received; sign of a successful
  // data transmission; to update forward link quality
  command error_t LinkEstimator.txAck(am_addr_t neighbor) {
    neighbor_table_entry_t *ne;
    uint8_t nidx = findIdx(neighbor);
    if (nidx == INVALID_RVAL) {
      return FAIL;
    }
    ne = &NeighborTable[nidx];
    ne->data_success++;
    ne->data_total++;
    if (ne->data_total >= DLQ_PKT_WINDOW) {
      updateDEETX(ne);
    }
    return SUCCESS;
  }

  // called when an acknowledgement is not received; could be due to
  // data pkt or acknowledgement loss; to update forward link quality
  command error_t LinkEstimator.txNoAck(am_addr_t neighbor) {
    neighbor_table_entry_t *ne;
    uint8_t nidx = findIdx(neighbor);
    if (nidx == INVALID_RVAL) {
      return FAIL;
    }

    ne = &NeighborTable[nidx];
    ne->data_total++;
    if (ne->data_total >= DLQ_PKT_WINDOW) {
      updateDEETX(ne);
    }
    return SUCCESS;
  }

  // called when the parent changes; clear state about data-driven link quality
  command error_t LinkEstimator.clearDLQ(am_addr_t neighbor) {
    neighbor_table_entry_t *ne;
    uint8_t nidx = findIdx(neighbor);
    if (nidx == INVALID_RVAL) {
      return FAIL;
    }
    ne = &NeighborTable[nidx];
    ne->data_total = 0;
    ne->data_success = 0;
    return SUCCESS;
  }


  // user of link estimator calls send here
  // slap the header and footer before sending the message
  command error_t Send.send(am_addr_t addr, message_t* msg, uint8_t len) {
    uint8_t newlen;
    newlen = addLinkEstHeaderAndFooter(msg, len);
    dbg("LITest", "%s packet of length %hhu became %hhu\n", __FUNCTION__, len, newlen);
    dbg("LI", "Sending seq: %d\n", linkEstSeq);
    print_packet(msg, newlen);
    return call AMSend.send(addr, msg, newlen);
  }

  // done sending the message that originated by
  // the user of this component
  event void AMSend.sendDone(message_t* msg, error_t error ) {
    signal Send.sendDone(msg, error);
  }

  // cascade the calls down
  command uint8_t Send.cancel(message_t* msg) {
    return call AMSend.cancel(msg);
  }

  command uint8_t Send.maxPayloadLength() {
    return call Packet.maxPayloadLength();
  }

  command void* Send.getPayload(message_t* msg, uint8_t len) {
    return call Packet.getPayload(msg, len);
  }

  // called when link estimator generator packet or
  // packets from upper layer that are wired to pass through
  // link estimator is received
  void processReceivedMessage(message_t* ONE msg, void* COUNT_NOK(len) payload, uint8_t len) {
    uint8_t nidx;
    uint8_t num_entries;

    dbg("LI", "LI receiving packet, buf addr: %x\n", payload);
    print_packet(msg, len);

    if (call SubAMPacket.destination(msg) == AM_BROADCAST_ADDR) {
      linkest_header_t* hdr = getHeader(msg);
      am_addr_t ll_addr;

      ll_addr = call SubAMPacket.source(msg);

      dbg("LI", "Got seq: %d from link: %d\n", hdr->seq, ll_addr);

      num_entries = hdr->flags & NUM_ENTRIES_FLAG;
      print_neighbor_table();

      // update neighbor table with this information
      // find the neighbor
      // if found
      //   update the entry
      // else
      //   find an empty entry
      //   if found
      //     initialize the entry
      //   else
      //     find a bad neighbor to be evicted
      //     if found
      //       evict the neighbor and init the entry
      //     else
      //       we can not accommodate this neighbor in the table
      nidx = findIdx(ll_addr);
      if (nidx != INVALID_RVAL) {
	dbg("LI", "Found the entry so updating\n");
	updateNeighborEntryIdx(nidx, hdr->seq);
      } else {
	nidx = findEmptyNeighborIdx();
	if (nidx != INVALID_RVAL) {
	  dbg("LI", "Found an empty entry\n");
	  initNeighborIdx(nidx, ll_addr);
	  updateNeighborEntryIdx(nidx, hdr->seq);
	} else {
	  nidx = findWorstNeighborIdx(EVICT_EETX_THRESHOLD);
	  if (nidx != INVALID_RVAL) {
	    dbg("LI", "Evicted neighbor %d at idx %d\n",
		NeighborTable[nidx].ll_addr, nidx);
	    signal LinkEstimator.evicted(NeighborTable[nidx].ll_addr);
	    initNeighborIdx(nidx, ll_addr);
	  } else {
	    dbg("LI", "No room in the table\n");

	    /* if the white bit is set, lets ask the router if the path through
	       this link is better than at least one known path - if so
	       lets insert this link into the table.
	    */
	    if (call LinkPacketMetadata.highChannelQuality(msg)) {
	      if (signal CompareBit.shouldInsert(msg, 
						 call Packet.getPayload(msg, call Packet.payloadLength(msg)),
						 call Packet.payloadLength(msg))) {
		nidx = findRandomNeighborIdx();
		if (nidx != INVALID_RVAL) {
		  signal LinkEstimator.evicted(NeighborTable[nidx].ll_addr);
		  initNeighborIdx(nidx, ll_addr);
		}
	      }
	    }
	  }
	}
      }
    }
  }

  // new messages are received here
  // update the neighbor table with the header
  // and footer in the message
  // then signal the user of this component
  event message_t* SubReceive.receive(message_t* msg,
				      void* payload,
				      uint8_t len) {
    dbg("LI", "Received upper packet. Will signal up\n");
    processReceivedMessage(msg, payload, len);
    return signal Receive.receive(msg,
				  call Packet.getPayload(msg, call Packet.payloadLength(msg)),
				  call Packet.payloadLength(msg));
  }

  command void Packet.clear(message_t* msg) {
    call SubPacket.clear(msg);
  }

  // subtract the space occupied by the link estimation
  // header and footer from the incoming payload size
  command uint8_t Packet.payloadLength(message_t* msg) {
    linkest_header_t *hdr;
    hdr = getHeader(msg);
    return call SubPacket.payloadLength(msg)
      - sizeof(linkest_header_t)
      - sizeof(linkest_footer_t)*(NUM_ENTRIES_FLAG & hdr->flags);
  }

  // account for the space used by header and footer
  // while setting the payload length
  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    linkest_header_t *hdr;
    hdr = getHeader(msg);
    call SubPacket.setPayloadLength(msg,
				    len
				    + sizeof(linkest_header_t)
				    + sizeof(linkest_footer_t)*(NUM_ENTRIES_FLAG & hdr->flags));
  }

  command uint8_t Packet.maxPayloadLength() {
    return call SubPacket.maxPayloadLength() - sizeof(linkest_header_t);
  }

  // application payload pointer is just past the link estimation header
  command void* Packet.getPayload(message_t* msg, uint8_t len) {
    void* payload = call SubPacket.getPayload(msg, len + sizeof(linkest_header_t));
    if (payload != NULL) {
      payload += sizeof(linkest_header_t);
    }
    return payload;
  }

}
