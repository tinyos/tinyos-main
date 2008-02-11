Title: open-zb protocol stack implementation for TinyOS v2.0
Author: André Cunha - IPP-HURRAY! http://www.open-zb.net
----------------------------------------------

Implementation of the ZigBee and the beacon-enabled mode of the IEEE 802.15.4.

This project is divided in two, the beacon-enabled mode of the IEEE 802.15.4 without any network level
and supporting the synchronized star topology, tested in the MicaZ and TelosB motes and the beacon-enabled
mode of the IEEE 802.15.4 with the ZigBee network layer supporting the Cluster-tree topology.

The current version of the implementation of the IEEE 802.15.4 beacon enabled mode supports the following functionalities:

-CSMA/CA algorithm – slotted version;
-GTS Mechanism;
-Indirect transmission mechanism;
-Direct / Indirect / GTS Data Transmission;
-Beacon Management;
-Frame construction – Short Addressing Fields only and extended addressing
fields in the association request;
-Association/Disassociation Mechanism;
-MAC PIB Management;
-Frame Reception Conditions;
-ED and PASSIVE channel scan;

The following functionalities are not implemented or tested in the current
version of the implementation 
-Unslotted version CSMA/CA;
-Extended Address Fields of the Frames;
-IntraPAN Address Fields of the Frames;
-Active and Orphan channel Scan;
-Orphan Devices;
-Frame Reception Conditions (Verify Conditions);
-Security – Out of the scope of this implementation;

The current version of the ZigBee Network Layer, besides the above functionalities, supports

-Creation of the Cluster-tree topology (statically defined) using the TDBS (refer to http://www.open-zb.net/publications/hurray-tr-070510.pdf)
-Cluster-tree routing protocol
-Address Assignment
-NWL PIB management


Notes:
------

The implementation files is organized as follows:

folders:

app 
- IEEE 802.15.4 test applications
	Contains 4 test applications
	-AssociationExample - uses the associates with the Coordinator, transmits data messages and dissasociates
	-DataSendExample - data transmission example
	-GTSManagementExample - Uses the GTS functions to allocate a GTS slot in the Coordinator, sends GTS messages and deallocate the GTS slot
	-SimpleRoutingExample - evolution of the DataSendExample used to demonstrate a simple netork layer where two nodes use the Coordinator to route messages
Notes:
The objective of these examples is to
provide a demonstration/testing of the protocol functionalities and allowing a simple
understanding of the implementation functions.
All the examples have a configuration file associated (eg <AppName>.h) located in
the application folder. The configuration include the type of device (eg
COORDINATOR or END_DEVICE), the logical channel, the beacon order, the
superframe order, the pan id and the device depth in the network (by default all the end
devices have a depth of 1 and the coordinator a depth of 0).

- ZigBee Network Layer with the TDBS
	
	-Test_APL
This application uses the interfaces provided by the NWKM component and currently is customized
to use with the TELOSB mote due to the interfacing with the mote user button. The TELOSB mote needs to
“warmup” before entering into normal operational behaviour, so, the user button is used to start the mote
operation either by starting to send beacons, in the case of the ZigBee Coordinator, or to associate to a
network in the case of ZigBee Routers or End Devices.
In order to test the cluster-tree approach we have forced the association to a specific parent device by
assigning some static parameters to the device. These parameters are located in the nwk_const.h file under
the lib.nwk and are the following:
-TYPE_DEVICE – selecting the role of the device in the network;
-DEVICE_DEPTH – selecting the depth of the device in the network. This parameter in be used in
computing the cskip functions used for the address assignment and for the tree-routing. This value
will also be used to select the appropriate parent selected for the association.
Depending of the selected depth the device will select the statically defined parent. The parent values are
assigned in the NLME_NETWORK_DISCOVERY.request primitive.The parents addresses (short address and
extended address) are defined in the following variables:
Activated when the device depth is 0x01
-D1_PAN_EXT0 0x00000001
-D1_PAN_EXT1 0x00000001
-D1_PAN_SHORT 0x0000
Activated when the device depth is 0x02
-D2_PAN_EXT0 0x00000002
-D2_PAN_EXT1 0x00000002
-D2_PAN_SHORT 0x0001
Activated when the device depth is 0x03
-D3_PAN_EXT0 0x00000003
-D3_PAN_EXT1 0x00000003
-D3_PAN_SHORT 0x0002
Activated when the device depth is 0x04
-D4_PAN_EXT0 0x00000006
-D4_PAN_EXT1 0x00000006
-D4_PAN_SHORT 0x0022
In order for a cluster-tree to work properly there is a need to schedule the beacon frames. This is
done by assigning a time offset to each routers. The device assigned as a ZigBee
Coordinator will accept the negotiation requests for beacon transmission. Upon the reception of these
messages the ZC will execute the process_beacon_scheduling function that already has an offset list for each
device (based on the short address). This function can be replaced with a scheduling algorithm.

More details in http://www.open-zb.net/publications/hurray-tr-070510.pdf
	

