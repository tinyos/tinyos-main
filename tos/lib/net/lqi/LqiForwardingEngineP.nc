// $Id: LqiForwardingEngineP.nc,v 1.4 2007-04-13 19:38:11 scipio Exp $


/* Copyright (c) 2007 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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

/* 
 * A simple module that handles multihop packet movement.  It accepts 
 * messages from both applications and the network and does the necessary
 * interception and forwarding.
 * It interfaces to an algorithmic componenet via RouteSelect. It also acts
 * as a front end for RouteControl
 */


/**
 * @author Philip Buonadonna
 * @auihor Alec Woo
 * @author Crossbow Inc.
 * @author Philip Levis (port from TinyOS 1.x)
 */

#include "AM.h"
#include "MultiHopLqi.h"
#include "CollectionDebugMsg.h"

module LqiForwardingEngineP {
  provides {
    interface Init;
    interface Send;
    interface Receive[collection_id_t id];
    interface Receive as Snoop[collection_id_t];
    interface Intercept[collection_id_t id];
    interface CollectionPacket;
    interface RouteControl;
    interface LqiRouteStats;
    interface Packet;
  }
  uses {
    interface Receive as SubReceive;
    interface AMSend as SubSend;
    interface AMSend as SubSendMine;
    interface RouteControl as RouteSelectCntl;
    interface RouteSelect;
    interface Leds;
    interface Packet as SubPacket;
    interface AMPacket;
    interface RootControl;
    interface Random;
    interface PacketAcknowledgements;
    interface CollectionDebug;
  }
}

