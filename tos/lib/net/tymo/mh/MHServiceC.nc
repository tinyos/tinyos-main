/*
 * Copyright (c) 2007 Romain Thouvenin <romain.thouvenin@gmail.com>
 * Published under the terms of the GNU General Public License (GPLv2).
 */

/**
 * MHServiceC - Implements a simple multihop transport protocol
 *
 * @author Romain Thouvenin
 */

configuration MHServiceC {
  provides { //For upper layer
    interface AMSend as MHSend[uint8_t id];
    interface Receive[uint8_t id];
    interface Intercept[uint8_t id];
    interface AMPacket as MHPacket;
    interface Packet;
    interface LinkMonitor;
  }
  uses {  //From lower layer
    interface AMPacket;
    interface Packet as SubPacket;
    interface AMSend;
    interface Receive as SubReceive;
    interface PacketAcknowledgements as Acks;
  }

  provides interface MHControl;
}

implementation {
  components DymoTableC, MHEngineM, MHPacketM;
  components new ForwardingEngineM(), new TimerMilliC();

  //provides
  MHSend      = ForwardingEngineM.AMSend;
  Receive     = ForwardingEngineM.Receive;
  Intercept   = ForwardingEngineM.Intercept;
  LinkMonitor = ForwardingEngineM.LinkMonitor;
  MHPacket    = MHPacketM.MHPacket;
  Packet      = MHPacketM.Packet;
  Acks        = ForwardingEngineM.Acks;

  //uses
  ForwardingEngineM.AMPacket   = AMPacket;  
  MHEngineM.AMPacket	       = AMPacket;  
  MHPacketM.AMPacket	       = AMPacket;  
  MHPacketM.SubPacket	       = SubPacket; 
  ForwardingEngineM.SubPacket  = SubPacket; 
  ForwardingEngineM.SubSend    = AMSend;    
  ForwardingEngineM.SubReceive = SubReceive;

  //MHEngine
  MHEngineM.MHPacket     -> MHPacketM.MHPacket;
  MHEngineM.RoutingTable -> DymoTableC;

  //ForwardingEngine
  ForwardingEngineM.RouteSelect -> MHEngineM;
  ForwardingEngineM.PPacket     -> MHPacketM.Packet;
  ForwardingEngineM.Timer       -> TimerMilliC;

  MHControl = ForwardingEngineM.MHControl;
}
