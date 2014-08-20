/* Configuration file of Neighbour Discovery

@author Md.Jamal <mjmohiuddin@cdac.in>
@version $Revision: 1.0

*/

#include "ND.h"
configuration NDC {

  provides interface SplitControl;




}


implementation {

  components NDP;
  SplitControl= NDP;

  components IPAddressC;
  NDP.IPAddress->IPAddressC;
  NDP.SetIPAddress -> IPAddressC;

  components LedsC as LedsC;
  NDP.Leds->LedsC;

  components IPStackC;
  NDP.RadioControl->IPStackC;

  components new ICMPCodeDispatchC(ICMP_TYPE_ROUTER_SOL) as ICMP_RS;
  NDP.IP_RS -> ICMP_RS.IP[ICMPV6_ND_CODE];

  components new ICMPCodeDispatchC(ICMP_TYPE_ROUTER_ADV) as ICMP_RA;
  NDP.IP_RA -> ICMP_RA.IP[ICMPV6_ND_CODE];
 
  components new ICMPCodeDispatchC(ICMP_TYPE_NEIGHBOR_SOL) as ICMP_NS;
  NDP.IP_NS -> ICMP_NS.IP[ICMPV6_ND_CODE];

  components new ICMPCodeDispatchC(ICMP_TYPE_NEIGHBOR_ADV) as ICMP_NA;
  NDP.IP_NA -> ICMP_NA.IP[ICMPV6_ND_CODE];

  components new ICMPCodeDispatchC(ICMP_TYPE_DUPLICATE_REQ) as ICMP_DAR;
  NDP.IP_DAR -> ICMP_DAR.IP[ICMPV6_ND_CODE];

  components new ICMPCodeDispatchC(ICMP_TYPE_DUPLICATE_CONFIRM) as ICMP_DAC;
  NDP.IP_DAC -> ICMP_DAC.IP[ICMPV6_ND_CODE];

  components new TimerMilliC() as RSTimer;
  NDP.RSTimer->RSTimer;

  components new TimerMilliC() as NSTimer;
  NDP.NSTimer->NSTimer;

  components NodeC;
  NDP.Node->NodeC;


  components Ieee154AddressC;
  NDP.Ieee154Address->Ieee154AddressC;



  components new MinuteTimerC() as MT;
  NDP.AROTimer->MT.MinuteTimer[unique("Minute")];
  
 
  components OptionC;
  NDP.Option->OptionC;


  components NeighbrCacheC;
  NDP.NeighbrCache->NeighbrCacheC;
  NDP.RouterList->NeighbrCacheC;

  components RandomC;
  NDP.Random->RandomC;
}
