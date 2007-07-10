// $Id: Tda5250ActiveMessageP.nc,v 1.7 2007-07-10 13:09:47 andreaskoepke Exp $

/*                                                                      tab:4
 * "Copyright (c) 2004-2005 The Regents of the University  of California.
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
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA,
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:             Philip Levis
 * Date last modified:  $Id: Tda5250ActiveMessageP.nc,v 1.7 2007-07-10 13:09:47 andreaskoepke Exp $
 *
 */

/**
 * @author Philip Levis
 * @author Vlado Handziski (TDA5250 modifications)
 * @date July 20 2005
 */

module Tda5250ActiveMessageP {
  provides {
    interface AMSend[am_id_t id];
    interface Receive[am_id_t id];
    interface Receive as Snoop[am_id_t id];
    interface AMPacket;
  }
  uses {
    interface Send as SubSend;
    interface Receive as SubReceive;
    interface Packet as SubPacket;
    command am_addr_t amAddress();
  }
}
implementation {

  tda5250_header_t* getHeader( message_t* msg ) {
                return (tda5250_header_t*)( msg->data - sizeof(tda5250_header_t) );
  }

  command error_t AMSend.send[am_id_t id](am_addr_t addr,
                                          message_t* msg,
                                          uint8_t len) {
    tda5250_header_t* header = getHeader(msg);
    header->type = id;
    header->dest = addr;
    header->src = call amAddress();
    return call SubSend.send(msg, len);
  }

  command error_t AMSend.cancel[am_id_t id](message_t* msg) {
    return call SubSend.cancel(msg);
  }

  event void SubSend.sendDone(message_t* msg, error_t result) {
    signal AMSend.sendDone[call AMPacket.type(msg)](msg, result);
  }

  command uint8_t AMSend.maxPayloadLength[am_id_t id]() {
    return call SubPacket.maxPayloadLength();
  }

  command void* AMSend.getPayload[am_id_t id](message_t* m) {
    return call SubPacket.getPayload(m, NULL);
  }

  /* Receiving a packet */

  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    if (call AMPacket.isForMe(msg)) {
      return signal Receive.receive[call AMPacket.type(msg)](msg, payload, len);
    }
    else {
      return signal Snoop.receive[call AMPacket.type(msg)](msg, payload, len);
    }
  }

  command void* Receive.getPayload[am_id_t id](message_t* m, uint8_t* len) {
    return call SubPacket.getPayload(m, len);
  }

  command uint8_t Receive.payloadLength[am_id_t id](message_t* m) {
    return call SubPacket.payloadLength(m);
  }

  command void* Snoop.getPayload[am_id_t id](message_t* m, uint8_t* len) {
    return call SubPacket.getPayload(m, len);
  }

  command uint8_t Snoop.payloadLength[am_id_t id](message_t* m) {
    return call SubPacket.payloadLength(m);
  }

  command am_addr_t AMPacket.address() {
    return call amAddress();
  }

  command am_addr_t AMPacket.destination(message_t* amsg) {
    tda5250_header_t* header = getHeader(amsg);
    return header->dest;
  }

  command void AMPacket.setDestination(message_t* amsg, am_addr_t addr) {
    tda5250_header_t* header = getHeader(amsg);
    header->dest = addr;
  }

  command am_addr_t AMPacket.source(message_t* amsg) {
    tda5250_header_t* header = getHeader(amsg);
    return header->src;
  }
  
  command void AMPacket.setSource(message_t* amsg, am_addr_t addr) {
    tda5250_header_t* header = getHeader(amsg);
    header->src = addr;
  }
  
  command bool AMPacket.isForMe(message_t* amsg) {
    return (call AMPacket.destination(amsg) == call AMPacket.address() ||
            call AMPacket.destination(amsg) == AM_BROADCAST_ADDR);
  }

  command am_id_t AMPacket.type(message_t* amsg) {
    tda5250_header_t* header = getHeader(amsg);
    return header->type;
  }

  command void AMPacket.setType(message_t* amsg, am_id_t type) {
    tda5250_header_t* header = getHeader(amsg);
    header->type = type;
  }

  command void AMPacket.setGroup(message_t* msg, am_group_t group) {
     return;
  }

  command am_group_t AMPacket.group(message_t* msg) {
    return TOS_AM_GROUP;
  }

  command am_group_t AMPacket.localGroup() {
    return TOS_AM_GROUP;
  }
  
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
