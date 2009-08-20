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
/*									tab:4
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
 *
 * @author Stephen Dawson-Haggerty
 * @version $Revision: 1.1 $ $Date: 2009-08-20 01:37:44 $
 */
 
#include "CC2420.h"
#include "IEEE802154.h"

module CC2420Ieee154MessageP {

  provides {
    interface Ieee154Send;
    interface Ieee154Packet;
    interface Packet;
  }
  
  uses {
    interface Send as SubSend;
    interface CC2420Packet;
    interface CC2420PacketBody;
    interface CC2420Config;
  }
}
implementation {

  /***************** Ieee154Send Commands ****************/
  command error_t Ieee154Send.send(ieee154_saddr_t addr,
                                   message_t* msg,
                                   uint8_t len) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader( msg );
    header->dest = addr;
    header->destpan = call CC2420Config.getPanAddr();
    header->src = call CC2420Config.getShortAddr();

    return call SubSend.send( msg, len );
  }

  command error_t Ieee154Send.cancel(message_t* msg) {
    return call SubSend.cancel(msg);
  }

  command uint8_t Ieee154Send.maxPayloadLength() {
    return call Packet.maxPayloadLength();
  }

  command void* Ieee154Send.getPayload(message_t* m, uint8_t len) {
    return call Packet.getPayload(m, len);
  }

  /***************** Ieee154Packet Commands ****************/
  command ieee154_saddr_t Ieee154Packet.address() {
    return call CC2420Config.getShortAddr();
  }
 
  command ieee154_saddr_t Ieee154Packet.destination(message_t* msg) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(msg);
    return header->dest;
  }
 
  command ieee154_saddr_t Ieee154Packet.source(message_t* msg) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(msg);
    return header->src;
  }

  command void Ieee154Packet.setDestination(message_t* msg, ieee154_saddr_t addr) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(msg);
    header->dest = addr;
  }

  command void Ieee154Packet.setSource(message_t* msg, ieee154_saddr_t addr) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(msg);
    header->src = addr;
  }

  command bool Ieee154Packet.isForMe(message_t* msg) {
    return (call Ieee154Packet.destination(msg) == call Ieee154Packet.address() ||
	    call Ieee154Packet.destination(msg) == IEEE154_BROADCAST_ADDR);
  }

  command ieee154_panid_t Ieee154Packet.pan(message_t* msg) {
    return (call CC2420PacketBody.getHeader(msg))->destpan;
  }

  command void Ieee154Packet.setPan(message_t* msg, ieee154_panid_t grp) {
    // Overridden intentionally when we send()
    (call CC2420PacketBody.getHeader(msg))->destpan = grp;
  }

  command ieee154_panid_t Ieee154Packet.localPan() {
    return call CC2420Config.getPanAddr();
  }


  /***************** Packet Commands ****************/
  command void Packet.clear(message_t* msg) {
    memset(call CC2420PacketBody.getHeader(msg), sizeof(cc2420_header_t) - AM_OVERHEAD, 0);
    memset(call CC2420PacketBody.getMetadata(msg), sizeof(cc2420_metadata_t), 0);
  }
  
  command uint8_t Packet.payloadLength(message_t* msg) {
    return (call CC2420PacketBody.getHeader(msg))->length - CC2420_SIZE;
  }
  
  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    (call CC2420PacketBody.getHeader(msg))->length  = len + CC2420_SIZE;
  }
  
  command uint8_t Packet.maxPayloadLength() {
    return TOSH_DATA_LENGTH + AM_OVERHEAD;
  }
  
  command void* Packet.getPayload(message_t* msg, uint8_t len) {
        return call SubSend.getPayload( msg, len );
  }

  
  /***************** SubSend Events ****************/
  event void SubSend.sendDone(message_t* msg, error_t result) {
    signal Ieee154Send.sendDone(msg, result);
  }

  /***************** CC2420Config Events ****************/
  event void CC2420Config.syncDone( error_t error ) {
  }

  default event void Ieee154Send.sendDone(message_t *msg, error_t e) {

  }
}
