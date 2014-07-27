/*
 * Copyright (c) 2010 Johns Hopkins University. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * RPLRoutingEngineC.nc
 * @author JeongGil Ko (John) <jgko@cs.jhu.edu>
 * @author Brad Campbell <bradjc@umich.edu>
 */

#include <RPL.h>
#include <lib6lowpan/ip.h>

configuration RPLRoutingEngineC {
  provides {
    interface RootControl;
    interface StdControl;
    interface RPLRoutingEngine;
  }
}

implementation{
  components new RPLRoutingEngineP() as Routing;
  components MainC, RandomC;
  components new TimerMilliC() as TrickleTimer;
  components new TimerMilliC() as InitDISTimer;
  components new TimerMilliC() as VersionTimer;
  components IPAddressC;
  components RPLRankC as RankC;
  components RPLDAORoutingEngineC;
  components RPLOFC;
  components new ICMPCodeDispatchC(ICMP_TYPE_RPL_CONTROL) as ICMP_RS;
  components IPNeighborDiscoveryC;

  RootControl = Routing;
  StdControl = Routing;
  RPLRoutingEngine = Routing;

  Routing.IP_DIO -> RankC.IP_DIO_Filter; // This should be connected to RankC;
  Routing.IP_DIS -> ICMP_RS.IP[ICMPV6_CODE_DIS];
  Routing.TrickleTimer -> TrickleTimer;
  Routing.InitDISTimer -> InitDISTimer;
  Routing.Random -> RandomC;
  Routing.RPLRankInfo -> RankC;
  Routing.IPAddress -> IPAddressC;
  Routing.RankControl -> RankC;
  Routing.RPLDAORoutingEngine -> RPLDAORoutingEngineC;
  Routing.IncreaseVersionTimer -> VersionTimer;
  Routing.RPLOF -> RPLOFC.RPLOF;
  Routing.NeighborDiscovery -> IPNeighborDiscoveryC.NeighborDiscovery;
}
