/**
 * Component for doing compile-time address allocation. Wired by the
 * stack, sets a static address based on IN6_PREFIX and TOS_NODE_ID on
 * boot. Useful for development or of you want to hard-code addresses.
 *
 * @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu>
 * @author Brad Campbell <bradjc@umich.edu>
 */

configuration StaticIPAddressC {
}
implementation {
  components StaticIPAddressP;
  components MainC;
  components IPAddressC;
  components LocalIeeeEui64C;

  StaticIPAddressP.Boot -> MainC.Boot;
  StaticIPAddressP.IPAddress -> IPAddressC.IPAddress;
  StaticIPAddressP.LocalIeeeEui64 -> LocalIeeeEui64C.LocalIeeeEui64;
}