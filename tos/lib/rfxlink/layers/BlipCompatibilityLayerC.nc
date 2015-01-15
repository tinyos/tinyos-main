generic configuration BlipCompatibilityLayerC(){
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
		interface BareSend as SubSend;
		interface BareReceive as SubReceive;
		interface RadioPacket as SubPacket;
		
		interface PacketField<uint8_t> as SubLqi;
		interface PacketField<uint8_t> as SubRssi;
	}
}
implementation{
	components new BlipCompatibilityLayerP(), ActiveMessageAddressC, LocalIeeeEui64C;
	
	BlipCompatibilityLayerP.ActiveMessageAddress -> ActiveMessageAddressC;
	BlipCompatibilityLayerP.LocalIeeeEui64 -> LocalIeeeEui64C;
	
	Send = BlipCompatibilityLayerP;
	SubSend = BlipCompatibilityLayerP;
	
	Receive = BlipCompatibilityLayerP;
	SubReceive = BlipCompatibilityLayerP;
	
	Packet = BlipCompatibilityLayerP;
	SubPacket = BlipCompatibilityLayerP;
	
	Ieee154Address = BlipCompatibilityLayerP;
	
	ReadLqi = BlipCompatibilityLayerP;
	SubLqi = BlipCompatibilityLayerP.SubLqi;
	SubRssi = BlipCompatibilityLayerP.SubRssi;
}