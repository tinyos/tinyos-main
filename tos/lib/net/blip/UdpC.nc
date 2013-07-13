/*
 * Module for wiring up the UDP protocol to the top of the IPv6 stack.
 * Applications should not wire to this directly but rather use UdpSocketC().
 *
 * @author Stephen Dawson-Haggerty <stevedh@cs.berkeley.edu>
 */

#include <BlipStatistics.h>

configuration UdpC {
  provides {
  	interface UDP[uint8_t clnt];
    interface BlipStatistics<udp_statistics_t>;
  }
} implementation {

  components MainC, IPStackC, UdpP, IPAddressC;
  UDP = UdpP.UDP;
  BlipStatistics = UdpP.BlipStatistics;

  MainC.SoftwareInit -> UdpP.Init;
  UdpP.IP -> IPStackC.IP[IANA_UDP];
  UdpP.IPAddress -> IPAddressC.IPAddress;
}
