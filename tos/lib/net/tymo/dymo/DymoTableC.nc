/*
 * Copyright (c) 2007 Romain Thouvenin <romain.thouvenin@gmail.com>
 * Published under the terms of the GNU General Public License (GPLv2).
 */

#include "dymo_table.h"

/**
 * DymoTableC - Provides a routing table with DYMO routing information.
 *
 * @author Romain Thouvenin
 */

configuration DymoTableC {
  provides {
    interface StdControl;
    interface RoutingTable;
    interface DymoTable;
  }
#ifdef DYMO_MONITORING
  provides interface RoutingTableInfo;
#endif

  uses interface LinkMonitor;
}

implementation {
  components new DymoTableM(MAX_TABLE_SIZE); 
  components new TimerMilliC() as BaseTimer;
  components new VirtualizeTimerC(TMilli, MAX_TABLE_SIZE * NB_ROUTE_TIMERS) as Timers;
  components TinySchedulerC;

  StdControl   = DymoTableM.StdControl;
  RoutingTable = DymoTableM.RoutingTable;
  DymoTable    = DymoTableM.DymoTable;
  LinkMonitor  = DymoTableM.LinkMonitor;

  DymoTableM.Timer -> Timers;

  Timers.TimerFrom -> BaseTimer.Timer;

#ifdef DYMO_MONITORING
  RoutingTableInfo = DymoTableM.RoutingTableInfo;
#endif
}
