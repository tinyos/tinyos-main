configuration RadioPacketMetadataC {
	provides interface LowPowerListening;
	provides interface PacketLink;
	provides interface PacketAcknowledgements;
}
implementation {
	components RF230RadioC;
	LowPowerListening = RF230RadioC;
	PacketLink = RF230RadioC;
	PacketAcknowledgements = RF230RadioC;
}
