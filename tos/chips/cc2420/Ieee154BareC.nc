
/* Provides an abstraction layer for complete access to an 802.15.4 packet
 * buffer. Packets provided to this module will be interpreted as 802.15.4
 * frames and will have the sequence number set. Higher layers must set all
 * other fields, including the 802.15.4 header and length byte, but not the
 * last 2 byte crc.
 *
 * Using this interface does not, however, preclude one from using other mac
 * layer modules, including the PacketLink component or LPL. Using those
 * interfaces from RadioPacketMetadataC.nc will continue to work. Using this
 * module just ensures one has free reign over the entire contents of the
 * 802.15.4 packet.
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

configuration Ieee154BareC {
  provides {
    interface SplitControl;

    interface Packet as BarePacket;
    interface Send as BareSend;
    interface Receive as BareReceive;
  }
}

implementation {
  components CC2420RadioC;

  SplitControl = CC2420RadioC.SplitControl;

  BarePacket = CC2420RadioC.BarePacket;
  BareSend = CC2420RadioC.BareSend;
  BareReceive = CC2420RadioC.BareReceive;
}
