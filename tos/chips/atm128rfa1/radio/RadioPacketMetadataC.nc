configuration RadioPacketMetadataC {
	provides interface LowPowerListening;
	provides interface PacketLink;
	provides interface PacketAcknowledgements;
}
implementation {
	components RFA1RadioC;
	LowPowerListening = RFA1RadioC;
	PacketLink = RFA1RadioC;
	PacketAcknowledgements = RFA1RadioC;
}
