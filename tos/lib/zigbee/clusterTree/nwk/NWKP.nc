/*
 * @author open-zb http://www.open-zb.net
 * @author Stefano Tennina
 */


//#include <Timer.h>
#include "printfUART.h"
#include "TKN154.h"

#include "log_enable.h"

#ifdef NWK_PRINTFS_ENABLED
	#define lclPrintf_NWK				printfUART
	#define lclPrintf_NWK_UART_init		printfUART_init
#else
	#define lclPrintf_NWK(VAR, __format, __args...)
	void lclPrintf_NWK_UART_init() {}
#endif

#if (LOG_LEVEL & TIME_PERFORMANCE)
	#define START_RECORD()		perLocTimeStart = call LocalTime.get()
	#define STOP_RECORD()		perLocTime[idxPerLocTime++] = (call LocalTime.get()) - perLocTimeStart
	#define PRINT_RECORD()		lclPrintf_NWK("Performance report (line %d)\n", __LINE__);					\
								for (idxPrintVector = 0; idxPrintVector<idxPerLocTime; idxPrintVector++){	\
									lclPrintf_NWK("Location: %d, time: %d\n", (uint32_t)idxPrintVector, 	\
																			perLocTime[idxPrintVector]);}	\
								idxPerLocTime = 0
#else
	#define START_RECORD();		
	#define STOP_RECORD();
	#define PRINT_RECORD();
#endif


module NWKP 
{
	uses {
		// Global
		interface Leds;
		interface Random;
		
		// IEEE802.15.4 MAC - APIs
		interface MLME_RESET;
		interface MLME_START;
		interface MLME_ASSOCIATE;
		interface MCPS_DATA;
		interface MLME_SET;
		interface MLME_GET;
		interface MLME_COMM_STATUS;
		interface MLME_SYNC;
		interface MLME_SYNC_LOSS;
		
#ifndef IM_COORDINATOR
		interface MLME_SCAN;
		interface MLME_BEACON_NOTIFY;
#endif

		// IEEE802.15.4 MAC - Messages
#ifndef IM_END_DEVICE
		interface IEEE154TxBeaconPayload;
#endif
		interface IEEE154Frame as Frame;
		interface Packet;

		interface IEEE154BeaconFrame as BeaconFrame;
#ifdef IM_ROUTER
		interface Pool<message_t> as FramePool;
#endif

		interface MLME_DISASSOCIATE;
		
		//MAC interfaces Still excluded
		//interface MLME_GTS;
		//interface MLME_ORPHAN;

#if (LOG_LEVEL & TIME_PERFORMANCE)
//		interface LocalTime<TMilli> as LocalTime;
		interface LocalTime<TMicro> as LocalTime;
#endif
	}

	provides
	{
		interface Init;
		interface NLDE_DATA;

		//NLME NWK Management services
#ifdef IM_COORDINATOR
		interface NLME_NETWORK_FORMATION;
#else
	   	interface NLME_NETWORK_DISCOVERY;
#endif

#ifdef IM_ROUTER
		interface NLME_START_ROUTER;
#endif

		interface NLME_JOIN;
		interface NLME_LEAVE;
		interface NLME_SYNC;
	 
		interface NLME_RESET;
	
		interface NLME_GET;
		interface NLME_SET;
	}
  
}
implementation {

#if (LOG_LEVEL & TIME_PERFORMANCE)
	uint32_t perLocTimeStart;
	uint32_t perLocTime[10];
	uint8_t idxPerLocTime;
	uint8_t idxPrintVector;
#endif

	// Variable needed to count the beacon transmitted to implement
	// adaptive "timers"
	norace uint16_t beaconCount;
	// Flag to enable the count of the beacon transmitted
	norace bool beaconCountEnable;

	nwkIB nwk_IB;
	
	//uint8_t device_type = TYPE_DEVICE;
	
/*****************************************************/
/*************Neighbourtable Variables****************/
/*****************************************************/ 

	//neighbour table array:
	norace neighbortableentry neighbortable[NEIGHBOUR_TABLE_SIZE];
	//number of neigbourtable entries:
	norace uint8_t neighbour_count /*= 0*/;
	//the index of the parents neighbortable entry
	uint8_t parent /*= 0xFF*/;		// Conventional value meaning No parent now
	
	// Chosen parent by configuration (initialize to default)
	uint16_t myChosenParent /*= DEF_CHOSEN_PARENT*/;
	uint16_t myChosenParentAddress;
	// Depth by configuration (initialize to default)
	uint8_t nwkMyDepth /*= DEF_DEVICE_DEPTH*/;
	
#ifndef IM_END_DEVICE
	// Flag to enable beacon payload setting
	bool flgSetBeaconPay;
#endif

/*****************************************************/
/****************ASSOCIATION Variables********************/
/*****************************************************/ 

	//CURRENT NETWORK ADDRESS
	uint16_t networkaddress /*= 0x0000*/;

	//COORDINATOR OR ROUTER
	//address assignement variables
	uint16_t cskip /*= 0*/;
	
	uint16_t cskip_routing /*= 0*/;

	//current pan characteristics
	uint8_t beaconorder;
	uint8_t superframeorder;
	
	//next child router address
	uint16_t next_child_router_address /*= 0*/;
	uint8_t number_child_router 	/*= 0x01*/;
	uint8_t number_child_end_devices/*= 0x01*/;
	
	
/******************************************************/
/*********NEIGHBORTABLE  MANAGEMENT FUNCTIONS*********/
/******************************************************/ 

	void init_nwkIB();
	
	uint8_t check_neighbortableentry(uint8_t addrmode, ieee154_address_t address);
	
	ieee154_status_t add_neighbortableentry(uint16_t PAN_Id,uint64_t Extended_Address,uint16_t Network_Address,uint8_t Device_Type,uint8_t Relationship, bool force);
	void update_neighbortableentry (uint16_t PAN_Id,uint64_t Extended_Address,uint16_t Network_Address,uint8_t Device_Type,uint8_t Relationship);
	
	//uint8_t find_suitable_parent();
	
	// Set the chosen parent after a successuful association
	uint8_t setParent(uint16_t shortAddress);
	// Remove the previously chosen parent entry in the table after a SYNC loss event
	uint8_t deleteParent(uint8_t idxParent);
	
	uint16_t Cskip(int8_t d);	// d can even be -1!!
	
	uint16_t nexthopaddress(uint16_t destinationaddress,uint8_t d);
	
#if (LOG_LEVEL & DBG_NEIGHBOR_TABLE)
	void list_neighbourtable();
#endif


#ifndef IM_COORDINATOR
	// Try to randomize the association request sending by implementing
	// a random counter of the beacons received
	uint8_t randomAssociation /*= 0*/;
	
	// Maximum association trials after that join unsuccess confirm is signaled
	uint8_t maxAssocTrials /*= MAX_ASSOCIATION_TRIALS*/;

	// Association status variable
	norace uint8_t associationStatus /*= 0*/;

	// Parent address for Association request
	ieee154_address_t parentAssocAddress;
#endif

	// IEEE802.15.4 Global Variables
	//uint8_t m_associatedToParent = FALSE;
	bool m_BeaconWasFound /*= FALSE*/;
	message_t m_frame;
	//bool m_dataConfirmPending = FALSE;
        ieee154_PANDescriptor_t m_PANDescriptor;
#ifndef IM_COORDINATOR
	ieee154_CapabilityInformation_t m_capabilityInformation;
	
	
	uint32_t lclScanChannels;
	uint8_t lclScanduration;
	void scanForBeacons(uint32_t ScanChannels, uint8_t Scanduration);
#endif

#ifdef DEBUG_STATUS_MESSAGE
	void IEEE154PrintStatus(uint16_t lineno, ieee154_status_t status);
	
	// Since printfs at the scan/beacon notify/association procedure
	// preturb the system working status, we define here a couple of 
	// variables to debug info in a deferred print
	ieee154_status_t addParentStatus[10];
	uint8_t currentStatusIndex /*= 0*/;
#endif
	

	task void initTask()
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf_NWK("NWKP Init.\n", "");
	#endif

	nwk_IB.nwkSequenceNumber = call Random.rand16();

	#ifdef DEBUG_STATUS_MESSAGE
		currentStatusIndex = 0;
		memset(addParentStatus, 0, 10*sizeof(ieee154_status_t));
	#endif
		
	#if (LOG_LEVEL & TIME_PERFORMANCE)
		perLocTimeStart = 0;
		memset(perLocTime, 0, 10*sizeof(uint32_t));
		idxPerLocTime = 0;
		idxPrintVector = 0;
	#endif
	
		beaconCount = 0;
		// Count beacon disabled by default
		beaconCountEnable = FALSE;

	/*****************************************************/
	/*************Neighbourtable Variables****************/
	/*****************************************************/ 

		// Initialize the neighbor table
		memset(neighbortable, 0, NEIGHBOUR_TABLE_SIZE*sizeof(neighbortableentry));
		
		//number of neigbourtable entries:
		neighbour_count = 0;
		//the index of the parents neighbortable entry
		parent = 0xFF;		// Conventional value meaning No parent now
		
#ifndef IM_END_DEVICE
		// First time beacon payload has to be set
		flgSetBeaconPay = TRUE;
#endif

	/*****************************************************/
	/****************ASSOCIATION Variables********************/
	/*****************************************************/ 

		//CURRENT NETWORK ADDRESS
		networkaddress = 0x0000;

		//COORDINATOR OR ROUTER
		//address assignement variables
		cskip = 0;
		cskip_routing = 0;
		
		//next child router address
		next_child_router_address = 0;
		number_child_router 	= 0x01;
		number_child_end_devices= 0x01;
		
	/*****************************************************/
	/****************Integer Variables********************/
	/*****************************************************/ 

#ifndef IM_COORDINATOR
		// Try to randomize the association request sending by implementing
		// a random counter of the beacons received
		randomAssociation = 0;
		
		// Maximum association trials after that join unsuccess confirm is signaled
		maxAssocTrials = MAX_ASSOCIATION_TRIALS;

		// Association status variable
		associationStatus = 0;
#endif

		// IEEE802.15.4 Global Variables
		//uint8_t m_associatedToParent = FALSE;
		m_BeaconWasFound = FALSE;
	
		// Set device type
#ifdef IM_ROUTER
		m_capabilityInformation.AlternatePANCoordinator	= 1;
		m_capabilityInformation.DeviceType				= 1;
		m_capabilityInformation.PowerSource				= 0;
		m_capabilityInformation.ReceiverOnWhenIdle		= 0;
		m_capabilityInformation.Reserved				= 0;
		m_capabilityInformation.SecurityCapability		= 0;
		m_capabilityInformation.AllocateAddress			= 1;
#else
#ifdef IM_END_DEVICE
		m_capabilityInformation.AlternatePANCoordinator	= 0;
		m_capabilityInformation.DeviceType				= 0;
		m_capabilityInformation.PowerSource				= 0;
		m_capabilityInformation.ReceiverOnWhenIdle		= 0;
		m_capabilityInformation.Reserved				= 0;
		m_capabilityInformation.SecurityCapability		= 0;
		m_capabilityInformation.AllocateAddress			= 1;
#endif
#endif
	}
	
	command error_t Init.init() {

		lclPrintf_NWK_UART_init();//make the possibility to print

		init_nwkIB();
		
		// Initialize the seed to TOS_NODE_ID (which is the default option)
		call Random.setSeed(0);
		
		// Chosen parent by configuration (initialize to default)
		myChosenParent = DEF_CHOSEN_PARENT;
		myChosenParentAddress = 0xFF;
		// Depth by configuration (initialize to default)
		nwkMyDepth = DEF_DEVICE_DEPTH;
		
		post initTask();

		return SUCCESS;
	}

