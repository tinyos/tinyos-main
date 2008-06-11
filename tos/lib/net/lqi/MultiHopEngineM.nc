// $Id: MultiHopEngineM.nc,v 1.4 2008-06-11 00:46:25 razvanm Exp $

/*
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


/*
 * Authors:          Philip Buonadonna, Alec Woo, Crossbow Inc.
 *
 */

#include "AM.h"
#include "MultiHop.h"

module MultiHopEngineM {
  provides {
    interface Init;
    interface Receive;
    interface Send;
    interface Packet;
    interface CollectionPacket;
    interface RouteControl;
    interface LqiRouteStats;
  }
  uses {
    interface Receive as SubReceive;
    interface AMSend as SubSend;
    interface RouteControl as RouteSelectCntl;
    interface RouteSelect;
    interface Leds;
    interface Packet as SubPacket;
    interface AMPacket;
    interface RootControl;
    interface PacketAcknowledgements;
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
      call Leds.led0On();
      return ESIZE;
    }
    if (call RootControl.isRoot()) {
      call Leds.led1On();
      return FAIL;
    }
    call RouteSelect.initializeFields(pMsg);
    
    if (call RouteSelect.selectRoute(pMsg, 0) != SUCCESS) {
      call Leds.led2On();
      return FAIL;
    }
    call PacketAcknowledgements.requestAck(pMsg);
    if (call SubSend.send(call AMPacket.destination(pMsg), pMsg, len) != SUCCESS) {
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
  
  static message_t* mForward(message_t* msg) {
    message_t* newMsg = msg;
    int8_t buf = get_buff();
    call Leds.led2Toggle();
    
    if (call RootControl.isRoot()) {
      return signal Receive.receive(msg, call Packet.getPayload(msg, NULL), call Packet.payloadLength(msg));
    }
    
    if (buf == -1) {
      dbg("LQI", "Dropped packet due to no space in queue.\n");
      return msg;
    }
    
    if ((call RouteSelect.selectRoute(msg, 0)) != SUCCESS) {
      FwdBufBusy[(uint8_t)buf] = 0;
      return msg;
    }
 
    // Failures at the send level do not cause the seq. number space to be 
    // rolled back properly.  This is somewhat broken.
    call PacketAcknowledgements.requestAck(msg);
    if (call SubSend.send(call AMPacket.destination(msg),
			  msg,
			  call SubPacket.payloadLength(msg) == SUCCESS)) {
      newMsg = FwdBufList[(uint8_t)buf];
      FwdBufList[(uint8_t)buf] = msg;
    }
    else{
      FwdBufBusy[(uint8_t)buf] = 0;
      sendFailures++;
    }
    return newMsg;    
  }

  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    return mForward(msg);
  }
  

  event void SubSend.sendDone(message_t* msg, error_t success) {
    int8_t buf;
    if (!call PacketAcknowledgements.wasAcked(msg) &&
	call AMPacket.destination(msg) != TOS_BCAST_ADDR &&
	fail_count < 5){
      call RouteSelect.selectRoute(msg, 1);
      if (call SubSend.send(call AMPacket.destination(msg),
			    msg,
			    call SubPacket.payloadLength(msg)) == SUCCESS) {
	fail_count ++;
      } else {
	sendFailures++;
      }
    }
    
    fail_count = 0;

    buf = is_ours(msg);

    if (buf != -1) { // Msg was from forwarding queue
      FwdBufBusy[(uint8_t)buf] = 0;
    } else {
      signal Send.sendDone(msg, success);
    } 
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

  command void* Receive.getPayload(message_t* m, uint8_t* len) {
    return call Packet.getPayload(m, len);
  }

  command uint8_t Receive.payloadLength(message_t* m) {
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
    *len -= sizeof(lqi_header_t);
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
    return 0;
  }

  command void CollectionPacket.setType(message_t* msg, collection_id_t id) {}
  
  command uint8_t CollectionPacket.getSequenceNumber(message_t* msg) {
    lqi_header_t* hdr = getHeader(msg);
    return hdr->originseqno;
  }
  
  command void CollectionPacket.setSequenceNumber(message_t* msg, uint8_t seqno) {
    lqi_header_t* hdr = getHeader(msg);
    hdr->originseqno = seqno;
  }
  
  default event void Send.sendDone(message_t* pMsg, error_t success) {}



}

