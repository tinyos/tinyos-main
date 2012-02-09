/* PAN COORDINATOR NODE
 * @author Stefano Tennina <sota@isep.ipp.pt>
 * 
 */

#include <Timer.h>
#include "printfUART.h"
#include "log_enable.h"

#ifdef APP_PRINTFS_ENABLED
	#define lclPrintf				printfUART
	#define lclprintfUART_init		printfUART_init
#else
	#define lclPrintf(__format, __args...)
	void lclprintfUART_init() {}
#endif



module coordinatorBasicC 
{
  uses {
	interface Boot;
//	interface Leds;
	interface NLDE_DATA;
	//NLME NWK Management services
	interface NLME_NETWORK_FORMATION;	
	interface NLME_JOIN;
	interface NLME_LEAVE;
	interface NLME_SYNC;
	interface NLME_RESET;
	interface NLME_GET;
	interface NLME_SET;
	//Timers
	interface Timer<TMilli> as T_init;

#if defined(PLATFORM_TELOSB)
	//user button
	interface Get<button_state_t>;
	interface Notify<button_state_t>;
#endif
    }
  
}
implementation
{
	// Depth by configuration
	uint8_t networkStarted;
	// This function initializes the variables.

	void initVariables()
	{
		// Depth by configuration (initialize to default)
		atomic	networkStarted = 0;
	}

	event void Boot.booted() 
	{
		initVariables();

	#if defined(PLATFORM_TELOSB)
		// TelosB: we can use the button to start
		call Notify.enable();  

	#else
		// In case of MicaZ, start immediately
		call NLME_RESET.request();
	#endif
	}


	//function used to schedule the beacon requests (PAN coordinator)
	void process_beacon_scheduling(uint16_t source_address,uint8_t beacon_order, uint8_t superframe_order)
	{
		uint8_t nsdu_pay[6];
		beacon_scheduling *beacon_scheduling_ptr = (beacon_scheduling *)(&nsdu_pay[0]);

		beacon_scheduling_ptr->beacon_order = beacon_order;
		beacon_scheduling_ptr->superframe_order = superframe_order;

		switch(source_address)
		{
			/*****************************************************************************/
			/*
			 * NORMAL TEST
				mwkMaxChildren (Cm)	6
				nwkMaxDepth (Lm)	3
				mwkMaxRouters (Rm)	4
			*/
		case 0x0001: 
			beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
			beacon_scheduling_ptr->transmission_offset[0] = 0x00;
			beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
			beacon_scheduling_ptr->transmission_offset[2] = 0x00;
			break;
		case 0x0020: 
			beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
			beacon_scheduling_ptr->transmission_offset[0] = 0x01;
			beacon_scheduling_ptr->transmission_offset[1] = 0xE0;
			beacon_scheduling_ptr->transmission_offset[2] = 0x00;
			break;
		case 0x0002: 
			beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
			beacon_scheduling_ptr->transmission_offset[0] = 0x00;
			beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
			beacon_scheduling_ptr->transmission_offset[2] = 0x00;
			break;
		case 0x0009: 
			beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
			beacon_scheduling_ptr->transmission_offset[0] = 0x00;
			beacon_scheduling_ptr->transmission_offset[1] = 0xF0;
			beacon_scheduling_ptr->transmission_offset[2] = 0x00;
			break;
		case 0x0021: 
			beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
			beacon_scheduling_ptr->transmission_offset[0] = 0x00;
			beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
			beacon_scheduling_ptr->transmission_offset[2] = 0x00;
			break;
		case 0x0028: 
			beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
			beacon_scheduling_ptr->transmission_offset[0] = 0x00;
			beacon_scheduling_ptr->transmission_offset[1] = 0xF0;
			beacon_scheduling_ptr->transmission_offset[2] = 0x00;
			break;
		case 0x0003: 
			beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
			beacon_scheduling_ptr->transmission_offset[0] = 0x00;
			beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
			beacon_scheduling_ptr->transmission_offset[2] = 0x00;
			break;
		case 0x0004: 
			beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
			beacon_scheduling_ptr->transmission_offset[0] = 0x00;
			beacon_scheduling_ptr->transmission_offset[1] = 0x78;
			beacon_scheduling_ptr->transmission_offset[2] = 0x00;
			break;
		case 0x000a: 
			beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
			beacon_scheduling_ptr->transmission_offset[0] = 0x00;
			beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
			beacon_scheduling_ptr->transmission_offset[2] = 0x00;
			break;
		case 0x000b: 
			beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
			beacon_scheduling_ptr->transmission_offset[0] = 0x00;
			beacon_scheduling_ptr->transmission_offset[1] = 0x78;
			beacon_scheduling_ptr->transmission_offset[2] = 0x00;
			break;
		case 0x0022: 
			beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
			beacon_scheduling_ptr->transmission_offset[0] = 0x00;
			beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
			beacon_scheduling_ptr->transmission_offset[2] = 0x00;
			break;
		case 0x0023: 
			beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
			beacon_scheduling_ptr->transmission_offset[0] = 0x00;
			beacon_scheduling_ptr->transmission_offset[1] = 0x78;
			beacon_scheduling_ptr->transmission_offset[2] = 0x00;
			break;
		case 0x0029: 
			beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
			beacon_scheduling_ptr->transmission_offset[0] = 0x00;
			beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
			beacon_scheduling_ptr->transmission_offset[2] = 0x00;
			break;
		case 0x002a: 
			beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
			beacon_scheduling_ptr->transmission_offset[0] = 0x00;
			beacon_scheduling_ptr->transmission_offset[1] = 0x78;
			beacon_scheduling_ptr->transmission_offset[2] = 0x00;
			break;

		default: 
			beacon_scheduling_ptr->request_type = SCHEDULING_DENY;
			beacon_scheduling_ptr->transmission_offset[0] = 0x00;
			beacon_scheduling_ptr->transmission_offset[1] = 0x00;
			beacon_scheduling_ptr->transmission_offset[2] = 0x00;
			break;
		}
		
		lclPrintf("Coordinator: Sending negotiation reply\n", "");
		call NLDE_DATA.request(source_address, 0x06, nsdu_pay, 0, 1, 0x00, 0);
	}


	/*****************************************************
	****************NLDE EVENTS***************************
	******************************************************/

	/*************************NLDE_DATA*****************************/

	event error_t NLDE_DATA.confirm(uint8_t NsduHandle, uint8_t Status)
	{
		lclPrintf("NLDE_DATA.confirm\n", "");
		return SUCCESS;
	}

	event error_t NLDE_DATA.indication(uint16_t SrcAddress, uint8_t NsduLength,
					uint8_t Nsdu[120], 
					uint16_t LinkQuality)
	{
		uint8_t packetCode = Nsdu[0];
		// TDBS mechanism
		beacon_scheduling *beacon_scheduling_ptr;

		lclPrintf("NLDE_DATA.indication\n", "");
		
		// The packet is for me (check has been done into MCPS_DATA.indication)

		// TDBS mechanism
		if (packetCode == SCHEDULING_REQUEST) 
		{
			beacon_scheduling_ptr = (beacon_scheduling *)Nsdu;

			// PAN coordinator receiving a negotiation request
			process_beacon_scheduling (SrcAddress, 
				beacon_scheduling_ptr->beacon_order, 
				beacon_scheduling_ptr->superframe_order);
		}
		
		// No other data is expected
   
		return SUCCESS;
	}


	/*****************************************************
	****************NLME EVENTS***************************
	******************************************************/ 

	/*****************NLME_NETWORK_FORMATION**********************/

	event error_t NLME_NETWORK_FORMATION.confirm(uint8_t Status)
	{	
		lclPrintf("NLME_NETWORK_FORMATION.confirm\n", ""); 

		networkStarted = 1;
		
		// The Coordinator is transmitting its own beacons
		return SUCCESS;
	}

	/*************************NLME_JOIN*****************************/
	event error_t NLME_JOIN.indication(uint16_t ShortAddress, uint32_t ExtendedAddress[], uint8_t CapabilityInformation, bool SecureJoin)
	{
		lclPrintf("NLME_JOIN.indication\n", "");
		return SUCCESS;
	}

	event error_t NLME_JOIN.confirm(uint16_t PANId, uint8_t Status, uint16_t parentAddress)
	{	
		return SUCCESS;
	}

	/*************************NLME_LEAVE****************************/
	event error_t NLME_LEAVE.indication(uint64_t DeviceAddress)
	{
		lclPrintf("NLME_LEAVE.indication\n", "");
		return SUCCESS;
	}

	event error_t NLME_LEAVE.confirm(uint64_t DeviceAddress, uint8_t Status)
	{
		lclPrintf("NLME_LEAVE.confirm\n", "");
		return SUCCESS;
	}

	/*************************NLME_SYNC*****************************/
	event error_t NLME_SYNC.indication()
	{
		lclPrintf("NLME_SYNC.indication\n", "");

		// We lost connection with our parent. Automatic rescan is done
		// by the NWK

		return SUCCESS;
	}

	event error_t NLME_SYNC.confirm(uint8_t Status)
	{
		return SUCCESS;
	}

	/*****************        NLME-SET     ********************/
	event error_t NLME_SET.confirm(uint8_t Status, uint8_t NIBAttribute)
	{
		return SUCCESS;
	}

	/*****************        NLME-GET     ********************/
	event error_t NLME_GET.confirm(uint8_t Status, uint8_t NIBAttribute, uint16_t NIBAttributeLength, uint16_t NIBAttributeValue)
	{
		return SUCCESS;
	}

	event error_t NLME_RESET.confirm(uint8_t status)
	{
		lclPrintf("NLME_RESET.confirm\n", "");

		call T_init.startOneShot(5000);
		return SUCCESS;
	}


	/*******************T_init**************************/
	event void T_init.fired() 
	{
		lclPrintf("I'm THE coordinator\n", "");
		call NLME_NETWORK_FORMATION.request(LOGICAL_CHANNEL, 8, BEACON_ORDER, SUPERFRAME_ORDER, MAC_PANID, 0);
		return;
	}

#if defined(PLATFORM_TELOSB)
	event void Notify.notify(button_state_t state)
	{
		if (state == BUTTON_PRESSED && networkStarted == 0) 
		{
			lclPrintf("Button pressed\n", "");
			call NLME_RESET.request();
		}
	}
#endif
  
}

