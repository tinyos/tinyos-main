
/* Provides an abstraction layer for complete access to an 802.15.4 packet
 * buffer. Packets provided to this module will be interpreted as 802.15.4
 * frames and will have the sequence number set. All other fields must be set
 * by upper layers.
 */

configuration Ieee154BareC {
  provides {
    interface SplitControl;

    interface Packet as BarePacket;
    interface Send as BareSend;
    interface Receive as BareReceive;

    interface LowPowerListening;
    interface PacketLink;
    interface PacketAcknowledgements;
  }
}

implementation {
  components CC2420RadioC;

  SplitControl = CC2420RadioC.SplitControl;

  BarePacket = CC2420RadioC.BarePacket;
  BareSend = CC2420RadioC.BareSend;
  BareReceive = CC2420RadioC.BareReceive;

  LowPowerListening = CC2420RadioC.LowPowerListening;
  PacketLink = CC2420RadioC.PacketLink;
  PacketAcknowledgements = CC2420RadioC.PacketAcknowledgements;
}
