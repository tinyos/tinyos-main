/* $Id: ForwardingEngineP.nc,v 1.3 2006-11-07 19:31:18 scipio Exp $ */
/*
 * Copyright (c) 2006 Stanford University.
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

/**
 *  The ForwardingEngine is responsible for queueing and scheduling outgoing
 *  packets in a collection protocol. It maintains a pool of forwarding messages 
 *  and a packet send 
 *  queue. A ForwardingEngine with a forwarding message pool of size <i>F</i> 
 *  and <i>C</i> CollectionSenderC clients has a send queue of size
 *  <i>F + C</i>. This implementation has a large number of configuration
 *  constants, which can be found in <code>ForwardingEngine.h</code>.
 *
 *  <p>Packets in the send queue are sent in FIFO order, with head-of-line
 *  blocking. Because this is a tree collection protocol, all packets are going
 *  to the same destination, and so the ForwardingEngine does not distinguish
 *  packets from one another: packets from CollectionSenderC clients are
 *  treated identically to forwarded packets.</p>
 *
 *  <p>If ForwardingEngine is on top of a link layer that supports
 *  synchronous acknowledgments, it enables them and retransmits packets
 *  when they are not acked. It transmits a packet up to MAX_RETRIES times
 *  before giving up and dropping the packet.</p> 
 *
 *  <p>The ForwardingEngine detects routing loops and tries to correct
 *  them. It assumes that the collection tree is based on a gradient,
 *  such as hop count or estimated transmissions. When the ForwardingEngine
 *  sends a packet to the next hop, it puts the local gradient value in
 *  the packet header. If a node receives a packet to forward whose
 *  gradient value is less than its own, then the gradient is not monotonically
 *  decreasing and there may be a routing loop. When the ForwardingEngine
 *  receives such a packet, it tells the RoutingEngine to advertise its
 *  gradient value soon, with the hope that the advertisement will update
 *  the node who just sent a packet and break the loop.
 *  
 *  <p>ForwardingEngine times its packet transmissions. It differentiates
 *  between four transmission cases: forwarding, success, ack failure, 
 *  and loop detection. In each case, the
 *  ForwardingEngine waits a randomized period of time before sending the next
 *  packet. This approach assumes that the network is operating at low
 *  utilization; its goal is to prevent correlated traffic -- such as 
 *  nodes along a route forwarding packets -- from interfering with itself.
 *
 *  <table>
 *    <tr>
 *      <td><b>Case</b></td>
 *      <td><b>CC2420 Wait (ms)</b></td>
 *      <td><b>Other Wait (ms)</b></td>
 *      <td><b>Description</b></td>
 *    </tr>
 *    <tr>
 *      <td>Forwarding</td>
 *      <td>Immediate</td>
 *      <td>Immediate</td>
 *      <td>When the ForwardingEngine receives a packet to forward and it is not
 *          already sending a packet (queue is empty). In this case, it immediately
 *          forwards the packet.</td>
 *    </tr>
 *    <tr>
 *      <td>Success</td>
 *      <td>16-31</td>
 *      <td>128-255</td>
 *      <td>When the ForwardingEngine successfully sends a packet to the next
 *          hop, it waits this long before sending the next packet in the queue.
 *          </td>
 *    </tr>
 *    <tr>
 *      <td>Ack Failure</td>
 *      <td>8-15</td>
 *      <td>128-255</td>
 *      <td>If the link layer supports acks and the ForwardingEngine did not
 *          receive an acknowledgment from the next hop, it waits this long before
 *          trying a retransmission. If the packet has exceeded the retransmission
 *          count, ForwardingEngine drops the packet and uses the Success timer instead. </td>
 *    </tr>
 *    <tr>
 *      <td>Loop Detection</td>
 *      <td>32-63</td>
 *      <td>512-1023</td>
 *      <td>If the ForwardingEngine is asked to forward a packet from a node that
 *          believes it is closer to the root, the ForwardingEngine pauses its
 *          transmissions for this interval and triggers the RoutingEngine to 
 *          send an update. The goal is to let the gradient become consistent before
 *          sending packets, in order to prevent routing loops from consuming
 *          bandwidth and energy.</td>
 *    </tr>
 *  </table>  
 *
 *  <p>The times above are all for CC2420-based platforms. The timings for
 *  other platforms depend on their bit rates, as they are based on packet
 *  transmission times.</p>

 *  @author Philip Levis
 *  @author Kyle Jamieson
 *  @date   $Date: 2006-11-07 19:31:18 $
 */

