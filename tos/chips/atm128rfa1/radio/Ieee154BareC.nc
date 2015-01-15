configuration Ieee154BareC{
	provides interface SplitControl;
	provides interface Send as BareSend;
	provides interface Receive as BareReceive;
	provides interface Packet as BarePacket;
}
implementation{
	components RFA1RadioC;
	SplitControl = RFA1RadioC;
	BareSend = RFA1RadioC;
	BareReceive = RFA1RadioC;
	BarePacket = RFA1RadioC;
}
