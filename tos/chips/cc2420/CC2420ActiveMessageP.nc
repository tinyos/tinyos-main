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
 * Active message implementation on top of the CC2420 radio. This
 * implementation uses the 16-bit addressing mode of 802.15.4: the
 * only additional byte it adds is the AM id byte, as the first byte
 * of the data payload.
 *
 * @author Philip Levis
 * @version $Revision: 1.8 $ $Date: 2007-07-04 00:37:14 $
 */
 
#include "CC2420.h"

module CC2420ActiveMessageP {
  provides {
    interface AMSend[am_id_t id];
    interface Receive[am_id_t id];
    interface Receive as Snoop[am_id_t id];
    interface AMPacket;
    interface Packet;
  }
  uses {
    interface Send as SubSend;
    interface Receive as SubReceive;
    interface CC2420Packet;
    interface CC2420PacketBody;
    interface CC2420Config;
    interface ActiveMessageAddress;
  }
}
implementation {

  enum {
    CC2420_SIZE = MAC_HEADER_SIZE + MAC_FOOTER_SIZE,
  };
  
  /***************** AMSend Commands ****************/
  command error_t AMSend.send[am_id_t id](am_addr_t addr,
					  message_t* msg,
					  uint8_t len) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader( msg );
    header->type = id;
    header->dest = addr;
    header->destpan = call CC2420Config.getPanAddr();
    
    return call SubSend.send( msg, len + CC2420_SIZE );
  }

  command error_t AMSend.cancel[am_id_t id](message_t* msg) {
    return call SubSend.cancel(msg);
  }

  command uint8_t AMSend.maxPayloadLength[am_id_t id]() {
    return call Packet.maxPayloadLength();
  }

  command void* AMSend.getPayload[am_id_t id](message_t* m) {
    return call Packet.getPayload(m, NULL);
  }

  /***************** Receive Commands ****************/
  command void* Receive.getPayload[am_id_t id](message_t* m, uint8_t* len) {
    return call Packet.getPayload(m, len);
  }

  command uint8_t Receive.payloadLength[am_id_t id](message_t* m) {
    return call Packet.payloadLength(m);
  }
  
  /***************** Snoop Commands ****************/
  command void* Snoop.getPayload[am_id_t id](message_t* m, uint8_t* len) {
    return call Packet.getPayload(m, len);
  }

  command uint8_t Snoop.payloadLength[am_id_t id](message_t* m) {
    return call Packet.payloadLength(m);
  }

  /***************** AMPacket Commands ****************/
  command am_addr_t AMPacket.address() {
    return call ActiveMessageAddress.amAddress();
  }
 
  command am_addr_t AMPacket.destination(message_t* amsg) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    return header->dest;
  }
 
  command am_addr_t AMPacket.source(message_t* amsg) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    return header->src;
  }

  command void AMPacket.setDestination(message_t* amsg, am_addr_t addr) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    header->dest = addr;
  }

  command void AMPacket.setSource(message_t* amsg, am_addr_t addr) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    header->src = addr;
  }

  command bool AMPacket.isForMe(message_t* amsg) {
    return (call AMPacket.destination(amsg) == call AMPacket.address() ||
	    call AMPacket.destination(amsg) == AM_BROADCAST_ADDR);
  }

  command am_id_t AMPacket.type(message_t* amsg) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    return header->type;
  }

  command void AMPacket.setType(message_t* amsg, am_id_t type) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    header->type = type;
  }
  
  command am_group_t AMPacket.group(message_t* amsg) {
    return (call CC2420PacketBody.getHeader(amsg))->destpan;
  }

  command void AMPacket.setGroup(message_t* amsg, am_group_t grp) {
    // Overridden intentionally when we send()
    (call CC2420PacketBody.getHeader(amsg))->destpan = grp;
  }

  command am_group_t AMPacket.localGroup() {
    return call CC2420Config.getPanAddr();
  }
  

  /***************** Packet Commands ****************/
  command void Packet.clear(message_t* msg) {
  }
  
  command uint8_t Packet.payloadLength(message_t* msg) {
    return (call CC2420PacketBody.getHeader(msg))->length - CC2420_SIZE;
  }
  
  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    (call CC2420PacketBody.getHeader(msg))->length  = len + CC2420_SIZE;
  }
  
  command uint8_t Packet.maxPayloadLength() {
    return TOSH_DATA_LENGTH;
  }
  
  command void* Packet.getPayload(message_t* msg, uint8_t* len) {
    if (len != NULL) {
      *len = call Packet.payloadLength(msg);
    }
    return msg->data;
  }

  
  /***************** SubSend Events ****************/
  event void SubSend.sendDone(message_t* msg, error_t result) {
    signal AMSend.sendDone[call AMPacket.type(msg)](msg, result);
  }

  
  /***************** SubReceive Events ****************/
  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    if (call AMPacket.isForMe(msg)) {
      return signal Receive.receive[call AMPacket.type(msg)](msg, payload, len - CC2420_SIZE);
    }
    else {
      return signal Snoop.receive[call AMPacket.type(msg)](msg, payload, len - CC2420_SIZE);
    }
  }
  

  /***************** ActiveMessageAddress Events ****************/
  async event void ActiveMessageAddress.changed() {
  }
  
  /***************** CC2420Config Events ****************/
  event void CC2420Config.syncDone( error_t error ) {
  }
  
  /***************** Defaults ****************/
  default event message_t* Receive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
    return msg;
  }
  
  default event message_t* Snoop.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
    return msg;
  }

  default event void AMSend.sendDone[uint8_t id](message_t* msg, error_t err) {
    return;
  }

}