#include <ForwardingEngine.h>
#include "CollectionDebugMsg.h"
   
generic module ForwardingEngineP() {
  provides {
    interface Init;
    interface StdControl;
    interface Send[uint8_t client];
    interface Receive[collection_id_t id];
    interface Receive as Snoop[collection_id_t id];
    interface Intercept[collection_id_t id];
    interface Packet;
    interface CollectionPacket;
  }
  uses {
    interface AMSend as SubSend;
    interface Receive as SubReceive;
    interface Receive as SubSnoop;
    interface Packet as SubPacket;
    interface UnicastNameFreeRouting;
    interface SplitControl as RadioControl;
    interface Queue<fe_queue_entry_t*> as SendQueue;
    interface Pool<fe_queue_entry_t> as QEntryPool;
    interface Pool<message_t> as MessagePool;
    interface Timer<TMilli> as RetxmitTimer;
    interface Cache<uint32_t> as SentCache;
    interface TreeRoutingInspect;
    interface PacketAcknowledgements;
    interface Random;
    interface RootControl;
    interface CollectionId[uint8_t client];
    interface AMPacket;
    interface CollectionDebug;
    interface LinkEstimator;
    interface Leds;
  }
}
implementation {
  /* Starts the retxmit timer with a random number masked by the given
   * mask and added to the given offset.
   */
  static void startRetxmitTimer(uint16_t mask, uint16_t offset);

  /* Keeps track of whether the routing layer is running; if not,
   * it will not send packets. */
  bool running = FALSE;

  /* Keeps track of whether the radio is on; no sense sending packets
   * if the radio is off. */
  bool radioOn = FALSE;

  /* Keeps track of whether an ack is pending on an outgoing packet,
   * so that the engine can work unreliably when the data-link layer
   * does not support acks. */
  bool ackPending = FALSE;

  /* Keeps track of whether the packet on the head of the queue
   * is being used, and control access to the data-link layer.*/
  bool sending = FALSE;

  /* Keep track of the last parent address we sent to, so that
     unacked packets to an old parent are not incorrectly attributed
     to a new parent. */
  am_addr_t lastParent;
  
  /* Network-level sequence number, so that receivers
   * can distinguish retransmissions from different packets. */
  uint8_t seqno;

  enum {
    CLIENT_COUNT = uniqueCount(UQ_COLLECTION_CLIENT)
  };

  /* Each sending client has its own reserved queue entry.
     If the client has a packet pending, its queue entry is in the 
     queue, and its clientPtr is NULL. If the client is idle,
     its queue entry is pointed to by clientPtrs. */

  fe_queue_entry_t clientEntries[CLIENT_COUNT];
  fe_queue_entry_t* clientPtrs[CLIENT_COUNT];

  /* The loopback message is for when a collection roots calls
     Send.send. Since Send passes a pointer but Receive allows
     buffer swaps, the forwarder copies the sent packet into 
     the loopbackMsgPtr and performs a buffer swap with it.
     See sendTask(). */
     
  message_t loopbackMsg;
  message_t* loopbackMsgPtr;

  command error_t Init.init() {
    int i;
    for (i = 0; i < CLIENT_COUNT; i++) {
      clientPtrs[i] = clientEntries + i;
      dbg("Forwarder", "clientPtrs[%hhu] = %p\n", i, clientPtrs[i]);
    }
    loopbackMsgPtr = &loopbackMsg;
    lastParent = call AMPacket.address();
    seqno = 0;
    return SUCCESS;
  }

  command error_t StdControl.start() {
    running = TRUE;
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    running = FALSE;
    return SUCCESS;
  }

  /* sendTask is where the first phase of all send logic
   * exists (the second phase is in SubSend.sendDone()). */
  task void sendTask();
  
  /* ForwardingEngine keeps track of whether the underlying
     radio is powered on. If not, it enqueues packets;
     when it turns on, it then starts sending packets. */ 
  event void RadioControl.startDone(error_t err) {
    if (err == SUCCESS) {
      radioOn = TRUE;
      if (!call SendQueue.empty()) {
        post sendTask();
      }
    }
  }
 
  /* 
   * If the ForwardingEngine has stopped sending packets because
   * these has been no route, then as soon as one is found, start
   * sending packets.
   */ 
  event void UnicastNameFreeRouting.routeFound() {
    post sendTask();
  }

  event void UnicastNameFreeRouting.noRoute() {
    // Depend on the sendTask to take care of this case;
    // if there is no route the component will just resume
    // operation on the routeFound event
  }
  
  event void RadioControl.stopDone(error_t err) {
    if (err == SUCCESS) {
      radioOn = FALSE;
    }
  }

  network_header_t* getHeader(message_t* m) {
    return (network_header_t*)call SubPacket.getPayload(m, NULL);
  }
 
  /*
   * The send call from a client. Return EBUSY if the client is busy
   * (clientPtrs is NULL), otherwise configure its queue entry
   * and put it in the send queue. If the ForwardingEngine is not
   * already sending packets (the RetxmitTimer isn't running), post
   * sendTask. It could be that the engine is running and sendTask
   * has already been posted, but the post-once semantics make this
   * not matter.
   */ 
  command error_t Send.send[uint8_t client](message_t* msg, uint8_t len) {
    network_header_t* hdr;
    fe_queue_entry_t *qe;
    dbg("Forwarder", "%s: sending packet from client %hhu: %x, len %hhu\n", __FUNCTION__, client, msg, len);
    if (!running) {return EOFF;}
    if (len > call Send.maxPayloadLength[client]()) {return ESIZE;}
    
    call Packet.setPayloadLength(msg, len);
    hdr = getHeader(msg);
    hdr->origin = TOS_NODE_ID;
    hdr->seqno  = seqno++;
    hdr->collectid = call CollectionId.fetch[client]();

    if (clientPtrs[client] == NULL) {
      dbg("Forwarder", "%s: send failed as client is busy.\n", __FUNCTION__);
      return EBUSY;
    }

    qe = clientPtrs[client];
    qe->msg = msg;
    qe->client = client;
    qe->retries = MAX_RETRIES;
    dbg("Forwarder", "%s: queue entry for %hhu is %hhu deep\n", __FUNCTION__, client, call SendQueue.size());
    if (call SendQueue.enqueue(qe) == SUCCESS) {
      if (radioOn && !call RetxmitTimer.isRunning()) {
        post sendTask();
      }
      clientPtrs[client] = NULL;
      return SUCCESS;
    }
    else {
      dbg("Forwarder", 
          "%s: send failed as packet could not be enqueued.\n", 
          __FUNCTION__);
      
      // send a debug message to the uart
      call CollectionDebug.logEvent(NET_C_FE_SEND_QUEUE_FULL);

      // Return the pool entry, as it's not for me...
      return FAIL;
    }
  }

  command error_t Send.cancel[uint8_t client](message_t* msg) {
    // cancel not implemented. will require being able
    // to pull entries out of the queue.
    return FAIL;
  }

  command uint8_t Send.maxPayloadLength[uint8_t client]() {
    return call Packet.maxPayloadLength();
  }

  command void* Send.getPayload[uint8_t client](message_t* msg) {
    return call Packet.getPayload(msg, NULL);
  }

  /*
   * These is where all of the send logic is. When the ForwardingEngine
   * wants to send a packet, it posts this task. The send logic is
   * independent of whether it is a forwarded packet or a packet from
   * a send client. 
   *
   * The task first checks that there is a packet to send and that
   * there is a valid route. It then marshals the relevant arguments
   * and prepares the packet for sending. If the node is a collection
   * root, it signals Receive with the loopback message. Otherwise,
   * it sets the packet to be acknowledged and sends it. It does not
   * remove the packet from the send queue: while sending, the 
   * packet being sent is at the head of the queue; a packet is dequeued
   * in the sendDone handler, either due to retransmission failure
   * or to a successful send.
   */

  task void sendTask() {
    dbg("Forwarder", "%s: Trying to send a packet. Queue size is %hhu.\n", __FUNCTION__, call SendQueue.size());
    if (sending) {
      dbg("Forwarder", "%s: busy, don't send\n", __FUNCTION__);
      call CollectionDebug.logEvent(NET_C_FE_SEND_BUSY);
      return;
    }
    else if (call SendQueue.empty()) {
      dbg("Forwarder", "%s: queue empty, don't send\n", __FUNCTION__);
      call CollectionDebug.logEvent(NET_C_FE_SENDQUEUE_EMPTY);
      return;
    }
    else if (!call RootControl.isRoot() && 
             !call UnicastNameFreeRouting.hasRoute()) {
      dbg("Forwarder", "%s: no route, don't send, start retry timer\n", __FUNCTION__);
      call RetxmitTimer.startOneShot(10000);

      // send a debug message to the uart
      call CollectionDebug.logEvent(NET_C_FE_NO_ROUTE);

      return;
    }
    else {
      error_t subsendResult;
      fe_queue_entry_t* qe = call SendQueue.head();
      uint8_t payloadLen = call SubPacket.payloadLength(qe->msg);
      am_addr_t dest = call UnicastNameFreeRouting.nextHop();
      uint32_t msg_uid = call CollectionPacket.getPacketID(qe->msg);
      uint16_t gradient;

      if (call SentCache.lookup(msg_uid)) {
        call CollectionDebug.logEvent(NET_C_FE_DUPLICATE_CACHE_AT_SEND);
        call SendQueue.dequeue();
	post sendTask();
        return;
      }
      /* If our current parent is not the same as the last parent
	 we sent do, then reset the count of unacked packets: don't
	 penalize a new parent for the failures of a prior one.*/
      if (dest != lastParent) {
	qe->retries = MAX_RETRIES;
	lastParent = dest;
      }
 
      dbg("Forwarder", "Sending queue entry %p\n", qe);
      if (call RootControl.isRoot()) {
        collection_id_t collectid = getHeader(qe->msg)->collectid;
        memcpy(loopbackMsgPtr, qe->msg, sizeof(message_t));
        ackPending = FALSE;
	
        dbg("Forwarder", "%s: I'm a root, so loopback and signal receive.\n", __FUNCTION__);
        loopbackMsgPtr = signal Receive.receive[collectid](loopbackMsgPtr,
							  call Packet.getPayload(loopbackMsgPtr, NULL), 
							  call Packet.payloadLength(loopbackMsgPtr));
        signal SubSend.sendDone(qe->msg, SUCCESS);
        return;
      }
      
      // Loop-detection functionality:
      if (call TreeRoutingInspect.getMetric(&gradient) != SUCCESS) {
        // If we have no metric, set our gradient conservatively so
        // that other nodes don't automatically drop our packets.
        gradient = 0;
      }
      call CollectionPacket.setGradient(qe->msg, gradient);
      
      ackPending = (call PacketAcknowledgements.requestAck(qe->msg) == SUCCESS);
      
      subsendResult = call SubSend.send(dest, qe->msg, payloadLen);
      if (subsendResult == SUCCESS) {
        // Successfully submitted to the data-link layer.
        sending = TRUE;
        dbg("Forwarder", "%s: subsend succeeded with %p.\n", __FUNCTION__, qe->msg);
        if (qe->client < CLIENT_COUNT) {
	        dbg("Forwarder", "%s: client packet.\n", __FUNCTION__);
        }
        else {
	        dbg("Forwarder", "%s: forwarded packet.\n", __FUNCTION__);
        }
        return;
      }
      else if (subsendResult == EOFF) {
	// The radio has been turned off underneath us. Assume that
	// this is for the best. When the radio is turned back on, we'll
	// handle a startDone event and resume sending.
        radioOn = FALSE;
	dbg("Forwarder", "%s: subsend failed from EOFF.\n", __FUNCTION__);
        // send a debug message to the uart
      	call CollectionDebug.logEvent(NET_C_FE_SUBSEND_OFF);
      }
      else if (subsendResult == EBUSY) {
	// This shouldn't happen, as we sit on top of a client and
        // control our own output; it means we're trying to
        // double-send (bug). This means we expect a sendDone, so just
        // wait for that: when the sendDone comes in, // we'll try
        // sending this packet again.	
	dbg("Forwarder", "%s: subsend failed from EBUSY.\n", __FUNCTION__);
        // send a debug message to the uart
        call CollectionDebug.logEvent(NET_C_FE_SUBSEND_BUSY);
      }
      else if (subsendResult == ESIZE) {
	dbg("Forwarder", "%s: subsend failed from ESIZE: truncate packet.\n", __FUNCTION__);
	call Packet.setPayloadLength(qe->msg, call Packet.maxPayloadLength());
	post sendTask();
	call CollectionDebug.logEvent(NET_C_FE_SUBSEND_SIZE);
      }
    }
  }

  void sendDoneBug() {
    // send a debug message to the uart
    call CollectionDebug.logEvent(NET_C_FE_BAD_SENDDONE);
  }

  /*
   * The second phase of a send operation; based on whether the transmission was
   * successful, the ForwardingEngine either stops sending or starts the
   * RetxmitTimer with an interval based on what has occured. If the send was
   * successful or the maximum number of retransmissions has been reached, then
   * the ForwardingEngine dequeues the current packet. If the packet is from a
   * client it signals Send.sendDone(); if it is a forwarded packet it returns
   * the packet and queue entry to their respective pools.
   * 
   */

  event void SubSend.sendDone(message_t* msg, error_t error) {
    fe_queue_entry_t *qe = call SendQueue.head();
    dbg("Forwarder", "%s to %hu and %hhu\n", __FUNCTION__, call AMPacket.destination(msg), error);
    if (qe == NULL || qe->msg != msg) {
      dbg("Forwarder", "%s: BUG: not our packet (%p != %p)!\n", __FUNCTION__, msg, qe->msg);
      sendDoneBug();      // Not our packet, something is very wrong...
      return;
    }
    else if (error != SUCCESS) {
      // Immediate retransmission is the worst thing to do.
      dbg("Forwarder", "%s: send failed\n", __FUNCTION__);
      call CollectionDebug.logEventMsg(NET_C_FE_SENDDONE_FAIL, 
					 call CollectionPacket.getSequenceNumber(msg), 
					 call CollectionPacket.getOrigin(msg), 
                                         call AMPacket.destination(msg));
      startRetxmitTimer(SENDDONE_FAIL_WINDOW, SENDDONE_FAIL_OFFSET);
    }
    else if (ackPending && !call PacketAcknowledgements.wasAcked(msg)) {

      call LinkEstimator.txNoAck(AMPacket.destination(msg));

      // AckPending is for case when DL cannot support acks.
      if (--qe->retries) { 
        dbg("Forwarder", "%s: not acked\n", __FUNCTION__);
        call CollectionDebug.logEventMsg(NET_C_FE_SENDDONE_WAITACK, 
					 call CollectionPacket.getSequenceNumber(msg), 
					 call CollectionPacket.getOrigin(msg), 
                                         call AMPacket.destination(msg));
        startRetxmitTimer(SENDDONE_NOACK_WINDOW, SENDDONE_NOACK_OFFSET);
      } else {
        //max retries, dropping packet
        if (qe->client < CLIENT_COUNT) {
            clientPtrs[qe->client] = qe;
            signal Send.sendDone[qe->client](msg, FAIL);
            call CollectionDebug.logEventMsg(NET_C_FE_SENDDONE_FAIL_ACK_SEND, 
					 call CollectionPacket.getSequenceNumber(msg), 
					 call CollectionPacket.getOrigin(msg), 
                                         call AMPacket.destination(msg));
        } else {
           if (call MessagePool.put(qe->msg) != SUCCESS)
             call CollectionDebug.logEvent(NET_C_FE_PUT_MSGPOOL_ERR);
           if (call QEntryPool.put(qe) != SUCCESS)
             call CollectionDebug.logEvent(NET_C_FE_PUT_QEPOOL_ERR);
           call CollectionDebug.logEventMsg(NET_C_FE_SENDDONE_FAIL_ACK_FWD, 
					 call CollectionPacket.getSequenceNumber(msg), 
					 call CollectionPacket.getOrigin(msg), 
                                         call AMPacket.destination(msg));
        }
        call SendQueue.dequeue();
        sending = FALSE;
        startRetxmitTimer(SENDDONE_OK_WINDOW, SENDDONE_OK_OFFSET);
      }
    }
    else if (qe->client < CLIENT_COUNT) {
      network_header_t* hdr;
      uint8_t client = qe->client;
      dbg("Forwarder", "%s: our packet for client %hhu, remove %p from queue\n", 
          __FUNCTION__, client, qe);
      call CollectionDebug.logEventMsg(NET_C_FE_SENT_MSG, 
					 call CollectionPacket.getSequenceNumber(msg), 
					 call CollectionPacket.getOrigin(msg), 
                                         call AMPacket.destination(msg));
      call LinkEstimator.txAck(AMPacket.destination(msg));
      clientPtrs[client] = qe;
      hdr = getHeader(qe->msg);
      call SendQueue.dequeue();
      signal Send.sendDone[client](msg, SUCCESS);
      sending = FALSE;
      startRetxmitTimer(SENDDONE_OK_WINDOW, SENDDONE_OK_OFFSET);
    }
    else if (call MessagePool.size() < call MessagePool.maxSize()) {
      // A successfully forwarded packet.
      dbg("Forwarder,Route", "%s: successfully forwarded packet (client: %hhu), message pool is %hhu/%hhu.\n", __FUNCTION__, qe->client, call MessagePool.size(), call MessagePool.maxSize());

      call LinkEstimator.txAck(AMPacket.destination(msg));

      call CollectionDebug.logEventMsg(NET_C_FE_FWD_MSG, 
					 call CollectionPacket.getSequenceNumber(msg), 
					 call CollectionPacket.getOrigin(msg), 
                                         call AMPacket.destination(msg));
      call SentCache.insert(call CollectionPacket.getPacketID(qe->msg));
      call SendQueue.dequeue();
      if (call MessagePool.put(qe->msg) != SUCCESS)
        call CollectionDebug.logEvent(NET_C_FE_PUT_MSGPOOL_ERR);
      if (call QEntryPool.put(qe) != SUCCESS)
        call CollectionDebug.logEvent(NET_C_FE_PUT_QEPOOL_ERR);
      sending = FALSE;
      startRetxmitTimer(SENDDONE_OK_WINDOW, SENDDONE_OK_OFFSET);
      call Leds.led2Toggle();
    }
    else {
      dbg("Forwarder", "%s: BUG: we have a pool entry, but the pool is full, client is %hhu.\n", __FUNCTION__, qe->client);
      sendDoneBug();    // It's a forwarded packet, but there's no room the pool;
      // someone has double-stored a pointer somewhere and we have nowhere
      // to put this, so we have to leak it...
    }
  }

  /*
   * Function for preparing a packet for forwarding. Performs
   * a buffer swap from the message pool. If there are no free
   * message in the pool, it returns the passed message and does not
   * put it on the send queue.
   */
  message_t* forward(message_t* m) {
    if (call MessagePool.empty()) {
      dbg("Route", "%s cannot forward, message pool empty.\n", __FUNCTION__);
      // send a debug message to the uart
      call CollectionDebug.logEvent(NET_C_FE_MSG_POOL_EMPTY);
    }
    else if (call QEntryPool.empty()) {
      dbg("Route", "%s cannot forward, queue entry pool empty.\n", 
          __FUNCTION__);
      // send a debug message to the uart
      call CollectionDebug.logEvent(NET_C_FE_QENTRY_POOL_EMPTY);
    }
    else {
      message_t* newMsg;
      fe_queue_entry_t *qe;
      uint16_t gradient;
      
      qe = call QEntryPool.get();
      if (qe == NULL) {
        call CollectionDebug.logEvent(NET_C_FE_GET_MSGPOOL_ERR);
        return m;
      }

      newMsg = call MessagePool.get();
      if (newMsg == NULL) {
        call CollectionDebug.logEvent(NET_C_FE_GET_QEPOOL_ERR);
        return m;
      }

      memset(newMsg, 0, sizeof(message_t));
      memset(m->metadata, 0, sizeof(message_metadata_t));
      
      qe->msg = m;
      qe->client = 0xff;
      qe->retries = MAX_RETRIES;

      
      if (call SendQueue.enqueue(qe) == SUCCESS) {
        dbg("Forwarder,Route", "%s forwarding packet %p with queue size %hhu\n", __FUNCTION__, m, call SendQueue.size());
        // Loop-detection code:
        if (call TreeRoutingInspect.getMetric(&gradient) == SUCCESS) {
          // We only check for loops if we know our own metric
          if (call CollectionPacket.getGradient(m) < gradient) {
            // The incoming packet's metric (gradient) is less than our
            // own gradient.  Trigger a route update and backoff.
            call TreeRoutingInspect.triggerRouteUpdate();
            startRetxmitTimer(LOOPY_WINDOW, LOOPY_OFFSET);
            call CollectionDebug.logEventMsg(NET_C_FE_LOOP_DETECTED,
					 call CollectionPacket.getSequenceNumber(m), 
					 call CollectionPacket.getOrigin(m), 
                                         call AMPacket.destination(m));
          }
        }

        if (!call RetxmitTimer.isRunning()) {
          // sendTask is only immediately posted if we don't detect a
          // loop.
          post sendTask();
        }
        
        // Successful function exit point:
        return newMsg;
      } else {
        // There was a problem enqueuing to the send queue.
        if (call MessagePool.put(newMsg) != SUCCESS)
          call CollectionDebug.logEvent(NET_C_FE_PUT_MSGPOOL_ERR);
        if (call QEntryPool.put(qe) != SUCCESS)
          call CollectionDebug.logEvent(NET_C_FE_PUT_QEPOOL_ERR);
      }
    }

    // Resource acquisition problem.  Send a debug message to the
    // uart.
    call CollectionDebug.logEvent(NET_C_FE_SEND_QUEUE_FULL);

    // We'll have to drop the packet on the floor: not enough
    // resources available to forward.
    return m;
  }
 
  /*
   * Received a message to forward. Check whether it is a duplicate by
   * checking the packets currently in the queue as well as the 
   * send history cache (in case we recently forwarded this packet).
   * The cache is important as nodes immediately forward packets
   * but wait a period before retransmitting after an ack failure.
   * If this node is a root, signal receive.
   */ 
  event message_t* 
  SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    network_header_t* hdr = getHeader(msg);
    uint8_t netlen;
    collection_id_t collectid;

    uint32_t msg_uid;
    bool duplicate = FALSE;
    fe_queue_entry_t* qe;
    uint8_t i;


    msg_uid = call CollectionPacket.getPacketID(msg);
    collectid = hdr->collectid;

    call CollectionDebug.logEventMsg(NET_C_FE_RCV_MSG,
					 call CollectionPacket.getSequenceNumber(msg), 
					 call CollectionPacket.getOrigin(msg), 
                                         call AMPacket.destination(msg));
    if (len > call SubSend.maxPayloadLength()) {
      return msg;
    }

    //See if we remember having seen this packet
    //We look in the sent cache ...
    if (call SentCache.lookup(msg_uid)) {
        call CollectionDebug.logEvent(NET_C_FE_DUPLICATE_CACHE);
        return msg;
    }
    //... and in the queue for duplicates
    if (call SendQueue.size() > 0) {
      for (i = call SendQueue.size(); --i;) {
	qe = call SendQueue.element(i);
	if (call CollectionPacket.getPacketID(qe->msg) == msg_uid) {
	  duplicate = TRUE;
	  break;
	}
      }
    }
    
    if (duplicate) {
        call CollectionDebug.logEvent(NET_C_FE_DUPLICATE_QUEUE);
        return msg;
    }

    // If I'm the root, signal receive. 
    else if (call RootControl.isRoot())
      return signal Receive.receive[collectid](msg, 
                        call Packet.getPayload(msg, &netlen), 
                        call Packet.payloadLength(msg));
    // I'm on the routing path and Intercept indicates that I
    // should not forward the packet.
    else if (!signal Intercept.forward[collectid](msg, 
                        call Packet.getPayload(msg, &netlen), 
                        call Packet.payloadLength(msg)))
      return msg;
    else {
      dbg("Route", "Forwarding packet from %hu.\n", hdr->origin);
      return forward(msg);
    }
  }

  command void* 
  Receive.getPayload[collection_id_t id](message_t* msg, uint8_t* len) {
    return call Packet.getPayload(msg, NULL);
  }

  command uint8_t
  Receive.payloadLength[collection_id_t id](message_t *msg) {
    return call Packet.payloadLength(msg);
  }

  command void *
  Snoop.getPayload[collection_id_t id](message_t *msg, uint8_t *len) {
    return call Packet.getPayload(msg, NULL);
  }

  command uint8_t Snoop.payloadLength[collection_id_t id](message_t *msg) {
    return call Packet.payloadLength(msg);
  }

  event message_t* 
  SubSnoop.receive(message_t* msg, void *payload, uint8_t len) {
    network_header_t* hdr = getHeader(msg);
    return signal Snoop.receive[hdr->collectid] (msg, (void *)(hdr + 1), 
                                          len - sizeof(network_header_t));
  }
  
  event void RetxmitTimer.fired() {
    sending = FALSE;
    post sendTask();
  }
  
  command void Packet.clear(message_t* msg) {
    call SubPacket.clear(msg);
  }
  
  command uint8_t Packet.payloadLength(message_t* msg) {
    return call SubPacket.payloadLength(msg) - sizeof(network_header_t);
  }

  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    call SubPacket.setPayloadLength(msg, len + sizeof(network_header_t));
  }
  
  command uint8_t Packet.maxPayloadLength() {
    return call SubPacket.maxPayloadLength() - sizeof(network_header_t);
  }

  command void* Packet.getPayload(message_t* msg, uint8_t* len) {
    uint8_t* payload = call SubPacket.getPayload(msg, len);
    if (len != NULL) {
      *len -= sizeof(network_header_t);
    }
    return payload + sizeof(network_header_t);
  }

  command am_addr_t CollectionPacket.getOrigin(message_t* msg) {
    return getHeader(msg)->origin;
  }

  command void CollectionPacket.setOrigin(message_t* msg, am_addr_t addr) {
    getHeader(msg)->origin = addr;
  }

  command uint8_t CollectionPacket.getCollectionID(message_t* msg) {
    return getHeader(msg)->collectid;
  }
  
  command void CollectionPacket.setCollectionID(message_t* msg, uint8_t id) {
    getHeader(msg)->collectid = id;
  }

  command uint8_t CollectionPacket.getControl(message_t* msg) {
    return getHeader(msg)->control;
  }
  
  command void CollectionPacket.setControl(message_t* msg, uint8_t control) {
    getHeader(msg)->control = control;
  }

  command uint16_t CollectionPacket.getGradient(message_t* msg) {
    return getHeader(msg)->gradient;
  }

  command void CollectionPacket.setGradient(message_t* msg, uint16_t gradient) {
    getHeader(msg)->gradient = gradient;
  }

  command uint8_t CollectionPacket.getSequenceNumber(message_t* msg) {
    return getHeader(msg)->seqno;
  }

  command void CollectionPacket.setSequenceNumber(message_t* msg, uint8_t _seqno) {
    getHeader(msg)->seqno = _seqno;
  }

  command uint32_t CollectionPacket.getPacketID(message_t* msg) {
    return ((uint32_t)(getHeader(msg)->origin) << 16) | (uint32_t)(getHeader(msg)->seqno);  
  }

  
  default event void
  Send.sendDone[uint8_t client](message_t *msg, error_t error) {
  }

  default event bool
  Intercept.forward[collection_id_t collectid](message_t* msg, void* payload, 
                                               uint16_t len) {
    return TRUE;
  }

  default event message_t *
  Receive.receive[collection_id_t collectid](message_t *msg, void *payload,
                                             uint8_t len) {
    return msg;
  }

  default event message_t *
  Snoop.receive[collection_id_t collectid](message_t *msg, void *payload,
                                           uint8_t len) {
    return msg;
  }

  default command collection_id_t CollectionId.fetch[uint8_t client]() {
    return 0;
  }

  static void startRetxmitTimer(uint16_t mask, uint16_t offset) {
    uint16_t r = call Random.rand16();
    r &= mask;
    r += offset;
    call RetxmitTimer.startOneShot(r);
    dbg("Forwarder", "started rexmit timer in %hu ms\n", r);
  }

  event void LinkEstimator.evicted(am_addr_t neighbor) {
  }

  /* Default implementations for CollectionDebug calls.
   * These allow CollectionDebug not to be wired to anything if debugging
   * is not desired. */

    default command error_t CollectionDebug.logEvent(uint8_t type) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventSimple(uint8_t type, uint16_t arg) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventDbg(uint8_t type, uint16_t arg1, uint16_t arg2, uint16_t arg3) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventMsg(uint8_t type, uint16_t msg, am_addr_t origin, am_addr_t node) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventRoute(uint8_t type, am_addr_t parent, uint8_t hopcount, uint16_t metric) {
        return SUCCESS;
    }
   
}
