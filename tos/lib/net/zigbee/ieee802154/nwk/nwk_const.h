/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author http://www.open-zb.net
 * @author Andre Cunha
 */
#ifndef __NWK_CONST__
#define __NWK_CONST__
 
//GLOBAL VARIABLES

#define MAC_PANID 0x1234

//SELECTED DEVICE TYPE

#define TYPE_DEVICE END_DEVICE
//#define TYPE_DEVICE ROUTER
//#define TYPE_DEVICE COORDINATOR

//test definitions
#define DEVICE_DEPTH 0x01

//used to operate in a fixed channel
#define LOGICAL_CHANNEL 0x15

//PAN VARIABLES
//conflict error
//#define PANID 0x1234

#define AVAILABLEADDRESSES 0x04
#define ADDRESSINCREMENT 0x0001
#define MAXCHILDREN 0x06
#define MAXDEPTH 0x03
#define MAXROUTERS 0x04

#define BEACON_ORDER 8
#define SUPERFRAME_ORDER 4

//test definitions

//activated when the device depth is 0x01
#define D1_PAN_EXT0 0x00000001
#define D1_PAN_EXT1 0x00000001
#define D1_PAN_SHORT 0x0000

//activated when the device depth is 0x02
#define D2_PAN_EXT0 0x00000002
#define D2_PAN_EXT1 0x00000002
#define D2_PAN_SHORT 0x0001

//activated when the device depth is 0x03
#define D3_PAN_EXT0 0x00000003
#define D3_PAN_EXT1 0x00000003
#define D3_PAN_SHORT 0x0002

//activated when the device depth is 0x04
#define D4_PAN_EXT0 0x00000006
#define D4_PAN_EXT1 0x00000006
#define D4_PAN_SHORT 0x0022


 
// The Network layer constants are defined in here.
//page 202
//#define nwkcCoordinatorCapable     //set at build time
//#define nwkcDefaultSecurityLevel   ENC-MIC-64

#define nwkcDiscoveryRetryLimit		0x03
#define nwkcMaxDepth				0x0f
#define nwkcMinHeaderOverhead		0x08
#define nwkcProtocolVersion			0x01    
#define nwkcRepairThreshold			0x03
#define nwkcRouteDiscoveryTime		0x2710
#define nwkcMaxBroadcastJitter		0x40
#define nwkcInitialRREQRetries		0x03
#define nwkcRREQRetries				0x02
#define nwkcRREQRetryInterval		0xfe
#define nwkcMinRReQJitter			0x01
#define nwkcMaxRReQJitter			0x40


// The NWK IB attributes are defined in here.
typedef struct
{
//page 204
	uint8_t nwkSequenceNumber;
	uint8_t nwkPassiveAckTimeout;
	uint8_t nwkMaxBroadcastRetries;
	uint8_t nwkMaxChildren;
	uint8_t nwkMaxDepth;
	uint8_t nwkMaxRouters;
//neighbortableentry nwkNeighborTable[];
	uint8_t nwkNetworkBroadcastDeliveryTime;
	uint8_t nwkReportConstantCost;
	uint8_t nwkRouteDiscoveryRetriesPermitted;
//set? nwkRouteTable;
	uint8_t nwkSymLink;
	uint8_t nwkCapabilityInformation;
	uint8_t nwkUseTreeAddrAlloc;
	uint8_t nwkUseTreeRouting;
	uint16_t nwkNextAddress;
	uint16_t nwkAvailableAddresses;
	uint16_t nwkAddressIncrement;
	uint16_t nwkTransactionPersistenceTime;
	
} nwkIB;


//NWK layer NeighborTableEntry
typedef struct
{
//page 218
	uint16_t PAN_Id;
	uint32_t Extended_Address0;
	uint32_t Extended_Address1;
	uint16_t Network_Address;
	uint8_t Device_Type;
	uint8_t Relationship;
	
	//optional fields
	//we choose to exclude this fields due to memory limitation
	
	//bool RxOnWhenIdle;
	uint8_t Depth;
	uint8_t Permit_Joining;
	uint8_t Logical_Channel;
	uint8_t Potential_Parent;
	/*
	uint8_t Beacon_Order;
	
	uint8_t Transmit_Failure;
	uint8_t Potential_Parent;
	uint8_t LQI;
	uint8_t Logical_Channel;
	uint32_t Incoming_Beacon_Timestamp;
	uint32_t Beacon_Transmission_Time_Offset;
*/
} neighbortableentry;

// NWK layer NetworkDescriptor
typedef struct
{
//page 166
	uint16_t PANId;
	uint8_t LogicalChannel;
	uint8_t StackProfile;
	uint8_t ZigBeeVersion;
	uint8_t BeaconOrder;
	uint8_t SuperframeOrder;
	uint8_t PermitJoining;
	
} networkdescriptor;

//NEIGhBOUR TABLE COUNT
#define NEIGHBOUR_TABLE_SIZE 7

//beacon scheduling mechanims
typedef struct
{
	uint8_t request_type;
	uint8_t beacon_order;
	uint8_t superframe_order;
	uint8_t transmission_offset[3];
	
}beacon_scheduling;

#define SCHEDULING_REQUEST 0x01
#define SCHEDULING_ACCEPT 0x02
#define SCHEDULING_DENY 0x03

#endif
