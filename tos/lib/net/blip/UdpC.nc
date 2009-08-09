
#include <Statistics.h>

configuration UdpC {
  provides interface UDP[uint8_t clnt];
  provides interface Statistics<udp_statistics_t>;
} implementation {

  components MainC, IPDispatchC, UdpP, IPAddressC;
  UDP = UdpP;
  Statistics = UdpP;

  MainC -> UdpP.Init;
  UdpP.IP -> IPDispatchC.IP[IANA_UDP];
  UdpP.IPAddress -> IPAddressC;
}
