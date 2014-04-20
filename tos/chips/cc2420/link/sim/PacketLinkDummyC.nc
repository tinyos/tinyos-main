/**
 * Dummy configuration for PacketLink Layer
 * @author David Moss
 * @author Jon Wyant
 */
 
configuration PacketLinkDummyC {
  provides {
    interface Send;
    interface PacketLink;
  }
  
  uses {
    interface Send as SubSend;
  }
}

implementation {
  components PacketLinkDummyP,
      ActiveMessageC;
  
  PacketLink = PacketLinkDummyP;
  Send = SubSend;
  
  PacketLinkDummyP.PacketAcknowledgements -> ActiveMessageC;
  
}

