/*
 * Convenient module for creating a UDP socket.
 *
 * @author Stephen Dawson-Haggerty <stevedh@cs.berkeley.edu>
 */

generic configuration UdpSocketC() {
  provides {
  	interface UDP;
  }
} implementation {

  components UdpC;

  UDP = UdpC.UDP[unique("UDP_CLIENT")];
}