implementation {

  enum {
    FWD_QUEUE_SIZE = MHOP_QUEUE_SIZE, // Forwarding Queue
    EMPTY = 0xff
  };

  /* Internal storage and scheduling state */
  message_t FwdBuffers[FWD_QUEUE_SIZE];
  message_t *FwdBufList[FWD_QUEUE_SIZE];
  uint8_t FwdBufBusy[FWD_QUEUE_SIZE];
  uint8_t iFwdBufHead, iFwdBufTail;
  uint16_t sendFailures = 0;
  uint8_t fail_count = 0;
  int fwdbusy = 0;
  
  lqi_header_t* getHeader(message_t* msg) {
    return (lqi_header_t*) call SubPacket.getPayload(msg, NULL);
  }
  
  /***********************************************************************
   * Initialization 
   ***********************************************************************/


  static void initialize() {
    int n;

    for (n=0; n < FWD_QUEUE_SIZE; n++) {
      FwdBufList[n] = &FwdBuffers[n];
      FwdBufBusy[n] = 0;
    } 
    iFwdBufHead = iFwdBufTail = 0;

    sendFailures = 0;
  }

  command error_t Init.init() {
    initialize();
    return SUCCESS;
  }


  /***********************************************************************
   * Commands and events
   ***********************************************************************/
  command error_t Send.send(message_t* pMsg, uint8_t len) {
    len += sizeof(lqi_header_t);
    if (len > call SubPacket.maxPayloadLength()) {
      return ESIZE;
    }
    if (call RootControl.isRoot()) {
      return FAIL;
    }
    call RouteSelect.initializeFields(pMsg);
    
    if (call RouteSelect.selectRoute(pMsg, 0) != SUCCESS) {
      return FAIL;
    }
    call PacketAcknowledgements.requestAck(pMsg);
    if (call SubSendMine.send(call AMPacket.destination(pMsg), pMsg, len) != SUCCESS) {
      sendFailures++;
      return FAIL;
    }

    return SUCCESS;
  } 
  
  int8_t get_buff(){
    uint8_t n;
    for (n=0; n < FWD_QUEUE_SIZE; n++) {
	uint8_t done = 0;
        atomic{
	  if(FwdBufBusy[n] == 0){
	    FwdBufBusy[n] = 1;
	    done = 1;
	  }
        }
	if(done == 1) return n;
      
    } 
    return -1;
  }

  int8_t is_ours(message_t* ptr){
    uint8_t n;
    for (n=0; n < FWD_QUEUE_SIZE; n++) {
       if(FwdBufList[n] == ptr){
		return n;
       }
    } 
    return -1;
  }

  static char* fields(message_t* msg) {
#ifdef TOSSIM
    static char mbuf[1024];
    lqi_header_t* hdr = getHeader(msg);
    sprintf(mbuf, "origin = %hu, seqno = %hu, oseqno = %hu, hopcount =%hu", hdr->originaddr, hdr->seqno, hdr->originseqno, hdr->hopcount);
    return mbuf;
#else
    return NULL;
#endif
  }

  static void forward(message_t* msg);
  
  static message_t* mForward(message_t* msg) {
    int8_t buf = get_buff();
    dbg("LQI", " Asked to forward packet @%s:\t%s\n", sim_time_string(), fields(msg));
    if (buf == -1) {
      dbg("LQI", "%s Dropped packet due to no space in queue.\n", __FUNCTION__);
      call CollectionDebug.logEvent(NET_C_FE_SEND_QUEUE_FULL);
      return msg;
    }
    if ((call RouteSelect.selectRoute(msg, 0)) != SUCCESS) {
      FwdBufBusy[(uint8_t)buf] = 0;
      call CollectionDebug.logEvent(NET_C_FE_NO_ROUTE);
      dbg("LQI", "%s Dropped packet due to no route.\n", __FUNCTION__);
      return msg;
    }
    else {
      message_t* newMsg = FwdBufList[(uint8_t)buf];
      FwdBufList[(uint8_t)buf] = msg;
      forward(msg);
      return newMsg;
    }
  }
  
  static void forward(message_t* msg) {
    // Failures at the send level do not cause the seq. number space to be 
    // rolled back properly.  This is somewhat broken.
    if (fwdbusy) {
      dbg("LQI", "%s forwarding busy, wait for later.\n", __FUNCTION__);
      return;
    }
    else {
      call PacketAcknowledgements.requestAck(msg);
      if (call SubSend.send(call AMPacket.destination(msg),
			    msg,
			    call SubPacket.payloadLength(msg)) == SUCCESS) {
	dbg("LQI", "%s: Send to %hu success.\n", __FUNCTION__, call AMPacket.destination(msg));
      }
      fwdbusy = TRUE;
    }
  }

  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    collection_id_t id = call CollectionPacket.getType(msg);
    payload += sizeof(lqi_header_t);
    len -= sizeof(lqi_header_t);

    if (call RootControl.isRoot()) {
      dbg("LQI,LQIDeliver", "LQI Root is receiving packet from node %hu @%s\n", getHeader(msg)->originaddr, sim_time_string());
      return signal Receive.receive[id](msg, payload, len);
    }
    else if (signal Intercept.forward[id](msg, payload, len)) {
      dbg("LQI,LQIDeliver", "LQI fwd is forwarding packet from node %hu @%s\n", getHeader(msg)->originaddr, sim_time_string());
      return mForward(msg);
    }
    else {
      return msg;
    }
  }
  
  message_t* nextMsg() {
    int i;
    int inc = call Random.rand16();
    for (i = 0; i < FWD_QUEUE_SIZE; i++) {
      int pindex = (i + inc) % FWD_QUEUE_SIZE;
      if (FwdBufBusy[pindex]) {
	return FwdBufList[pindex];
      }
    }
    return NULL;
  }
  
  event void SubSend.sendDone(message_t* msg, error_t success) {
    int8_t buf;
    message_t* nextToSend;
    if (!call PacketAcknowledgements.wasAcked(msg) &&
	call AMPacket.destination(msg) != TOS_BCAST_ADDR &&
	fail_count < 5){
      call RouteSelect.selectRoute(msg, 1);
      call PacketAcknowledgements.requestAck(msg);
      if (call SubSend.send(call AMPacket.destination(msg),
			    msg,
			    call SubPacket.payloadLength(msg)) == SUCCESS) {
	dbg("LQI", "Packet not acked, retransmit @%s:\n\t%s\n", sim_time_string(), fields(msg));
        call CollectionDebug.logEventMsg(NET_C_FE_SENDDONE_WAITACK, 
					 call CollectionPacket.getSequenceNumber(msg), 
					 call CollectionPacket.getOrigin(msg), 
                                         call AMPacket.destination(msg));
	fail_count ++;
	return;
      } else {
	call CollectionDebug.logEventMsg(NET_C_FE_SENDDONE_FAIL, 
					 call CollectionPacket.getSequenceNumber(msg), 
					 call CollectionPacket.getOrigin(msg), 
                                         call AMPacket.destination(msg));
	dbg("LQI", "Packet not acked, retransmit fail @%s:\n\t%s\n", sim_time_string(), fields(msg));
	sendFailures++;
	return;
      }
    }
    else if (fail_count >= 5) {
      call CollectionDebug.logEventMsg(NET_C_FE_SENDDONE_FAIL_ACK_FWD, 
				       call CollectionPacket.getSequenceNumber(msg), 
				       call CollectionPacket.getOrigin(msg), 
				       call AMPacket.destination(msg));
      dbg("LQI", "Packet failed:\t%s\n", fields(msg));
    }
    else if (call PacketAcknowledgements.wasAcked(msg)) {
      dbg("LQI", "Packet acked:\t%s\n", fields(msg));
      call CollectionDebug.logEventMsg(NET_C_FE_FWD_MSG, 
				       call CollectionPacket.getSequenceNumber(msg), 
				       call CollectionPacket.getOrigin(msg), 
				       call AMPacket.destination(msg));
    }
    
    fail_count = 0;
    buf = is_ours(msg);
    if (buf != -1) {
      FwdBufBusy[(uint8_t)buf] = 0;
    }
    
    nextToSend = nextMsg();
    fwdbusy = FALSE;
	  
    if (nextToSend != NULL) {
      forward(nextToSend);
    }
    
    dbg("LQI", "Packet not longer busy:\t%s\n", fields(msg));
  }

  event void SubSendMine.sendDone(message_t* msg, error_t success) {
    if (!call PacketAcknowledgements.wasAcked(msg) &&
	call AMPacket.destination(msg) != TOS_BCAST_ADDR &&
	fail_count < 5){
      call RouteSelect.selectRoute(msg, 1);
      call PacketAcknowledgements.requestAck(msg);
      if (call SubSendMine.send(call AMPacket.destination(msg),
			    msg,
			    call SubPacket.payloadLength(msg)) == SUCCESS) {
	dbg("LQI", "Packet not acked, retransmit (%hhu) @%s:\n\t%s\n", fail_count, sim_time_string(), fields(msg));
	call CollectionDebug.logEventMsg(NET_C_FE_SENDDONE_WAITACK, 
					 call CollectionPacket.getSequenceNumber(msg), 
					 call CollectionPacket.getOrigin(msg), 
                                         call AMPacket.destination(msg));
	fail_count ++;
	return;
      } else {
	call CollectionDebug.logEventMsg(NET_C_FE_SENDDONE_FAIL, 
					 call CollectionPacket.getSequenceNumber(msg), 
					 call CollectionPacket.getOrigin(msg), 
                                         call AMPacket.destination(msg));
	dbg("LQI", "Packet not acked, retransmit fail @%s:\n\t%s\n", sim_time_string(), fields(msg));
	sendFailures++;
	return;
      }
    }
    else if (fail_count >= 5) {
      call CollectionDebug.logEventMsg(NET_C_FE_SENDDONE_FAIL_ACK_SEND, 
				       call CollectionPacket.getSequenceNumber(msg), 
				       call CollectionPacket.getOrigin(msg), 
				       call AMPacket.destination(msg));
      dbg("LQI", "Packet failed:\t%s\n", fields(msg));
    }
    else if (call PacketAcknowledgements.wasAcked(msg)) {
      dbg("LQI", "Packet acked:\t%s\n", fields(msg));
      call CollectionDebug.logEventMsg(NET_C_FE_SENT_MSG, 
				       call CollectionPacket.getSequenceNumber(msg), 
				       call CollectionPacket.getOrigin(msg), 
				       call AMPacket.destination(msg));
    }

    fail_count = 0;
    signal Send.sendDone(msg, success);
  }


  command uint16_t RouteControl.getParent() {
    return call RouteSelectCntl.getParent();
  }

  command uint8_t RouteControl.getQuality() {
    return call RouteSelectCntl.getQuality();
  }

  command uint8_t RouteControl.getDepth() {
    return call RouteSelectCntl.getDepth();
  }

  command uint8_t RouteControl.getOccupancy() {
    uint16_t uiOutstanding = (uint16_t)iFwdBufTail - (uint16_t)iFwdBufHead;
    uiOutstanding %= FWD_QUEUE_SIZE;
    return (uint8_t)uiOutstanding;
  }


  command error_t RouteControl.setUpdateInterval(uint16_t Interval) {
    return call RouteSelectCntl.setUpdateInterval(Interval);
  }

  command error_t RouteControl.manualUpdate() {
    return call RouteSelectCntl.manualUpdate();
  }

  command uint16_t LqiRouteStats.getSendFailures() {
    return sendFailures;
  }

  command void Packet.clear(message_t* msg) {
    
  }

  command void* Send.getPayload(message_t* m) {
    return call Packet.getPayload(m, NULL);
  }

  command uint8_t Send.maxPayloadLength() {
    return call Packet.maxPayloadLength();
  }

  command error_t Send.cancel(message_t* m) {
    return FAIL;
  }

  
  command void* Receive.getPayload[collection_id_t id](message_t* msg, uint8_t* len) {
    return call Packet.getPayload(msg, len);
  }
  
  command uint8_t Receive.payloadLength[collection_id_t id](message_t* m) {
    return call Packet.payloadLength(m);
  }

  command void* Snoop.getPayload[collection_id_t id](message_t* msg, uint8_t* len) {
    return call Packet.getPayload(msg, len);
  }
  
  command uint8_t Snoop.payloadLength[collection_id_t id](message_t* m) {
    return call Packet.payloadLength(m);
  }
  
  command uint8_t Packet.payloadLength(message_t* msg) {
    return call SubPacket.payloadLength(msg) - sizeof(lqi_header_t);
  }
  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    call SubPacket.setPayloadLength(msg, len + sizeof(lqi_header_t));
  }
  command uint8_t Packet.maxPayloadLength() {
    return (call SubPacket.maxPayloadLength() - sizeof(lqi_header_t));
  }
  command void* Packet.getPayload(message_t* msg, uint8_t* len) {
    void* rval = call SubPacket.getPayload(msg, len);
    if (len != NULL) {
      *len -= sizeof(lqi_header_t);
    }
    rval += sizeof(lqi_header_t);
    return rval;
  }

  command am_addr_t CollectionPacket.getOrigin(message_t* msg) {
    lqi_header_t* hdr = getHeader(msg);
    return hdr->originaddr;  
  }

  command void CollectionPacket.setOrigin(message_t* msg, am_addr_t addr) {
    lqi_header_t* hdr = getHeader(msg);
    hdr->originaddr = addr;
  }

  command collection_id_t CollectionPacket.getType(message_t* msg) {
    return getHeader(msg)->collectId;
  }

  command void CollectionPacket.setType(message_t* msg, collection_id_t id) {
    getHeader(msg)->collectId = id;
  }
  
  command uint8_t CollectionPacket.getSequenceNumber(message_t* msg) {
    lqi_header_t* hdr = getHeader(msg);
    return hdr->originseqno;
  }
  
  command void CollectionPacket.setSequenceNumber(message_t* msg, uint8_t seqno) {
    lqi_header_t* hdr = getHeader(msg);
    hdr->originseqno = seqno;
  }
  
 default event void Send.sendDone(message_t* pMsg, error_t success) {}
 default event message_t* Snoop.receive[collection_id_t id](message_t* pMsg, void* payload, uint8_t len) {return pMsg;}
 default event message_t* Receive.receive[collection_id_t id](message_t* pMsg, void* payload, uint8_t len) {
   return pMsg;
 }
 default event bool Intercept.forward[collection_id_t id](message_t* pMsg, void* payload, uint16_t len) {
   return 1;
 }
}