/*****************************************************************************************************/  
/**************************************MLME-RESET*****************************************************/
/*****************************************************************************************************/ 
	event void MLME_RESET.confirm(ieee154_status_t status)
	{

lclPrintf_NWK("resetyouupie\n","");

	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf_NWK("MLME_RESET.confirm.\n", "");
	#endif
	#ifdef DEBUG_STATUS_MESSAGE
		IEEE154PrintStatus(__LINE__, status);
	#endif
	
		signal NLME_RESET.confirm(status);
	}


#ifndef IM_COORDINATOR
	task void tryAssociation()
	{
		if ( (associationStatus & IM_ASSOCIATING) == IM_ASSOCIATING )
		{
			ieee154_status_t status;
			
			//START_RECORD();

			status = call MLME_ASSOCIATE.request(
							m_PANDescriptor.LogicalChannel,	// LogicalChannel 
							m_PANDescriptor.ChannelPage,	// ChannelPage
							ADDR_MODE_SHORT_ADDRESS,		// CoordAddrMode
							MAC_PANID,						// CoordPANID
							parentAssocAddress,				// CoordAddress
							m_capabilityInformation,		// CapabilityInformation
							0								// Security
						);

		#ifdef DEBUG_STATUS_MESSAGE
			// Debug status here....
			addParentStatus[currentStatusIndex] = status;
			currentStatusIndex++;
		#endif
		}
	}

	// Scan for beacon is called by the network discovery request and 
	// starts the scan process calling the MLME_SCAN.request
	void scanForBeacons(uint32_t ScanChannels, uint8_t Scanduration)
	{
		uint8_t scanDuration = Scanduration;
		// we only scan the single channel on which we expect the PAN coordinator
		ieee154_phyChannelsSupported_t channel = ((uint32_t) 1) << ScanChannels;
		
		// Initialize the flags
		associationStatus = IM_SCANNING;

		m_BeaconWasFound = FALSE;
		
		// we want to be signalled every single beacon that is received during the 
		// channel SCAN-phase, that's why we set  "macAutoRequest" to FALSE
		call MLME_SET.macAutoRequest(FALSE);
		call MLME_SCAN.request(
				PASSIVE_SCAN,			// ScanType
				channel,				// ScanChannels
				scanDuration,			// ScanDuration
				0x00,					// ChannelPage
				0,						// EnergyDetectListNumEntries
				NULL,					// EnergyDetectList
				0,						// PANDescriptorListNumEntries
				NULL,					// PANDescriptorList
				0						// security
			);
	}


	// It asynchronously receives beacons. If in the scan time, it save information about beacon found
	event message_t* MLME_BEACON_NOTIFY.indication(message_t* frame)
	{
		ieee154_phyCurrentPage_t page;
		//networkdescriptor networkdescriptorlist;
		uint8_t srcBeaconDevice = COORDINATOR;
#ifdef DEBUG_STATUS_MESSAGE
		ieee154_status_t status;
#endif
		beaconPay_t *bcnPay;
		
		uint32_t extAddress_trial = 0;

		atomic {
			if ( (associationStatus & ASSOCIATED) == ASSOCIATED) {
				// We are already associated with the Parent
				// and just received one of its periodic beacons
				//call Leds.led2Toggle();
				
				return frame;
			}
			
			if ( (associationStatus & IM_ASSOCIATING) == IM_ASSOCIATING )
			{
				// Filter out the un-needed beacons (maybe it is not necessary since we should have been already sync'ed)
				page = call MLME_GET.phyCurrentPage();
				if (call BeaconFrame.parsePANDescriptor(frame, LOGICAL_CHANNEL, page, &m_PANDescriptor) == SUCCESS)
				{
					if (m_PANDescriptor.CoordAddrMode == ADDR_MODE_SHORT_ADDRESS &&
						m_PANDescriptor.CoordPANId == MAC_PANID && 
						m_PANDescriptor.CoordAddress.shortAddress == parentAssocAddress.shortAddress )
					{
						if (randomAssociation == 0)
							post tryAssociation();
						else
							randomAssociation--;
					}
				}
				
				return frame;
			}
			
			if ( (associationStatus & IM_SCANNING) != IM_SCANNING )
				return frame;

			START_RECORD();

			// Executed only in scanning phase

			// We have received "some" beacon during the SCAN-phase, let's
			// check if it is the beacon from our PAN
			page = call MLME_GET.phyCurrentPage();
			if ( SUCCESS == ( call BeaconFrame.parsePANDescriptor(frame, LOGICAL_CHANNEL, page, &m_PANDescriptor) )
				)
			{
				if (m_PANDescriptor.CoordAddrMode == ADDR_MODE_SHORT_ADDRESS &&
					m_PANDescriptor.CoordPANId == MAC_PANID )
				{
					if (m_PANDescriptor.CoordAddress.shortAddress == 0x0000)
					{
						srcBeaconDevice = COORDINATOR;
						//lclPrintf_NWK("found coordinator!!\n", "");
					}
					else
					{
						srcBeaconDevice = ROUTER;
						//lclPrintf_NWK("found a router!!\n", "");
					}

					// Add the parent to the neighbor table. NOTE: the extended address is not available from the Beacon.
					// I'm defining a different value for the extended address that can be used as a "key" to access the table
					extAddress_trial = ((uint32_t)(m_PANDescriptor.CoordPANId) << 16) | m_PANDescriptor.CoordAddress.shortAddress;
					
					// Children look at beacon payload

					bcnPay = (beaconPay_t *)(call BeaconFrame.getBeaconPayload(frame));
					if (bcnPay->tosAddress != myChosenParent)
					{
						call Leds.led0Toggle();
					#ifdef DEBUG_STATUS_MESSAGE
						// Debug status here....
						addParentStatus[currentStatusIndex] = add_neighbortableentry(
										m_PANDescriptor.CoordPANId,
										extAddress_trial,
										m_PANDescriptor.CoordAddress.shortAddress,
										srcBeaconDevice,
										NEIGHBOR_IS_ALT_PARENT,
										FALSE);
						currentStatusIndex++;
					#else
						add_neighbortableentry(
									m_PANDescriptor.CoordPANId,
									extAddress_trial,
									m_PANDescriptor.CoordAddress.shortAddress,
									srcBeaconDevice,
									NEIGHBOR_IS_ALT_PARENT,
									FALSE);
					#endif
					
						STOP_RECORD();
					
						return frame;
					}

					m_BeaconWasFound = TRUE; // yes!

					call Leds.led0Off();
					call Leds.led1Toggle();
					myChosenParentAddress = m_PANDescriptor.CoordAddress.shortAddress;

					// Force the neighbor table entry to be added
					#ifdef DEBUG_STATUS_MESSAGE
						// Debug status here....
						addParentStatus[currentStatusIndex] = add_neighbortableentry(
										m_PANDescriptor.CoordPANId,
										extAddress_trial,
										m_PANDescriptor.CoordAddress.shortAddress,
										srcBeaconDevice,
										NEIGHBOR_IS_ALT_PARENT,
										TRUE);
						currentStatusIndex++;
					#else
						add_neighbortableentry(
									m_PANDescriptor.CoordPANId,
									extAddress_trial,
									m_PANDescriptor.CoordAddress.shortAddress,
									srcBeaconDevice,
									NEIGHBOR_IS_ALT_PARENT,
									TRUE);
					#endif
				}
			}

			STOP_RECORD();
		}

		return frame;
	}

	// This is activated at the end of the scan process.
	// It is linked to the beacon notify to check if during the scan we get the expected beacon or not
	event void MLME_SCAN.confirm(
			ieee154_status_t status,
			uint8_t ScanType,
			uint8_t ChannelPage,
			uint32_t UnscannedChannels,
			uint8_t EnergyDetectListNumEntries,
			int8_t* EnergyDetectList,
			uint8_t PANDescriptorListNumEntries,
			ieee154_PANDescriptor_t* PANDescriptorList
		)
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf_NWK("MLME_SCAN.confirm\n", "");
	#endif
	#ifdef DEBUG_STATUS_MESSAGE
		IEEE154PrintStatus(__LINE__, status);
	#endif

		PRINT_RECORD();
		
		if (m_BeaconWasFound)
		{
			atomic {
				// our candidate parent is out there sending beacons
				
				// Now we have a choice:
				// 1. signaling a discovery confirm and start the association after a join request, or
				// 2. avoid this signal and directly try to associate, issuing directly a JOIN confirm
				//	after the successful association
				// Go for OPTION 2
		
				// Force the topology to the one preplanned!!
				parentAssocAddress.shortAddress = myChosenParentAddress;
				
				// let's try to associate with it
				call MLME_SET.macCoordShortAddress(parentAssocAddress.shortAddress);
				call MLME_SET.macPANId(m_PANDescriptor.CoordPANId);
				call MLME_SYNC.request(m_PANDescriptor.LogicalChannel, m_PANDescriptor.ChannelPage, TRUE);
				
				// Try association after "randomAssociation" beacons
				randomAssociation = OFFSET_BCN_COUNTER + ((call Random.rand16()) % MAX_RANDOM_BCN_COUNTER);

				call Leds.led1On();

				associationStatus = IM_ASSOCIATING;
			#if (LOG_LEVEL & DBG_CUSTOM)
				lclPrintf_NWK("randomAssociation  %d\n", (uint32_t)randomAssociation);
			#endif
			}
			
		} else {
			// Not got it. Retry!!
			scanForBeacons(lclScanChannels, lclScanduration);
		}
	}
