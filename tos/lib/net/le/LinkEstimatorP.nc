/* $Id: LinkEstimatorP.nc,v 1.4 2006-12-12 18:23:29 vlahan Exp $ */
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
    interface LinkSrcPacket;
  }

  uses {
    interface AMSend;
    interface AMPacket as SubAMPacket;
    interface Packet as SubPacket;
    interface Receive as SubReceive;
  }
}

implementation {

  // configure the link estimator and some constants
  enum {
    // If the eetx estimate is below this threshold
    // do not evict a link
    EVICT_EETX_THRESHOLD = 55,
    // maximum link update rounds before we expire the link
    MAX_AGE = 6,
    // if received sequence number if larger than the last sequence
    // number by this gap, we reinitialize the link
    MAX_PKT_GAP = 10,
    BEST_EETX = 0,
    INVALID_RVAL = 0xff,
    INVALID_NEIGHBOR_ADDR = 0xff,
    INFINITY = 0xff,
    // decay the link estimate using this alpha
    // we use a denominator of 10, so this corresponds to 0.2
    ALPHA = 2,
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
    return (linkest_header_t*)call SubPacket.getPayload(m, NULL);
  }

  // get the link estimation footer (neighbor entries) in the packet
  linkest_footer_t* getFooter(message_t* m, uint8_t len) {
    return (linkest_footer_t*)(len + (uint8_t *)call Packet.getPayload(m,NULL));
  }

  // add the link estimation header (seq no) and link estimation
  // footer (neighbor entries) in the packet. Call just before sending
  // the packet.
  uint8_t addLinkEstHeaderAndFooter(message_t *msg, uint8_t len) {
    uint8_t newlen;
    linkest_header_t *hdr;
    linkest_footer_t *footer;
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
      k = (prevSentIdx + i + 1) % NEIGHBOR_TABLE_SIZE;
      if (NeighborTable[k].flags & VALID_ENTRY) {
	footer->neighborList[j].ll_addr = NeighborTable[k].ll_addr;
	footer->neighborList[j].inquality = NeighborTable[k].inquality;
	newPrevSentIdx = k;
	dbg("LI", "Loaded on footer: %d %d %d\n", j, footer->neighborList[j].ll_addr,
	    footer->neighborList[j].inquality);
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
    ne->inage = MAX_AGE;
    ne->outage = MAX_AGE;
    ne->inquality = 0;
    ne->outquality = 0;
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

  // update the quality of the link link: self->neighbor
  // this is found in the entries in the footer of incoming message
  void updateReverseQuality(am_addr_t neighbor, uint8_t outquality) {
    uint8_t idx;
    idx = findIdx(neighbor);
    if (idx != INVALID_RVAL) {
      NeighborTable[idx].outquality = outquality;
      NeighborTable[idx].outage = MAX_AGE;
    }
  }

  // update the EETX estimator
  // called when new beacon estimate is done
  // also called when new DEETX estimate is done
  void updateEETX(neighbor_table_entry_t *ne, uint16_t newEst) {
    ne->eetx = (ALPHA * ne->eetx + (10 - ALPHA) * newEst)/10;
  }


  // update data driven EETX
  void updateDEETX(neighbor_table_entry_t *ne) {
    uint16_t estETX;

    if (ne->data_success == 0) {
      // if there were no successful packet transmission in the
      // last window, assign a large EETX estimate
      estETX = LARGE_EETX_VALUE;
    } else {
      estETX = (10 * ne->data_total) / ne->data_success - 10;
    }
    updateEETX(ne, estETX);
    ne->data_success = 0;
    ne->data_total = 0;
  }


  // EETX (Extra Expected number of Transmission)
  // EETX = ETX - 1
  // computeEETX returns EETX*10
  uint8_t computeEETX(uint8_t q1) {
    uint16_t q;
    if (q1 > 0) {
      q =  2550 / q1 - 10;
      if (q > 255) {
	q = INFINITY;
      }
      return (uint8_t)q;
    } else {
      return INFINITY;
    }
  }

  // BidirETX = 1 / (q1*q2)
  // BidirEETX = BidirETX - 1
  // computeBidirEETX return BidirEETX*10
  uint8_t computeBidirEETX(uint8_t q1, uint8_t q2) {
    uint16_t q;
    if ((q1 > 0) && (q2 > 0)) {
      q =  65025u / q1;
      q = (10*q) / q2 - 10;
      if (q > 255) {
	q = LARGE_EETX_VALUE;
      }
      return (uint8_t)q;
    } else {
      return LARGE_EETX_VALUE;
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
	  if (ne->inage > 0)
	    ne->inage--;
	  if (ne->outage > 0)
	    ne->outage--;
	  
	  if ((ne->inage == 0) && (ne->outage == 0)) {
	    ne->flags ^= VALID_ENTRY;
	    ne->inquality = ne->outquality = 0;
	  } else {
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
	      newEst = (255 * ne->rcvcnt) / totalPkt;
	      dbg("LI,LITest", "  %hu: %hhu -> %hhu", ne->ll_addr, ne->inquality, (ALPHA * ne->inquality + (10-ALPHA) * newEst)/10);
	      ne->inquality = (ALPHA * ne->inquality + (10-ALPHA) * newEst)/10;
	    }
	    ne->rcvcnt = 0;
	    ne->failcnt = 0;
	  }
	  updateEETX(ne, computeBidirEETX(ne->inquality, ne->outquality));
	}
	else {
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
    NeighborTable[idx].inage = MAX_AGE;
    if (packetGap > 0) {
      NeighborTable[idx].failcnt += packetGap - 1;
    }
    if (packetGap > MAX_PKT_GAP) {
      NeighborTable[idx].failcnt = 0;
      NeighborTable[idx].rcvcnt = 1;
      NeighborTable[idx].outage = 0;
      NeighborTable[idx].outquality = 0;
      NeighborTable[idx].inquality = 0;
    }

    if (NeighborTable[idx].rcvcnt >= BLQ_PKT_WINDOW) {
      updateNeighborTableEst(NeighborTable[idx].ll_addr);
    }

  }



  // print the neighbor table. for debugging.
  void print_neighbor_table() {
    uint8_t i;
    neighbor_table_entry_t *ne;
    for (i = 0; i < NEIGHBOR_TABLE_SIZE; i++) {
      ne = &NeighborTable[i];
      if (ne->flags & VALID_ENTRY) {
	dbg("LI,LITest", "%d:%d inQ=%d, inA=%d, outQ=%d, outA=%d, rcv=%d, fail=%d, biQ=%d\n",
	    i, ne->ll_addr, ne->inquality, ne->inage, ne->outquality, ne->outage,
	    ne->rcvcnt, ne->failcnt, computeBidirEETX(ne->inquality, ne->outquality));
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
  command uint8_t LinkEstimator.getLinkQuality(am_addr_t neighbor) {
    uint8_t idx;
    idx = findIdx(neighbor);
    if (idx == INVALID_RVAL) {
      return INFINITY;
    } else {
      return NeighborTable[idx].eetx;
    };
  }

  // return the quality of the link: neighor->self
  command uint8_t LinkEstimator.getReverseQuality(am_addr_t neighbor) {
    uint8_t idx;
    idx = findIdx(neighbor);
    if (idx == INVALID_RVAL) {
      return INFINITY;
    } else {
      return computeEETX(NeighborTable[idx].inquality);
    };
  }

  // return the quality of the link: self->neighbor
  command uint8_t LinkEstimator.getForwardQuality(am_addr_t neighbor) {
    uint8_t idx;
    idx = findIdx(neighbor);
    if (idx == INVALID_RVAL) {
      return INFINITY;
    } else {
      return computeEETX(NeighborTable[idx].outquality);
    };
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


  // get the link layer source address for the incoming packet
  command am_addr_t LinkSrcPacket.getSrc(message_t* msg) {
    return call SubAMPacket.source(msg);
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
    return signal Send.sendDone(msg, error);
  }

  // cascade the calls down
  command uint8_t Send.cancel(message_t* msg) {
    return call AMSend.cancel(msg);
  }

  command uint8_t Send.maxPayloadLength() {
    return call Packet.maxPayloadLength();
  }

  command void* Send.getPayload(message_t* msg) {
    return call Packet.getPayload(msg, NULL);
  }

  // called when link estimator generator packet or
  // packets from upper layer that are wired to pass through
  // link estimator is received
  void processReceivedMessage(message_t* msg, void* payload, uint8_t len) {
    uint8_t nidx;
    uint8_t num_entries;

    dbg("LI", "LI receiving packet, buf addr: %x\n", payload);
    print_packet(msg, len);

    if (call SubAMPacket.destination(msg) == AM_BROADCAST_ADDR) {
      linkest_header_t* hdr = getHeader(msg);
      linkest_footer_t* footer;
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
	  }
	}
      }

      if ((nidx != INVALID_RVAL) && (num_entries > 0)) {
	dbg("LI", "Number of footer entries: %d\n", num_entries);
	footer = (linkest_footer_t*) ((uint8_t *)call SubPacket.getPayload(msg, NULL)
				      + call SubPacket.payloadLength(msg)
				      - num_entries*sizeof(linkest_footer_t));
	{
	  uint8_t i, my_ll_addr;
	  my_ll_addr = call SubAMPacket.address();
	  for (i = 0; i < num_entries; i++) {
	    dbg("LI", "%d %d %d\n", i, footer->neighborList[i].ll_addr,
		footer->neighborList[i].inquality);
	    if (footer->neighborList[i].ll_addr == my_ll_addr) {
	      updateReverseQuality(ll_addr, footer->neighborList[i].inquality);
	    }
	  }
	}
      }
      print_neighbor_table();
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
				  call Packet.getPayload(msg, NULL),
				  call Packet.payloadLength(msg));
  }

  command void* Receive.getPayload(message_t* msg, uint8_t* len) {
    return call Packet.getPayload(msg, len);
  }

  command uint8_t Receive.payloadLength(message_t* msg) {
    return call Packet.payloadLength(msg);
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
  command void* Packet.getPayload(message_t* msg, uint8_t* len) {
    uint8_t* payload = call SubPacket.getPayload(msg, len);
    linkest_header_t *hdr;
    hdr = getHeader(msg);
    if (len != NULL) {
      *len = *len - sizeof(linkest_header_t) - sizeof(linkest_footer_t)*(NUM_ENTRIES_FLAG & hdr->flags);
    }
    return payload + sizeof(linkest_header_t);
  }
}

