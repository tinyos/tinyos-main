/*
 * Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
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
 * - Neither the name of the copyright holders nor the names of
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
 *
 */

/*
 * Provides message dispatch based on the next header field of IP packets.
 *
 */
#include "IPDispatch.h"

configuration IPDispatchC {
  provides {
    interface SplitControl;
    interface IPAddress;
    interface IP[uint8_t nxt_hdr];

    interface Statistics<ip_statistics_t> as IPStats;
    interface Statistics<route_statistics_t> as RouteStats;
    interface Statistics<icmp_statistics_t> as ICMPStats;

  }
} implementation {
  
  components Ieee154MessageC as MessageC; 
  components MainC, IPDispatchP, IPAddressC, IPRoutingP; 
  components NoLedsC as LedsC;
  components RandomC;

  SplitControl = IPDispatchP.SplitControl;
  IPAddress = IPAddressC;
  IP = IPDispatchP;

  IPDispatchP.Boot -> MainC;

#ifdef IEEE154FRAMES_ENABLED
  IPDispatchP.Ieee154Send -> MessageC;
#else
  components ResourceSendP;
  ResourceSendP.SubSend -> MessageC;
  ResourceSendP.Resource -> MessageC.SendResource[unique(RADIO_SEND_RESOURCE)];
  IPDispatchP.Ieee154Send -> ResourceSendP.Ieee154Send;
#endif

  IPDispatchP.Ieee154Receive -> MessageC.Ieee154Receive;
  IPDispatchP.Packet -> MessageC.Packet;
#ifdef LOW_POWER_LISTENING
  IPDispatchP.LowPowerListening -> MessageC;
#endif

  components ReadLqiC;
  IPDispatchP.Ieee154Packet -> MessageC;
  IPDispatchP.PacketLink -> MessageC;
  IPDispatchP.ReadLqi -> ReadLqiC;

  IPDispatchP.Leds -> LedsC;

  IPDispatchP.IPAddress -> IPAddressC;

  components new TimerMilliC();
  IPDispatchP.ExpireTimer -> TimerMilliC;

  components new PoolC(message_t, IP_NUMBER_FRAGMENTS) as FragPool;

  components new PoolC(send_entry_t, IP_NUMBER_FRAGMENTS) as SendEntryPool;
  components new QueueC(send_entry_t *, IP_NUMBER_FRAGMENTS);

  components new PoolC(send_info_t, N_FORWARD_ENT) as SendInfoPool;

  IPDispatchP.FragPool -> FragPool;
  IPDispatchP.SendEntryPool -> SendEntryPool;
  IPDispatchP.SendInfoPool  -> SendInfoPool;
  IPDispatchP.SendQueue -> QueueC;

  components ICMPResponderC;
  components new TimerMilliC() as TGenTimer;
  IPDispatchP.ICMP -> ICMPResponderC;
  IPRoutingP.ICMP  -> ICMPResponderC;
  IPDispatchP.RadioControl -> MessageC;

  components IPExtensionP;
  MainC.SoftwareInit -> IPExtensionP.Init;
  IPDispatchP.InternalIPExtension -> IPExtensionP;

  IPDispatchP.IPRouting -> IPRoutingP;
  IPRoutingP.Boot -> MainC;
  IPRoutingP.Leds -> LedsC;
  IPRoutingP.IPAddress -> IPAddressC;
  IPRoutingP.Random -> RandomC;
  IPRoutingP.TrafficGenTimer -> TGenTimer;
  IPRoutingP.TGenSend -> IPDispatchP.IP[IPV6_NONEXT];

  IPRoutingP.IPExtensions -> IPDispatchP;
  IPRoutingP.DestinationExt -> IPExtensionP.DestinationExt[0];
  

  IPStats    = IPDispatchP;
  RouteStats = IPRoutingP;
  ICMPStats  = ICMPResponderC;

  components new TimerMilliC() as RouteTimer;
  IPRoutingP.SortTimer -> RouteTimer;

#ifdef DELUGE
  components NWProgC;
#endif

}