#endif		// #ifndef IM_COORDINATOR


	/*****************************************************************************************************/  
	/**************************************MLME-ASSOCIATE*************************************************/
	/*****************************************************************************************************/ 
	event void MLME_ASSOCIATE.confirm(
				uint16_t assocShortAddress,
				uint8_t status,
				ieee154_security_t *security
			)
	{
#ifndef IM_COORDINATOR

	#ifdef DEBUG_STATUS_MESSAGE
		uint8_t idxParent;
		IEEE154PrintStatus(__LINE__, status);
		
		for (idxParent=0; idxParent<currentStatusIndex; idxParent++)
		{
			lclPrintf_NWK("Association 0x%x\n", addParentStatus[idxParent]);
		}
		memset(addParentStatus, 0, currentStatusIndex*sizeof(ieee154_security_t));
		currentStatusIndex = 0;
	#endif

		if (status == IEEE154_ASSOCIATION_SUCCESSFUL)
		{
			//STOP_RECORD();
			//PRINT_RECORD();
						
			// we are associated with the Parent
			atomic {
				// From now on the device will not be notified anymore of beacons
				// and even parent -> child communication must be enabled
				call MLME_SET.macAutoRequest(TRUE);
				
				associationStatus = ASSOCIATED;
				
				// Set my local address
				call MLME_SET.macShortAddress(assocShortAddress);
				networkaddress = assocShortAddress;
				
				// Set my parent
				//lclPrintf_NWK("Setting parent 0x%x\n", m_PANDescriptor.CoordAddress.shortAddress);
				parent = setParent(parentAssocAddress.shortAddress);
			#if (LOG_LEVEL & ERROR_CONDITIONS)
				if (parent == 0xFF)
				{
					// Device not found in the table
					lclPrintf_NWK("Parent not found in the table\n", "");
				#if (LOG_LEVEL & DBG_NEIGHBOR_TABLE)
					list_neighbourtable();
				#endif
				}
			#endif
				
			}

			call Leds.led0Off();
			call Leds.led1Off();
			
			// Signal the confirmation of the ASSOCIATION/JOIN process
			signal NLME_JOIN.confirm(MAC_PANID, NWK_SUCCESS, parentAssocAddress.shortAddress);
			
		} else {

#if (MAX_ASSOCIATION_TRIALS==0)

			// Retry infinitely after "randomAssociation" beacons
			randomAssociation = (call Random.rand16()) % MAX_RANDOM_BCN_COUNTER;
			// Refresh the association status (might be useless...)
			associationStatus = IM_ASSOCIATING;
		#if (LOG_LEVEL & DBG_CUSTOM)
			lclPrintf_NWK("randomAssociation  %d\n", (uint32_t)randomAssociation);
		#endif

#else
			// Try a finite number of times
			if (maxAssocTrials == 0)
			{
				// Signal join unsuccessfull to upper level
				signal NLME_JOIN.confirm(MAC_PANID, NWK_STARTUP_FAILURE, parentAssocAddress.shortAddress);
				// Reset association trials counter
				maxAssocTrials = MAX_ASSOCIATION_TRIALS;
				// Reset association status
				associationStatus = 0;
			}
			else
			{
				maxAssocTrials--;
				
				// Retry after "randomAssociation" beacons
				randomAssociation = (call Random.rand16()) % MAX_RANDOM_BCN_COUNTER;
				// Refresh the association status (might be useless...)
				associationStatus = IM_ASSOCIATING;
			#if (LOG_LEVEL & DBG_CUSTOM)
				lclPrintf_NWK("randomAssociation  %d\n", (uint32_t)randomAssociation);
			#endif
			}
#endif
			
		}
#endif
	}


	event void MLME_ASSOCIATE.indication(
				uint64_t deviceAddress,
				ieee154_CapabilityInformation_t capabilityInformation,
				ieee154_security_t *security
			)
	{
#ifndef IM_END_DEVICE
		uint8_t cindex = 0xFF;
		ieee154_address_t address;
	#ifdef DEBUG_STATUS_MESSAGE
		//ieee154_status_t status;
	#endif
		atomic
		{
			address.extendedAddress = deviceAddress;
			
			// Check the neighbour table
			cindex = check_neighbortableentry(ADDR_MODE_EXTENDED_ADDRESS, address);

			if( cindex != 0xFF )
			{
			#if (LOG_LEVEL & DBG_CUSTOM)
				lclPrintf_NWK("Device already present. Confirming address: 0x%x\n", neighbortable[cindex].Network_Address);
			#endif
			
				call MLME_ASSOCIATE.response(
							deviceAddress,
							neighbortable[cindex].Network_Address,
							IEEE154_ASSOCIATION_SUCCESSFUL,
							0
						);
						
				return;
			}
			
			if(nwk_IB.nwkAvailableAddresses == 0)
			{
				// If there are no available addresses the coordinator/router 
				// shall not respond to the association request
				call MLME_ASSOCIATE.response(
							deviceAddress,
							0xFFFF,
							IEEE154_PAN_AT_CAPACITY,
							0
						);
						
			#if (LOG_LEVEL & ERROR_CONDITIONS)
				lclPrintf_NWK("nwk_IB.nwkAvailableAddresses = 0\n", "");
			#endif
			
				// Terminate immediately
				return;
			}

			//verify if the device is associating as a router (FFD) or an end device (RFD)
			if ( capabilityInformation.DeviceType == 1 )
			{
				if (number_child_router > 1 + MAXROUTERS)
				{
					// number_child_router starts from 1 instead of 0 due to cskip mechanism
					
					// If there are no available addresses the coordinator/router shall not respond to the association request
					call MLME_ASSOCIATE.response(
								deviceAddress,
								0xFFFF,
								IEEE154_PAN_AT_CAPACITY,
								0
							);
							
				#if (LOG_LEVEL & ERROR_CONDITIONS)
					lclPrintf_NWK("number_child_router (%d) > MAXROUTERS\n",(uint32_t)number_child_router);
				#endif
				
					// Terminate immediately
					return;
				}
				
				//add ROUTER to the neighbour table
			#ifndef DEBUG_STATUS_MESSAGE
				add_neighbortableentry(
								MAC_PANID,
								deviceAddress,
								next_child_router_address,
								ROUTER,
								NEIGHBOR_IS_CHILD,
								FALSE);
			#else
				IEEE154PrintStatus(__LINE__, 
						add_neighbortableentry(
								MAC_PANID,
								deviceAddress,
								next_child_router_address,
								ROUTER,
								NEIGHBOR_IS_CHILD,
								FALSE));
			#endif
	
			#if (LOG_LEVEL & DBG_CUSTOM)
				lclPrintf_NWK("It's a router: sending address: 0x%x\n",next_child_router_address);
			#endif

				//send response, this shall lead to confirm in child device
				call MLME_ASSOCIATE.response(
							deviceAddress,
							next_child_router_address,
							IEEE154_ASSOCIATION_SUCCESSFUL,
							0
						);

				// Compute the next address
				next_child_router_address = networkaddress + ((number_child_router-1) * cskip) +1 ;
				// Increment the number of associated routers
				number_child_router++;
				// Decrese the number of available addresses
				nwk_IB.nwkAvailableAddresses--;
	
				//lclPrintf_NWK("Dn_cr %x\n",next_child_router_address);
				
				// Terminate immediately
				return;
			}
			
			// Verify if its possible to associate children in the address space
			// The number of end devices musts be > to maximum children minus maximum routers
			if (number_child_end_devices > 1 + (MAXCHILDREN - (number_child_router-1)))
			{
				// Both number_child_end_devices and number_child_router start 
				// from 1 instead of 0 due to cskip mechanism
				
				//if there are no available addresses the coordinator/router shall not respond to the association request
				call MLME_ASSOCIATE.response(
							deviceAddress,
							0xFFFF,
							IEEE154_PAN_AT_CAPACITY,
							0
						);
						
				#if (LOG_LEVEL & ERROR_CONDITIONS)
					lclPrintf_NWK("number_child_end_devices (%d) > 1 + (MAXCHILDREN - (number_child_router (%d) - 1))\n",
									(uint32_t)number_child_end_devices, (uint32_t)number_child_router);
				#endif
				
				// Terminate immediately
				return;
			}
			
			//add END_DEVICE to the neighbour table
		#ifndef DEBUG_STATUS_MESSAGE
			add_neighbortableentry(
							MAC_PANID,
							deviceAddress,
							nwk_IB.nwkNextAddress,
							END_DEVICE,
							NEIGHBOR_IS_CHILD,
							FALSE);
		
		#else
			IEEE154PrintStatus(__LINE__, 
					add_neighbortableentry(
							MAC_PANID,
							deviceAddress,
							nwk_IB.nwkNextAddress,
							END_DEVICE,
							NEIGHBOR_IS_CHILD,
							FALSE));
		#endif
		
		#if (LOG_LEVEL & DBG_CUSTOM)
			lclPrintf_NWK("It's an end_device: sending address: 0x%x\n", nwk_IB.nwkNextAddress);
		#endif
			//send response, this shall lead to confirm in child device
			call MLME_ASSOCIATE.response(
						deviceAddress,
						nwk_IB.nwkNextAddress,
						IEEE154_ASSOCIATION_SUCCESSFUL,
						0
					);
	
			// Compute next address
			nwk_IB.nwkNextAddress = nwk_IB.nwkNextAddress + nwk_IB.nwkAddressIncrement;
			// Increment the number of associated end devices
			number_child_end_devices++;
			// Decrese the number of available addresses
			nwk_IB.nwkAvailableAddresses--;
		}
#endif
	}
	
	
	/*****************************************************************************************************/  
	/**************************************MLME-START*****************************************************/
	/*****************************************************************************************************/ 
	event void MLME_START.confirm(ieee154_status_t status)
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf_NWK("MLME_START.confirm.\n", "");
	#endif
	#ifdef DEBUG_STATUS_MESSAGE
		IEEE154PrintStatus(__LINE__, status);
	#endif
	
		if (status != IEEE154_SUCCESS)
			call MLME_RESET.request(TRUE);
		else
		{
#ifdef IM_COORDINATOR
			signal NLME_NETWORK_FORMATION.confirm(status);
#else
#ifdef IM_ROUTER
			if ( (associationStatus & ASSOCIATED) == ASSOCIATED )
				signal NLME_START_ROUTER.confirm(status);
#endif
#endif
		}
	}


#ifdef IM_COORDINATOR
	/*************************************************************/
	/******************NLME - NETWORK - FORMATION*****************/
	/*************************************************************/

	//This primitive allows the NHL to request to start a ZigBee network with itself as the coordinator
	//Page 167-169
	command error_t NLME_NETWORK_FORMATION.request(uint8_t logicalChannel, uint8_t ScanDuration, uint8_t BeaconOrder, uint8_t SuperframeOrder, uint16_t PANId, bool BatteryLifeExtension)
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf_NWK("NLME_NETWORK_FORMATION.request.\n", "");
	#endif

		// COORDINATOR OR ROUTER
		// Reset address assignement variables
		// next child router address
		number_child_router 	= 0x01;
		number_child_end_devices= 0x01;

		//*******************************************************
		//***********SET PAN VARIABLES***************************
		//depth = 0;	// The depth for the coordinator is 0 by default
		nwk_IB.nwkAvailableAddresses	= AVAILABLEADDRESSES;
		nwk_IB.nwkAddressIncrement		= ADDRESSINCREMENT;
	
		nwk_IB.nwkMaxChildren	= MAXCHILDREN;	//number of children a device is allowed to have on its current network
		nwk_IB.nwkMaxDepth		= MAXDEPTH;		//the depth a device can have
		nwk_IB.nwkMaxRouters	= MAXROUTERS;
	
		cskip = Cskip(nwkMyDepth);
		cskip_routing = Cskip(nwkMyDepth - 1);
	
		nwk_IB.nwkNextAddress = networkaddress + (cskip * nwk_IB.nwkMaxRouters) + nwk_IB.nwkAddressIncrement;
		next_child_router_address = networkaddress +((number_child_router-1) * cskip) + 1;
	
		number_child_router++;

		// Start the Coordinator
		call MLME_SET.macShortAddress(0x0000);
		call MLME_SET.macAssociationPermit(TRUE);

	#ifdef DEBUG_STATUS_MESSAGE
		IEEE154PrintStatus(__LINE__, call MLME_START.request(
						PANId,			// PANId
						logicalChannel,	// LogicalChannel
						0,				// ChannelPage,
						0,				// StartTime,
						BeaconOrder,	// BeaconOrder
						SuperframeOrder,// SuperframeOrder
						TRUE,			// PANCoordinator
						FALSE,			// BatteryLifeExtension
						FALSE,			// CoordRealignment
						0,				// CoordRealignSecurity
						0				// BeaconSecurity
					));
	#else
		call MLME_START.request(
				PANId,			// PANId
				logicalChannel,	// LogicalChannel
				0,				// ChannelPage,
				0,				// StartTime,
				BeaconOrder,	// BeaconOrder
				SuperframeOrder,// SuperframeOrder
				TRUE,			// PANCoordinator
				FALSE,			// BatteryLifeExtension
				FALSE,			// CoordRealignment
				0,				// CoordRealignSecurity
				0				// BeaconSecurity
			);
	#endif

		return SUCCESS;
	}
