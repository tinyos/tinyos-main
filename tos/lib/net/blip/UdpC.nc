
configuration UdpC {
  provides interface UDP[uint8_t clnt];                         
} implementation {

  components MainC, IPDispatchC, UdpP, IPAddressC;
  UDP = UdpP;

  MainC -> UdpP.Init;
  UdpP.IP -> IPDispatchC.IP[IANA_UDP];
  UdpP.IPAddress -> IPAddressC;
}
