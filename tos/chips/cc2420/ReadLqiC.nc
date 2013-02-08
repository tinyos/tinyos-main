
/*
 * Different platforms have different ways of getting in touch with
 * the LQI reading the radio provides.  This module wraps the
 * different ways in platform-independent logic.
 *
 *
 * @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu>
 */

configuration ReadLqiC {
  provides interface ReadLqi;
} implementation {

  // cc2420 platforms
  components CC2420ReadLqiC, CC2420PacketC;
  ReadLqi = CC2420ReadLqiC;
  CC2420ReadLqiC.CC2420Packet -> CC2420PacketC;

}
