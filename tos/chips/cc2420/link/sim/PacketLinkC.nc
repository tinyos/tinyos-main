/**
 * Reliable Packet Link Functionality
 * @author David Moss
 * @author Jon Wyant
 */

#warning "*** USING PACKET LINK LAYER"

configuration PacketLinkC {
  provides {
    interface Send;
    interface PacketLink;
  }
  
  uses {
    interface Send as SubSend;
  }
}

implementation {

  components PacketLinkP,
      ActiveMessageC,
      CC2420PacketC,
      RandomC,
      new StateC() as SendStateC,
      new TimerMilliC() as DelayTimerC;
  
  PacketLink = PacketLinkP;
  Send = PacketLinkP.Send;
  SubSend = PacketLinkP.SubSend;
  
  PacketLinkP.SendState -> SendStateC;
  PacketLinkP.DelayTimer -> DelayTimerC;
  PacketLinkP.PacketAcknowledgements -> ActiveMessageC;
  PacketLinkP.AMPacket -> ActiveMessageC;
  PacketLinkP.CC2420PacketBody -> CC2420PacketC;

}
