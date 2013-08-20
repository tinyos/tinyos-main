/*
 * Neighbor Discovery for blip
 *
 * @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu>
 */

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

  NeighborDiscovery = IPNeighborDiscoveryP.NeighborDiscovery;
  IPForward = IPNeighborDiscoveryP.IPForward;

  IPNeighborDiscoveryP.IPLower = IPLower;
  IPNeighborDiscoveryP.IPAddress -> IPAddressC.IPAddress;
  IPNeighborDiscoveryP.Ieee154Address -> Ieee154AddressC.Ieee154Address;
}
