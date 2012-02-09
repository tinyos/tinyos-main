/* ROUTER
 * @author Ricardo Severino <rars@isep.ipp.pt>
 * 
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

module routerBasicC 
{
	uses 
	{
		interface Boot;
		interface Leds;

		interface NLDE_DATA;
		//NLME NWK Management services
		interface NLME_NETWORK_DISCOVERY;
		interface NLME_START_ROUTER;
		interface NLME_JOIN;
		interface NLME_LEAVE;
		interface NLME_SYNC;
		interface NLME_RESET;
		interface NLME_GET;
		interface NLME_SET;

		//Timers
		interface Timer<TMilli> as T_init;
		interface Timer<TMilli> as T_schedule;
		interface Timer<TMilli> as NetAssociationDeferredTimer;
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
	uint8_t myDepth;
	//boolean variable definig if the device has joined to the PAN
	uint8_t joined;
	// Maximum number of join trials before restart from network discovery
	uint8_t maxJoinTrials;
	//boolean variable defining if the device is waiting for the beacon request response
	uint8_t requested_scheduling;
	//function used to start the beacon broadcast (router devices)
	task void start_sending_beacons_request();

	// This function initializes the variables.
	void initVariables()
	{
		// Depth by configuration (initialize to default)
		myDepth = DEF_DEVICE_DEPTH;
		//boolean variable definig if the device has joined to the PAN
		joined = 0x00;
		// Maximum number of join trials before restart from network discovery
		maxJoinTrials = MAX_JOIN_TRIALS;
		//boolean variable defining if the device is waiting for the beacon request response
		requested_scheduling = 0x00;	
	}

	event void Boot.booted() 
	{
		lclprintfUART_init();//make the possibility to print
		initVariables();
		call NLME_RESET.request();
	}

	task void start_sending_beacons_request()
	{
		uint8_t nsdu_pay[6];
		beacon_scheduling *beacon_scheduling_ptr;
		beacon_scheduling_ptr = (beacon_scheduling *)&nsdu_pay[0]; 
		   
		beacon_scheduling_ptr->request_type = SCHEDULING_REQUEST;
		beacon_scheduling_ptr->beacon_order = BEACON_ORDER;
		beacon_scheduling_ptr->superframe_order = SUPERFRAME_ORDER;
		beacon_scheduling_ptr->transmission_offset[0] = 0x00;
		beacon_scheduling_ptr->transmission_offset[1] = 0x00;
		beacon_scheduling_ptr->transmission_offset[2] = 0x00;	
		
		requested_scheduling = 0x01;
		
		lclPrintf("Router: Sending negotiation request\n", "");
		call NLDE_DATA.request(0x0000, 0x06, nsdu_pay, 0, 1, 0x00, 0);
		
		call T_schedule.startOneShot(20000);   
		return;
	}

	/*****************************************************
	****************NLDE EVENTS***************************
	******************************************************/

	/*************************NLDE_DATA*****************************/

	event error_t NLDE_DATA.confirm(uint8_t NsduHandle, uint8_t Status)
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf("NLDE_DATA.confirm\n", "");
	#endif
		call Leds.led1Toggle();
		return SUCCESS;
	}

	event error_t NLDE_DATA.indication(uint16_t SrcAddress, uint8_t NsduLength,
				uint8_t Nsdu[120], 
				uint16_t LinkQuality)
	{
		uint8_t packetCode = Nsdu[0];
		// TDBS mechanism
		beacon_scheduling *beacon_scheduling_ptr;
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf("NLDE_DATA.indication\n", "");
	#endif
		
		// The packet is for me (check has been done into MCPS_DATA.indication in NWKP.nc)
		// TDBS mechanism  
		if(requested_scheduling == 0x01)
		{
			//the router receives a negotiation reply
			atomic requested_scheduling = 0x00;    
			// Stop this timer to prevent a further fire event (if any)
			call T_schedule.stop();
			if(packetCode == SCHEDULING_ACCEPT)
			{
				// TDBS Mechanism
				uint32_t start_time = 0x00000000;
				uint16_t start_time1= 0x0000;
				uint16_t start_time2= 0x0000;
				beacon_scheduling_ptr = (beacon_scheduling *)Nsdu;

				start_time1 = ( (beacon_scheduling_ptr->transmission_offset[0] << 0) ) ;
				start_time2 = ( (beacon_scheduling_ptr->transmission_offset[1] << 8 ) | 
								(beacon_scheduling_ptr->transmission_offset[2] << 0 ) );

				start_time  = ( ((uint32_t)start_time1 << 16) | (start_time2 << 0) );

				lclPrintf("start_time=0x%x\n", start_time);

				call NLME_START_ROUTER.request (
						beacon_scheduling_ptr->beacon_order, 
						beacon_scheduling_ptr->superframe_order, 
						0, 
						start_time);
			}
		}
		return SUCCESS; 
	}

	/*****************************************************
	****************NLME EVENTS***************************
	******************************************************/ 

	/*****************NLME_NETWORK_DISCOVERY**************************/
	// This is not called anymore by the NKWP since it tries to associate 
	// directly to the parent and issuing a JOIN confirm, instead
	event error_t NLME_NETWORK_DISCOVERY.confirm(uint8_t NetworkCount,networkdescriptor networkdescriptorlist[], uint8_t Status)
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf("NLME_NETWORK_DISCOVERY.confirm\n", ""); 
	#endif
		return SUCCESS;
	}

	/*****************NLME_START_ROUTER*****************************/
	event error_t NLME_START_ROUTER.confirm(uint8_t Status)
	{ 
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf("NLME_START_ROUTER.confirm\n", "");
	#endif
		return SUCCESS;
	}

	/*************************NLME_JOIN*****************************/
	event error_t NLME_JOIN.indication(uint16_t ShortAddress, uint32_t ExtendedAddress[], uint8_t CapabilityInformation, bool SecureJoin)
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf("NLME_JOIN.indication\n", "");
	#endif
		return SUCCESS;
	}

	event error_t NLME_JOIN.confirm(uint16_t PANId, uint8_t Status, uint16_t parentAddress)
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf("NLME_JOIN.confirm\n", "");
	#endif
		switch(Status)
		{
		case NWK_SUCCESS:
			// Join procedure successful
			joined = 0x01;

			call Leds.led0Off();
			requested_scheduling = 0x01;
			call T_schedule.startOneShot(9000);
			break;
			
		case NWK_NOT_PERMITTED:
			joined = 0x00;
			//join failed
			break;
			
		case NWK_STARTUP_FAILURE:
			joined = 0x00;
			maxJoinTrials--;
			if (maxJoinTrials == 0)
			{
				// Retry restarting from the network discovery phase
				call T_init.startOneShot(5000);
			}
			else
			{
				// Retry after a few seconds
				call NetAssociationDeferredTimer.startOneShot(JOIN_TIMER_RETRY);
			}
			break;
			
		default:
			//default procedure - join failed
			joined = 0x00;
			break;
		}
		return Status;

	}

	/*************************NLME_LEAVE****************************/
	event error_t NLME_LEAVE.indication(uint64_t DeviceAddress)
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf("NLME_LEAVE.indication\n", "");
	#endif
		return SUCCESS;
	}

	event error_t NLME_LEAVE.confirm(uint64_t DeviceAddress, uint8_t Status)
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf("NLME_LEAVE.confirm\n", "");
	#endif
		return SUCCESS;
	}

	/*************************NLME_SYNC*****************************/
	event error_t NLME_SYNC.indication()
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf("NLME_SYNC.indication\n", "");
	#endif
		// We lost connection with our parent. Automatic rescan is done
		// at the NWK layer

		// Switch off all leds
		call Leds.led0Off();
		call Leds.led1Off();
		call Leds.led2Off();

		return SUCCESS;
	}

	event error_t NLME_SYNC.confirm(uint8_t Status)
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf("NLME_SYNC.confirm\n", "");
	#endif
		return SUCCESS;
	}

	/*****************        NLME-SET     ********************/
	event error_t NLME_SET.confirm(uint8_t Status, uint8_t NIBAttribute)
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf("NLME_SET.confirm\n", "");
	#endif
		return SUCCESS;
	}

	/*****************        NLME-GET     ********************/
	event error_t NLME_GET.confirm(uint8_t Status, uint8_t NIBAttribute, uint16_t NIBAttributeLength, uint16_t NIBAttributeValue)
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf("NLME_GET.confirm\n", "");
	#endif
		return SUCCESS;
	}

	event error_t NLME_RESET.confirm(uint8_t status)
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf("NLME_RESET.confirm\n", "");
	#endif

		call T_init.startOneShot(5000);
		return SUCCESS;
	}


	/*****************************************************
	****************TIMER EVENTS***************************
	******************************************************/ 

	/*******************T_init**************************/
	event void T_init.fired() 
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf("I'm NOT the coordinator\n", "");
	#endif

		call NLME_NETWORK_DISCOVERY.request(LOGICAL_CHANNEL, BEACON_ORDER);
		return;
	}


	/*******************NetAssociationDeferredTimer**************************/
	event void NetAssociationDeferredTimer.fired()
	{
	#if (LOG_LEVEL & TRACE_FUNC)
		lclPrintf("go join as router\n", ""); 
	#endif

		call NLME_JOIN.request(MAC_PANID, TRUE, FALSE, 0, 0, 0, 0, 0);
	}

	/*******************T_schedule**************************/
	event void T_schedule.fired()
	{  
		//event that fires if the negotiation for beacon transmission is unsuccessful 
		//(the device does not receive any negotiation reply)
		if(requested_scheduling == 0x01)
		{
			post start_sending_beacons_request();
		}
	}

#if defined(PLATFORM_TELOSB)
	event void Notify.notify(button_state_t state)
	{
		if (state == BUTTON_PRESSED) 
		{
		#if (LOG_LEVEL & TRACE_FUNC)
			lclPrintf("Button pressed\n", "");
		#endif

			call Leds.led0On();
			call NLME_RESET.request();
		}
	}
#endif
  
}

