/*
 * Copyright (c) 2010 Johns Hopkins University.
 * All rights reserved.
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
 * - Neither the name of the copyright holders nor the names of
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
 * @author Doug Carlson
 */

#include "SourceRouteEngine.h"

module SourceRouteEngineP {
  provides {
    interface StdControl;
    interface SourceRouteSend[uint8_t client];
    interface SourceRoutePacket;
    interface Receive[sourceroute_id_t id];
    interface Init;
  }
  uses {
    interface SourceRouteId[uint8_t client];
    interface AMSend as SubSend;
    interface Receive as SubReceive;
    
    interface Queue<srf_queue_entry_t*> as SendQueue;
    interface Pool<srf_queue_entry_t> as QEntryPool;
    interface Pool<message_t> as MessagePool;

    interface SplitControl as SubControl;
  }
}
implementation {
  enum{
    CLIENT_COUNT = uniqueCount(UQ_SRP_CLIENT),
    FORWARD_CLIENT = 0xff,
  };

  //Forwarding engine states
  enum {
    S_OFF = 0,
    S_IDLE = 1,
    S_SENDING = 2,
    S_ERROR = 3,
  };

  //client states
  enum{
    SC_IDLE = 0,
    SC_SENDING = 1,
  };

  //forwarding engine state var
  uint8_t state = S_OFF;
  uint8_t seqno;

  //client variables
  //static space for clients
  srf_queue_entry_t clientEntries[CLIENT_COUNT];
  //client statuses
  uint8_t clientStatus[CLIENT_COUNT];  
  
  sr_header_t* getSRPHeader(message_t* msg);

  void printSRPHeader(sr_header_t* hdr) {
    dbg("SRPDebug", "header %p srlen %d hops_left %d seqno %d payload_id %d\n", hdr, hdr->sr_len, hdr->hops_left, hdr->seqno, hdr->payload_id);
  }
  
  void printQE(srf_queue_entry_t* qe) {
    dbg("SRPDebug", "QE: msg %p len %d client %d\n", qe->msg, qe->len, qe->client);
  }  

  command error_t Init.init(){
    uint8_t i;
    for (i=0; i < CLIENT_COUNT; i++) {
      clientEntries[i].client = i;
    }
    return SUCCESS;
  }

  void setState(uint8_t s) {
    if (state != S_ERROR) {
      dbg("SRPDebug", "setState %d -> %d\n", state, s);
      state = s;
    } else {
      dbg("SRPDebug", "setState Ignore %d -> %d\n", state, s);
    }
  }

  task void sendTask() {
    srf_queue_entry_t* qe;
    error_t err;
    dbg("SRPDebug", "sendTask\n");
    if (state == S_IDLE) {
      dbg("SRPDebug", "state OK\n");
      if (call SendQueue.size() == 0) {
        dbg("SRPDebug", "queue empty\n");
        return;
      } else {
        dbg("SRPDebug", "queue not  empty\n");
        state = S_SENDING;
        qe = call SendQueue.head();
        printQE(qe);
        dbg("SRPInfo", "Sending QE %p msg %p to %d. src %d dest %d seqno %d\n", qe, qe->msg, call SourceRoutePacket.getNextHop(qe->msg), (call SourceRoutePacket.getRoute(qe->msg))[0], call SourceRoutePacket.getDest(qe->msg), getSRPHeader(qe->msg)->seqno);
        err = call SubSend.send(call SourceRoutePacket.getNextHop(qe->msg), qe -> msg, qe->len);
        if ( err == SUCCESS ) {
          dbg("SRPDebug", "sendTask subsend OK\n"); 
        } else {
          dbg("SRPError", "ERROR sendTask subsend failed\n");
          //clean up from failed send. signal local clients or drop forwarding packets
          state = S_IDLE;
          if (qe->client != FORWARD_CLIENT) {
            clientStatus[qe->client] = SC_IDLE;
            signal SourceRouteSend.sendDone[qe->client](qe->msg, FAIL);
          }
          call SendQueue.dequeue();
        }
      }
    } else {
      dbg("SRPDebug", "sendTask: skipping (in state %d)\n", state);
    }
  }

  /**
   * SourceRouteSend commands
   */
  command error_t SourceRouteSend.send[uint8_t client](am_addr_t *path, uint8_t pathLen, message_t* msg, uint8_t len) {
    sr_header_t* hdr; 
    //NOTE this is only here for the workaround required due to nx_am_addr v. am_addr in SourceRoutePacket
    nx_am_addr_t nxPath[SRP_MAX_PATHLEN];
    uint8_t i;
    dbg("SRPDebug", "Send from %d %p\n", client, msg);

    if (state == S_OFF) {
      return EOFF;
    }
    //busy/fail if client is already sending or no space
    if (clientStatus[client] == SC_SENDING) {
      return EBUSY;
    } 
    if ( call SendQueue.size() == call SendQueue.maxSize() ) {
      return FAIL;
    }

    //NOTE: setting route is unsafe with memcpy as-is (am_addr_t vs nx_am_addr_t)
    //would like to do:
    //  call SourceRoutePacket.setRoute(msg, path, pathLen);
    //this is the workaround until SourceRoutePacket.setRoute signature changes
    for (i = 0; i < pathLen; i++) {
      nxPath[i] = path[i];
    }
    call SourceRoutePacket.setRoute(msg, nxPath, pathLen);

    hdr = getSRPHeader(msg);
    hdr -> payload_id = call SourceRouteId.fetch[client]();
    hdr -> seqno = seqno++;
    
    //set hops_left to path length - 2 (NOTE e.g. one-hop path has S, D is of length 2. when a packet is received with hops_left = 0, it is at the destination)
    hdr -> hops_left = pathLen - 2;
    
    clientStatus[client] = SC_SENDING;
    if (call SendQueue.enqueue(&clientEntries[client]) == SUCCESS) {
      clientEntries[client].msg = msg;
      //NOTE: variable-length path will change this
      clientEntries[client].len = len + sizeof(sr_header_t);
      post sendTask();
      printSRPHeader(hdr);
      return SUCCESS;
    } else {
      clientStatus[client] = SC_IDLE;
      return FAIL;
    }
  }

  command void* SourceRouteSend.getPayload[uint8_t client](message_t* msg, uint8_t len) {
    if (len > call SourceRouteSend.maxPayloadLength[client]()) {
      return NULL;
    } else {
      return call SubSend.getPayload(msg, len + sizeof(sr_header_t)) + sizeof(sr_header_t);
    }
  }

  command uint8_t SourceRouteSend.maxPayloadLength[uint8_t client]() {
    return call SubSend.maxPayloadLength() - sizeof(sr_header_t);
  }

  command error_t SourceRouteSend.cancel[uint8_t client](message_t* msg) {
    //TODO: SourceRouteSend.cancel: find msg in queue and remove it if possible
    return FAIL;
  }

  /**
   * SubSend
   */
  event void SubSend.sendDone(message_t* msg, error_t err) {
    srf_queue_entry_t* qe;
    dbg("SRPDebug", "SubSend.sendDone %d %p\n",err, msg);
    if (state != S_SENDING) {
      dbg("SRPError", "ERROR bad state: %d\n", state);
      setState(S_ERROR);
    }  else {
      state = S_IDLE;
      qe = call SendQueue.dequeue();

      if (qe -> msg != msg ) {
        dbg("SRPError", "ERROR queue message != sent message %p != %p \n", msg, qe->msg);
        setState(S_ERROR);
        return;
      }

      if (! call SendQueue.empty()) {
        post sendTask();
      }

      if (qe -> client == FORWARD_CLIENT) {
        dbg("SRPDebug", "Finished forwarding qe %p msg %p, put them back in pools\n", qe, msg);
        call MessagePool.put(msg);
        call QEntryPool.put(qe);
      } else {
        dbg("SRPDebug", "Finished sending for %d\n", qe->client);
        clientStatus[qe->client] = SC_IDLE;
        signal SourceRouteSend.sendDone[qe->client](msg, err);
      } 
    } 
    dbg("SRPInfo","After SendDone: state %d SendQueue len %d, QEPool size %d, MsgPool size %d\n", state, call SendQueue.size(), call QEntryPool.size(), call MessagePool.size());
  }

  /**
   * SubReceive
   */
  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
     sr_header_t* hdr;
     srf_queue_entry_t* qe;

     dbg("SRPDebug", "receive m %p p %p l %d\n", msg, payload, len);
     hdr = getSRPHeader(msg);
     printSRPHeader(hdr);
     //remove header/signal up
     if (hdr -> hops_left == 0) {
       return signal Receive.receive[hdr -> payload_id](msg, call SourceRouteSend.getPayload[0](msg, len - sizeof(sr_header_t)), len - sizeof(sr_header_t));
     } else {
       dbg("SRPDebug", "forwarding %p\n", msg);
       if ( call SendQueue.size() < call SendQueue.maxSize() 
            && ! call MessagePool.empty() 
            && ! call QEntryPool.empty() ) {
         hdr-> hops_left--;
         qe = call QEntryPool.get();
         qe -> client = FORWARD_CLIENT;
         qe -> len = len;
         qe -> msg = msg;
         call SendQueue.enqueue(qe);
         post sendTask();
         return call MessagePool.get();
       } else {
         dbg("SRPError", "ERROR queue full or message pool empty or queue entry pool empty\n");
         return msg;
       }
     }
  }


  /**
   * SourceRoutePacket commands
   */
  sr_header_t* getSRPHeader(message_t* msg) {
    sr_header_t* ret = (sr_header_t*)call SubSend.getPayload(msg, sizeof(sr_header_t));
    return ret;
  }

  command error_t SourceRoutePacket.clearRoute(message_t *msg) {
    //NOTE that if the route goes in the footer or is variable-length, we can't safely overwrite the values in it (space might be used for payload). 
    memset(getSRPHeader(msg)->route, 0, sizeof(nx_am_addr_t)*SRP_MAX_PATHLEN);
    getSRPHeader(msg)->sr_len = 0; 
    return SUCCESS;
  }

  command error_t SourceRoutePacket.setRoute(message_t *msg, nx_am_addr_t *path, uint8_t len) {
    sr_header_t* hdr = getSRPHeader(msg);
    hdr -> sr_len = len;
    memcpy(hdr->route, path, len * sizeof(nx_am_addr_t));
    return FAIL;
  }

  command nx_am_addr_t* SourceRoutePacket.getRoute(message_t *msg) {
    return getSRPHeader(msg) -> route;
  }
  
  command uint8_t SourceRoutePacket.getRouteLen(message_t *msg) {
    return getSRPHeader(msg) -> sr_len;
  }

  command error_t SourceRoutePacket.setRouteLen(message_t *msg, uint8_t len) {
    getSRPHeader(msg) -> sr_len = len;
    return SUCCESS;
  }

  //NOTE: The hops_left field is decremented when the packet is enqueued (i.e. at forward, not at sendTask)
  //NOTE: When a packet reaches the destination, hops_left is 0.
  //NOTE: So, getNextHop should return the destination addr when hops_left is 0.
  command am_addr_t SourceRoutePacket.getNextHop(message_t *msg) {
    sr_header_t* hdr = getSRPHeader(msg);
    return (call SourceRoutePacket.getRoute(msg))[hdr->sr_len - 1 - hdr->hops_left ];
  }

  command am_addr_t SourceRoutePacket.getDest(message_t *msg) {
    sr_header_t* hdr = getSRPHeader(msg);
    return (call SourceRoutePacket.getRoute(msg))[hdr->sr_len - 1];
  }
  
  command am_addr_t SourceRoutePacket.getSource(message_t *msg) {
    sr_header_t* hdr = getSRPHeader(msg);
    return (call SourceRoutePacket.getRoute(msg))[0];
  }
  
  command uint8_t SourceRoutePacket.getHopsLeft(message_t *msg) {
    sr_header_t* hdr = getSRPHeader(msg);
    return hdr->hops_left ;
  }

  command error_t SourceRoutePacket.setHopsLeft(message_t *msg, uint8_t hopsLeft) {
    getSRPHeader(msg) -> hops_left = hopsLeft;
    return SUCCESS;
  }
  
  command uint8_t SourceRoutePacket.getSeqNo(message_t *msg) {
    return getSRPHeader(msg) -> seqno;
  }

  /**
   * StdControl commands. should it be splitcontrol?
   */
  command error_t StdControl.start() {
    setState(S_IDLE);
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    setState(S_OFF);
    return SUCCESS;
  }

  /**
   *  SubControl events. 
   */
  event void SubControl.startDone(error_t error) {
    setState(S_IDLE);
    //OK to start forwarding.
  }

  event void SubControl.stopDone(error_t error) {
    setState(S_OFF);
    //stop forwarding: should tell clients that the radio is off?
  }

  /** 
   *  Defaults
   */
  default event void SourceRouteSend.sendDone[uint8_t client](message_t *msg, error_t error) {
  }
	  
  default event message_t *
  Receive.receive[sourceroute_id_t sourcerouteid](message_t *msg, void *payload, uint8_t len) {
    return msg;
  }

  default command sourceroute_id_t SourceRouteId.fetch[uint8_t client]() {
    return 0;
  }

}
