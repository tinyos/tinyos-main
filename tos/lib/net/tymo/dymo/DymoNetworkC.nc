/*
 * Copyright (c) 2007 Romain Thouvenin <romain.thouvenin@gmail.com>
 * Published under the terms of the GNU General Public License (GPLv2).
 */

#include "routing.h"

/**
 * DymoNetworkC - Top level configuration providing a multihop network
 * layer and implementing DYMO (DYnamic Manet On-demand) routing.
 *
 * @author Romain Thouvenin
 */

configuration DymoNetworkC {
  provides {
    interface AMSend as MHSend[uint8_t id];
    interface AMPacket as MHPacket;
    interface Packet;
    interface Receive[uint8_t id];
    interface Intercept[uint8_t id];
    interface SplitControl;
  }

#ifdef DYMO_MONITORING
  provides {
    interface DymoMonitor;
    interface RoutingTableInfo;
  }
#endif
  provides interface MHControl;
}

implementation {
  components ActiveMessageC;
  components new AMReceiverC(AM_MULTIHOP) as MHReceiver, new AMReceiverC(AM_DYMO) as DymoReceiver;
  components new AMSenderC(AM_MULTIHOP) as MHQueue, new AMSenderC(AM_DYMO) as DymoQueue;
  components MHServiceC, DymoServiceC, NetControlM, DymoTableC;
#ifdef LOOPBACK
  components LoopBackM;
#endif

#ifdef LOOPBACK
  MHSend    = LoopBackM.AMSend;
  Receive   = LoopBackM.Receive;
#else
  MHSend    = MHServiceC.MHSend;
  Receive   = MHServiceC.Receive;
#endif
  MHPacket  = MHServiceC.MHPacket;
  Packet    = MHServiceC.Packet;
  Intercept = MHServiceC.Intercept;

  SplitControl = NetControlM.SplitControl;

#ifdef LOOPBACK
  LoopBackM.SubSend    -> MHServiceC.MHSend;
  LoopBackM.SubReceive -> MHServiceC.Receive;
  LoopBackM.AMPacket   -> MHServiceC.MHPacket;
  LoopBackM.Packet     -> MHServiceC.Packet;
#endif

  MHServiceC.AMPacket    -> ActiveMessageC;
  MHServiceC.SubPacket   -> ActiveMessageC;
  MHServiceC.AMSend      -> MHQueue;
  MHServiceC.SubReceive  -> MHReceiver;
  MHServiceC.Acks        -> MHQueue;

  DymoServiceC.AMPacket    -> ActiveMessageC;
  DymoServiceC.Packet      -> ActiveMessageC;
  DymoServiceC.AMSend      -> DymoQueue;
  DymoServiceC.Receive     -> DymoReceiver;
#if DYMO_LINK_FEEDBACK
  DymoServiceC.LinkMonitor -> MHServiceC;
#endif

  NetControlM.AMControl     -> ActiveMessageC.SplitControl;
  NetControlM.TableControl  -> DymoTableC.StdControl;
  NetControlM.EngineControl -> DymoServiceC.SplitControl;

#ifdef DYMO_MONITORING  
  RoutingTableInfo = DymoTableC.RoutingTableInfo;
  DymoMonitor = DymoServiceC.DymoMonitor;
#endif
  MHControl   = MHServiceC.MHControl;

}
