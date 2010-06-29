/*
 * Copyright (c) 2008 Johns Hopkins University.
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
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

module CAMRadioP {
  uses {
    interface BlockingStdControl;
    interface BlockingReceive[am_id_t amId];
    interface BlockingReceive as BlockingReceiveAny;
    interface BlockingReceive as BlockingSnoop[am_id_t amId];
    interface BlockingReceive as BlockingSnoopAny;
    interface BlockingAMSend as Send[am_id_t id];
    interface Packet;
    interface AMPacket;
    interface PacketAcknowledgements;
  }
}
implementation {
  error_t amRadioStart() @C() AT_SPONTANEOUS { 
    return call BlockingStdControl.start();
  }
  error_t amRadioStop() @C() AT_SPONTANEOUS { 
    return call BlockingStdControl.stop();
  }
  error_t amRadioReceive(message_t* m, uint32_t timeout, am_id_t amId) @C() AT_SPONTANEOUS {
    if(amId == AM_RECEIVE_FROM_ANY)
      return call BlockingReceiveAny.receive(m, timeout);
    else 
      return call BlockingReceive.receive[amId](m, timeout);
  }
  error_t amRadioSnoop(message_t* m, uint32_t timeout, am_id_t amId) @C() AT_SPONTANEOUS {
    if(amId == AM_RECEIVE_FROM_ANY)
      return call BlockingSnoopAny.receive(m, timeout);
    else 
      return call BlockingSnoop.receive[amId](m, timeout);
  }
  error_t amRadioSend(am_addr_t addr, message_t* msg, uint8_t len, am_id_t amId) @C() AT_SPONTANEOUS {
    return call Send.send[amId](addr, msg, len);
  }
  am_addr_t amRadioGetLocalAddress() @C() AT_SPONTANEOUS {
    return call AMPacket.address();
  }
  am_group_t amRadioGetLocalGroup() @C() AT_SPONTANEOUS {
    return call AMPacket.localGroup();
  }
  am_addr_t amRadioGetDestination(message_t* amsg) @C() AT_SPONTANEOUS {
    return call AMPacket.destination(amsg);
  }
  am_addr_t amRadioGetSource(message_t* amsg) @C() AT_SPONTANEOUS {
    return call AMPacket.source(amsg);
  }
  void amRadioSetDestination(message_t* amsg, am_addr_t addr) @C() AT_SPONTANEOUS {
    call AMPacket.setDestination(amsg, addr);
  }
  void amRadioSetSource(message_t* amsg, am_addr_t addr) @C() AT_SPONTANEOUS {
    call AMPacket.setSource(amsg, addr);
  }
  bool amRadioIsForMe(message_t* amsg) @C() AT_SPONTANEOUS {
    return call AMPacket.isForMe(amsg);
  }
  am_id_t amRadioGetType(message_t* amsg) @C() AT_SPONTANEOUS {
    return call AMPacket.type(amsg);
  }
  void amRadioSetType(message_t* amsg, am_id_t t) @C() AT_SPONTANEOUS {
    call AMPacket.setType(amsg, t);
  }
  am_group_t amRadioGetGroup(message_t* amsg) @C() AT_SPONTANEOUS {
    return call AMPacket.group(amsg);
  }
  void amRadioSetGroup(message_t* amsg, am_group_t grp) @C() AT_SPONTANEOUS {
    call AMPacket.setGroup(amsg, grp);
  }
  void radioClear(message_t* msg) @C() AT_SPONTANEOUS {
    call Packet.clear(msg);
  }
  uint8_t radioGetPayloadLength(message_t* msg) @C() AT_SPONTANEOUS {
    return call Packet.payloadLength(msg);
  }
  void  radioSetPayloadLength(message_t* msg, uint8_t len) @C() AT_SPONTANEOUS {
    call Packet.setPayloadLength(msg, len);
  }
  uint8_t radioMaxPayloadLength() @C() AT_SPONTANEOUS {
    return call Packet.maxPayloadLength();
  }
  void* radioGetPayload(message_t* msg, uint8_t len) @C() AT_SPONTANEOUS {
    return call Packet.getPayload(msg, len);
  }
  error_t radioRequestAck( message_t* msg ) @C() AT_SPONTANEOUS {
    return call PacketAcknowledgements.requestAck(msg);
  }
  error_t radioNoAck( message_t* msg ) @C() AT_SPONTANEOUS {
    return call PacketAcknowledgements.noAck(msg);
  }
  bool radioWasAcked(message_t* msg) @C() AT_SPONTANEOUS {
    return call PacketAcknowledgements.wasAcked(msg);
  }
}