#endif


#ifndef IM_COORDINATOR
	/*************************************************************/
	/***************NLME - NETWORK - DISCOVERY *******************/
	/*************************************************************/

	//This primitive allows the next higher layer to request that the NWK layer discover networks currently operating within the POS.
	//p164 and 210
	command error_t NLME_NETWORK_DISCOVERY.request(uint32_t ScanChannels, uint8_t Scanduration)
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf_NWK("NLME_NETWORK_DISCOVERY.request.\n", "");
	#endif
		
		// Store scan parameters for future retries
		lclScanChannels = ScanChannels;
		lclScanduration = Scanduration;
	
		scanForBeacons(ScanChannels, Scanduration);

		return SUCCESS;
	}
#endif


/** 
 * The MLME-SAP communication status primitive defines how the MLME
 * communicates to the next higher layer about transmission status,
 * when the transmission was INSTIGATED by a RESPONSE PRIMITIVE, and
 * about security errors on incoming packets. (IEEE 802.15.4-2006,
 * Sect. 7.1.12)
 */
// In our case, security is disabled and the only response primitive is issued
// by the MLME_ASSOCIATE interface!!
	event void MLME_COMM_STATUS.indication (
			uint16_t PANId,
			uint8_t SrcAddrMode,
			ieee154_address_t SrcAddr,
			uint8_t DstAddrMode,
			ieee154_address_t DstAddr,
			ieee154_status_t status,
			ieee154_security_t *security
		)
	{
		
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf_NWK("MLME_COMM_STATUS.indication.\n", "");
	#endif
	#ifdef DEBUG_STATUS_MESSAGE
		IEEE154PrintStatus(__LINE__, status);
	#endif
		if (status == IEEE154_SUCCESS){
			call Leds.led0Off();
#ifndef IM_END_DEVICE
			signal NLME_JOIN.indication(0, 0, 0, 0);
#endif
		} else {
			call Leds.led0On();
		}
	}


	/*************************************************************/
	/************************NLME - JOIN**************************/
	/*************************************************************/
	//This primitive allows the NHL to request to join a network through association.
	//p173 and 210
	// Used only if MAX_ASSOCIATION_TRIALS > 0, since the association 
	// request is automatically repeated in case of failure after the scan process
	command error_t NLME_JOIN.request(uint16_t PANId, bool JoinAsRouter, bool RejoinNetwork, uint32_t ScanChannels, uint8_t ScanDuration, uint8_t PowerSource, uint8_t RxOnWhenIdle, uint8_t MACSecurity)
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf_NWK("NLME_JOIN.request.\n", "");
	#endif
#ifndef IM_COORDINATOR
		atomic {
			if ( (associationStatus & ASSOCIATED) != ASSOCIATED )
			{
				// Try or Retry association after "randomAssociation" beacons
				randomAssociation = OFFSET_BCN_COUNTER + ((call Random.rand16()) % MAX_RANDOM_BCN_COUNTER);

				// Refresh the association status (might be useless...)
				associationStatus = IM_ASSOCIATING;
				
			#if (LOG_LEVEL & DBG_CUSTOM)
				lclPrintf_NWK("randomAssociation  %d\n", (uint32_t)randomAssociation);
			#endif
			}
		}
#endif

		return SUCCESS;
	}


	/*************************************************************/
	/*************************NLDE - DATA*************************/
	/*************************************************************/

	//This primitive requests the transfer of a data PDU
	//page 159-161
	command error_t NLDE_DATA.request(uint16_t DstAddr, uint8_t NsduLength, uint8_t Nsdu[120], uint8_t NsduHandle, uint8_t Radius, uint8_t DiscoverRoute, uint8_t SecurityEnable)
	{
		//prefixed size because the devices reset itself when there is an error in the length
		routing_fields *routing_fields_ptr;
		uint8_t m_payloadLen = 0;
		
		// Pointer for using payload for IEEE802.15.4 TKN MAC
		uint8_t *p;
		// Destination Address for IEEE802.15.4 TKN MAC
		ieee154_address_t deviceShortAddress;
		// QoS Required from the packet
		uint8_t MAC_QoS = 0;
		
#ifndef IM_END_DEVICE
		uint8_t next_hop_index;
#endif
	
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf_NWK("NLDE_DATA.request. DstAddr: 0x%x\n", DstAddr);
	#endif
	#if (LOG_LEVEL & DBG_NEIGHBOR_TABLE)
		// Print actual neighbor table
		list_neighbourtable();
	#endif

#ifndef IM_COORDINATOR
		if ( (associationStatus & ASSOCIATED) != ASSOCIATED )
		{
		#if (LOG_LEVEL & ERROR_CONDITIONS)
			lclPrintf_NWK("NLDE_DATA.request - NWK_INVALID_REQUEST\n", "");
		#endif
		
			signal NLDE_DATA.confirm(NsduHandle, NWK_INVALID_REQUEST);
			
			return FAIL;
		}
#endif
		// Create Payload
		m_payloadLen = (NsduLength + sizeof(routing_fields));
		p = call Packet.getPayload(&m_frame, m_payloadLen);
		
		if (p != NULL)	
		{
			atomic 
			{
				// Try to simplify/speed up this process copying directly 
				// into the packet
				routing_fields_ptr = (routing_fields *)p;
				
				routing_fields_ptr->frame_control		= set_route_frame_control(0x00,0x01,DiscoverRoute,SecurityEnable);
				routing_fields_ptr->destination_address	= DstAddr;
				routing_fields_ptr->source_address		= networkaddress;
				routing_fields_ptr->radius				= Radius;
				routing_fields_ptr->sequence_number		= nwk_IB.nwkSequenceNumber;
				nwk_IB.nwkSequenceNumber = (nwk_IB.nwkSequenceNumber+1) % 0xFF;
				
				memcpy(&(p[sizeof(routing_fields)]), Nsdu, NsduLength*sizeof(uint8_t));
			}

		}
		else {
		#if (LOG_LEVEL & ERROR_CONDITIONS)
			// Some feedback on this
			lclPrintf_NWK("NLDE_DATA.request - Packet.getPayload fails\n", "");
		#endif
			return FAIL;
		}

	#if (LOG_LEVEL & DBG_CUSTOM)
		//lclPrintf_NWK("Sending message. Payload lenght: 0x%x\n", m_payloadLen);
		//for (i=0; i<sizeof(routing_fields)+4; i++)
		//	lclPrintf_NWK("MSDU[i]: 0x%x\n", MSDU[i]);

		lclPrintf_NWK("networkaddress: 0x%x\n", networkaddress);
		lclPrintf_NWK("cskip_routing: 0x%x\n", cskip_routing);
		lclPrintf_NWK("routing_fields_ptr->destination_address: 0x%x\n", routing_fields_ptr->destination_address);
	#endif
	
#ifdef IM_END_DEVICE

		// The end device always sends the message to the parent only
		deviceShortAddress.shortAddress = neighbortable[parent].Network_Address; // destination

#else

		// Send message if the device is the COORDINATOR or a ROUTER
		
		if (routing_fields_ptr->destination_address == 0xFFFF)
		{
			// This is a broadcast packet.
			deviceShortAddress.shortAddress = 0xFFFF; // destination
		}
		else if( (networkaddress < routing_fields_ptr->destination_address) && 
			 (routing_fields_ptr->destination_address < (networkaddress + cskip_routing ) ) 
			)
		{
			// Route down to appropriate child
			
			// Temporarily use that variable to store the intended ultimate destination address
			deviceShortAddress.shortAddress = routing_fields_ptr->destination_address;
			// Check if destination is one of my children
			next_hop_index = check_neighbortableentry(ADDR_MODE_SHORT_ADDRESS, deviceShortAddress);

			if (next_hop_index == 0xFF)
			{
				// Destination is not my child
				deviceShortAddress.shortAddress = nexthopaddress(routing_fields_ptr->destination_address, nwkMyDepth);
			}
			else
			{
				// I'm routing to my child
				deviceShortAddress.shortAddress = neighbortable[next_hop_index].Network_Address;
			}

		#if (LOG_LEVEL & DBG_CUSTOM)
			lclPrintf_NWK("Sending data down\n", "");
		#endif
		}
		else
		{
			// Route up to parent
			deviceShortAddress.shortAddress = neighbortable[parent].Network_Address;
		#if (LOG_LEVEL & DBG_CUSTOM)
			lclPrintf_NWK("Sending data up\n", "");
		#endif
		}
		
#endif

	#if (LOG_LEVEL & DBG_CUSTOM)
		lclPrintf_NWK("Sending data to 0x%x\n", deviceShortAddress.shortAddress);
	#endif
		
		// Send Message
		call Frame.setAddressingFields(
				&m_frame,                
				ADDR_MODE_SHORT_ADDRESS,	// SrcAddrMode,
				ADDR_MODE_SHORT_ADDRESS,	// DstAddrMode,
				MAC_PANID,					// DstPANId,
				&deviceShortAddress,		// DstAddr,
				NULL						// security
			);      

#ifdef IM_COORDINATOR
		// The coordinator musts put INDIRECT as a TX option
		MAC_QoS = TX_OPTIONS_INDIRECT;
#endif
		// Request ACK by default. If broadcast packet, then this setting
		// is automathically ignored at the MAC level
		MAC_QoS |= TX_OPTIONS_ACK;
		
	#if (LOG_LEVEL & DBG_CUSTOM)
		lclPrintf_NWK("MAC_QoS 0x%x\n", MAC_QoS);
		lclPrintf_NWK("Sending data to 0x%x\n", deviceShortAddress.shortAddress);
	#endif
	
	
	#ifndef DEBUG_STATUS_MESSAGE
		call MCPS_DATA.request(
				&m_frame,			// msdu,
				m_payloadLen,		// payloadLength,
				NsduHandle,			// msduHandle,
				MAC_QoS				// TxOptions,
			);
	#else
		IEEE154PrintStatus(__LINE__, 
			call MCPS_DATA.request(
				&m_frame,			// msdu,
				m_payloadLen,		// payloadLength,
				NsduHandle,			// msduHandle,
				MAC_QoS				// TxOptions,
			));
	#endif
	
		return SUCCESS;
	}


/*****************************************************************************************************/  
/*****************************************************************************************************/  
/*********************			MCPS EVENTS		**************************************/
/*****************************************************************************************************/ 
/*****************************************************************************************************/  


