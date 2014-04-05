<!--
# @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu
# @author Brad Campbell <bradjc@umich.edu>
# @status dev
-->

blip-2.0 Overview
=================

Rebuilding from the ground up, we're trying to make blip a robust
foundation for experimenting with either routing protocols or
adaptation layers, without needing extensive re-writes.

In the diagram below, routing protcols and neighbor discovery runs
between the L2.5 and L3 interfaces, and can completly re-work the
stack structure within those limits.  In truth, there is a fair amount
of modularity in that space as well, since (for instance) it is
probably desirable to be able to work on the routing protocol while
also using 6lowpan neighbor discovery.  Utility components for
managing bound addresses should be shared as well.


UdpC  TcpC  ICMPCoreC  -- provide true higher layer services -- transport and management
  |
  |
-+--------------   Layer 3 top interface
IPDispatchC -- wires together layers
  |
  |
IPProtocolsP -- sets up IP header, resolves next hop.  Currently works only for LL.
 |              strips off extention headers, dispatches based on transport "next header" field
 |
IPAddressFilterP -- split up packets depending on what their destination is:
                      - for local packets, dispatch them up through the stack to the appropriate protocol handler
                      - non-local packets go to the ForwardIP
                        interface; routing protocols are responsible
                        for dealing with packets deliver via this
                        interface.  The default behavior is to drop
  |                     the packets if no routing protocol is wired.
  |
  |
--+--------------   Layer 2.5 Interface
IPDispatchP -- Interface to the 6lowpan compression engine
               provides header compression and packet fragmentation
               some additional upper-layer interfaces are necessary for propagating context information
-+---------------   Layer 2 interface
 |                  sends packets over links using the 802.15.4 frame format
 |                  6lowpan component writes the frame header



Unfinished
----------

Portions of blip were started and seemingly never finished. To avoid cluttering
the tree with untested code I removed the files. If you wish to continue work
the code can be found in an earlier commit (ex: SHA
6203922e36c02b2c505f4fc88b264f99338af472).

Removed code:

- Multicast
- IPExtensions
