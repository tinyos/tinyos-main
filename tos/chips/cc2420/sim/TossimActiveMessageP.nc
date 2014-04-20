/**
 *
 * The basic chip-independent TOSSIM Active Message layer for radio chips
 * that do not have simulation support.
 *
 * @author Philip Levis
 * @date December 2 2005
 */

#include <AM.h>

module TossimActiveMessageP
{
  provides {
    interface AMSend[am_id_t id];
    interface Receive[am_id_t id];
    interface Receive as Snoop[am_id_t id];
    interface SendNotifier[am_id_t amId];

    interface Packet;
    interface AMPacket;
  }
  uses {
    interface Send as SubSend;
    interface Receive as SubReceive;
    command am_addr_t amAddress();
  }
}
implementation {

  message_t buffer;
  message_t* bufferPointer = &buffer;
  
  tossim_header_t* getHeader(message_t* amsg)
  {
    return (tossim_header_t*)(amsg->data - sizeof(tossim_header_t));
  }
  
  command error_t AMSend.send[am_id_t id](am_addr_t addr,
					  message_t* amsg,
					  uint8_t len)
  {
    error_t err;
    tossim_header_t* header = getHeader(amsg);
    dbg("AM", "AM: Sending packet (id=%hhu, len=%hhu) to %hu\n", id, len, addr);
    header->type = id;
    header->dest = addr;
    header->src = call AMPacket.address();
    header->length = len;
    signal SendNotifier.aboutToSend[id](addr, amsg);


//-------------------------------------------------------------------------------------------------//
   err = call SubSend.send(amsg, len + sizeof(tossim_header_t));
   //err = SUCCESS;
   //signal AMSend.sendDone[call AMPacket.type(amsg)](amsg, err);
//-------------------------------------------------------------------------------------------------//


    if(err != SUCCESS )
      dbg("AM", "AM: Failed Sending packet (id=%hhu, len=%hhu) to %hu\n", id, len, addr);
    return err;
  }

  command error_t AMSend.cancel[am_id_t id](message_t* msg) { return call SubSend.cancel(msg); }
  command uint8_t AMSend.maxPayloadLength[am_id_t id]() { return call Packet.maxPayloadLength(); }
  command void* AMSend.getPayload[am_id_t id](message_t* m, uint8_t len) { return call Packet.getPayload(m, len); }

  command am_addr_t AMPacket.address() { return call amAddress(); }
 
  command am_addr_t AMPacket.destination(message_t* amsg)
  {
    tossim_header_t* header = getHeader(amsg);
    return header->dest;
  }

  command void AMPacket.setDestination(message_t* amsg, am_addr_t addr)
  {
    tossim_header_t* header = getHeader(amsg);
    header->dest = addr;
  }

  command am_addr_t AMPacket.source(message_t* amsg)
  {
    tossim_header_t* header = getHeader(amsg);
    return header->src;
  }

  command void AMPacket.setSource(message_t* amsg, am_addr_t addr)
  {
    tossim_header_t* header = getHeader(amsg);
    header->src = addr;
  }
  
  command bool AMPacket.isForMe(message_t* amsg)
  {
    dbg("AM", "AM: isForMe: %d %d\n", call AMPacket.destination(amsg), call AMPacket.address());
    return (call AMPacket.destination(amsg) == call AMPacket.address() ||
	    call AMPacket.destination(amsg) == AM_BROADCAST_ADDR);
  }

  command am_id_t AMPacket.type(message_t* amsg)
  {
    tossim_header_t* header = getHeader(amsg);
    return header->type;
  }

  command void AMPacket.setType(message_t* amsg, am_id_t t)
  {
    tossim_header_t* header = getHeader(amsg);
    header->type = t;
  }
 
  command void Packet.clear(message_t* msg) { }
  
  command uint8_t Packet.payloadLength(message_t* msg) { return getHeader(msg)->length; }
  command void Packet.setPayloadLength(message_t* msg, uint8_t len) { getHeader(msg)->length = len; }
  command uint8_t Packet.maxPayloadLength() { return TOSH_DATA_LENGTH; }
  
  command void* Packet.getPayload(message_t* msg, uint8_t len)
  {
    return msg->data;
  }

  command am_group_t AMPacket.group(message_t* amsg)
  {
    tossim_header_t* header = getHeader(amsg);
    return header->group;
  }
  
  command void AMPacket.setGroup(message_t* msg, am_group_t group)
  {
    tossim_header_t* header = getHeader(msg);
    header->group = group;
  }

  command am_group_t AMPacket.localGroup() { return TOS_AM_GROUP; }

  default event message_t* Receive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) { return msg; }
  default event message_t* Snoop.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) { return msg; }
  default event void AMSend.sendDone[uint8_t id](message_t* msg, error_t err) { return; }

  default command am_addr_t amAddress() { return 0; }
  
  
  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len)
  {
    dbg("AM", "AM: Received active message.\n"); 
    if (call AMPacket.isForMe(msg)) {
      dbg("AM", "Received active message (%p) of type %hhu and length %hhu for me @ %s.\n", 
	  msg, call AMPacket.type(msg), len, sim_time_string());
      return signal Receive.receive[call AMPacket.type(msg)](msg, payload, len);
    } else {
      dbg("AM", "Snooped on active message of type %hhu and length %hhu for %hu @ %s.\n", 
	  call AMPacket.type(msg), len, call AMPacket.destination(msg), sim_time_string());
      return signal Snoop.receive[call AMPacket.type(msg)](msg, payload, len);
    }
  }

  event void SubSend.sendDone(message_t* msg, error_t error) { signal AMSend.sendDone[call AMPacket.type(msg)](msg, error); }
 default event void SendNotifier.aboutToSend[am_id_t amId](am_addr_t addr, message_t *msg) { }
}
