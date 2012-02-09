README for cluster tree test application
Author/Contact: Stefano Tennina <sota@isep.ipp.pt>

Description:

This folder contains the first implementation of the Network (NWK) layer for ZigBee 
Cluster Tree model as well as an example application to test its functionalities.
The NWK layer is implemented on top of the TKN15.4 MAC layer and uses the 
beacon-enabled mode.
A ZigBee cluster tree network is a network composed by 3 types of devices: a PAN 
coordinator, which acts as root of the tree, the end devices, which are the leaves 
of the tree, and the routers, which lead clusters of end devices and interconnect 
the leaves with the root.
The code for NWK layer is in the folder "clusterTree" and includes the code for 
the 3 devices.

The application is in the folder "tests" and includes the codes for each type of device.
The folder "shadow" includes a modified version of the Random interface, used to schedule 
the association start from multiple nodes to a single parent.

If you want to use this network layer instead of your platform's default protocol in 
your own application, you need to modify the pmote.sh script which is used to program 
the nodes and configuring them to form the cluster tree network.
To run the scripts it is needed to make them executable using the Linux command from 
the "zigbee" folder:
	chmod +x *.sh

The pmote script must be run to compile and install software in a mote and the assumption 
made is that nodes are all TelosB (although any platform which is supported by the 
TKN154 MAC can run this code). 
Each mote can be a Coordinator (GW, gateway), Router (CH, cluster head), 
End-device (SN, sensor node) or Sniffer.
Its usage is as follows:
	./pmote.sh <install type> <device type> <USB port number> <device address> [<depth> <address parent> <xPos> <yPos>]

For convenience, a pnetwork script is included to setup a small network 
as follows:

GW <-> CH1 <-+-> SN1
             +-> SN2

This scripts simply calls the pmote recursively to build the network, supposing that 
4 nodes are attached on USB ports from /dev/ttyUSB0 to /dev/ttyUSB3.

The addressing mechanism implemented in the NWK layer is the simple ZigBee Cskip.

Some of the configuration parameters can be set on the pmote script (e.g., channel, 
PAN ID, transmission power), while others such as Beacon Order and Superframe Order 
can be changed from the MAC_profile.h file which is in the "zigbee/clusterTree/includes" 
folder.


Criteria for a successful test:

Press the USER button on the GW and it will start sending beacons (blue led toggles 
every beacon transmitted). The CH1 is configured to wait for beacons from the GW and 
it will switch on the green led when the first beacon is received. The SNs are 
configured to wait for CH1's beacons and toggle the red led every time they receive 
a beacon from nodes other than CH1.
CH1 then associates with the GW and starts the negotiation phase to get a time window 
to start its superframe in a non-overlapping fashion with the other clusters (i.e., 
in this case, the GW). The windows are statically allocated based on the Time Division 
Cluster Scheduling algorithm.
As soon as the negotiation is accomplished, CH1 starts sending 
beacons (blue led toggles) and the SNs switch on their green led starting the process 
for association.
When the network has been setup, the SNs transmit dummy data towards the GW though the 
CH and every time the data is transmitted by SNs or the CH the green led toggles.
If the USER button of a SN is pressed, the node will send a disassociation request 
to the parent CH and then stops transmitting data.


Known bugs/limitations:

- GTS allocation policies still not implemented (although GTS slots are handled at 
  the MAC layer)

- Allocation of the time windows to cluster heads for their superframe during the 
  negotiation phase after the CHs association is based on fixed configuration 
  (process_beacon_scheduling() function in coordinatorBasicC.nc).

- Many TinyOS 2 platforms do not have a clock that satisfies the
  precision/accuracy requirements of the IEEE 802.15.4 standard (e.g. 
  62.500 Hz, +-40 ppm in the 2.4 GHz band); in this case the MAC timing 
  is not standard compliant
