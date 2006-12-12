// $Id: AMQueueImplP.nc,v 1.4 2006-12-12 18:23:46 vlahan Exp $
/*
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * An AM send queue that provides a Service Instance pattern for
 * formatted packets and calls an underlying AMSend in a round-robin
 * fashion. Used to share L2 bandwidth between different communication
 * clients.
 *
 * @author Philip Levis
 * @date   Jan 16 2006
 */ 

#include "AM.h"

generic module AMQueueImplP(int numClients) {
  provides interface Send[uint8_t client];
  uses{
    interface AMSend[am_id_t id];
    interface AMPacket;
    interface Packet;
  }
}

implementation {

  
  enum {
    QUEUE_EMPTY = 255,
  };

  typedef struct {
    message_t* msg;
  } queue_entry_t;
  
  uint8_t current = QUEUE_EMPTY;
  queue_entry_t queue[numClients];


  void tryToSend();
  
  void nextPacket() {
    uint16_t i;
    uint8_t initial = current;
    if (initial == QUEUE_EMPTY) {
      initial = 0;
    }
    i = initial;
    for (; i < (initial + numClients); i++) {
      uint8_t client = (uint8_t)i % numClients;
      if (queue[client].msg != NULL) {
	current = client;
	return;
      }
    }
    current = QUEUE_EMPTY;
  }
  

  /**
   * Accepts a properly formatted AM packet for later sending.
   * Assumes that someone has filled in the AM packet fields
   * (destination, AM type).
   *
   * @param msg - the message to send
   * @param len - the length of the payload
   *
   */
  
  command error_t Send.send[uint8_t clientId](message_t* msg,
                                              uint8_t len) {
    if (clientId > numClients) {return FAIL;}
    if (queue[clientId].msg != NULL) {return EBUSY;}
    dbg("AMQueue", "AMQueue: request to send from %hhu (%p): passed checks\n", clientId, msg);

    queue[clientId].msg = msg;
    call Packet.setPayloadLength(msg, len);
    
    if (current == QUEUE_EMPTY) {
      error_t err;
      am_id_t amId = call AMPacket.type(msg);
      am_addr_t dest = call AMPacket.destination(msg);

      dbg("AMQueue", "%s: request to send from %hhu (%p): queue empty\n", __FUNCTION__, clientId, msg);
      current = clientId;

      err = call AMSend.send[amId](dest, msg, len);
      if (err != SUCCESS) {
        dbg("AMQueue", "%s: underlying send failed.\n", __FUNCTION__);
	current = QUEUE_EMPTY;
	queue[clientId].msg = NULL;
      }
      return err;
    }
    else {
      dbg("AMQueue", "AMQueue: request to send from %hhu (%p): queue not empty\n", clientId, msg);
    }
    return SUCCESS;
  }

  command error_t Send.cancel[uint8_t clientId](message_t* msg) {
    if (clientId > numClients ||         // Not a valid client    
	queue[clientId].msg == NULL ||    // No packet pending
	queue[clientId].msg != msg) {     // Not the right packet
      return FAIL;
    }
    if (current == clientId) {
      am_id_t amId = call AMPacket.type(msg);
      error_t err = call AMSend.cancel[amId](msg);
      if (err == SUCCESS) {
	// remove it from the queue
	nextPacket();
      }
      return err;
    }
    else {
      queue[clientId].msg = NULL;
      return SUCCESS;
    }
  }

  task void errorTask() {
    message_t* msg = queue[current].msg;
    queue[current].msg = NULL;
    signal Send.sendDone[current](msg, FAIL);
    tryToSend();
  }

  // NOTE: Increments current!
  void tryToSend() {
    nextPacket();
    if (current != QUEUE_EMPTY) {
      error_t nextErr;
      message_t* nextMsg = queue[current].msg;
      am_id_t nextId = call AMPacket.type(nextMsg);
      am_addr_t nextDest = call AMPacket.destination(nextMsg);
      uint8_t len = call Packet.payloadLength(nextMsg);
      nextErr = call AMSend.send[nextId](nextDest, nextMsg, len);
      if (nextErr != SUCCESS) {
	post errorTask();
      }
    }
  }
  
  event void AMSend.sendDone[am_id_t id](message_t* msg, error_t err) {
    if (queue[current].msg == msg) {
      uint8_t last = current;
      dbg("PointerBug", "%s received send done for %p, signaling for %p.\n", __FUNCTION__, msg, queue[current].msg);
      queue[last].msg = NULL;
      tryToSend();
      signal Send.sendDone[last](msg, err);
    }
  }
  
  command uint8_t Send.maxPayloadLength[uint8_t id]() {
    return call AMSend.maxPayloadLength[0]();
  }

  command void* Send.getPayload[uint8_t id](message_t* m) {
    return call AMSend.getPayload[0](m);
  }

 default event void Send.sendDone[uint8_t id](message_t* msg, error_t err) {
   // Do nothing
 }
}
