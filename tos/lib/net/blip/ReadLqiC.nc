
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
  
#if defined(PLATFORM_MICAZ) || defined(PLATFORM_TELOSB)  || \
    defined(PLATFORM_EPIC)  || defined(PLATFORM_SHIMMER) || \
    defined(PLATFORM_INTELMOTE2)
  // cc2420 platforms
  components CC2420ReadLqiC, CC2420PacketC;
  ReadLqi = CC2420ReadLqiC;
  CC2420ReadLqiC.CC2420Packet -> CC2420PacketC;
#elif defined(PLATFORM_IRIS) 
  components RF230ReadLqiC, RF230Ieee154MessageC;
  ReadLqi = RF230ReadLqiC;
  RF230ReadLqiC.SubLqi -> RF230Ieee154MessageC.PacketLinkQuality;
#else
#error "No radio support is available for your platform"
#endif

}
