//#define OPEN_ZB_MAC

/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 *
 */
#include <Timer.h>
#include "printfUART.h"

module Test_APLM {

	uses interface Boot;
	uses interface Leds;
	
	uses interface NLDE_DATA;
//NLME NWK Management services
	uses interface NLME_NETWORK_DISCOVERY;
	uses interface NLME_NETWORK_FORMATION;	
	uses interface NLME_START_ROUTER;
	uses interface NLME_JOIN;
	uses interface NLME_LEAVE;
	uses interface NLME_SYNC;
	
	/*
	uses interface NLME_PERMIT_JOINING;
	uses interface NLME_DIRECT_JOIN;*/
	uses interface NLME_RESET;
	
	
	uses interface NLME_GET;
	uses interface NLME_SET;
			
	uses interface Timer<TMilli> as T_init;
	
	uses interface Timer<TMilli> as T_test;
	
	uses interface Timer<TMilli> as T_schedule;		

//user button
  uses interface Get<button_state_t>;
  uses interface Notify<button_state_t>;	
  
}
implementation {
	
	//descriptor of the Parent device
	networkdescriptor PAN_network;
	//boolean variable definig if the device has joined to the PAN
	uint8_t joined =0x00;
	//boolean variable defining if the device is waiting for the beacon request response
	uint8_t requested_scheduling = 0x00;
	//function used to start the beacon broadcast (router devices)
	task void start_sending_beacons_request();
	//function used to schedule the beacon requests (PAN coordinator)
	void process_beacon_scheduling(uint16_t source_address,uint8_t beacon_order, uint8_t superframe_order);
	
	void process_beacon_scheduling(uint16_t source_address,uint8_t beacon_order, uint8_t superframe_order)
	{
	
		uint8_t nsdu_pay[6];
		
		beacon_scheduling *beacon_scheduling_ptr;
		
		beacon_scheduling_ptr = (beacon_scheduling *)&nsdu_pay[0];
		
		switch(source_address)
		{
			
			/*****************************************************************************/
			/*DEPTH 
			mwkMaxChildren (Cm)	6
			nwkMaxDepth (Lm)	4
			mwkMaxRouters (Rm)	4
			*/
			/*
			case 0x0001: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0002: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0021: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x01;
					beacon_scheduling_ptr->transmission_offset[1] = 0x2C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0003: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0022: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0004: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0005: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x78;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			
			case 0x0023: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			
			case 0x0024: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x78;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
						*/			
			/*****************************************************************************/
			/*NORMAL TEST
			mwkMaxChildren (Cm)	6
			nwkMaxDepth (Lm)	3
			mwkMaxRouters (Rm)	4
*/
			case 0x0001: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0020: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x01;
					beacon_scheduling_ptr->transmission_offset[1] = 0xE0;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0002: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0009: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0xF0;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0021: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0028: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0xF0;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0003: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0004: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x78;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x000a: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x000b: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x78;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0022: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0023: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x78;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0029: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x002a: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x78;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			
			/*******************************************************************/
			/*
			case 0x0001: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0002: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0009: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x78;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
					
					
			case 0x0020: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0xF0;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0021: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0028: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x78;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;		
			
			case 0x003F: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x01;
					beacon_scheduling_ptr->transmission_offset[1] = 0xE0;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0040: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0047: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x78;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
					
			case 0x005e: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x02;
					beacon_scheduling_ptr->transmission_offset[1] = 0xDC;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x005f: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0066: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x78;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;	
			*/
			/*******************************************************************/
			/*
			case 0x0001: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0002: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0009: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x78;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x00010: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0xB4;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0017: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0xF0;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;		
			
			
			case 0x0020: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x01;
					beacon_scheduling_ptr->transmission_offset[1] = 0x68;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0021: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0028: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x78;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0002F: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0xB4;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0036: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0xF0;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;		
			
			
			case 0x003F: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x02;
					beacon_scheduling_ptr->transmission_offset[1] = 0xD0;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0040: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0047: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x78;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0004E: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0xB4;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0055: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0xF0;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;	
					
					
					
			case 0x005e: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x04;
					beacon_scheduling_ptr->transmission_offset[1] = 0x38;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x005F: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x3C;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0066: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x78;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0006D: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0xB4;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
			case 0x0074: 
					beacon_scheduling_ptr->request_type = SCHEDULING_ACCEPT;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0xF0;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;	
			*/
			default: 
					beacon_scheduling_ptr->request_type = SCHEDULING_DENY;
					beacon_scheduling_ptr->beacon_order = beacon_order;
					beacon_scheduling_ptr->superframe_order = superframe_order;
					beacon_scheduling_ptr->transmission_offset[0] = 0x00;
					beacon_scheduling_ptr->transmission_offset[1] = 0x00;
					beacon_scheduling_ptr->transmission_offset[2] = 0x00;
					break;
		
		}

		
		call NLDE_DATA.request(source_address,0x06, nsdu_pay, 1, 1, 0x00, 0);
	return;
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

		//command result_t NLDE_DATA.request(uint16_t DstAddr, uint8_t NsduLength, uint8_t Nsdu[], uint8_t NsduHandle, uint8_t Radius, uint8_t DiscoverRoute, bool SecurityEnable)
		call NLDE_DATA.request(0x0000,0x06, nsdu_pay, 0x01, 0x01, 0x00, 0x00);
	
		call T_schedule.startOneShot(20000);
		//call Schedule_timer.start(TIMER_ONE_SHOT,20000);
	return;
	}
	
	
	
  event void Boot.booted() {
    	
	call Notify.enable();	
	
	//using the telosb motes the used button enables the association to the network (routers and end devices)
	//or the beacon broadcasting (PAN coordinator)
	//in the MICAz motes a timer is needed to start all the above operations
		
	//if (TYPE_DEVICE == COORDINATOR)
	//	call T_init.startOneShot(12000);
		
  }


/*****************************************************
****************TIMER EVENTS***************************
******************************************************/ 


/*******************T_init**************************/
  event void T_init.fired() {
 
    //printfUART("Timer fired\n", "");
	if (TYPE_DEVICE == COORDINATOR)
	{	
		


//printfUART("coordinator procedure\n", "");
		//start forming a PAN
		//command result_t request(uint32_t ScanChannels, uint8_t ScanDuration, uint8_t BeaconOrder, uint8_t SuperframeOrder, uint16_t PANId, bool BatteryLifeExtension);
		call NLME_NETWORK_FORMATION.request(0x000000ff, 8, BEACON_ORDER, SUPERFRAME_ORDER, MAC_PANID,0);
		
		//call Leds.redOff();
		//call Leds.led0Off();
		//call Test_timer.start(TIMER_REPEAT, 8000); 
	}
	else
	{	

//printfUART("child procedure\n", "");
	
	
		call NLME_NETWORK_DISCOVERY.request(0x000000ff, 8);
	
			
	}
	return;
  }

/*******************T_test**************************/
  event void T_test.fired() {
    
    	uint8_t nsdu_pay[20];
	//printfUART("Test_timer.fired\n", "");
 
	nsdu_pay[0]=0x05;
	nsdu_pay[1]=0x05;
	nsdu_pay[2]=0x05;
	nsdu_pay[3]=0x05;
	nsdu_pay[4]=0x05;
	nsdu_pay[5]=0x05;
	nsdu_pay[6]=0x05;
	
	//call Leds.redToggle();
	
	//command result_t NLDE_DATA.request(uint16_t DstAddr, uint8_t NsduLength, uint8_t Nsdu[], uint8_t NsduHandle, uint8_t Radius, uint8_t DiscoverRoute, bool SecurityEnable)
	call NLDE_DATA.request(0x0000,0x07, nsdu_pay, 1, 1, 0x00, 0);
  }
  
  /*******************T_schedule**************************/
  event void T_schedule.fired() {
    	//event that fires if the negotiation for beacon transmission is unsuccessful 
	//(the device does not receive any negotiation reply)
	if(requested_scheduling == 0x01)
	{
		post start_sending_beacons_request();
	}
    
  }


/*****************************************************
****************NLDE EVENTS***************************
******************************************************/ 

/*************************NLDE_DATA*****************************/

event error_t NLDE_DATA.confirm(uint8_t NsduHandle, uint8_t Status)
{
	//printfUART("NLME_DATA.confirm\n", "");
	
	return SUCCESS;
}

event error_t NLDE_DATA.indication(uint16_t SrcAddress, uint16_t NsduLength,uint8_t Nsdu[100], uint16_t LinkQuality)
{

	uint32_t start_time=0x00000000;
	uint16_t start_time1=0x0000;
	uint16_t start_time2=0x0000;
		
	if (TYPE_DEVICE == COORDINATOR)
	{	
		if(Nsdu[0] == SCHEDULING_REQUEST)
		{
			//the PAN coordinator receives a negotiation request
			process_beacon_scheduling(SrcAddress,Nsdu[1],Nsdu[2]);
		}
	}
	
	if(TYPE_DEVICE==ROUTER && requested_scheduling ==0x01)
	{
		//the routes receives a negotiation reply
		atomic requested_scheduling =0x00;

		if(Nsdu[0] == SCHEDULING_ACCEPT)
		{
			start_time1 =( (Nsdu[3] << 0) ) ;
			start_time2 =( (Nsdu[4] << 8 ) | (Nsdu[5] << 0 ) );
			
			start_time = ( ((uint32_t)start_time1 << 16) | (start_time2 << 0));
			
			call NLME_START_ROUTER.request(Nsdu[1],Nsdu[2],0,start_time);
		}

	}
	
	return SUCCESS;
}

/*****************************************************
****************NLME EVENTS***************************
******************************************************/ 

/*****************NLME_NETWORK_DISCOVERY**************************/
event error_t NLME_NETWORK_DISCOVERY.confirm(uint8_t NetworkCount,networkdescriptor networkdescriptorlist[], uint8_t Status)
{
	//printfUART("NLME_NETWORK_DISCOVERY.confirm\n", ""); 

	PAN_network = networkdescriptorlist[0];
	
	if (TYPE_DEVICE == ROUTER)
	{
		//printfUART("go join router\n", ""); 
		call NLME_JOIN.request(networkdescriptorlist[0].PANId, 0x01, 0, 0x000000ff, 8, 0, 0, 0);
	}
	else
	{
		//printfUART("go join non router\n", ""); 
		call NLME_JOIN.request(networkdescriptorlist[0].PANId, 0x00, 0, 0x000000ff, 8, 0, 0, 0);
	}	
	return SUCCESS;
}

 
/*****************NLME_NETWORK_FORMATION**********************/

event error_t NLME_NETWORK_FORMATION.confirm(uint8_t Status)
{	
	

//printfUART("NLME_NETWORK_FORMATION.confirm\n", ""); 

	return SUCCESS;
}
 
/*****************NLME_START_ROUTER*****************************/
event error_t NLME_START_ROUTER.confirm(uint8_t Status)
{ 
	//printfUART("NLME_START_ROUTER.confirm\n", ""); 
		
	return SUCCESS;
}

/*************************NLME_JOIN*****************************/

event error_t NLME_JOIN.indication(uint16_t ShortAddress, uint32_t ExtendedAddress[], uint8_t CapabilityInformation, bool SecureJoin)
{
	//printfUART("NLME_JOIN.indication\n", "");
	
	return SUCCESS;
}

event error_t NLME_JOIN.confirm(uint16_t PANId, uint8_t Status)
{	
	//printfUART("NLME_JOIN.confirm\n", "");
	
	switch(Status)
	{
	
		case NWK_SUCCESS:			joined =0x01;
									if (TYPE_DEVICE == ROUTER)
									{
										//join procedure successful
										//call Leds.redOff();
										call Leds.led0Off();
										
										requested_scheduling = 0x01;
										
										call T_schedule.startOneShot(9000);
										

										//call Test_timer.start(TIMER_REPEAT, 8000); 
									}
									else
									{
										//the device is an end device and starts transmitting data periodically
										call T_test.startPeriodic(10000);
										//call Test_timer.start(TIMER_REPEAT, 10000); 
									}
									break;
									
		case NWK_NOT_PERMITTED: 	joined =0x00;
									//join failed
									break;
									
		default:					//default procedure - join failed
									joined =0x00;
									break;
	}
	return SUCCESS;
}


/*************************NLME_LEAVE****************************/

event error_t NLME_LEAVE.indication(uint32_t DeviceAddress[])
{
	////printfUART("NLME_LEAVE.indication\n", "");
	return SUCCESS;
}

event error_t NLME_LEAVE.confirm(uint32_t DeviceAddress[], uint8_t Status)
{
	//printfUART("NLME_LEAVE.confirm\n", "");
	return SUCCESS;
}



/*************************NLME_SYNC*****************************/

event error_t NLME_SYNC.indication()
{
	//printfUART("NLME_SYNC.indication\n", "");
	return SUCCESS;
}

event error_t NLME_SYNC.confirm(uint8_t Status)
{
	
	return SUCCESS;
}


/*************************************************************/
/*****************        NLME-SET     ********************/
/*************************************************************/

event error_t NLME_SET.confirm(uint8_t Status, uint8_t NIBAttribute)
{

return SUCCESS;
}

/*************************************************************/
/*****************        NLME-GET     ********************/
/*************************************************************/

event error_t NLME_GET.confirm(uint8_t Status, uint8_t NIBAttribute, uint16_t NIBAttributeLength, uint16_t NIBAttributeValue)
{


return SUCCESS;
}

event error_t NLME_RESET.confirm(uint8_t status){

call T_init.startOneShot(5000);
return SUCCESS;
}

event void Notify.notify( button_state_t state)
{
	if (state == BUTTON_PRESSED) {
		//call Leds.led0On();
		
		call NLME_RESET.request();

	}
    
}


  
}

