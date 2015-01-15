
generic module BlipCompatibilityLayerP()
{
	provides
	{
		interface Send;
		interface Receive;
		interface Packet;
		
		interface Ieee154Address;
		
		interface ReadLqi;
	}

	uses
	{
		interface BareReceive as SubReceive;
		interface BareSend as SubSend;
		interface RadioPacket as SubPacket;
		
		interface ActiveMessageAddress;
		interface LocalIeeeEui64;
		
		interface PacketField<uint8_t> as SubLqi;
		interface PacketField<uint8_t> as SubRssi;
	}
}
implementation{
//------ Send
	command error_t Send.send(message_t* msg, uint8_t len){
		call Packet.setPayloadLength(msg, len);
		return call SubSend.send(msg);
	}
	
	event void SubSend.sendDone(message_t* msg, error_t error){
		signal Send.sendDone(msg, error);
	}
	
	command error_t Send.cancel(message_t* msg){
		return call SubSend.cancel(msg);
	}
	
	command uint8_t Send.maxPayloadLength(){
		return call Packet.maxPayloadLength();
	}
	
	command void* Send.getPayload(message_t* msg, uint8_t len){
		return call Packet.getPayload(msg, len);
	}
	
//------ Receive
	
	event message_t* SubReceive.receive(message_t* msg){
		return signal Receive.receive(msg, call Packet.getPayload(msg, call Packet.payloadLength(msg)), call Packet.payloadLength(msg));
	}
	
//------ Packet
	
	enum{
		BLIP_LENGTH_DIFF=1, //PHR
	};
	
	command void Packet.clear(message_t* msg){
		call SubPacket.clear(msg);
	}
	
	command uint8_t Packet.payloadLength(message_t* msg){
		return call SubPacket.payloadLength(msg) + BLIP_LENGTH_DIFF;
	}
	
	command void Packet.setPayloadLength(message_t* msg, uint8_t len){
		call SubPacket.setPayloadLength(msg, len - BLIP_LENGTH_DIFF);
	}
	
	command uint8_t Packet.maxPayloadLength(){
		return call SubPacket.maxPayloadLength() + BLIP_LENGTH_DIFF;
	}
	
	command void* Packet.getPayload(message_t* msg, uint8_t len){
		if( len > call SubPacket.maxPayloadLength() + BLIP_LENGTH_DIFF )
			return NULL;
		
		return ((void*)msg) + call SubPacket.headerLength(msg) - BLIP_LENGTH_DIFF;
	}
	
//------ Ieee154Address
	
	command ieee154_panid_t Ieee154Address.getPanId() {
		// The am group is 1 byte, and the pan id is 2.
		// However, blip doesn't seems to care with the panId, so it doesn't matter
		return call ActiveMessageAddress.amGroup();
	}
	command ieee154_saddr_t Ieee154Address.getShortAddr() {
		return call ActiveMessageAddress.amAddress();
	}
	command ieee154_laddr_t Ieee154Address.getExtAddr() {
		ieee154_laddr_t addr = call LocalIeeeEui64.getId();
		uint8_t i;
		uint8_t tmp;
		/* the LocalIeeeEui is big endian */
		/* however, Ieee 802.15.4 addresses are little endian */
		for (i = 0; i < 4; i++) {
			tmp = addr.data[i];
			addr.data[i] = addr.data[7 - i];
			addr.data[7 - i] = tmp;
		}
		return addr;
	}
	
	command error_t Ieee154Address.setShortAddr(ieee154_saddr_t addr) {
		call ActiveMessageAddress.setAddress(call ActiveMessageAddress.amGroup(), addr);
		return SUCCESS;
	}
	
	task void addressChanged(){
		signal Ieee154Address.changed();
	}
	
	async event void ActiveMessageAddress.changed(){
		post addressChanged();
	}
	
//------ ReadLqi
	
	command uint8_t ReadLqi.readLqi(message_t *msg) {
		return call SubLqi.get(msg);
	}
	
	command uint8_t ReadLqi.readRssi(message_t *msg) {
		return call SubRssi.get(msg);
	}
}
