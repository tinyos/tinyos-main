
generic configuration UdpSocketC() {
  provides interface UDP;
} implementation {
  
  components UdpC;

  UDP = UdpC.UDP[unique("UDP_CLIENT")];
}
