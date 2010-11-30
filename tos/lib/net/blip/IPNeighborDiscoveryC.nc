
configuration IPNeighborDiscoveryC {
  provides {
    interface NeighborDiscovery;
    interface IPForward;
  } 
  uses {
    interface IPLower;
  }
} implementation {
  components IPNeighborDiscoveryP, IPAddressC, Ieee154AddressC;

  NeighborDiscovery = IPNeighborDiscoveryP;
  IPForward = IPNeighborDiscoveryP;
  IPNeighborDiscoveryP.IPLower = IPLower;

  IPNeighborDiscoveryP.IPAddress -> IPAddressC;
  IPNeighborDiscoveryP.Ieee154Address -> Ieee154AddressC;
}
