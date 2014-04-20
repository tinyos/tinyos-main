module CC2420CsmaP
{
  provides interface SplitControl;
  provides interface Send;
  provides interface Receive;
  provides interface RadioBackoff[am_id_t amId];
  uses interface TossimPacketModel as Model;
  uses interface SimMote;
  uses interface AMPacket;
  uses interface Packet;
  uses interface CC2420Config;
  uses interface CC2420PacketBody;
  uses command am_addr_t amAddress();
}
#include <CC2420.h>
implementation
{
  message_t buffer;
  message_t* bufferPointer = &buffer;

  tossim_header_t* getHeader(message_t* amsg)
  {
    return (tossim_header_t*)(amsg->data - sizeof(tossim_header_t));
  }

void print_bytes(uint8_t *ptr, uint8_t len)
{
  uint32_t i;
  char buf[300] = "", num[3];
  for(i = 0; i < len; i++) {
    sprintf(num, "%02x", ptr[i]);
    strcat(buf, num);
  }
  dbg("Debug", "%s\n", buf);
}
  /**
   * @return TRUE if the given message passes address recognition
   */
  bool passesAddressCheck(message_t *msg) {
    cc2420_header_t *header = (cc2420_header_t*)(call CC2420PacketBody.getHeader( msg ));
    int mode = (header->fcf >> IEEE154_FCF_DEST_ADDR_MODE) & 3;
    ieee_eui64_t *ext_addr;

    if(!(call CC2420Config.isAddressRecognitionEnabled())) {
      dbg("Csma", "isAddressRecognitionEnabled:False\n");
      return TRUE;
    }

    if (mode == IEEE154_ADDR_SHORT) {
      return (header->dest == call CC2420Config.getShortAddr()
          || header->dest == IEEE154_BROADCAST_ADDR);
    } else if (mode == IEEE154_ADDR_EXT) {
      ieee_eui64_t local_addr = (call CC2420Config.getExtAddr());
      ext_addr = TCAST(ieee_eui64_t* ONE, &header->dest);
      return (memcmp(ext_addr->data, local_addr.data, IEEE_EUI64_LENGTH) == 0);
    } else {
      /* reject frames with either no address or invalid type */
      return FALSE;
    }
  }

  command error_t SplitControl.start()
  {
    return SUCCESS;
  }

  command error_t SplitControl.stop() { return SUCCESS; }

  command error_t Send.cancel(message_t* msg) { return call Model.cancel(msg); }
  command error_t Send.send(message_t* msg, uint8_t len)
  {
    error_t res;
    dbg("Csma", "Csma sim: Sending packet %p to %hu, len %d, dsn %d\n",
        msg, call AMPacket.destination(msg), len, (call CC2420PacketBody.getHeader(msg))->dsn);
    res = call Model.send(call AMPacket.destination(msg), msg, len);

	//print_bytes(msg, 20);

    if( res != SUCCESS )
      dbg("Csma", "Csma sim: failed Sending packet %p to %hu, len %d, dsn %d\n",
          msg, call AMPacket.destination(msg), len, (call CC2420PacketBody.getHeader(msg))->dsn);

    return res;
  }
  command void* Send.getPayload(message_t* msg, uint8_t len) { return msg->data; }
  command uint8_t Send.maxPayloadLength() { return TOSH_DATA_LENGTH; }

  async command void RadioBackoff.setInitialBackoff[am_id_t amId](uint16_t backoffTime) { }
  async command void RadioBackoff.setCongestionBackoff[am_id_t amId](uint16_t backoffTime) { }
  async command void RadioBackoff.setCca[am_id_t amId](bool useCca) { }

  event void Model.sendDone(message_t* msg, error_t result)
  {
    dbg("Csma", "Csma sim: Signaling sendDone for packet %p, destination %d, dsn %d, error %d\n",
        msg, call AMPacket.destination(msg), (call CC2420PacketBody.getHeader(msg))->dsn, result);
    signal Send.sendDone(msg, result);
  }

  event void Model.receive(message_t* msg)
  {
    uint8_t len = call Packet.payloadLength(msg);
    void* payload;

    dbg("Csma", "Calling passesAddressCheck\n");

    if (!passesAddressCheck(msg)) {
      dbg("Csma", "Dropping packet %p not meant for me\n");
      return;
    }

    memcpy(bufferPointer, msg, sizeof(message_t));
    payload = call Packet.getPayload(bufferPointer, len);
    dbg("Csma", "Csma sim: Receiving packet %p from %d in %p, len %d, dsn %d\n",
        msg, call AMPacket.source(msg), bufferPointer, len,
        (call CC2420PacketBody.getHeader(msg))->dsn);
    bufferPointer = signal Receive.receive(bufferPointer, payload, len);
  }

  event bool Model.shouldAck(message_t* msg)
  {
    tossim_header_t* header = getHeader(msg);
      dbg("Acks", "Acks: BRO DO YOU EVEN ACK\n");
	//print_bytes(msg, header->length);
    if (!call CC2420Config.isAutoAckEnabled()) {
      dbg("Acks", "Acks: autoAck is disabled\n");
      return FALSE;
    }
		dbg("Acks", "Addr: %X %X\n", header->dest, call CC2420Config.getShortAddr());
    if (passesAddressCheck(msg)) {
    //if (header->dest == call CC2420Config.getShortAddr()) {
    //if (header->dest == call amAddress()) {
      dbg("Acks", "Acks: Received packet addressed to me so ack it\n");
      return TRUE;
    }
    if (header->dest == AM_BROADCAST_ADDR) {
      dbg("Acks", "Acks: Received broadcast packet so ack it\n");
      return TRUE;
    }
      dbg("Acks", "Acks: NO BRO\n");
    return FALSE;
  }

  void active_message_deliver_handle(sim_event_t* evt)
  {
    message_t* m = (message_t*)evt->data;
    dbg("Packet", "Packet: Delivering packet to %i at %s\n", (int)sim_node(), sim_time_string());
    signal Model.receive(m);
  }

  sim_event_t* allocate_deliver_event(int node, message_t* msg, sim_time_t t)
  {
    sim_event_t* evt = (sim_event_t*)malloc(sizeof(sim_event_t));
    evt->mote = node;
    evt->time = t;
    evt->handle = active_message_deliver_handle;
    evt->cleanup = sim_queue_cleanup_event;
    evt->cancelled = 0;
    evt->force = 0;
    evt->data = msg;
    return evt;
  }

  void active_message_deliver(int node, message_t* msg, sim_time_t t) __attribute__ ((C, spontaneous))
  {
    sim_event_t* evt = allocate_deliver_event(node, msg, t);
    sim_queue_insert(evt);
  }

  event void CC2420Config.syncDone( error_t error ) { }

  default command void Packet.clear(message_t* msg) {}
  default command uint8_t Packet.payloadLength(message_t* msg) { return 0; }
  default command void Packet.setPayloadLength(message_t* msg, uint8_t len) {}
  default command uint8_t Packet.maxPayloadLength() { return 0; }
  default command void* Packet.getPayload(message_t* msg, uint8_t len) { return NULL; }

  default command am_addr_t AMPacket.address() { return TOS_NODE_ID; }
  default command am_addr_t AMPacket.destination(message_t* amsg) { return 0xFFFF; }
  default command am_addr_t AMPacket.source(message_t* amsg) { return 0xFFFF; }
  default command void AMPacket.setDestination(message_t* amsg, am_addr_t addr) {}
  default command void AMPacket.setSource(message_t* amsg, am_addr_t addr) {}
  default command bool AMPacket.isForMe(message_t* amsg) { return FALSE; }
  default command am_id_t AMPacket.type(message_t* amsg) { return 0; }
  default command void AMPacket.setType(message_t* amsg, am_id_t t) {}
  default command am_group_t AMPacket.group(message_t* amsg) { return 0; }
  default command void AMPacket.setGroup(message_t* amsg, am_group_t grp) {}
  default command am_group_t AMPacket.localGroup() { return 0; }

  default async command tossim_header_t* CC2420PacketBody.getHeader(message_t *msg) { return NULL; }
  default async command tossim_metadata_t* CC2420PacketBody.getMetadata(message_t *msg) { return NULL; }

  default event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) { return msg; }
}
