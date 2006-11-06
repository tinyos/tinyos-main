/* $Id: LinkEstimatorDummyP.nc,v 1.2 2006-11-06 11:57:17 scipio Exp $ */
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


#include "Timer.h"

module LinkEstimatorDummyP {
  provides {
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
    interface Timer<TMilli>;
  }
}

implementation {

  // link estimator header added to
  // every message passing thru' the link estimator
  typedef nx_struct linkest_header {
    nx_am_addr_t ll_addr;
  } linkest_header_t;

  linkest_header_t* getHeader(message_t* m) {
    return (linkest_header_t*)call SubPacket.getPayload(m, NULL);
  }


  uint8_t addLinkEstHeaderAndFooter(message_t *msg, uint8_t len) {
    uint8_t newlen;
    linkest_header_t *hdr;
    dbg("LI", "newlen1 = %d\n", len);
    newlen = len + sizeof(linkest_header_t);
    call Packet.setPayloadLength(msg, newlen);
    hdr = getHeader(msg);

    hdr->ll_addr = call SubAMPacket.address();
    dbg("LI", "newlen2 = %d\n", newlen);
    return newlen;
  }

  command error_t Init.init() {
    return SUCCESS;
  }

  event void Timer.fired() { }

  // EETX (Extra Expected number of Transmission)
  // EETX = ETX - 1
  // computeEETX returns EETX*10

  command uint8_t LinkEstimator.getLinkQuality(uint16_t neighbor) {
    return 2;
  }

  command uint8_t LinkEstimator.getReverseQuality(uint16_t neighbor) {
    return 1;
  }

  command uint8_t LinkEstimator.getForwardQuality(uint16_t neighbor) {
    return 1;
  }

  command am_addr_t LinkSrcPacket.getSrc(message_t* msg) {
    linkest_header_t* hdr = getHeader(msg);
    return hdr->ll_addr;
  }

  command error_t Send.send(am_addr_t addr, message_t* msg, uint8_t len) {
    uint8_t newlen;
    newlen = addLinkEstHeaderAndFooter(msg, len);
    return call AMSend.send(addr, msg, newlen);
  }

  event void AMSend.sendDone(message_t* msg, error_t error ) {
    return signal Send.sendDone(msg, error);
  }

  command uint8_t Send.cancel(message_t* msg) {
    return call AMSend.cancel(msg);
  }

  command uint8_t Send.maxPayloadLength() {
    return call Packet.maxPayloadLength();
  }

  command void* Send.getPayload(message_t* msg) {
    return call Packet.getPayload(msg, NULL);
  }

  event message_t* SubReceive.receive(message_t* msg,
				      void* payload,
				      uint8_t len) {
    if (call SubAMPacket.destination(msg) == AM_BROADCAST_ADDR) {
      linkest_header_t* hdr = getHeader(msg);
      dbg("LI", "Got pkt from link: %d\n", hdr->ll_addr);
    }
    
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

  command uint8_t Packet.payloadLength(message_t* msg) {
    return call SubPacket.payloadLength(msg) - sizeof(linkest_header_t);
  }

  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    call SubPacket.setPayloadLength(msg, len + sizeof(linkest_header_t));
  }

  command uint8_t Packet.maxPayloadLength() {
    return call SubPacket.maxPayloadLength() - sizeof(linkest_header_t);
  }

  command void* Packet.getPayload(message_t* msg, uint8_t* len) {
    uint8_t* payload = call SubPacket.getPayload(msg, len);
    if (len != NULL) {
      *len -= sizeof(linkest_header_t);
    }
    return payload + sizeof(linkest_header_t);
  }

}