/*****************************************************************************************************/  
/*********************			MCPS-DATA		**************************************/
/*****************************************************************************************************/ 

	event message_t* MCPS_DATA.indication(message_t* rcvdFrame)
	{
#ifdef IM_ROUTER
		message_t* returnFrame; 
		ieee154_address_t deviceShortAddress;
		uint8_t next_hop_index;
		uint8_t MAC_QoS;
#endif
             
		uint8_t rxPayloadLen = call Frame.getPayloadLength(rcvdFrame);
		uint8_t* rxPayload = call Frame.getPayload(rcvdFrame);
		uint16_t mpduLinkQuality = call Frame.getLinkQuality(rcvdFrame);  
		//uint8_t i = 0;
		
		routing_fields *routing_fields_ptr;
		routing_fields_ptr = (routing_fields *)rxPayload;

	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf_NWK("MCPS_DATA.indication.\n", "");
	#endif
	
		// Safety check on the payload length
		if (rxPayloadLen < sizeof(routing_fields))
		{
		#if (LOG_LEVEL & ERROR_CONDITIONS)
			lclPrintf_NWK("MCPS_DATA.indication %d: Received a bad packet.. discarding it \n", __LINE__);
		#endif
			return rcvdFrame;
		}
	
#ifndef IM_COORDINATOR
		// If the node is not connected to a parent, 
		// discard the packet received
		if ( (associationStatus & ASSOCIATED) != ASSOCIATED )
		{	
		#if (LOG_LEVEL & ERROR_CONDITIONS)
			lclPrintf_NWK("MCPS_DATA.indication %d: Not associated.. discarding packet \n", __LINE__);
		#endif
			return rcvdFrame; 
		}
#endif

		if ( routing_fields_ptr->destination_address == networkaddress || 
			 routing_fields_ptr->destination_address == 0xFFFF )
		{
			uint8_t payload[120];
			
			atomic {
				memset(payload, 0, 120*sizeof(uint8_t));
				
				// I am the final destination or in the "destination (broadcast) group"
			#if (LOG_LEVEL & DBG_CUSTOM)
				lclPrintf_NWK("MCPS_DATA.indication. I am the destination\n", "");
			#endif
				memcpy(payload,&(rxPayload[sizeof(routing_fields)]),(rxPayloadLen-sizeof(routing_fields))*sizeof(uint8_t));
			
				//pass data up to APP layer
				signal NLDE_DATA.indication(routing_fields_ptr->source_address, (uint8_t)(rxPayloadLen-sizeof(routing_fields)), payload, mpduLinkQuality);
			}
		
			return rcvdFrame;
		}
		
		//I am not the destination: must forward this packet
		//lclPrintf_NWK("I am NOT the destination. Packet to forward\n", "");
		
#ifndef IM_ROUTER

	#if (LOG_LEVEL & ERROR_CONDITIONS)
		lclPrintf_NWK("I'm not a router. Check this!!\n", "");
	#endif
		return rcvdFrame;
		
#else
		// The message should be forwarded

		// Since this event handler has to return a frame buffer to the MAC,
		// we don't want to return "receivedFrame", because we will try
		// to forward that. Instead we get an "empty"
		// frame through the PoolC component and return that to the MAC.
		returnFrame = call FramePool.get();
		if (returnFrame == NULL)
		{
		#if (LOG_LEVEL & ERROR_CONDITIONS)
			lclPrintf_NWK("no empty frame left!\n", "");
		#endif
			return rcvdFrame; // no empty frame left!
		}
		
		// Act as usual forwarding the packet along the tree
		if( (networkaddress < routing_fields_ptr->destination_address) && 
			(routing_fields_ptr->destination_address < (networkaddress + cskip_routing ) ) 
		  )
		{
		#if (LOG_LEVEL & DBG_CUSTOM)
			lclPrintf_NWK("route down to appropriate child\n", "");
		#endif
		
			MAC_QoS = TX_OPTIONS_INDIRECT | TX_OPTIONS_ACK;

			// Temporarily use that variable to store the intended ultimate destination address
			deviceShortAddress.shortAddress = (uint16_t)routing_fields_ptr->destination_address;
			//check if destination is one of my children
			next_hop_index = check_neighbortableentry(ADDR_MODE_SHORT_ADDRESS, deviceShortAddress);
			
			if (next_hop_index == 0xFF)
			{
				//destination is not my child
				deviceShortAddress.shortAddress = nexthopaddress(routing_fields_ptr->destination_address, nwkMyDepth);
			}
			else
			{
				//Im routing to my child
				deviceShortAddress.shortAddress = neighbortable[next_hop_index].Network_Address;
			}
		}
		else
		{
			//route up to the parent
		#if (LOG_LEVEL & DBG_CUSTOM)
			lclPrintf_NWK("route up to the parent\n", "");
		#endif
			deviceShortAddress.shortAddress = neighbortable[parent].Network_Address;
			
			MAC_QoS = TX_OPTIONS_ACK;
		}
		
		// to forward the frame we update the addressing part 
		// The payload part remains unchanged
		call Frame.setAddressingFields(
				rcvdFrame,
				ADDR_MODE_SHORT_ADDRESS,	// SrcAddrMode,
				ADDR_MODE_SHORT_ADDRESS,	// DstAddrMode,
				MAC_PANID,					// DstPANId,
				&deviceShortAddress,		// DstAddr,
				NULL						// security
			);

		// Forward the received Message

	#ifndef DEBUG_STATUS_MESSAGE
		call MCPS_DATA.request(
				rcvdFrame,					// msdu,
				rxPayloadLen,				// payloadLength,
				0,							// msduHandle,
				MAC_QoS						// TxOptions
			);
	#else
		IEEE154PrintStatus(__LINE__, 
			call MCPS_DATA.request(
				rcvdFrame,					// msdu,
				rxPayloadLen,				// payloadLength,
				0,							// msduHandle,
				MAC_QoS						// TxOptions
			));
	#endif
	
		// Return the empty frame to the MAC
		return returnFrame;

#endif	// ifndef IM_ROUTER else branch
	}


	event void MCPS_DATA.confirm(
			message_t *msg,
			uint8_t msduHandle,
			ieee154_status_t status,
			uint32_t timestamp
		)
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf_NWK("MCPS_DATA.confirm.\n", "");
	#endif
	#ifdef DEBUG_STATUS_MESSAGE
		IEEE154PrintStatus(__LINE__, status);
	#endif
	
#ifdef IM_ROUTER
		// Since the MCPS_DATA.indication event handler has to return a frame buffer to the MAC
		// we put an "empty" frame through the PoolC component to be used in the MCPS_DATA.indication.
		call FramePool.put(msg);
#endif
		
		signal NLDE_DATA.confirm(msduHandle,status);
	}  



#ifdef IM_ROUTER
	/*************************************************************/
	/*******************NLME - START - ROUTER*********************/
	/*************************************************************/
	//This primitive allows the NHL of a ZigBee Router to initialize or change its superframe configuration.
	//p171 and 210
	command error_t NLME_START_ROUTER.request(uint8_t BeaconOrder, uint8_t SuperframeOrder, bool BatteryLifeExtension,uint32_t StartTime)
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf_NWK("NLME_START_ROUTER.request. StartTime: 0x%x\n", StartTime);
	#endif
		//assign current BO and SO
		beaconorder = BeaconOrder;
		superframeorder = SuperframeOrder;

		// Reset address assignement variables (this is for the beginning
		// or after a beacon loss and restart)
		// next child router address
		number_child_router 	= 0x01;
		number_child_end_devices= 0x01;

		//*******************************************************
		//***********SET PAN VARIABLES***************************
	
		nwk_IB.nwkAvailableAddresses	= AVAILABLEADDRESSES;
		nwk_IB.nwkAddressIncrement		= ADDRESSINCREMENT;
		nwk_IB.nwkMaxChildren			= MAXCHILDREN;	//number of children a device is allowed to have on its current network
		nwk_IB.nwkMaxDepth				= MAXDEPTH;		//the depth a device can have
		nwk_IB.nwkMaxRouters			= MAXROUTERS;
	
		cskip = Cskip(nwkMyDepth);
		cskip_routing = Cskip(nwkMyDepth - 1);
	
		nwk_IB.nwkNextAddress = networkaddress + (cskip * nwk_IB.nwkMaxRouters) + nwk_IB.nwkAddressIncrement;
		next_child_router_address = networkaddress +((number_child_router-1) * cskip) + 1;
		number_child_router++;
	
	#if (LOG_LEVEL & DBG_CUSTOM)
		lclPrintf_NWK("TOS_NODE_ID  %d\n", (uint32_t)TOS_NODE_ID);
		lclPrintf_NWK("nwkMyDepth  %d\n", (uint32_t)nwkMyDepth);
		//lclPrintf_NWK("nwkMyDepth  %d\n", (uint32_t)nwkMyDepth);
		//lclPrintf_NWK("cskip  %d\n", (uint32_t)cskip);
		//lclPrintf_NWK("C %d D %d r %d\n", (uint32_t)MAXCHILDREN, (uint32_t)MAXDEPTH, (uint32_t)MAXROUTERS);
	#endif
		call MLME_SET.macAssociationPermit(TRUE);

	#ifdef DEBUG_STATUS_MESSAGE
		IEEE154PrintStatus(__LINE__, call MLME_START.request(
						MAC_PANID,			// PANId
						LOGICAL_CHANNEL,	// LogicalChannel
						0,					// ChannelPage,
						StartTime,			// StartTime,
						BeaconOrder,		// BeaconOrder
						SuperframeOrder,	// SuperframeOrder
						FALSE,				// PANCoordinator
						FALSE,				// BatteryLifeExtension
						FALSE,				// CoordRealignment
						0,					// CoordRealignSecurity
						0					// BeaconSecurity
					));
	#else
		call MLME_START.request(
				MAC_PANID,			// PANId
				LOGICAL_CHANNEL,	// LogicalChannel
				0,					// ChannelPage,
				StartTime,			// StartTime,
				BeaconOrder,		// BeaconOrder
				SuperframeOrder,	// SuperframeOrder
				FALSE,				// PANCoordinator
				FALSE,				// BatteryLifeExtension
				FALSE,				// CoordRealignment
				0,					// CoordRealignSecurity
				0					// BeaconSecurity
			);
	#endif

		return SUCCESS;
	}
#endif


	/*****************************************************************************************************/  
	/**************************************MLME-SYNC-LOSS*************************************************/
	/*****************************************************************************************************/ 
	event void MLME_SYNC_LOSS.indication(
			ieee154_status_t lossReason,
			uint16_t PANId, 
			uint8_t LogicalChannel, 
			uint8_t ChannelPage, 
			ieee154_security_t *security
		)
	{
#ifndef IM_COORDINATOR

	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf_NWK("MLME_SYNC_LOSS.indication.\n", "");
	#endif
	#ifdef DEBUG_STATUS_MESSAGE
		IEEE154PrintStatus(__LINE__, lossReason);
	#endif
	
	#ifdef IM_ROUTER
		// We have lost track of our Parent's beacons :(
		// We stop sending our own beacons, until we have synchronized with
		// the Parent again.
		if (lossReason == IEEE154_BEACON_LOSS) 
		{
			call Leds.led2Off();
			// Reset the sending beacons
			call MLME_START.request(
					MAC_PANID,			// PANId
					LOGICAL_CHANNEL,	// LogicalChannel
					0,					// ChannelPage,
					0,					// StartTime,
					15,					// BeaconOrder
					15,					// SuperframeOrder
					FALSE,				// PANCoordinator
					FALSE,				// BatteryLifeExtension
					FALSE,				// CoordRealignment
					0,					// CoordRealignSecurity
					0					// BeaconSecurity
				);
		}
		
		// Block temporarily the association 
		// mechanism from other nodes
		call MLME_SET.macAssociationPermit(FALSE);
		
	#endif

		// Remove the current parent from the neighbor table
		parent = deleteParent(parent);
		
		// Signal this to the Adaptation Layer to be instructed that 
		// a new association is necessary and send again position info
		signal NLME_SYNC.indication();
		
		// If the sync loss is *not* on purpose ...
		if ( (associationStatus & DISASSOCIATED) != DISASSOCIATED)
		{
			// ... restart automatically from the scan channels
			scanForBeacons(lclScanChannels, lclScanduration);
		}

#endif	// #ifndef IM_COORDINATOR
	}



