// $Id: SendVirtualizerP.nc,v 1.2 2007-09-13 23:10:18 scipio Exp $
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
 * A Send queue that provides a Service Instance pattern for formatted
 * packets and calls an underlying Send in a round-robin fashion. Used
 * to share L3 bandwidth between different communication clients.
 *
 * @author Philip Levis
 * @date   April 6 2007
 */ 

#include "AM.h"

generic module SendVirtualizerP(int numClients) {
    provides interface Send[uint8_t client];
    uses { 
      interface Send as SubSend;
      interface Packet;
    }
}

implementation {
    typedef struct {
        message_t* msg;
    } queue_entry_t;
  
    uint8_t current = numClients; // mark as empty
    queue_entry_t queue[numClients];
    uint8_t cancelMask[numClients/8 + 1];

    void tryToSend();
    
    void nextPacket() {
        uint8_t i;
        current = (current + 1) % numClients;
        for(i = 0; i < numClients; i++) {
            if((queue[current].msg == NULL) ||
               (cancelMask[current/8] & (1 << current%8)))
            {
                current = (current + 1) % numClients;
            }
            else {
                break;
            }
        }
        if(i >= numClients) current = numClients;
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
        if (clientId >= numClients) {
            return FAIL;
        }
        if (queue[clientId].msg != NULL) {
            return EBUSY;
        }
        dbg("AMQueue", "AMQueue: request to send from %hhu (%p): passed checks\n", clientId, msg);
        
        queue[clientId].msg = msg;
        call Packet.setPayloadLength(msg, len);
    
        if (current >= numClients) { // queue empty
            error_t err;
            current = clientId;
            
            err = call SubSend.send(msg, len);
            if (err != SUCCESS) {
	      dbg("AMQueue", "%s: underlying send failed.\n", __FUNCTION__);
	      current = numClients;
	      queue[clientId].msg = NULL;
            }
            return err;
        }
        else {
	  dbg("AMQueue", "AMQueue: request to send from %hhu (%p): queue not empty\n", clientId, msg);
        }
        return SUCCESS;
    }

    task void CancelTask() {
      uint8_t i,j,mask,last;
      message_t *msg;
      for(i = 0; i < numClients/8 + 1; i++) {
	if(cancelMask[i]) {
	  for(mask = 1, j = 0; j < 8; j++) {
	    if(cancelMask[i] & mask) {
	      last = i*8 + j;
	      msg = queue[last].msg;
		queue[last].msg = NULL;
		cancelMask[i] &= ~mask;
		signal Send.sendDone[last](msg, ECANCEL);
	    }
	    mask <<= 1;
	  }
	}
      }
    }
    
    command error_t Send.cancel[uint8_t clientId](message_t* msg) {
      if (clientId >= numClients ||         // Not a valid client    
	  queue[clientId].msg == NULL ||    // No packet pending
	  queue[clientId].msg != msg) {     // Not the right packet
	return FAIL;
      }
      if(current == clientId) {
	error_t err = call SubSend.cancel(msg);
	return err;
      }
      else {
	cancelMask[clientId/8] |= 1 << clientId % 8;
	post CancelTask();
	return SUCCESS;
      }
    }

    void sendDone(uint8_t last, message_t *msg, error_t err) {
      queue[last].msg = NULL;
      tryToSend();
      signal Send.sendDone[last](msg, err);
    }

    task void errorTask() {
      sendDone(current, queue[current].msg, FAIL);
    }
    
    // NOTE: Increments current!
    void tryToSend() {
      nextPacket();
      if (current < numClients) { // queue not empty
	error_t nextErr;
	message_t* nextMsg = queue[current].msg;
	uint8_t len = call Packet.payloadLength(nextMsg);
	nextErr = call SubSend.send(nextMsg, len);
	if(nextErr != SUCCESS) {
	  post errorTask();
	}
      }
    }
    
    event void SubSend.sendDone(message_t* msg, error_t err) {
      if(queue[current].msg == msg) {
	sendDone(current, msg, err);
      }
      else {
	dbg("PointerBug", "%s received send done for %p, signaling for %p.\n",
	    __FUNCTION__, msg, queue[current].msg);
      }
    }
    
    command uint8_t Send.maxPayloadLength[uint8_t id]() {
        return call SubSend.maxPayloadLength();
    }

    command void* Send.getPayload[uint8_t id](message_t* m, uint8_t len) {
      return call SubSend.getPayload(m, len);
    }

    default event void Send.sendDone[uint8_t id](message_t* msg, error_t err) {
        // Do nothing
    }
}
