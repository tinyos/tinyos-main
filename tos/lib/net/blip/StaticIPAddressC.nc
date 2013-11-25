/**
 * Component for doing compile-time address allocation. Wired by the
 * stack, sets a static address based on IN6_PREFIX and EUI64 on
 * boot. Useful if you want know addresses at install time.
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
  StaticIPAddressP.SetIPAddress -> IPAddressC.SetIPAddress;
  StaticIPAddressP.LocalIeeeEui64 -> LocalIeeeEui64C.LocalIeeeEui64;
}