#ifndef IM_COORDINATOR 
	task void tryDisassociation()
	{
		call MLME_DISASSOCIATE.request  (
							  ADDR_MODE_SHORT_ADDRESS,
							  MAC_PANID,
							  parentAssocAddress,
							  IEEE154_DEVICE_WISHES_TO_LEAVE,
							  1,
							  0);
	}
#endif

/*************************************************************/
/************************NLME - LEAVE*************************/
/*************************************************************/
	//This primitive allows the NWK to request that it or another device leaves the network
	//page 181-183
	command error_t NLME_LEAVE.request(uint64_t extDeviceAddress, bool RemoveChildren, bool MACSecurityEnable)
	{
#ifndef IM_COORDINATOR
		if (!RemoveChildren)
			post tryDisassociation();
#endif

		return SUCCESS;
	}


/*****************************************************************************************************/  
/**************************************MLME-DISASSOCIATE**********************************************/
/*****************************************************************************************************/ 
	event void MLME_DISASSOCIATE.confirm (
			ieee154_status_t status,
			uint8_t DeviceAddrMode,
			uint16_t DevicePANID,
			ieee154_address_t DeviceAddress
		)
	{
		uint64_t address;
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf_NWK("MLME_DISASSOCIATE.confirm.\n", "");
	#endif
	#ifdef DEBUG_STATUS_MESSAGE
		IEEE154PrintStatus(__LINE__, status);
	#endif
		
		switch (DeviceAddrMode)
		{
		case ADDR_MODE_SHORT_ADDRESS:
			address = (uint64_t)(DeviceAddress.shortAddress);
			break;
			
		case ADDR_MODE_EXTENDED_ADDRESS:
			address = DeviceAddress.extendedAddress;
			break;
			
		default:
			// Something strange happens
		#if (LOG_LEVEL & ERROR_CONDITIONS)
			lclPrintf_NWK("MLME_DISASSOCIATE.confirm. DeviceAddrMode (0x%x) not recognized\n", DeviceAddrMode);
		#endif
			break;
		}
		
		if (status == IEEE154_SUCCESS)
		{
#ifndef IM_COORDINATOR
			// Association status variable set to disassociate to prevent
			// a new automatic association tentative after the sync loss event
			associationStatus = DISASSOCIATED;
#endif
			signal NLME_LEAVE.confirm(address, NWK_SUCCESS);
		} else {
			signal NLME_LEAVE.confirm(address, NWK_LEAVE_UNCONFIRMED);
		}
	}

	event void MLME_DISASSOCIATE.indication (
			uint64_t DeviceAddress,
			ieee154_disassociation_reason_t DisassociateReason,
			ieee154_security_t *security
		)
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		switch (DisassociateReason)
		{
		case IEEE154_COORDINATOR_WISHES_DEVICE_TO_LEAVE:
			lclPrintf_NWK("MLME_DISASSOCIATE.indication. IEEE154_COORDINATOR_WISHES_DEVICE_TO_LEAVE\n", "");
			break;
		case IEEE154_DEVICE_WISHES_TO_LEAVE:
			lclPrintf_NWK("MLME_DISASSOCIATE.indication. IEEE154_DEVICE_WISHES_TO_LEAVE\n", "");
			break;
		}
	#endif
		
#ifndef IM_COORDINATOR
		if (DisassociateReason == IEEE154_COORDINATOR_WISHES_DEVICE_TO_LEAVE)
		{
			// Association status variable set to disassociate to prevent
			// a new automatic association tentative after the sync loss event
			associationStatus = DISASSOCIATED;
		}
#endif

		signal NLME_LEAVE.indication(DeviceAddress);
	}




/*************************************************************/
/*******************NLME IMPLEMENTATION***********************/
/*************************************************************/


/*************************************************************
******************* NLME-RESET********************************
**************************************************************/
	command error_t NLME_RESET.request()
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf_NWK("NLME_RESET.request.\n", "");
	#endif
		call MLME_RESET.request(TRUE);
		return SUCCESS;
	}

/*************************************************************/
/************************NLME - SYNC**************************/
/*************************************************************/
	//This primitive allows the NHL to synchronize or extract data from its ZigBee coordinator or router
	//page 186-187
	command error_t NLME_SYNC.request(bool Track)
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf_NWK("NLME_SYNC.request. Track: 0x%x\n", Track);
	#endif
		call MLME_SYNC.request(LOGICAL_CHANNEL, 0, Track);

		return SUCCESS;
	}



  
/*************************************************************/
/*****************        NLME-SET     ********************/
/*************************************************************/
	
	command error_t NLME_SET.request(uint8_t NIBAttribute, uint16_t NIBAttributeLength, uint16_t NIBAttributeValue)
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf_NWK("NLME_SET.request. NIBAttribute: 0x%x\n", NIBAttribute);
	#endif
		atomic{
			switch(NIBAttribute)
			{
				case NWKSEQUENCENUMBER :
					nwk_IB.nwkSequenceNumber = (uint8_t) NIBAttributeValue;
					//////lclPrintf_NWK("nwk_IB.nwkSequenceNumber: %x\n",nwk_IB.nwkSequenceNumber);
					signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
					break;

				case NWKPASSIVEACKTIMEOUT :
					nwk_IB.nwkPassiveAckTimeout = (uint8_t) NIBAttributeValue;
					//////lclPrintf_NWK("nwk_IB.nwkPassiveAckTimeout: %x\n",nwk_IB.nwkPassiveAckTimeout);
					signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
				break;

				case NWKMAXBROADCASTRETRIES :
					nwk_IB.nwkMaxBroadcastRetries = (uint8_t) NIBAttributeValue;
					//////lclPrintf_NWK("nwk_IB.nwkMaxBroadcastRetries: %x\n",nwk_IB.nwkMaxBroadcastRetries);
					signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
					break;

				case NWKMAXCHILDREN :
					nwk_IB.nwkMaxChildren = (uint8_t) NIBAttributeValue;
					//////lclPrintf_NWK("nwk_IB.nwkMaxChildren: %x\n",nwk_IB.nwkMaxChildren);
					signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
					break;

				case NWKMAXDEPTH :
					nwk_IB.nwkMaxDepth = (uint8_t) NIBAttributeValue;
					//////lclPrintf_NWK("nwk_IB.nwkMaxDepth: %x\n",nwk_IB.nwkMaxDepth);
					signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
					break;

				case NWKMAXROUTERS :
					nwk_IB.nwkMaxRouters = (uint8_t) NIBAttributeValue;
					//////lclPrintf_NWK("nwk_IB.nwkMaxRouters: %x\n",nwk_IB.nwkMaxRouters);
					signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
					break;

				case NWKMETWORKBROADCASTDELIVERYTIME :
					nwk_IB.nwkNetworkBroadcastDeliveryTime = (uint8_t) NIBAttributeValue;
					//////lclPrintf_NWK("nwk_IB.nwkNetworkBroadcastDeliveryTime: %x\n",nwk_IB.nwkNetworkBroadcastDeliveryTime);
					signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
					break;
					
				case NWKREPORTCONSTANTCOST :
					nwk_IB.nwkReportConstantCost = (uint8_t) NIBAttributeValue;
					//////lclPrintf_NWK("nwk_IB.nwkReportConstantCost: %x\n",nwk_IB.nwkReportConstantCost);
					signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
					break;
					
				case NWKROUTEDISCOVERYRETRIESPERMITED :
					nwk_IB.nwkRouteDiscoveryRetriesPermitted = (uint8_t) NIBAttributeValue;
					//////lclPrintf_NWK("nwk_IB.nwkRouteDiscoveryRetriesPermitted: %x\n",nwk_IB.nwkRouteDiscoveryRetriesPermitted);
					signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
					break;

				case NWKSYMLINK :
					nwk_IB.nwkSymLink = (uint8_t) NIBAttributeValue;
					//////lclPrintf_NWK("nwk_IB.nwkSymLink: %x\n",nwk_IB.nwkSymLink);
					signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
					break;

				case NWKCAPABILITYINFORMATION :
					nwk_IB.nwkCapabilityInformation = (uint8_t) NIBAttributeValue;
					//////lclPrintf_NWK("nwk_IB.nwkCapabilityInformation: %x\n",nwk_IB.nwkCapabilityInformation);
					signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
					break;

				case NWKUSETREEADDRALLOC :
					nwk_IB.nwkUseTreeAddrAlloc = (uint8_t) NIBAttributeValue;
					//////lclPrintf_NWK("nwk_IB.nwkUseTreeAddrAlloc: %x\n",nwk_IB.nwkUseTreeAddrAlloc);
					signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
					break;

				case NWKUSETREEROUTING :
					nwk_IB.nwkUseTreeRouting = (uint8_t) NIBAttributeValue;
					//////lclPrintf_NWK("nwk_IB.nwkUseTreeRouting: %x\n",nwk_IB.nwkUseTreeRouting);
					signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
					break;

				case NWKNEXTADDRESS :
					nwk_IB.nwkNextAddress = NIBAttributeValue;
					//////lclPrintf_NWK("nwk_IB.nwkNextAddress: %x\n",nwk_IB.nwkNextAddress);
					signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
					break;

				case NWKAVAILABLEADDRESSES :
					nwk_IB.nwkAvailableAddresses = NIBAttributeValue;
					//////lclPrintf_NWK("nwk_IB.nwkAvailableAddresses: %x\n",nwk_IB.nwkAvailableAddresses);
					signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
					break;

				case NWKADDRESSINCREMENT :
					nwk_IB.nwkAddressIncrement =NIBAttributeValue;
					//////lclPrintf_NWK("nwk_IB.nwkAddressIncrement: %x\n",nwk_IB.nwkAddressIncrement);
					signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
					break;

				case NWKTRANSACTIONPERSISTENCETIME :
					nwk_IB.nwkTransactionPersistenceTime = (uint8_t) NIBAttributeValue;
					//////lclPrintf_NWK("nwk_IB.nwkTransactionPersistenceTime: %x\n",nwk_IB.nwkTransactionPersistenceTime);
					signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
					break;

				default:
					signal NLME_SET.confirm(NWK_UNSUPPORTED_ATTRIBUTE,NIBAttribute);
					break;
			}
		}

		return SUCCESS;
	}


