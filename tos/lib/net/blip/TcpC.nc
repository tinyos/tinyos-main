
configuration TcpC {
  provides interface Tcp[uint8_t client];
} implementation {

  components MainC, IPDispatchC, TcpP, IPAddressC;
  components new TimerMilliC();

  Tcp = TcpP;

  MainC -> TcpP.Init;
  TcpP.Boot -> MainC;
  TcpP.IP -> IPDispatchC.IP[IANA_TCP];

  TcpP.Timer -> TimerMilliC;
  TcpP.IPAddress -> IPAddressC;
}
