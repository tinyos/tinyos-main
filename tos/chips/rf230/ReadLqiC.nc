
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

  components RF230ReadLqiC, RF230Ieee154MessageC;
  ReadLqi = RF230ReadLqiC;
  RF230ReadLqiC.SubLqi -> RF230Ieee154MessageC.PacketLinkQuality;
  RF230ReadLqiC.SubRssi -> RF230Ieee154MessageC.PacketRSSI;

}
