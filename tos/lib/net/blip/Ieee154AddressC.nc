
configuration Ieee154AddressC {
  provides interface Ieee154Address;

} implementation {
  components Ieee154AddressP;
  components LocalIeeeEui64C;

#if defined(PLATFORM_MICAZ) || defined(PLATFORM_IRIS)
  components BareMessageC;
#endif

  components MainC;
  Ieee154Address = Ieee154AddressP;

  MainC.SoftwareInit -> Ieee154AddressP;
  Ieee154AddressP.LocalIeeeEui64 -> LocalIeeeEui64C;

#if defined(PLATFORM_MICAZ) || defined(PLATFORM_IRIS)
  Ieee154AddressP.ShortAddressConfig -> BareMessageC;

#elif defined(PLATFORM_TELOSB) || defined (PLATFORM_EPIC) || defined (PLATFORM_TINYNODE)
  // workaround until the radio stack uses this interface
  components CC2420ControlC;
  Ieee154AddressP.CC2420Config -> CC2420ControlC;

#else
  // workaround until the radio stack uses this interface
  components CC2420ControlC;
  Ieee154AddressP.CC2420Config -> CC2420ControlC;
#endif


}
