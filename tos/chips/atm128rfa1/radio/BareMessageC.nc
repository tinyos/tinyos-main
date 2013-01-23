configuration BareMessageC
{
  provides
  {
    interface BareSend;
    interface BareReceive;
    interface Packet as BarePacket;
    interface PacketLink;
    interface LowPowerListening;
    interface SplitControl as RadioControl;
    interface ShortAddressConfig;
  }
}
implementation
{
  components RFA1RadioC;

	BareSend = RFA1RadioC;
	BareReceive = RFA1RadioC;
	BarePacket = RFA1RadioC.BarePacket;
	PacketLink = RFA1RadioC;
	LowPowerListening = RFA1RadioC;
	RadioControl = RFA1RadioC.SplitControl;
	ShortAddressConfig = RFA1RadioC;
}
