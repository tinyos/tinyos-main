/*
 * Copyright (c) 2007 Romain Thouvenin <romain.thouvenin@gmail.com>
 * Published under the terms of the GNU General Public License (GPLv2).
 */

/**
 * DymoServiceC - Implements the DYMO routing protocol This is the
 * simulator version, without persistent storage of the sequence
 * number.
 *
 *  @author Romain Thouvenin
 */

configuration DymoServiceC {
  provides {
    interface SplitControl;
  }
  uses {
    interface Packet;
    interface AMPacket;
    interface AMSend;
    interface Receive;
    interface LinkMonitor;
  }

#ifdef DYMO_MONITORING
  provides {
    interface DymoMonitor;
  }
#endif
}

implementation {
  components DymoTableC, DymoEngineM, DymoPacketM;

  SplitControl = DymoEngineM.SplitControl;
  Packet       = DymoPacketM.Packet;
  AMPacket     = DymoEngineM.AMPacket;
  AMSend       = DymoEngineM.AMSend;
  Receive      = DymoEngineM.Receive;
  LinkMonitor  = DymoTableC.LinkMonitor;

  DymoEngineM.DymoPacket   -> DymoPacketM;
  DymoEngineM.RoutingTable -> DymoTableC;
  DymoEngineM.DymoTable    -> DymoTableC;

#ifdef DYMO_MONITORING
  components new TimerMilliC();

  DymoMonitor = DymoEngineM.DymoMonitor;
  DymoEngineM.Timer     -> TimerMilliC;
#endif
}
