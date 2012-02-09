/*
 * @author open-zb http://www.open-zb.net
 * @author Stefano Tennina
 */

#ifndef __NWK_CONST__
#define __NWK_CONST__
 
#include "MAC_profile.h"
#include "nwk_enumerations.h"

//GLOBAL VARIABLES

//SELECTED DEVICE TYPE
#define TYPE_DEVICE COORDINATOR

// Default Device Depth
#ifndef DEF_DEVICE_DEPTH
#define DEF_DEVICE_DEPTH		0x00
#endif

// Default Parent
#ifndef DEF_CHOSEN_PARENT
#define DEF_CHOSEN_PARENT		0x0000
#endif

// Default Position - X
#ifndef DEF_MY_X
#define DEF_MY_X		TOS_NODE_ID
#endif

// Default Position - Y
#ifndef DEF_MY_Y
#define DEF_MY_Y		(TOS_NODE_ID+5)
#endif

#ifdef GEO_3D
	// Default Position - Z
	#ifndef DEF_MY_Z
	#define DEF_MY_Z		0x0000
	#endif
#endif

// Maximum number of alternative parents (fault tolerance) including 
// the actual one. This definition impacts on the neighbor table dimension
#define MAXPARENTS			0x00

// The Network layer constants are defined in here.
//page 202
//#define nwkcCoordinatorCapable     //set at build time
//#define nwkcDefaultSecurityLevel   ENC-MIC-64

#define nwkcDiscoveryRetryLimit	0x03
#define nwkcMaxDepth			0x0f
#define nwkcMinHeaderOverhead	0x08
#define nwkcProtocolVersion		0x01    
#define nwkcRepairThreshold		0x03
#define nwkcRouteDiscoveryTime	0x2710
#define nwkcMaxBroadcastJitter	0x40
#define nwkcInitialRREQRetries	0x03
#define nwkcRREQRetries			0x02
#define nwkcRREQRetryInterval	0xfe
#define nwkcMinRReQJitter		0x01
#define nwkcMaxRReQJitter		0x40


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
//set nwkRouteTable;
	uint8_t nwkSymLink;
	uint8_t nwkCapabilityInformation;
	uint8_t nwkUseTreeAddrAlloc;
	uint8_t nwkUseTreeRouting;
	uint16_t nwkNextAddress;
	uint16_t nwkAvailableAddresses;
	uint16_t nwkAddressIncrement;
	uint16_t nwkTransactionPersistenceTime;
	
} nwkIB;


typedef struct
{
	uint16_t tosAddress;
	uint16_t depth;
} beaconPay_t;


//NWK layer NeighborTableEntry
typedef struct
{
//page 218
	uint16_t PAN_Id;
	uint64_t Extended_Address;
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

//NEIGHBOUR TABLE COUNT
#define NEIGHBOUR_TABLE_SIZE	(MAXCHILDREN+MAXPARENTS)

//beacon scheduling mechanims
typedef struct
{
	uint8_t request_type;
	uint8_t beacon_order;
	uint8_t superframe_order;
	uint8_t transmission_offset[3];
	
}beacon_scheduling;

#define SCHEDULING_REQUEST	0x01
#define SCHEDULING_ACCEPT	0x02
#define SCHEDULING_DENY		0x03

#endif