/*************************************************************/
/*****************        NLME-GET     ********************/
/*************************************************************/
	
	command error_t NLME_GET.request(uint8_t NIBAttribute)
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf_NWK("NLME_GET.request. NIBAttribute: 0x%x\n", NIBAttribute);
	#endif
		switch(NIBAttribute)
		{
			case NWKSEQUENCENUMBER :
				signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkSequenceNumber);
				break;

			case NWKPASSIVEACKTIMEOUT :
				signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkPassiveAckTimeout);
				break;

			case NWKMAXBROADCASTRETRIES :
				signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkMaxBroadcastRetries);
				break;

			case NWKMAXCHILDREN :
				signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkMaxChildren);
				break;

			case NWKMAXDEPTH :
				signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkMaxDepth);
				break;

			case NWKMAXROUTERS :
				signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkMaxRouters);
				break;

			case NWKMETWORKBROADCASTDELIVERYTIME :
				signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkNetworkBroadcastDeliveryTime);
				break;

			case NWKREPORTCONSTANTCOST :
				signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkReportConstantCost);
				break;

			case NWKROUTEDISCOVERYRETRIESPERMITED :
				signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkRouteDiscoveryRetriesPermitted);
				break;

			case NWKSYMLINK :
				signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkSymLink);
				break;

			case NWKCAPABILITYINFORMATION :
				signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkCapabilityInformation);
				break;

			case NWKUSETREEADDRALLOC :
				signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkUseTreeAddrAlloc);
				break;

			case NWKUSETREEROUTING :
				signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkUseTreeRouting);
				break;

			case NWKNEXTADDRESS :
				signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0002,(uint16_t)&nwk_IB.nwkNextAddress);
				break;

			case NWKAVAILABLEADDRESSES :
				signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0002,(uint16_t)&nwk_IB.nwkAvailableAddresses);
				break;

			case NWKADDRESSINCREMENT :
				signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0002,(uint16_t)&nwk_IB.nwkAddressIncrement);
				break;

			case NWKTRANSACTIONPERSISTENCETIME :
				signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkTransactionPersistenceTime);
				break;

			default:
				signal NLME_GET.confirm(NWK_UNSUPPORTED_ATTRIBUTE,NIBAttribute,0x0000,0x00);
				break;
		}
	
		return SUCCESS;
	}


/*************************************************************/
/**************neighbor table management functions************/
/*************************************************************/

//check if a specific neighbourtable Entry is present
//Return 0xFF:	Entry is not present
//Return i:		Entry is present and return its index
	uint8_t check_neighbortableentry(uint8_t addrmode, ieee154_address_t address)
	{	
		uint8_t idx = 0;
		
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf_NWK("check_neighbortableentry. neighbour_count: 0x%x\n", neighbour_count);
	#endif
		if (neighbour_count == 0)
		{
			//lclPrintf_NWK("no neigb\n", "");
			return 0xFF;
		}
		
		switch (addrmode)
		{
		case ADDR_MODE_SHORT_ADDRESS:
			while (idx < NEIGHBOUR_TABLE_SIZE)
			{
				//lclPrintf_NWK("compare %x %x\n", neighbortable[idx].Network_Address, address.shortAddress);
				if( (neighbortable[idx].PAN_Id != 0) && 
					(neighbortable[idx].Network_Address == address.shortAddress)
				 )
				{
					//lclPrintf_NWK("already present \n", "" );
					return idx;
				}
				idx++;
			}
			break;
		
		case ADDR_MODE_EXTENDED_ADDRESS:
			while (idx < NEIGHBOUR_TABLE_SIZE)
			{	
				//lclPrintf_NWK("compare %x %x\n", neighbortable[idx].Extended_Address, address.extendedAddress);
				if( (neighbortable[idx].PAN_Id != 0) && 
					(neighbortable[idx].Extended_Address == address.extendedAddress)
				 )
				{
					//lclPrintf_NWK("already present \n", "" );
					return idx;
				}
				idx++;
			}
			break;
		
		default:
			return 0xFF;
		}
		
		return 0xFF;
	}
	
#if 0
	//function used to find a parent in the neighbour table
	//Return 0:no parent is present
	//Return i:parent is present and return the index of the entry + 1
	uint8_t find_suitable_parent()
	{
		uint8_t i = 0;
		
	#ifdef TRACE_FUNC_ENABLED
		lclPrintf_NWK("find_suitable_parent. neighbour_count: 0x%x\n", neighbour_count);
	#endif
	
		for (i=0; i<NEIGHBOUR_TABLE_SIZE; i++)
		{
			if(neighbortable[i].Relationship == NEIGHBOR_IS_PARENT)
			{
				return i+1;
			}
		}
		return 0;
	}
#endif

	// Add a neighbortable entry in the first free slot and update the
	// actual number of neighbors.
	// Return:	
	//	IEEE154_SUCCESS if the neighbor has been added
	//	IEEE154_LIMIT_REACHED if the table was full, so the neighbor has not been added
	//	IEEE154_INVALID_PARAMETER if the entry is already present in the table
	ieee154_status_t add_neighbortableentry(uint16_t PAN_Id,uint64_t Extended_Address,uint16_t Network_Address,uint8_t Device_Type,uint8_t Relationship, bool force)
	{
		//bool isPresent = FALSE;
		bool slotFound = FALSE;
		//uint8_t i;
		uint8_t firstFreeSlot;
		ieee154_address_t address;

		atomic
		{
			address.extendedAddress = Extended_Address;

			if (0xFF != check_neighbortableentry(ADDR_MODE_EXTENDED_ADDRESS, address))
				// The entry is already present in the table
				return IEEE154_INVALID_PARAMETER;
			
			// It is not present
			
			// Search for the first free slot in the table
			for (firstFreeSlot = 0; firstFreeSlot < NEIGHBOUR_TABLE_SIZE; firstFreeSlot++)
			{
				if (neighbortable[firstFreeSlot].PAN_Id == 0)
				{
					slotFound = TRUE;
					break;
				}
			}

			if (slotFound)
			{
				neighbortable[firstFreeSlot].PAN_Id				= PAN_Id;
				neighbortable[firstFreeSlot].Extended_Address	= Extended_Address;
				neighbortable[firstFreeSlot].Network_Address	= Network_Address;
				neighbortable[firstFreeSlot].Device_Type		= Device_Type;
				neighbortable[firstFreeSlot].Relationship		= Relationship;
			
				neighbour_count++;
				
				return IEEE154_SUCCESS;
			}
			else
			{
				if (force == TRUE)
				{
					// Overwrite by default the row 0 in the neighbor table
					neighbortable[0].PAN_Id				= PAN_Id;
					neighbortable[0].Extended_Address	= Extended_Address;
					neighbortable[0].Network_Address	= Network_Address;
					neighbortable[0].Device_Type		= Device_Type;
					neighbortable[0].Relationship		= Relationship;
					
					return IEEE154_SUCCESS;
				}

				return IEEE154_LIMIT_REACHED;
			}
		}
	}

	
	//update a neighbourtable entry
	void update_neighbortableentry(uint16_t PAN_Id,uint64_t Extended_Address,uint16_t Network_Address,uint8_t Device_Type,uint8_t Relationship)
	{
		//search entry with correct extended address
		uint8_t nrofEntry = 0xFF;
		ieee154_address_t address;
		
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf_NWK("update_neighbortableentry. neighbour_count: 0x%x\n", neighbour_count);
	#endif
		atomic {
			address.extendedAddress = Extended_Address;
			nrofEntry = check_neighbortableentry(ADDR_MODE_EXTENDED_ADDRESS, address);
			
			if (nrofEntry != 0xFF)
			{
				//update every attribute
				neighbortable[nrofEntry].PAN_Id				= PAN_Id;
				neighbortable[nrofEntry].Extended_Address	= Extended_Address;
				neighbortable[nrofEntry].Network_Address	= Network_Address;
				neighbortable[nrofEntry].Device_Type		= Device_Type;
				neighbortable[nrofEntry].Relationship		= Relationship;
				
				//lclPrintf_NWK("updated neighbourtable entry\n", "");
			}
		#if (LOG_LEVEL & ERROR_CONDITIONS)
			else
			{
				lclPrintf_NWK("update_neighbortableentry. Extended_Address 0x%x Not found\n", Extended_Address);
			}
		#endif
		}
	}
	
	// This function searches for device in the neighbor table and, if it 
	// is present, updates it as NEIGHBOR_IS_PARENT and return index,
	// otherwise return 0xFF indicating that the device has not been found
	uint8_t setParent(uint16_t shortAddress)
	{
		uint8_t nrofEntry;
		ieee154_address_t address;
		address.shortAddress = shortAddress;
		
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf_NWK("setParent. shortAddress: 0x%x\n", shortAddress);
	#endif

		atomic {
			// First check if this neighbor is present
			nrofEntry = check_neighbortableentry(ADDR_MODE_SHORT_ADDRESS, address);
			
			if (nrofEntry == 0xFF)	// Conventional Error
				return nrofEntry;
			
			if (neighbortable[nrofEntry].Relationship == NEIGHBOR_IS_ALT_PARENT)
			{
				neighbortable[nrofEntry].Relationship = NEIGHBOR_IS_PARENT;
				return nrofEntry;
			}
			return 0xFF;	// Conventional Error
		}
	}
	
	uint8_t deleteParent(uint8_t idxParent)
	{
		atomic {
			// If there is a parent, delete it
			if (idxParent != 0xFF)
			{
				// Reset the PANID field of that entry, so "releasing" the slot
				neighbortable[idxParent].PAN_Id	= 0;
				
				// Decrement the number of currently available neighbors
				neighbour_count--;
			}
		}
		return 0xFF;		// Conventional value to indicate error
	}


#if (LOG_LEVEL & DBG_NEIGHBOR_TABLE)
	void list_neighbourtable()
	{
		uint8_t i;

		lclPrintf_NWK("N List Count: %d\n", (uint32_t)neighbour_count);
		lclPrintf_NWK("parent idx is: %d\n", (uint32_t)parent);
	
		for(i=0; i<NEIGHBOUR_TABLE_SIZE; i++)
		{
			if (neighbortable[i].PAN_Id != 0)
			{
				lclPrintf_NWK("Panid 0x%x; ",	neighbortable[i].PAN_Id);
				lclPrintf_NWK("Extaddr 0x%x; ",	neighbortable[i].Extended_Address);
				lclPrintf_NWK("nwkaddr 0x%x; ",	neighbortable[i].Network_Address);
				lclPrintf_NWK("devtype %u; ",	(uint32_t)neighbortable[i].Device_Type);
				lclPrintf_NWK("relation %u\n",	(uint32_t)neighbortable[i].Relationship);
			}
		}
	}
#endif

/*************************************************************/
/*****************Address Assignment functions****************/
/*************************************************************/

	//calculate the size of the address sub-block for a router at depth d
	uint16_t Cskip(int8_t d)
	{	
		int16_t skip;
		int16_t x = 1;
		int16_t i;
		int16_t Cm = nwk_IB.nwkMaxChildren;
		int16_t Rm = nwk_IB.nwkMaxRouters;
		int16_t Lm = nwk_IB.nwkMaxDepth;

		atomic {
			if (Rm == 1)
				skip = 1 + Cm * (Lm - d - 1);
			else
			{	
				for (i=0; i<(Lm - d - 1); i++)
					x *= Rm;

				skip = (1 + Cm - Rm - (Cm * x))/(1-Rm);
			}
		}
		
		return (uint16_t)skip;
	}

	//Calculate the nexthopaddress of the appropriate child if route down is required
	uint16_t nexthopaddress(uint16_t destinationaddress, uint8_t d)
	{
		return ( (networkaddress + 1 + (int16_t)((destinationaddress-(networkaddress+1))/Cskip(d)) * Cskip(d)) );
	}

