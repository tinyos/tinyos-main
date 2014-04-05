/** Test the link-local communication in the blip stack
 */
configuration TestLinkLocalAppC {

} implementation {
  components MainC, LedsC;
  components TestLinkLocalC;
  components IPStackC;
  components new TimerMilliC();
  components new UdpSocketC();

  TestLinkLocalC.Boot -> MainC;
  TestLinkLocalC.SplitControl -> IPStackC;
  TestLinkLocalC.Sock -> UdpSocketC;
  TestLinkLocalC.Timer -> TimerMilliC;
  TestLinkLocalC.Leds -> LedsC;

  components StaticIPAddressTosIdC; // Use TOS_NODE_ID in address
  //components StaticIPAddressC; // Use LocalIeee154 in address
}
