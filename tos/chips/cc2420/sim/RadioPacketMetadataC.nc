
/* Wrapper config for interfaces that operate on the metadata level of a packet.
 * This is designed for BLIP, and any radio that wishes to support BLIP needs
 * to create this configuration and provide these interfaces.
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

configuration RadioPacketMetadataC {
  provides {
#ifdef LOW_POWER_LISTENING
    interface LowPowerListening;
#endif
    interface PacketLink;
    interface PacketAcknowledgements;
  }
}

implementation {
  components CC2420RadioC;

#ifdef LOW_POWER_LISTENING
	LowPowerListening = CC2420RadioC;
#endif
  PacketLink = CC2420RadioC;
  PacketAcknowledgements = CC2420RadioC;
}
