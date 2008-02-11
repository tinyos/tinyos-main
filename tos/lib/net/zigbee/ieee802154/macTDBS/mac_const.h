/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author open-zb http://www.open-zb.net
 * @author Andre Cunha
 */

// The MAC constants are defined in here.
// Notice that these makes use of the PHY constants.
//pag 134

#ifndef __MAC_CONST__
#define __MAC_CONST__


#define aBaseSlotDuration          60
#define aBaseSuperframeDuration    960 //aBaseSlotDuration*aNumSuperframeSlots

//#define aExtendedAddress         // This should be defined by the device!

#define aMaxBE                     5 //CSMA-CA

#define aMaxBeaconOverhead         75
#define aMaxBeaconPayloadLength    aMaxPHYPacketSize-aMaxBeaconOverhead
#define aGTSDescPersistenceTime    4
#define aMaxFrameOverhead          25
#define aMaxFrameResponseTime      1220
#define aMaxFrameRetries           1

//(SYNC)number of beacons lost before sending a Beacon-Lost indication
#define aMaxLostBeacons            4
#define aMaxMACFrameSize           aMaxPHYPacketSize-aMaxFrameOverhead
#define aMaxSIFSFrameSize          18
#define aMinCAPLength              440
#define aMinLIFSPeriod             40
#define aMinSIFSPeriod             12
#define aNumSuperframeSlots        16
#define aResponseWaitTime          32*aBaseSuperframeDuration
#define aUnitBackoffPeriod         20


#define TYPE_BEACON 0
#define TYPE_DATA 1
#define TYPE_ACK 2
#define TYPE_CMD 3

#define SHORT_ADDRESS 2
#define LONG_ADDRESS 3
#define RESERVED_ADDRESS 1

#define NUMBER_TIME_SLOTS 16

#define ACK_LENGTH 5

//buffer sizes
#define MAX_GTS_BUFFER 7

//#define MAX_GTS_PEND 2
//#define MAX_GTS_IN_SLOT 1

#define INDIRECT_BUFFER_SIZE 2
#define RECEIVE_BUFFER_SIZE 4
#define SEND_BUFFER_SIZE 3

#define UPSTREAM_BUFFER_SIZE 3

#define GTS_SEND_BUFFER_SIZE 3

#define BACKOFF_PERIOD_MS 0.34724
#define BACKOFF_PERIOD_US 347.24

//value of each symbol in us
#define EFFECTIVE_SYMBOL_VALUE 17.362

// MAC PIB attribute
typedef struct
{
	//pag 135
	uint8_t macAckWaitDuration;
	bool macAssociationPermit;//FDD
	bool macAutoRequest;
	bool macBattLifeExt;
	uint8_t macBattLifeExtPeriods;
	
	uint8_t macBeaconPayload[aMaxBeaconPayloadLength];//FDD
	
	uint8_t macBeaconPayloadLenght;//FDD
	uint8_t macBeaconOrder;//FDD
	
	uint32_t macBeaconTxTime;//FDD
	uint8_t macBSN;//FDD
	uint32_t macCoordExtendedAddress0;
	uint32_t macCoordExtendedAddress1;
	uint16_t macCoordShortAddress;
	uint8_t macDSN;
	bool macGTSPermit;//FDD
	uint8_t macMaxCSMABackoffs;
	uint8_t macMinBE;
	uint16_t macPANId;
	bool macPromiscuousMode;//FDD
	bool macRxOnWhenIdle;
	uint32_t macShortAddress;
	uint8_t macSuperframeOrder;//FDD
	uint32_t macTransactionPersistenceTime;//FDD
	
} macPIB;

// MAC PIB security ACL entry descriptor
typedef struct
{
	uint32_t ACLExtendedAddress[2];
	uint16_t ACLShortAddress;
	uint16_t ACLPANId;
	uint8_t ACLSecurityMaterialLength;
	//variable string
	uint8_t ACLSecurityMaterial;
	uint8_t ACLSecuritySuite;
	
}ACLDescriptor;

// MAC PIB security attribute
typedef struct
{
	//pag 138
	ACLDescriptor macACLEntryDescriptorSet;
	uint8_t macACLEntryDescriptorSetSize;
	bool macDefaultSecurity;
	uint8_t macDefaultSecurityMaterialLength;
	//variable string
	uint8_t macDefaultSecurityMaterial;
	uint8_t macDefaultSecuritySuite;
	uint8_t macSecurityMode;
	
}macPIBsec;

//MAC PANDescriptor
typedef struct
{
	//pag76
	uint8_t CoordAddrMode;
	uint16_t CoordPANId;
	uint32_t CoordAddress0;
	uint32_t CoordAddress1;
	uint8_t LogicalChannel;
	//superframe specification field
	uint16_t SuperframeSpec;
	bool GTSPermit;
	uint8_t LinkQuality;
	uint32_t TimeStamp;
	bool SecurityUse;
	uint8_t ACLEntry;
	bool SecurityFailure;

}PANDescriptor;

//GTS entry (used in the PAN coordinator)
typedef struct
{
	uint8_t gts_id;
	uint8_t starting_slot;
	uint8_t length;
	uint8_t direction;
	uint16_t DevAddressType;
	uint8_t expiration;

}GTSinfoEntryType;

//GTS entry (used in the PAN coordinator)
typedef struct
{
	uint8_t gts_id;
	uint8_t starting_slot;
	uint8_t length;
	uint16_t DevAddressType;
	uint8_t persistencetime;

}GTSinfoEntryType_null;

typedef struct
{
	uint8_t handler;
	uint16_t transaction_persistent_time;
	
	//MPDU frame;
	uint8_t frame[127];

}indirect_transmission_element;

typedef struct gts_slot_element
{
	uint8_t element_count;
	uint8_t element_in;
	uint8_t element_out;
	uint8_t gts_send_frame_index[GTS_SEND_BUFFER_SIZE];

}gts_slot_element;


typedef struct time_stamp32
{

uint32_t time_stamp;

}time_stamp32;

typedef struct time_stamp16
{

uint16_t time_stamp;

}time_stamp16;

//MAC ACTIVE CHANNEL SCAN REDUCED PAN DESCRIPTOR (SHOR ADDRESS ONLY)
typedef struct SCAN_PANDescriptor
{
	//pag76
	uint16_t CoordPANId;
	uint16_t CoordAddress;
	uint8_t LogicalChannel;
	//superframe specification field
	uint16_t SuperframeSpec;
	uint8_t lqi;
}SCAN_PANDescriptor;


#endif
