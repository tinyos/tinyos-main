/**
 * Original TinyOS T-Frames use a packet header that is not compatible with
 * other 6LowPAN networks.  They do not include the network byte 
 * responsible for identifying the packing as being sourced from a TinyOS
 * network.
 *
 * TinyOS I-Frames are interoperability packets that do include a network
 * byte as defined by 6LowPAN specifications.  The I-Frame header type is
 * the default packet header used in TinyOS networks.
 *
 * Since either packet header is acceptable, this layer must do some 
 * preprocessing (sorry) to figure out whether or not it needs to include 
 * the functionality to process I-frames.  If I-Frames are used, then
 * the network byte is added on the way out and checked on the way in.
 * If the packet came from a network different from a TinyOS network, the
 * user may access it through the DispatchP's NonTinyosReceive[] Receive 
 * interface and process it in a different radio stack.
 *
 * If T-Frames are used instead, this layer is simply pass-through wiring to the
 * layer beneath.  
 *
 * Define "CC2420_IFRAME_TYPE" to use the interoperability frame and 
 * this layer
 * 
 * @author David Moss
 */
 
#include "CC2420.h"

configuration CC2420TinyosNetworkC {
  provides {
    interface Send;
    interface Receive;
    
    interface Send as ActiveSend;
    interface Receive as ActiveReceive;
    //BLIPSIM
    interface Packet as BarePacket;
  }
  
  uses {
    interface Receive as SubReceive;
    interface Send as SubSend;
  }
}

implementation {

#ifdef CC2420_IFRAME_TYPE
  components CC2420TinyosNetworkP;
  components CC2420PacketC;
  
  CC2420TinyosNetworkP.Send = Send;
  CC2420TinyosNetworkP.Receive = Receive;
  CC2420TinyosNetworkP.SubSend = SubSend;
  CC2420TinyosNetworkP.SubReceive = SubReceive;
  
  CC2420TinyosNetworkP.CC2420PacketBody -> CC2420PacketC;

#else
  components CC2420TinyosNetworkP;
  components CC2420PacketC;
  
#if 0
  Send = SubSend;
  Receive = SubReceive;
  
  //Srikanth - BLIPSIM
  //CC2420TinyosNetworkP.SubSend = SubSend;
  //CC2420TinyosNetworkP.Send = Send;
  //CC2420TinyosNetworkP.Receive = Receive;
  //CC2420TinyosNetworkP.SubReceive = SubReceive;
  //Srikanth - BLIPSIM

  //CC2420TinyosNetworkP.BareSend = Send;
  //CC2420TinyosNetworkP.BareReceive = Receive;
  CC2420TinyosNetworkP.BarePacket = BarePacket;

  CC2420TinyosNetworkP.CC2420PacketBody -> CC2420PacketC;
  //CC2420TinyosNetworkP.CC2420PacketBody -> CC2420PacketC;
#endif
  CC2420TinyosNetworkP.BareSend = Send;
  CC2420TinyosNetworkP.BareReceive = Receive;
  CC2420TinyosNetworkP.BarePacket = BarePacket;
  CC2420TinyosNetworkP.SubSend = SubSend;
  CC2420TinyosNetworkP.SubReceive = SubReceive;
  CC2420TinyosNetworkP.ActiveSend = ActiveSend;
  CC2420TinyosNetworkP.ActiveReceive = ActiveReceive;

  CC2420TinyosNetworkP.CC2420Packet -> CC2420PacketC;
  CC2420TinyosNetworkP.CC2420PacketBody -> CC2420PacketC;


#endif

}

