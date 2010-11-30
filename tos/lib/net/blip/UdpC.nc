
#include <BlipStatistics.h>

configuration UdpC {
  provides interface UDP[uint8_t clnt];
  provides interface BlipStatistics<udp_statistics_t>;
} implementation {

  components MainC, IPStackC, UdpP, IPAddressC;
  UDP = UdpP;
  BlipStatistics = UdpP;

  MainC -> UdpP.Init;
  UdpP.IP -> IPStackC.IP[IANA_UDP];
  UdpP.IPAddress -> IPAddressC;
}
