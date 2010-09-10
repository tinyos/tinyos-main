/*
 * "Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/*
 * Provides message dispatch based on the next header field of IP packets.
 *
 */
#include "IPDispatch.h"

configuration IPDispatchC {
  provides {
    interface BlipStatistics<ip_statistics_t>;
    interface SplitControl;
    interface IP[uint8_t nxt_hdr];
  }
} implementation {
  
  components MainC;
  components LedsC as LedsC;

  /* IPDispatchP wiring -- fragment rassembly and lib6lowpan bindings */
  components IPDispatchP;
  components CC2420RadioC as MessageC;
  components ReadLqiC;
  components new TimerMilliC();

  SplitControl = IPDispatchP.SplitControl;

  IPDispatchP.Boot -> MainC;
/* #else */
/*   components ResourceSendP; */
/*   ResourceSendP.SubSend -> MessageC; */
/*   ResourceSendP.Resource -> MessageC.SendResource[unique("RADIO_SEND_RESOURCE")]; */
/*   IPDispatchP.Ieee154Send -> ResourceSendP.Ieee154Send; */
/* #endif */
  IPDispatchP.RadioControl -> MessageC;

  IPDispatchP.BarePacket -> MessageC.BarePacket;
  IPDispatchP.Ieee154Send -> MessageC.BareSend;
  IPDispatchP.Ieee154Receive -> MessageC.BareReceive;

/* #ifdef LOW_POWER_LISTENING */
/*   IPDispatchP.LowPowerListening -> MessageC; */
/* #endif */

/*   IPDispatchP.Ieee154Packet -> MessageC; */
  IPDispatchP.PacketLink -> MessageC;
  IPDispatchP.ReadLqi -> ReadLqiC;
  IPDispatchP.Leds -> LedsC;

/*   IPDispatchP.IPAddress -> IPAddressC; */

  IPDispatchP.ExpireTimer -> TimerMilliC;

  components new PoolC(message_t, N_FRAGMENTS) as FragPool;
  components new PoolC(struct send_entry, N_FRAGMENTS) as SendEntryPool;
  components new QueueC(struct send_entry *, N_FRAGMENTS);
  components new PoolC(struct send_info, N_CONCURRENT_SENDS) as SendInfoPool;
  
  IPDispatchP.FragPool -> FragPool;
  IPDispatchP.SendEntryPool -> SendEntryPool;
  IPDispatchP.SendInfoPool  -> SendInfoPool;
  IPDispatchP.SendQueue -> QueueC;

  BlipStatistics    = IPDispatchP;

  /* wiring up of the IP stack */
  /* SDH : this potentially should be in a seperate component so this
     one only provides the low-level fragmentation reassembly. */
  components IPAddressC, IPAddressFilterP, IPProtocolsP;
  IP = IPProtocolsP;
  IPProtocolsP.SubIP -> IPAddressFilterP.LocalIP;
  IPProtocolsP.IPAddress -> IPAddressC;

  IPAddressFilterP.SubIP -> IPDispatchP;
  IPAddressFilterP.IPAddress -> IPAddressC;

  components ICMPCoreP;
  ICMPCoreP.IP -> IPProtocolsP.IP[IANA_ICMP];


/*   components ICMPResponderC; */
/*   components new TimerMilliC() as TGenTimer; */
/*   IPDispatchP.ICMP -> ICMPResponderC; */
/*   IPRoutingP.ICMP  -> ICMPResponderC; */

/*   components IPExtensionP; */
/*   MainC.SoftwareInit -> IPExtensionP.Init; */
/*   IPDispatchP.InternalIPExtension -> IPExtensionP; */

/*   IPDispatchP.IPRouting -> IPRoutingP; */
/*   IPRoutingP.Boot -> MainC; */
/*   IPRoutingP.Leds -> LedsC; */
/*   IPRoutingP.IPAddress -> IPAddressC; */
/*   IPRoutingP.Random -> RandomC; */
/*   IPRoutingP.TrafficGenTimer -> TGenTimer; */
/*   IPRoutingP.TGenSend -> IPDispatchP.IP[IPV6_NONEXT]; */

/*   IPRoutingP.IPExtensions -> IPDispatchP; */
/*   IPRoutingP.DestinationExt -> IPExtensionP.DestinationExt[0]; */
  

/*   RouteStats = IPRoutingP; */
/*   ICMPStats  = ICMPResponderC; */

/*   components new TimerMilliC() as RouteTimer; */
/*   IPRoutingP.SortTimer -> RouteTimer; */

  // multicast wiring
/* #ifdef BLIP_MULTICAST */
/*   components MulticastP; */
/*   components new TrickleTimerMilliC(2, 30, 2, 1); */
/*   IP = MulticastP.IP; */
  
/*   MainC.SoftwareInit -> MulticastP.Init; */
/*   MulticastP.MulticastRx -> IPDispatchP.Multicast; */
/*   MulticastP.HopHeader -> IPExtensionP.HopByHopExt[0]; */
/*   MulticastP.TrickleTimer -> TrickleTimerMilliC.TrickleTimer[0]; */
/*   MulticastP.IPExtensions -> IPDispatchP; */
/* #endif */

#ifdef DELUGE
  components NWProgC;
#endif

}
