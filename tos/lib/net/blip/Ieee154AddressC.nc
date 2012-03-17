
configuration Ieee154AddressC {
  provides interface Ieee154Address;

} implementation {
  components Ieee154AddressP;
  components LocalIeeeEui64C;
  Ieee154Address = Ieee154AddressP;

  Ieee154AddressP.LocalIeeeEui64 -> LocalIeeeEui64C;

  // workaround until the radio stack uses this interface
  components ActiveMessageAddressC;
  Ieee154AddressP.ActiveMessageAddress -> ActiveMessageAddressC;
}