/*************************************************************/
/*****************Initialization functions********************/
/*************************************************************/
	//initialization of the nwk IB
	void init_nwkIB()
	{	
		//nwk IB default values p 204-206
		nwk_IB.nwkPassiveAckTimeout		=	0x03;
		nwk_IB.nwkMaxBroadcastRetries	=	0x03;
		nwk_IB.nwkMaxChildren			=	MAXCHILDREN;	//number of children a device is allowed to have on its current network
		nwk_IB.nwkMaxDepth				=	MAXDEPTH;		//the depth a device can have
		nwk_IB.nwkMaxRouters			=	MAXROUTERS;		//number of routers any device is allowed to have on its current network
		//neighbortableentry nwkNeighborTable[];//null set
		nwk_IB.nwkNetworkBroadcastDeliveryTime	=	( nwk_IB.nwkPassiveAckTimeout * nwk_IB.nwkMaxBroadcastRetries );
		nwk_IB.nwkReportConstantCost			=	0x00;
		nwk_IB.nwkRouteDiscoveryRetriesPermitted=	nwkcDiscoveryRetryLimit;
		//set nwkRouteTable;//Null set
		nwk_IB.nwkSymLink				=	0;
		nwk_IB.nwkCapabilityInformation	=	0x00;
		nwk_IB.nwkUseTreeAddrAlloc		=	1;
		nwk_IB.nwkUseTreeRouting		=	1;
		nwk_IB.nwkNextAddress			=	0x0000;
		nwk_IB.nwkAvailableAddresses	=	0x0000;
		nwk_IB.nwkAddressIncrement		=	0x0001;
		nwk_IB.nwkTransactionPersistenceTime	=	0x01f4;
	}

	// ******************************************************************************* //
	// ************************* 802.15.4 MAC remaining events *********************** //
	// ******************************************************************************* //
#ifndef IM_END_DEVICE
	event void IEEE154TxBeaconPayload.aboutToTransmit()
	{
		if (flgSetBeaconPay == TRUE)
		{
			beaconPay_t bcnPay;
		#if (LOG_LEVEL & TRACE_FUNC)
			lclPrintf_NWK("IEEE154TxBeaconPayload.aboutToTransmit.\n", "");
		#endif
			// Prepare Beacon Payload
			bcnPay.tosAddress = (uint16_t)TOS_NODE_ID;
			bcnPay.depth = (uint16_t)nwkMyDepth;

		#ifdef DEBUG_STATUS_MESSAGE
			IEEE154PrintStatus(__LINE__, call IEEE154TxBeaconPayload.setBeaconPayload(&bcnPay, sizeof(beaconPay_t)));
		#else
			call IEEE154TxBeaconPayload.setBeaconPayload(&bcnPay, sizeof(beaconPay_t));
		#endif
		}
	}

	event void IEEE154TxBeaconPayload.setBeaconPayloadDone(void *beaconPayload, uint8_t length) 
	{
		if (flgSetBeaconPay == TRUE)
			flgSetBeaconPay = FALSE;
	}

	event void IEEE154TxBeaconPayload.modifyBeaconPayloadDone(uint8_t offset, void *buffer, uint8_t bufferLength) { }

	event void IEEE154TxBeaconPayload.beaconTransmitted() 
	{
		call Leds.led2Toggle();
	}  
#endif

#ifdef DEBUG_STATUS_MESSAGE
	void TinyErrorPrintStatus(uint8_t status)
	{
		switch (status)
		{
		case FAIL:
			{lclPrintf_NWK("Status: 0x%x, Fail Generic condition\n", status);}
			break;
		case ESIZE:
			{lclPrintf_NWK("Status: 0x%x, Parameter passed in was too big\n", status);}
			break;
		case ECANCEL:
			{lclPrintf_NWK("Status: 0x%x, Operation cancelled by a call\n", status);}
			break;
		case EOFF:
			{lclPrintf_NWK("Status: 0x%x, Subsystem is not active\n", status);}
			break;
		case EBUSY:
			{lclPrintf_NWK("Status: 0x%x, The underlying system is busy; retry later\n", status);}
			break;
		case EINVAL:
			{lclPrintf_NWK("Status: 0x%x, An invalid parameter was passed\n", status);}
			break;
		case ERETRY:
			{lclPrintf_NWK("Status: 0x%x, A rare and transient failure: can retry\n", status);}
			break;
		case ERESERVE:
			{lclPrintf_NWK("Status: 0x%x, Reservation required before usage\n", status);}
			break;
		case EALREADY:
			{lclPrintf_NWK("Status: 0x%x, The device state you are requesting is already set\n", status);}
			break;
		case ENOMEM:
			{lclPrintf_NWK("Status: 0x%x, Memory required not available\n", status);}
			break;
		case ENOACK:
			{lclPrintf_NWK("Status: 0x%x, A packet was not acknowledged\n", status);}
			break;
		default:
			{lclPrintf_NWK("Status: 0x%x, Unknown\n", status);}
		}
	}
  
	void IEEE154PrintStatus(uint16_t lineno, ieee154_status_t status)
	{
	#if (LOG_LEVEL & DEBUG_STATUS)
		if (status != IEEE154_SUCCESS)
		{
			lclPrintf_NWK("NWKP.nc, Line %d - ", (uint32_t)lineno);
		}
		
		switch (status)
		{
		case IEEE154_SUCCESS:
			break;
		case IEEE154_BEACON_LOSS:
			{lclPrintf_NWK("Status: 0x%x, BEACON_LOSS\n", status);}
			break;
		case IEEE154_CHANNEL_ACCESS_FAILURE:
			{lclPrintf_NWK("Status: 0x%x, CHANNEL_ACCESS_FAILURE\n", status);}
			break;
		case IEEE154_COUNTER_ERROR:
			{lclPrintf_NWK("Status: 0x%x, COUNTER_ERROR\n", status);}
			break;
		case IEEE154_DENIED:
			{lclPrintf_NWK("Status: 0x%x, DENIED\n", status);}
			break;
		case IEEE154_DISABLE_TRX_FAILURE:
			{lclPrintf_NWK("Status: 0x%x, DISABLE_TRX_FAILURE\n", status);}
			break;
		case IEEE154_FRAME_TOO_LONG:
			{lclPrintf_NWK("Status: 0x%x, FRAME_TOO_LONG\n", status);}
			break;
		case IEEE154_IMPROPER_KEY_TYPE:
			{lclPrintf_NWK("Status: 0x%x, IMPROPER_KEY_TYPE\n", status);}
			break;
		case IEEE154_IMPROPER_SECURITY_LEVEL:
			{lclPrintf_NWK("Status: 0x%x, IMPROPER_SECURITY_LEVEL\n", status);}
			break;
		case IEEE154_INVALID_ADDRESS:
			{lclPrintf_NWK("Status: 0x%x, INVALID_ADDRESS\n", status);}
			break;
		case IEEE154_INVALID_GTS:
			{lclPrintf_NWK("Status: 0x%x, INVALID_GTS\n", status);}
			break;
		case IEEE154_INVALID_HANDLE:
			{lclPrintf_NWK("Status: 0x%x, INVALID_HANDLE\n", status);}
			break;
		case IEEE154_INVALID_INDEX:
			{lclPrintf_NWK("Status: 0x%x, INVALID_INDEX\n", status);}
			break;
		case IEEE154_INVALID_PARAMETER:
			{lclPrintf_NWK("Status: 0x%x, INVALID_PARAMETER\n", status);}
			break;
		case IEEE154_LIMIT_REACHED:
			{lclPrintf_NWK("Status: 0x%x, LIMIT_REACHED\n", status);}
			break;
		case IEEE154_NO_ACK:
			{lclPrintf_NWK("Status: 0x%x, NO_ACK\n", status);}
			break;
		case IEEE154_NO_BEACON:
			{lclPrintf_NWK("Status: 0x%x, NO_BEACON\n", status);}
			break;
		case IEEE154_NO_DATA:
			{lclPrintf_NWK("Status: 0x%x, NO_DATA\n", status);}
			break;
		case IEEE154_NO_SHORT_ADDRESS:
			{lclPrintf_NWK("Status: 0x%x, NO_SHORT_ADDRESS\n", status);}
			break;
		case IEEE154_ON_TIME_TOO_LONG:
			{lclPrintf_NWK("Status: 0x%x, ON_TIME_TOO_LONG\n", status);}
			break;
		case IEEE154_OUT_OF_CAP:
			{lclPrintf_NWK("Status: 0x%x, OUT_OF_CAP\n", status);}
			break;
		case IEEE154_PAN_ID_CONFLICT:
			{lclPrintf_NWK("Status: 0x%x, PAN_ID_CONFLICT\n", status);}
			break;
		case IEEE154_PAST_TIME:
			{lclPrintf_NWK("Status: 0x%x, PAST_TIME\n", status);}
			break;
		case IEEE154_READ_ONLY:
			{lclPrintf_NWK("Status: 0x%x, READ_ONLY\n", status);}
			break;
		case IEEE154_REALIGNMENT:
			{lclPrintf_NWK("Status: 0x%x, REALIGNMENT\n", status);}
			break;
		case IEEE154_SCAN_IN_PROGRESS:
			{lclPrintf_NWK("Status: 0x%x, SCAN_IN_PROGRESS\n", status);}
			break;
		case IEEE154_SECURITY_ERROR:
			{lclPrintf_NWK("Status: 0x%x, SECURITY_ERROR\n", status);}
			break;
		case IEEE154_SUPERFRAME_OVERLAP:
			{lclPrintf_NWK("Status: 0x%x, SUPERFRAME_OVERLAP\n", status);}
			break;
		case IEEE154_TRACKING_OFF:
			{lclPrintf_NWK("Status: 0x%x, TRACKING_OFF\n", status);}
			break;
		case IEEE154_TRANSACTION_EXPIRED:
			{lclPrintf_NWK("Status: 0x%x, TRANSACTION_EXPIRED\n", status);}
			break;
		case IEEE154_TRANSACTION_OVERFLOW:
			{lclPrintf_NWK("Status: 0x%x, TRANSACTION_OVERFLOW\n", status);}
			break;
		case IEEE154_TX_ACTIVE:
			{lclPrintf_NWK("Status: 0x%x, TX_ACTIVE\n", status);}
			break;
		case IEEE154_UNAVAILABLE_KEY:
			{lclPrintf_NWK("Status: 0x%x, UNAVAILABLE_KEY\n", status);}
			break;
		case IEEE154_UNSUPPORTED_ATTRIBUTE:
			{lclPrintf_NWK("Status: 0x%x, UNSUPPORTED_ATTRIBUTE\n", status);}
			break;
		case IEEE154_UNSUPPORTED_LEGACY:
			{lclPrintf_NWK("Status: 0x%x, UNSUPPORTED_LEGACY\n", status);}
			break;
		case IEEE154_UNSUPPORTED_SECURITY:
			{lclPrintf_NWK("Status: 0x%x, UNSUPPORTED_SECURITY\n", status);}
			break;
		case IEEE154_PURGED:	// custom attribute
			{lclPrintf_NWK("Status: 0x%x, PURGED (custom attribute)\n", status);}
			break;
		default:
			{
				TinyErrorPrintStatus((uint8_t)status);
			}
		}
	#endif
	}
#endif

}
