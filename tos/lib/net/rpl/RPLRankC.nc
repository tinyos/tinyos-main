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

/*
 * Copyright (c) 2010 Stanford University. All rights reserved.
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
 * @author Yiwei Yao <yaoyiwei@stanford.edu>
 * @author JeongGil Ko (John) <jgko@cs.jhu.edu>
 */


configuration RPLRankC {
  provides {
    interface IP as IP_DIO_Filter;
    interface RPLRank;
    interface StdControl;
  }
  uses {
    interface IP as ICMP_RA[uint8_t code];
  }
}
implementation {
  components RPLRankP;
  components RPLRoutingEngineC;
  components RPLOFC;

  components IPAddressC;
  components IPStackC;
  components IPPacketC;
  components IPNeighborDiscoveryC;

#if RPL_ADDR_AUTOCONF
  // If we are using RPL to handle our IPv6 address autoconfiguration, wire
  // to the relevant interfaces.
  components LocalIeeeEui64C;
  RPLRankP.SetIPAddress -> IPAddressC.SetIPAddress;
  RPLRankP.LocalIeeeEui64 -> LocalIeeeEui64C.LocalIeeeEui64;
#endif

  RPLRank = RPLRankP;
  StdControl = RPLRankP;
  IP_DIO_Filter = RPLRankP.IP_DIO_Filter;
  RPLRankP.IP_DIO = ICMP_RA[ICMPV6_CODE_DIO];

  RPLRankP.RouteInfo -> RPLRoutingEngineC.RPLRoutingEngine;
  RPLRankP.IPAddress -> IPAddressC.IPAddress;
  RPLRankP.ForwardingEvents -> IPStackC.ForwardingEvents[RPL_IFACE];
  RPLRankP.IPPacket -> IPPacketC.IPPacket;
  RPLRankP.NeighborDiscovery -> IPNeighborDiscoveryC.NeighborDiscovery;
  RPLRankP.RPLOF -> RPLOFC.RPLOF;
}
