

generic configuration TcpSocketC() {
  provides interface Tcp;
} implementation {

  components TcpC;

  Tcp = TcpC.Tcp[unique("TCP_CLIENT")];
  
}
