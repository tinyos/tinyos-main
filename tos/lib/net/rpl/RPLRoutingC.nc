/*
 * Copyright (c) 2011 Johns Hopkins University. All rights reserved.
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
 * RPLRoutingC.nc
 * @ author Stephen Dawson-Haggerty
 * @ author JeongGil Ko (John) <jgko@cs.jhu.edu>
 */

/* Top-level component to wire together the RPL layers */
#include <lib6lowpan/ip.h>

configuration RPLRoutingC {
  provides {
    interface StdControl;
    interface RootControl;
  }
} implementation {
  components RPLRankC;
  components RPLRoutingEngineC;
  components RPLDAORoutingEngineC;

  /* we receive routing messages through the ICMP component, which
     recieves all packets with the ICMP  */
  components IPStackC;
  components new ICMPCodeDispatchC(ICMP_TYPE_RPL_CONTROL) as ICMP_RA;

  StdControl = RPLRoutingEngineC;
  StdControl = RPLRankC;
  /* Cancel below for no-downstream messages */
  StdControl = RPLDAORoutingEngineC;
  RootControl = RPLRoutingEngineC;

  RPLRankC.ICMP_RA -> ICMP_RA;
  RPLDAORoutingEngineC.ICMP_RA -> ICMP_RA;
  IPStackC.RoutingControl -> RPLRoutingEngineC.StdControl;
  IPStackC.RoutingControl -> RPLDAORoutingEngineC.StdControl;

}
