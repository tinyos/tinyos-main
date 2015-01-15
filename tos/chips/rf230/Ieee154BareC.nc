configuration Ieee154BareC{
	provides interface SplitControl;
	provides interface Send as BareSend;
	provides interface Receive as BareReceive;
	provides interface Packet as BarePacket;
}
implementation{
	components RF230RadioC;
	SplitControl = RF230RadioC;
	BareSend = RF230RadioC;
	BareReceive = RF230RadioC;
	BarePacket = RF230RadioC;
}
