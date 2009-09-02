/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 *
 */

#include <Timer.h>

#include "printfUART.h"

#include "frame_format.h"
#include "phy_const.h"

#include "mac_const.h"
#include "mac_enumerations.h"

#include "mac_func.h"

module MacM {

#ifndef TKN154_MAC 
	provides interface Init;
	
	provides interface MLME_START;
	provides interface MLME_SET;
    provides interface MLME_GET;
	
	provides interface MLME_ASSOCIATE;
	provides interface MLME_DISASSOCIATE;
	
	provides interface MLME_BEACON_NOTIFY;
	provides interface MLME_GTS;
	
	provides interface MLME_ORPHAN;
	
	provides interface MLME_SYNC;
	provides interface MLME_SYNC_LOSS;
		
	provides interface MLME_RESET;
	
	provides interface MLME_SCAN;
	
	//MCPS
	provides interface MCPS_DATA;
	provides interface MCPS_PURGE;
#endif
		
	
	uses interface Timer<TMilli> as T_ackwait;	
		
	uses interface Timer<TMilli> as	T_ResponseWaitTime;
	
	uses interface Timer<TMilli> as	T_ScanDuration;
	
	uses interface Leds;
	
	uses interface SplitControl as AMControl;
	
	uses interface Random;
	
	uses interface GeneralIO as CCA;
	
	
	//uses interface CC2420Config;
	
	uses interface AddressFilter;
	
	//uses interface Test_send;
	
	uses interface TimerAsync;
	
	uses interface PD_DATA;
	
	uses interface PLME_ED;
	uses interface PLME_CCA;
	uses interface PLME_SET;
	uses interface PLME_GET;
	uses interface PLME_SET_TRX_STATE;


  
}
implementation {
 
/*****************************************************/
/*				GENERAL 				 */
/*****************************************************/  
	/***************Variables*************************/
	//local extended address
	uint32_t aExtendedAddress0;
	uint32_t aExtendedAddress1;

	macPIB mac_PIB;

//If the the MLME receives a start request the node becomes a pan coordinator
	//and start transmiting beacons 
	bool PANCoordinator = 0;
	//(0 NO beacon transmission; 1 beacon transmission);
	bool Beacon_enabled_PAN = 0;
	
	//(RESET) when the reset command arrives it checks whether or not to reset the PIB
	bool SetDefaultPIB=0;
	
	//use security
	bool SecurityEnable=0;
	
	//others
	bool pending_reset=0;
	
	//transceiver status -every time the transceiver changes state this variable is updated
	uint8_t trx_status;
	
	//defines the transmission
	bool beacon_enabled=0;
	
	/***************Functions Definition***************/
	
	void init_MacPIB(); 
	
	uint8_t min(uint8_t val1, uint8_t val2);
	
	void init_MacCon();
	
	
	task void signal_loss();
	

	void create_data_request_cmd();
	void create_beacon_request_cmd();
	void create_gts_request_cmd(uint8_t gts_characteristics);
	
	void build_ack(uint8_t sequence,uint8_t frame_pending);
	
	void create_data_frame(uint8_t SrcAddrMode, uint16_t SrcPANId, uint32_t SrcAddr[], uint8_t DstAddrMode, uint16_t DestPANId, uint32_t DstAddr[], uint8_t msduLength, uint8_t msdu[],uint8_t msduHandle, uint8_t TxOptions,uint8_t on_gts_slot,uint8_t pan);




/*****************************************************/	
/*				Association 				         */
/*****************************************************/ 
	/***************Variables*************************/
	uint8_t associating = 0;
	uint8_t association_cmd_seq_num =0;
	
	/*association parameters*/
	
	uint8_t a_LogicalChannel;
	uint8_t a_CoordAddrMode;
	uint16_t a_CoordPANId;
	uint32_t a_CoordAddress[2];
	uint8_t a_CapabilityInformation;
	bool a_securityenable;
	
	/***************Functions Definition***************/		
	
	void create_association_request_cmd(uint8_t CoordAddrMode,uint16_t CoordPANId,uint32_t CoordAddress[],uint8_t CapabilityInformation);

	error_t create_association_response_cmd(uint32_t DeviceAddress[],uint16_t shortaddress, uint8_t status);
	
	void create_disassociation_notification_cmd(uint32_t DeviceAddress[],uint8_t disassociation_reason);
	
	void process_dissassociation_notification(MPDU *pdu);

/*****************************************************/
/*				Synchronization					 */
/*****************************************************/ 
	/***************Variables*************************/
	//(SYNC)the device will try to track the beacon ie enable its receiver just before the espected time of each beacon
	bool TrackBeacon=0;
	bool beacon_processed=0;
	//beacon loss indication
	uint8_t beacon_loss_reason;
	
	//(SYNC)the device will try to locate one beacon
	bool findabeacon=0;
	//(SYNC)number of beacons lost before sending a Beacon-Lost indication comparing to aMaxLostBeacons
	uint8_t missed_beacons=0;
	//boolean variable stating if the device is synchonized with the beacon or not
	uint8_t on_sync=0;
	
	uint32_t parent_offset=0x00000000;


/*****************************************************/
/*				GTS Variables					 */
/*****************************************************/  
	/***************Variables*************************/
	
	uint8_t gts_request=0;
	uint8_t gts_request_seq_num=0;
	
	bool gts_confirm;
	
	uint8_t GTS_specification;
	bool GTSCapability=1;
	
	uint8_t final_CAP_slot=15;
	
	//GTS descriptor variables, coordinator usage only
	GTSinfoEntryType GTS_db[7];
	uint8_t GTS_descriptor_count=0;
	uint8_t GTS_startslot=16;
	uint8_t GTS_id=0x01;


	//null gts descriptors
	GTSinfoEntryType_null GTS_null_db[7];
	
	uint8_t GTS_null_descriptor_count=0;
	//uint8_t GTS_null_id=0x01;
	
	//node GTS variables
	// 1 GTS for transmit
	uint8_t s_GTSss=0;           //send gts start slot
	uint8_t s_GTS_length=0;		 //send gts length
	//1 GTS for receive
	uint8_t r_GTSss=0;			 //receive gts start slot
	uint8_t r_GTS_length=0;		 //receive gts lenght
	
	//used to state that the device is on its transmit slot
	uint8_t on_s_GTS=0;
	//used to state that the device is on its receive slot
	uint8_t on_r_GTS=0;
	
	//used to determine if the next time slot is used for transmission
	uint8_t next_on_s_GTS=0;
	//used to determine if the next time slot is used for reception
	uint8_t next_on_r_GTS=0;
	
	//variable stating if the coordinator allow GTS allocations
	uint8_t allow_gts=1;
	
	//COORDINATOR GTS BUFFER 	
	gts_slot_element gts_slot_list[7];
	uint8_t available_gts_index[GTS_SEND_BUFFER_SIZE];
	uint8_t available_gts_index_count;
	
	uint8_t coordinator_gts_send_pending_data=0;
	uint8_t coordinator_gts_send_time_slot=0;
	
	//gts buffer used to store the gts messages both in COORDINATOR and NON COORDINATOR
	norace MPDU gts_send_buffer[GTS_SEND_BUFFER_SIZE];
	
	//NON PAN COORDINATOR BUFFER
	//buffering for sending
	uint8_t gts_send_buffer_count=0;
	uint8_t gts_send_buffer_msg_in=0;
	uint8_t gts_send_buffer_msg_out=0;
	uint8_t gts_send_pending_data=0;
	

	/***************Functions Definition***************/
	
	void process_gts_request(MPDU *pdu);	
	void init_available_gts_index();
	task void start_coordinator_gts_send();
	
	
	//GTS FUNCTIONS
	error_t remove_gts_entry(uint16_t DevAddressType);
	error_t add_gts_entry(uint8_t gts_length,bool direction,uint16_t DevAddressType);
	error_t add_gts_null_entry(uint8_t gts_length,bool direction,uint16_t DevAddressType);
	
	//increment the idle GTS for GTS deallocation purposes, not fully implemented yet
	task void increment_gts_null();
	
	task void start_gts_send();
	
	
	
	//initialization functions
	void init_gts_slot_list();
	void init_GTS_null_db();
	
	void init_GTS_db();


	uint32_t calculate_gts_expiration();
	task void check_gts_expiration();


/*****************************************************/
/*				CHANNEL SCAN Variables				 */
/*****************************************************/ 
	//current_channel
	uint8_t current_channel=0;

	/***************Variables*************************/
	//ED-SCAN variables
	
	bool scanning_channels;
	
	uint32_t channels_to_scan;
	uint8_t current_scanning=0;
	//uint8_t scan_count=0;
	uint8_t scanned_values[16];
	uint8_t scan_type;
	
	SCAN_PANDescriptor scan_pans[16];
	
	uint16_t scan_duration;
	
	task void data_channel_scan_indication();
	
/*****************************************************/
/*				TIMER VARIABLES					 */
/*****************************************************/  
	/***************Variables*************************/
	uint32_t response_wait_time;
	
	//Beacon Interval
	uint32_t BI;
	//Superframe duration
	uint32_t SD;
	
	//timer variables
	uint32_t time_slot; //backoff boundary timer
	uint32_t backoff;  //backoff timer
	
	//current number of backoffs in the active period
	uint8_t number_backoff=1;
	uint8_t number_time_slot=0;
	
	bool csma_slotted=0;
/*****************************************************/
/*				CSMA VARIABLES					 */
/*****************************************************/  	
	/***************Variables*************************/	

	//DEFERENCE CHANGE
	uint8_t cca_deference = 0;
	uint8_t backoff_deference = 0;
	uint8_t check_csma_ca_backoff_send_conditions(uint32_t delay_backoffs);

	//STEP 2
	uint8_t delay_backoff_period;
	bool csma_delay=0;
	
	bool csma_locate_backoff_boundary=0;
	
	bool csma_cca_backoff_boundary=0;
	
	//Although the receiver of the device is enabled during the channel assessment portion of this algorithm, the
	//device shall discard any frames received during this time.
	bool performing_csma_ca=0;
	
	//CSMA-CA variables
	uint8_t BE; //backoff exponent
	uint8_t CW; //contention window (number of backoffs to clear the channel)
	uint8_t NB; //number of backoffs

	/***************Functions Definition***************/	
	
	void init_csma_ca(bool slotted);
	void perform_csma_ca();
	task void perform_csma_ca_unslotted();
	task void perform_csma_ca_slotted();
	//task void start_csma_ca_slotted();
	
/*****************************************************/
/*				Indirect Transmission buffers		 */
/*****************************************************/
	/***************Variables*************************/	
	//indirect transmission buffer
	norace indirect_transmission_element indirect_trans_queue[INDIRECT_BUFFER_SIZE];
	//indirect transmission message counter
	uint8_t indirect_trans_count=0;

	/***************Functions Definition***************/	
	
	//function used to initialize the indirect transmission buffer
	void init_indirect_trans_buffer();
	//function used to search and send an existing indirect transmission message
	void send_ind_trans_addr(uint32_t DeviceAddress[]);
	//function used to remove an existing indirect transmission message
	error_t remove_indirect_trans(uint8_t handler);
	//function used to increment the transaction persistent time on each message
	//if the transaction time expires the messages are discarded
	void increment_indirect_trans();
	
/*****************************************************/
/*				RECEIVE buffers		                  */
/*****************************************************/  
	/***************Variables*************************/
	
	//buffering variables
	norace MPDU buffer_msg[RECEIVE_BUFFER_SIZE];
	int current_msg_in=0;
	int current_msg_out=0;
	int buffer_count=0;

	/***************Functions Definition***************/	
	
	task void data_indication();
	
	void indication_cmd(MPDU *pdu, int8_t ppduLinkQuality);
	void indication_ack(MPDU *pdu, int8_t ppduLinkQuality);
	void indication_data(MPDU *pdu, int8_t ppduLinkQuality);
/*****************************************************/
/*				RECEPTION AND TRANSMISSION		                  */
/*****************************************************/  
	
	/***************Variables*************************/
	
	//buffering for sending
	norace MPDUBuffer send_buffer[SEND_BUFFER_SIZE];
	uint8_t send_buffer_count=0;
	uint8_t send_buffer_msg_in=0;
	uint8_t send_buffer_msg_out=0;
	
	//retransmission information
	uint8_t send_ack_check;//ack requested in the transmitted frame
	uint8_t retransmit_count;//retransmission count
	uint8_t ack_sequence_number_check;//transmission sequence number
	uint8_t send_retransmission;
	uint8_t send_indirect_transmission;

	uint8_t pending_request_data=0;
	
	uint8_t ackwait_period;
	
	uint8_t link_quality;
	
	norace ACK mac_ack;
	ACK *mac_ack_ptr;
	
	uint32_t gts_expiration;

	uint8_t I_AM_IN_CAP=0;
	uint8_t I_AM_IN_CFP=0;
	uint8_t I_AM_IN_IP=0;
	
	/***************Functions Definition***************/	
	
	task void send_frame_csma();
	
	uint8_t check_csma_ca_send_conditions(uint8_t frame_length,uint8_t frame_control1);

	uint8_t check_gts_send_conditions(uint8_t frame_length);
	
	uint8_t calculate_ifs(uint8_t pk_length);



/*****************************************************/
/*				BEACON MANAGEMENT  		              */
/*****************************************************/ 
	/***************Variables*************************/
	norace MPDU mac_beacon_txmpdu;
	MPDU *mac_beacon_txmpdu_ptr;
	
	uint8_t *send_beacon_frame_ptr;
	uint8_t send_beacon_length;

	/***************Functions Definition***************/	
	/*function to create the beacon*/
	task void create_beacon();
	/*function to process the beacon information*/
	void process_beacon(MPDU *packet,uint8_t ppduLinkQuality);
	

/*****************************************************/
/*	 Fault tolerance functions            */
/*****************************************************/ 
//FAULT-TOLERANCE	
	void create_coordinator_realignment_cmd(uint32_t device_extended0, uint32_t device_extended1, uint16_t device_short_address);

	void create_orphan_notification();
	
	void process_coordinator_realignment(MPDU *pdu);

	/*******************************************/
	/*******BEACON SCHEDULING IMPLEMENTATION****/
	/*******************************************/
	
	//bolean that checks if the device is in the parent active period
	uint8_t I_AM_IN_PARENT_CAP = 0;
	
	
	//upstream buffer
	norace MPDUBuffer upstream_buffer[UPSTREAM_BUFFER_SIZE];
	uint8_t upstream_buffer_count=0;
	uint8_t upstream_buffer_msg_in=0;
	uint8_t upstream_buffer_msg_out=0;

	uint8_t sending_upstream_frame=0;
	
	task void send_frame_csma_upstream();

/***************************DEBUG FUNCTIONS******************************/
/* This function are list functions with the purpose of debug, to use then uncomment the declatarion
on top of this file*/
/*
	void list_mac_pib();
	
	void list_gts();
	
	void list_my_gts();
	void list_gts_null();
	*/
	//list all the handles in the indirect transmission buffer, debug purposes
	void list_indirect_trans_buffer();	
			
/***************************END DEBUG FUNCTIONS******************************/


/***************** Init Commands ****************/
  command error_t Init.init() {
  
  call AMControl.start();


	//initialization of the beacon structure
	mac_beacon_txmpdu_ptr = &mac_beacon_txmpdu;



   atomic{

	//inicialize the mac PIB
	init_MacPIB();
	
	init_GTS_db();
	
	init_GTS_null_db();
	
	init_gts_slot_list();
	
	init_available_gts_index();
	
	aExtendedAddress0=TOS_NODE_ID;
	aExtendedAddress1=TOS_NODE_ID;
	


	call AddressFilter.set_address(mac_PIB.macShortAddress, aExtendedAddress0, aExtendedAddress1);

	call AddressFilter.set_coord_address(mac_PIB.macCoordShortAddress, mac_PIB.macPANId);
	

											
	init_indirect_trans_buffer();


	}
	
	//beacon
	mac_beacon_txmpdu_ptr = &mac_beacon_txmpdu;
		
	//ack
	mac_ack_ptr = &mac_ack;
	
	//Other timers, sync timers units expressed in miliseconds
	ackwait_period = ((mac_PIB.macAckWaitDuration * 4.0 ) / 250.0) * 3;

	response_wait_time = ((aResponseWaitTime * 4.0) / 250.0) * 2;

	atomic{
	
		
		BI = aBaseSuperframeDuration * powf(2,mac_PIB.macBeaconOrder);
		SD = aBaseSuperframeDuration * powf(2,mac_PIB.macSuperframeOrder);
		
		
		//backoff_period
		backoff = aUnitBackoffPeriod;
		//backoff_period_boundary
		
		time_slot = SD / NUMBER_TIME_SLOTS;
			
		call TimerAsync.set_enable_backoffs(1);	
		call TimerAsync.set_backoff_symbols(backoff);
		
		call TimerAsync.set_bi_sd(BI,SD);
		
		call TimerAsync.start();
	}


printfUART_init();

    return SUCCESS;
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
     	
	call TimerAsync.start();
		
	}
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  }


/*****************************************************/
/*				TIMERS FIRED       					 */
/*****************************************************/ 

async event error_t TimerAsync.before_bi_fired()
{
	//printfUART("bbi %i\n",call TimerAsync.get_current_ticks());
		
	if (mac_PIB.macBeaconOrder != mac_PIB.macSuperframeOrder )
	{
		if ( Beacon_enabled_PAN == 1 )
		{
			//
			//post set_trx();
			trx_status = PHY_TX_ON;
			call PLME_SET_TRX_STATE.request(PHY_TX_ON);
		}
		else
		{
			//
			//post set_trx();
			trx_status = PHY_RX_ON;
			call PLME_SET_TRX_STATE.request(PHY_RX_ON);
		}
	}
	
	//I_AM_IN_CAP = 1;
	findabeacon = 1;
		
	return SUCCESS;
}

/*******************Timer BEACON INTERVAL******************/
async event error_t TimerAsync.bi_fired()
{
	call Leds.led2On();
	//call Test_send.send();
	
	I_AM_IN_CAP = 1;
	I_AM_IN_IP = 0;
	
	//printfUART("bi\n","");
	
	
	if ( Beacon_enabled_PAN == 1 )
	{
		//the beacon is send directly without CSMA/CA
		call PD_DATA.request(send_beacon_length,send_beacon_frame_ptr);
	}

	number_backoff =0;
	number_time_slot=0;
	
	
	//CHECK there is the need to wait a small amount of time before checking if the beacon as been processed or not
	//possible solition, if it receives a packet stand by for confirmation it its a beacon
	//The device must always receive the beacon
	if (TrackBeacon == 1) 
	{
		if (beacon_processed==1) 
		{
			beacon_processed=0;
		}
		else
		{
			//dealocate all GTS
			//beacon loss

			on_sync =0;
			beacon_loss_reason = MAC_BEACON_LOSS;
			
			//TODO
			//post signal_loss();
		}
	}
	
	post send_frame_csma();

	return SUCCESS;
}

/*******************Timer SUPERFRAME DURATION******************/
async event error_t TimerAsync.sd_fired()
{
	call Leds.led2Off();

	//printfUART("sd\n","");

	I_AM_IN_CFP = 0;
	I_AM_IN_IP = 1;
	
	
	number_backoff=0;
	number_time_slot=0;
	
	
	if (PANCoordinator == 0 && TYPE_DEVICE == ROUTER)
	{
		trx_status = PHY_RX_ON;
	
		call PLME_SET_TRX_STATE.request(PHY_RX_ON);
	}
	else
	{
		trx_status = PHY_RX_ON;
		
		call PLME_SET_TRX_STATE.request(PHY_RX_ON);
		
	}
	
	if (mac_PIB.macShortAddress==0xffff && TYPE_DEVICE == END_DEVICE)
	{
		trx_status = PHY_RX_ON;
		
		call PLME_SET_TRX_STATE.request(PHY_RX_ON);
	}
	
	//trx_status = PHY_RX_ON;
	//post set_trx();
	/*
		//turn the transceiver off
	if (mac_PIB.macBeaconOrder != mac_PIB.macSuperframeOrder )
	{
		if ( mac_PIB.macRxOnWhenIdle == 0 && findabeacon == 0) 
		{
			trx_status = PHY_TRX_OFF;
			post set_trx();
		}
		else
		{
			trx_status = PHY_RX_ON;
			post set_trx();
		}
	}
	//if the node is trying to synchronize
		if (on_sync == 0 || mac_PIB.macPromiscuousMode == 1)
	{
		atomic{
			trx_status = PHY_RX_ON;
			post set_trx();
		}
	}
	*/
	if (PANCoordinator == 1)
	{
		//increment the gts_null descriptors
		atomic{
			
				//if (GTS_null_descriptor_count > 0) post increment_gts_null();
			
				//if (GTS_descriptor_count >0 ) post check_gts_expiration();
			
				//if (indirect_trans_count > 0) increment_indirect_trans();
				
				//creation of the beacon
				post create_beacon();
		}
		//trx_status = PHY_TRX_OFF;
		//post set_trx();
	}
	else
	{
	//temporariamente aqui //aten��o quando for para o cluster-tree � preciso mudar para fora
	//e necessario destinguir ZC de ZR (que tem que manter a sync com o respectivo pai)
	if (on_sync == 0)
	{
		//sync not ok
		
		//findabeacon=1;
		if (missed_beacons == aMaxLostBeacons)
		{
		
			printfUART("sync_loss %i\n",missed_beacons);
			//out of sync
			post signal_loss();
		}
		//printfUART("out_sync %i\n",missed_beacons);
		missed_beacons++;
		call Leds.led1Off();
		
	}
	else
	{
		//sync ok
		missed_beacons=0;
	
		on_sync=0;
	}
	
	}

	//trx_status = PHY_TRX_OFF;
	//call PLME_SET_TRX_STATE.request(PHY_TRX_OFF);

	return SUCCESS;
}

/*******************Timer BEFORE TIME SLOT FIRED******************/
async event error_t TimerAsync.before_time_slot_fired()
{
	on_s_GTS=0;
	on_r_GTS=0;
	
	if (next_on_s_GTS == 1)
	{	
		on_s_GTS=1;
		next_on_s_GTS =0;
		trx_status = PHY_TX_ON;
		call PLME_SET_TRX_STATE.request(PHY_TX_ON);
		//post set_trx();
	}
	
	if(next_on_r_GTS == 1)
	{
		on_r_GTS=1;
		next_on_r_GTS=0;
		trx_status = PHY_RX_ON;
		call PLME_SET_TRX_STATE.request(PHY_RX_ON);
		//post set_trx();
	}

return SUCCESS;
}
/*******************Timer TIME SLOT FIRED******************/
async event error_t TimerAsync.time_slot_fired()
{
	//reset the backoff counter and increment the slot boundary
	number_backoff=0;
	number_time_slot++;
		
	//verify is there is data to send in the GTS, and try to send it
	if(PANCoordinator == 1 && GTS_db[15-number_time_slot].direction == 1 && GTS_db[15-number_time_slot].gts_id != 0)
	{
		//COORDINATOR SEND DATA
		//////////printfUART("bbck%i:%i:%i\n", (15-number_time_slot),GTS_db[15-number_time_slot].direction,gts_slot_list[15-number_time_slot].element_count);
		
		post start_coordinator_gts_send();
				
	}
	else
	{
		//DEVICE SEND DATA
		if (number_time_slot == s_GTSss && gts_send_buffer_count > 0 && on_sync == 1)//(send_s_GTSss-send_s_GTS_len) 
		{
				//current_time = call TimerAsync.get_total_tick_counter();
				post start_gts_send();
		}		
	}
	
	next_on_r_GTS =0;
	next_on_s_GTS=0;
	
	
	//printfUART("ts%i %i %i\n", number_time_slot,s_GTSss,r_GTSss);
	
	
	//verification if the time slot is entering the CAP
	//GTS FIELDS PROCESSING
	
	if ((number_time_slot + 1) >= final_CAP_slot && (number_time_slot + 1) < 16)
	{
		I_AM_IN_CAP = 0;
		I_AM_IN_CFP = 1;
		
		//printfUART("bts %i\n",I_AM_IN_CAP, number_time_slot); 
	
	atomic{
		
		//verification of the next time slot
		if(PANCoordinator == 1 && number_time_slot < 15)
		{
		//COORDINATOR verification of the next time slot
			if(GTS_db[14-number_time_slot].gts_id != 0x00 && GTS_db[14-number_time_slot].DevAddressType != 0x0000)
			{	
				if(GTS_db[14-number_time_slot].direction == 1 ) // device wants to receive
				{
					next_on_s_GTS =1; //PAN coord mode
				}
				else
				{
					next_on_r_GTS=1; //PAN coord mode
				}
			}	
		}
		else
		{
		//device verification of the next time slot
			if( (number_time_slot +1) == s_GTSss || (number_time_slot +1) == r_GTSss )
			{
				//printfUART("s_GTSss: %i r_GTSss: %i\n", s_GTSss,r_GTSss);
				if((number_time_slot + 1) == s_GTSss)
				{	
					//printfUART("MY SEND SLOT \n", "");
					next_on_s_GTS =1;
					s_GTS_length --;
					if (s_GTS_length != 0 )
					{
						s_GTSss++;
					}
				}
				else			
				{
					////////////printfUART("MY RECEIVE SLOT \n", "");
					next_on_r_GTS =1;
					r_GTS_length --;
					if (r_GTS_length != 0 )
					{
						r_GTSss++;
					}
				}				
			}
			else
			{
				//idle
				next_on_s_GTS=0;
				next_on_r_GTS=0;
			}
		}
	}
	}
	
return SUCCESS;
}
async event error_t TimerAsync.sfd_fired()
{

return SUCCESS;
}

/*******************Timer BACKOFF PERIOD******************/
async event error_t TimerAsync.backoff_fired()
{
	//slotted CSMA/CA function
	atomic{
	
		if( csma_locate_backoff_boundary == 1 )
		{
			csma_locate_backoff_boundary=0;
			
			//post start_csma_ca_slotted();
			
			//DEFERENCE CHANGE
			if (backoff_deference == 0)
			{
				//normal situation
				delay_backoff_period = (call Random.rand16() & ((uint8_t)(powf(2,BE)) - 1));
				
				if (check_csma_ca_backoff_send_conditions((uint32_t) delay_backoff_period) == 1)
				{
					backoff_deference = 1;
				}
				
			}
			else
			{
				backoff_deference = 0;
			}
			
			csma_delay=1;
		}
		
		
		
		if( csma_cca_backoff_boundary == 1 )
			post perform_csma_ca_slotted();
	}
	//CSMA/CA
	atomic{
		if(csma_delay == 1 )
		{
			if (delay_backoff_period == 0)
			{
				if(csma_slotted == 0)
				{
					post perform_csma_ca_unslotted();
				}
				else
				{
					//CSMA/CA SLOTTED
					csma_delay=0;
					csma_cca_backoff_boundary=1;
				}
			}
			delay_backoff_period--;
		}
	}
	number_backoff++;
return SUCCESS;
}

/*******************T_ackwait**************************/
  event void T_ackwait.fired() {
  
  ////////printfUART("Tfd \n", "");
	
	//call Leds.redToggle();

	if (send_ack_check == 1)
	{
		retransmit_count++;
		
		if (retransmit_count == aMaxFrameRetries || send_indirect_transmission > 0)
		{
				//check the type of data being send
				/*
				if (associating == 1)
				{
					printfUART("af ack\n", "");
					associating=0;
					signal MLME_ASSOCIATE.confirm(0x0000,MAC_NO_ACK);
				}
				*/
				
			atomic{	
				//////////printfUART("TRANSMISSION FAIL\n",""); 
				//stardard procedure, if fail discard the packet
				atomic send_buffer_count --;
				send_buffer_msg_out++;
			
					//failsafe
					if(send_buffer_count > SEND_BUFFER_SIZE)
					{
						
						atomic send_buffer_count =0;
						send_buffer_msg_out=0;
						send_buffer_msg_in=0;
						
					}
					
					
					if (send_buffer_msg_out == SEND_BUFFER_SIZE)
						send_buffer_msg_out=0;
					
					if (send_buffer_count > 0)
						post send_frame_csma();
						
					send_ack_check=0;
					retransmit_count=0;
					ack_sequence_number_check=0;
				
				}
		}
		
		//////////printfUART("RETRY\n",""); 
		//retransmissions
		post send_frame_csma();
	}
    
  }

/*******************T_ResponseWaitTime**************************/
  event void T_ResponseWaitTime.fired() {
  	//command response wait time
	//////////printfUART("T_ResponseWaitTime.fired\n", "");

	if (associating == 1)
	{
		printfUART("af rwt\n", "");
		associating=0;
		signal MLME_ASSOCIATE.confirm(0x0000,MAC_NO_DATA);
		
	}
  
  }

/*******************TDBS Implementation Timers**************************/
async event error_t TimerAsync.before_start_track_beacon_fired()
{
	I_AM_IN_PARENT_CAP = 1;

return SUCCESS;
}



//track beacon events timers
async event error_t TimerAsync.start_track_beacon_fired()
{
	I_AM_IN_PARENT_CAP = 1;

	//printfUART("fi\n","");
	
	if (upstream_buffer_count > 0)
		post send_frame_csma_upstream();



return SUCCESS;
}
async event error_t TimerAsync.end_track_beacon_fired()
{

	I_AM_IN_PARENT_CAP = 0;
	
	//printfUART("unfi\n","");
	//call Leds.greenOff();

return SUCCESS;
}





/*****************************************************
****************PD_DATA EVENTS***********************
******************************************************/
  async event error_t PD_DATA.confirm(uint8_t status) {


    return SUCCESS;     
  }
 
/*****************************************************
****************       PD_DATA     ********************
******************************************************/ 

async event error_t PD_DATA.indication(uint8_t psduLenght,uint8_t* psdu, int8_t ppduLinkQuality){
/*
MPDU *packet;

uint8_t destination_address=0;

dest_short *dest_short_ptr;
dest_long *dest_long_ptr;
	
beacon_addr_short *beacon_addr_short_ptr;

*/
atomic{
		//if(I_AM_IN_CAP == 1 || I_AM_IN_CFP == 1 || mac_PIB.macShortAddress==0xffff || scanning_channels ==1 || findabeacon == 1)
		//{
			if (buffer_count > RECEIVE_BUFFER_SIZE)
			{
				//call Leds.redToggle();
				printfUART("full\n","");
			}
			else
			{
		
				/*
				packet = (MPDU*)psdu;
							
				
				switch ((packet->frame_control1 & 0x7))
				{
					case TYPE_BEACON:
									beacon_addr_short_ptr = (beacon_addr_short *) &packet->data[0];
									
									//avoid VERIFY static assignment of coordinator parent
									if (beacon_addr_short_ptr->source_address != mac_PIB.macCoordShortAddress)
									{
											printfUART("pb %x %x\n", beacon_addr_short_ptr->source_address,mac_PIB.macCoordShortAddress);
											return SUCCESS;
									}
									
									/*
									
									if ( mac_PIB.macShortAddress != 0xffff)
									{
										if ( beacon_addr_short_ptr->source_address != mac_PIB.macCoordShortAddress)
										{
											printfUART("pb %x %x\n", beacon_addr_short_ptr->source_address,mac_PIB.macCoordShortAddress);
											return SUCCESS;
										}
									}*/
					/*
					break;
					case TYPE_DATA:
					case TYPE_CMD:
									//VALIDATION OF DESTINATION ADDRESSES - NOT TO OVERLOAD THE PROCESSOR
									destination_address=get_fc2_dest_addr(packet->frame_control2);
				
									if (destination_address > 1)
									{
										switch(destination_address)
										{
											case SHORT_ADDRESS: 
																dest_short_ptr = (dest_short *) &packet->data[0];
																
																if ( dest_short_ptr->destination_address != 0xffff && dest_short_ptr->destination_address != mac_PIB.macShortAddress)
																{
																	printfUART("nsm %x %x\n", dest_short_ptr->destination_address,mac_PIB.macShortAddress); 
																	return SUCCESS;
																}
																//If a destination PAN identifier is included in the frame, it shall match macPANId or shall be the
																//broadcast PAN identifier (0 x ffff).
																if(dest_short_ptr->destination_PAN_identifier != 0xffff && dest_short_ptr->destination_PAN_identifier != mac_PIB.macPANId )
																{
																	printfUART("wsP %x %x \n", dest_short_ptr->destination_PAN_identifier,mac_PIB.macPANId); 
																	return SUCCESS;
																}
																break;
											
											case LONG_ADDRESS: 
																dest_long_ptr = (dest_long *) &packet->data[0];
																
																if ( dest_long_ptr->destination_address0 !=aExtendedAddress0 && dest_long_ptr->destination_address1 !=aExtendedAddress1 )
																{
																	printfUART("nlm %x %x \n",dest_long_ptr->destination_address0,dest_long_ptr->destination_address1); 
																	return SUCCESS;
																}
																//If a destination PAN identifier is included in the frame, it shall match macPANId or shall be the
																//broadcast PAN identifier (0 x ffff).
																if(dest_long_ptr->destination_PAN_identifier != 0xffff && dest_long_ptr->destination_PAN_identifier != mac_PIB.macPANId )
																{
																	printfUART("wLP %x %x\n", dest_long_ptr->destination_PAN_identifier,mac_PIB.macPANId); 
																	return SUCCESS;
																}
																
																break;
										}
									}
					

					
									break;
					case TYPE_ACK:
				
									break;
				}
						
				*/
				memcpy(&buffer_msg[current_msg_in],psdu,sizeof(MPDU));

				atomic{
					current_msg_in++;
				
					if ( current_msg_in == RECEIVE_BUFFER_SIZE ) 
						current_msg_in = 0;
		
					buffer_count ++;
				}
				
				link_quality = ppduLinkQuality;
				
				if (scanning_channels ==1)
				{
					//channel scan operation, accepts beacons only
					post data_channel_scan_indication();
				
				}
				else
				{
				//normal operation
					post data_indication();
				}
			}
		//}
		//else
		//{
		//	printfUART("drop\n","");
		//}
}
return SUCCESS;
}



task void data_indication()
{
	//check all the conditions for a receiver packet
    //pag 155
 
	uint8_t link_qual;
	
	atomic link_qual = link_quality;

	//printfUART("data_indication\n","");
	////////printfUART("buf  %i %i\n",buffer_count,indirect_trans_count);

	//Although the receiver of the device is enabled during the channel assessment portion of this algorithm, the
	//device shall discard any frames received during this time.
	////////////printfUART("performing_csma_ca: %i\n",performing_csma_ca);
	if (performing_csma_ca == 1)
	{	
		////////////printfUART("REJ CSMA\n","");
		atomic{ 
			buffer_count--;
		
			current_msg_out++;
		if ( current_msg_out == RECEIVE_BUFFER_SIZE )	
			current_msg_out = 0;
			}
		
		return;
    }
	
	//while performing channel scan disable the packet reception
	if ( scanning_channels == 1)
	{	
		atomic{ 
			buffer_count--;
	
			current_msg_out++;
		if ( current_msg_out == RECEIVE_BUFFER_SIZE )	
			current_msg_out = 0;
			}
		return;
	}	
atomic{

    ////printfUART("data ind %x %x %i\n",buffer_msg[current_msg_out].frame_control1,buffer_msg[current_msg_out].frame_control2,(buffer_msg[current_msg_out].frame_control2 & 0x7));
	
	//check the frame type of the received packet
	switch( (buffer_msg[current_msg_out].frame_control1 & 0x7) )
	{
		
			case TYPE_DATA: //printfUART("rd %i\n",buffer_msg[current_msg_out].seq_num);
							indication_data(&buffer_msg[current_msg_out],link_qual);
							break;
							
			case TYPE_ACK: //printfUART("ra\n","");
							//ack_received = 1;
							indication_ack(&buffer_msg[current_msg_out],link_qual);
							
							break;
							
			case TYPE_CMD:  //printfUART("rc\n","");
							indication_cmd(&buffer_msg[current_msg_out],link_qual);
							break;
			
			case TYPE_BEACON:
							
							//printfUART("rb %i\n",buffer_msg[current_msg_out].seq_num);
							if (mac_PIB.macShortAddress == 0x0000) 
							{
								buffer_count--;
							}
							else
							{
								process_beacon(&buffer_msg[current_msg_out],link_qual);
								
							}

							break;
			default: 
						atomic buffer_count--;
						////printfUART("Invalid frame type\n","");

						break;
	}
	atomic{
			current_msg_out++;
		if ( current_msg_out == RECEIVE_BUFFER_SIZE )	
			current_msg_out = 0;
		}
	}
	return;
}



/*****************************************************
****************PLME_ED EVENTS***********************
******************************************************/ 
event error_t PLME_CCA.confirm(uint8_t status){
return SUCCESS;
}
   
   
event error_t PLME_SET.confirm(uint8_t status, uint8_t PIBAttribute){   
return SUCCESS;
}
 
async event error_t PLME_SET_TRX_STATE.confirm(uint8_t status){

return SUCCESS;
}    
   
event error_t PLME_GET.confirm(uint8_t status,uint8_t PIBAttribute, uint8_t PIBAttributeValue){
   
return SUCCESS;
}    

event error_t PLME_ED.confirm(uint8_t status,int8_t EnergyLevel){

return SUCCESS;
}

/*******************************************************************************************************/
/*******************************************************************************************************/
/*******************************************************************************************************/
/****************************************PACKET PROCESSING FUNCTIONS************************************/
/*******************************************************************************************************/
/*******************************************************************************************************/
/*******************************************************************************************************/

void process_beacon(MPDU *packet,uint8_t ppduLinkQuality)
{

	/*
	ORGANIZE THE PROCESS BEACON FUNCION AS FOLLOWS.
	1- GET THE BEACON ORDER
	2- GET THE SUPERFRAME ORDER
	3- GET THE FINAL CAP SLOT
	4 - COMPUTE SD, BI, TS, BACKOFF PERIOD IN MILLISECONDS
	
	4- SYNCHRONIZE THE NODE BY DOING THE FOLLOWING
		- SET A TIMER IN MS FOR THE FINAL TIME SLOT (SUPERFRAME DURATION) : IT EXPRIES AFTER SD - TX TIME - PROCESS TIME
		- SET A TIMER IN MS FOR THE GTS IF ANY EXIST IT EXPRIES AFTER GTS_NBR * TIME_SLOT - TX TIME - PROCESS TIME 
	*/
	uint32_t SO_EXPONENT;
	uint32_t BO_EXPONENT;
	int i=0;
	uint16_t gts_descriptor_addr;
	uint8_t data_count;
	
	uint8_t gts_directions;
	uint8_t gts_des_count;
	
	uint8_t gts_ss;
	uint8_t gts_l;
	uint8_t dir;
	uint8_t dir_mask;

	//end gts variables

	//function that processes the received beacon
	beacon_addr_short *beacon_ptr;
	
	PANDescriptor pan_descriptor;

	// beacon_trans_delay = (((packet->length(bytes) * 8.0) / 250.00(bits/s) ) / 0.34(s) (timer_granularity) ) (symbols)

	//pending frames
	uint8_t short_addr_pending=0;
	uint8_t long_addr_pending=0;

	//used in the synchronization
	//uint32_t process_tick_counter; //symbols
	
	//uint32_t becon_trans_delay; //symbols
	//uint32_t start_reset_ct; //number of clock ticks since the start of the beacon interval
	
	//used in the track beacon
	beacon_processed = 1;
	missed_beacons=0;
	
	//initializing pointer to data structure
	beacon_ptr = (beacon_addr_short*) (packet->data);
	
	
		//decrement buffer count
	atomic buffer_count --;
	
	//printfUART("Received Beacon\n","");
	//printfUART("rb panid: %x %x \n",beacon_ptr->source_address,mac_PIB.macCoordShortAddress);
	//////printfUART("My macPANID: %x\n",mac_PIB.macPANId);
	printfUART("rb %x %x\n",beacon_ptr->source_address,mac_PIB.macCoordShortAddress);
	if( beacon_ptr->source_address != mac_PIB.macCoordShortAddress)
	{
		printfUART("nmp \n","");
		return;
	}
	//printfUART("bea %i\n",call TimerAsync.get_current_ticks());
	
	/**********************************************************************************/
	/*					PROCESSING THE SUPERFRAME STRUCTURE							  */
	/**********************************************************************************/
	
	if (PANCoordinator == 0)
	{
		mac_PIB.macBeaconOrder = get_beacon_order(beacon_ptr->superframe_specification);
		mac_PIB.macSuperframeOrder = get_superframe_order(beacon_ptr->superframe_specification);
		
		//mac_PIB.macCoordShortAddress = beacon_ptr->source_address;
		
		//printfUART("BO,SO:%i %i\n",mac_PIB.macBeaconOrder,mac_PIB.macSuperframeOrder);
		
		//mac_PIB.macPANId = beacon_ptr->source_PAN_identifier;
		
		//beacon order check if it changed
		if (mac_PIB.macSuperframeOrder == 0)
		{
			SO_EXPONENT = 1;
		}
		else
		{
			SO_EXPONENT = powf(2,mac_PIB.macSuperframeOrder);
		}
		
		if ( mac_PIB.macBeaconOrder ==0)
		{
			BO_EXPONENT =1;
		}
		else
		{
				BO_EXPONENT = powf(2,mac_PIB.macBeaconOrder);
		}
		BI = aBaseSuperframeDuration * BO_EXPONENT; 
		SD = aBaseSuperframeDuration * SO_EXPONENT; 
		
		//backoff_period
		backoff = aUnitBackoffPeriod;
		time_slot = SD / NUMBER_TIME_SLOTS;
		
		call TimerAsync.set_bi_sd(BI,SD);
	}	
		
	/**********************************************************************************/
	/*							PROCESS GTS CHARACTERISTICS							  */
	/**********************************************************************************/
		allow_gts =1;
	
		//initializing the gts variables
		s_GTSss=0;
		s_GTS_length=0;
		
		r_GTSss=0;
		r_GTS_length=0;
		
		/*
		send_s_GTSss=0;  
		send_r_GTSss=0;	
		send_s_GTS_len=0;
		send_r_GTS_len=0;
		*/
		final_CAP_slot = 15;


		gts_des_count = (packet->data[8] & 0x0f);
		
		data_count = 9;
		
		final_CAP_slot = 15 - gts_des_count;
		
		if (gts_des_count > 0 )
		{
		data_count = 10; //position of the current data count
		//process descriptors
		
			gts_directions = packet->data[9];
			
			//printfUART("gts_directions:%x\n",gts_directions);
			
			for(i=0; i< gts_des_count; i++)
			{	
				gts_descriptor_addr = (uint16_t) packet->data[data_count];
					
				//printfUART("gts_des_addr:%x mac short:%x\n",gts_descriptor_addr,mac_PIB.macShortAddress);
				
				data_count = data_count+2;
				//check if it concerns me
				if (gts_descriptor_addr == mac_PIB.macShortAddress)
				{
					//confirm the gts request
					////////////printfUART("packet->data[data_count]: %x\n",packet->data[data_count]);
					//gts_ss = 15 - get_gts_descriptor_ss(packet->data[data_count]);
					gts_ss = get_gts_descriptor_ss(packet->data[data_count]);
					gts_l = get_gts_descriptor_len(packet->data[data_count]);

					if ( i == 0 )
					{
						dir_mask=1;
					}
					else
					{
					
							dir_mask = powf(2,i);
					}
					////////////printfUART("dir_mask: %x i: %x gts_directions: %x \n",dir_mask,i,gts_directions);
					dir = ( gts_directions & dir_mask);
					if (dir == 0)
					{
						s_GTSss=gts_ss;
						s_GTS_length=gts_l;
					}
					else
					{

						r_GTSss=gts_ss;
						r_GTS_length=gts_l;
					}
					
					//printfUART("PB gts_ss: %i gts_l: %i dir: %i \n",gts_ss,gts_l,dir);
					////////////printfUART("PB send_s_GTSss: %i send_s_GTS_len: %i\n",send_s_GTSss,send_s_GTS_len);
					
					if ( gts_l == 0 )
					{
						allow_gts=0;
					}

					if (gts_confirm == 1 && gts_l != 0)
					{
						//signal ok
						//printfUART("gts confirm \n","");
						gts_confirm =0;
						signal MLME_GTS.confirm(GTS_specification,MAC_SUCCESS);
					}
					else
					{
						//signal not ok
						////////////printfUART("gts not confirm \n","");
						gts_confirm =0;
						signal MLME_GTS.confirm(GTS_specification,MAC_DENIED);
					}
					
				}
				data_count++;	
			}
		}
	
	/**********************************************************************************/
	/*							PROCESS PENDING ADDRESSES INFORMATION				  */
	/**********************************************************************************/	
		//this should pass to the network layer
		
		
		short_addr_pending=get_number_short(packet->data[data_count]);
		long_addr_pending=get_number_extended(packet->data[data_count]);
		
		//////////printfUART("ADD COUNT %i %i\n",short_addr_pending,long_addr_pending);
		
		data_count++;
		
		if(short_addr_pending > 0)
		{
			for(i=0;i < short_addr_pending;i++)
			{
				//////////printfUART("PB %i %i\n",(uint16_t)packet->data[data_count],short_addr_pending);
				
				//if(packet->data[data_count] == (uint8_t)mac_PIB.macShortAddress && packet->data[data_count+1] == (uint8_t)(mac_PIB.macShortAddress >> 8) )
				if((uint16_t)packet->data[data_count] == mac_PIB.macShortAddress)
				{
					
					create_data_request_cmd();
				}
				data_count = data_count + 2;
			}
		}
		if(long_addr_pending > 0)
		{
			for(i=0; i < long_addr_pending;i++)
			{
				if((uint32_t)packet->data[data_count] == aExtendedAddress0 && (uint32_t)packet->data[data_count + 4] == aExtendedAddress1)
				{
					
					data_count = data_count + 8;

				}
			
			}
		}

	/**********************************************************************************/
	/*				BUILD the PAN descriptor of the COORDINATOR						  */
	/**********************************************************************************/
		
		
	   //Beacon NOTIFICATION
	   //BUILD the PAN descriptor of the COORDINATOR
		//assuming that the adress is short
		pan_descriptor.CoordAddrMode = SHORT_ADDRESS;
		pan_descriptor.CoordPANId = 0x0000;//beacon_ptr->source_PAN_identifier;
		pan_descriptor.CoordAddress0=0x00000000;
		pan_descriptor.CoordAddress1=mac_PIB.macCoordShortAddress;
		pan_descriptor.LogicalChannel=current_channel;
		//superframe specification field
		pan_descriptor.SuperframeSpec = beacon_ptr->superframe_specification;
		
		pan_descriptor.GTSPermit=mac_PIB.macGTSPermit;
		pan_descriptor.LinkQuality=0x00;
		pan_descriptor.TimeStamp=0x000000;
		pan_descriptor.SecurityUse=0;
		pan_descriptor.ACLEntry=0x00;
		pan_descriptor.SecurityFailure=0x00;
	   
		//I_AM_IN_CAP = 1;
	   
	/**********************************************************************************/
	/*								SYNCHRONIZING									  */
	/**********************************************************************************/

	//processing time + beacon transmission delay
	
	//removed not used
	//process_tick_counter = call TimerAsync.get_process_frame_tick_counter();
	//removed not used	
	//start_reset_ct = ((1000 * (packet->length * 8.0) / 250)) / 69.54;  //(process_tick_counter - receive_tick_counter);

	if(PANCoordinator == 0)
	{
			I_AM_IN_CAP = 1;
			I_AM_IN_IP = 0;
			
			//call Leds.yellowOn();
			call Leds.led2On();
			
			call Leds.led1On();
			
			if(findabeacon == 1)
			{
				//printfUART("findabeacon\n", "");
				call TimerAsync.set_timers_enable(1);
				findabeacon =0;
			}
			
			//#ifdef PLATFORM_MICAZ
			//number_time_slot = call TimerAsync.reset_start(start_reset_ct+process_tick_counter+52);// //SOBI=3 52 //SOBI=0 15
			//#else
			
			//call TimerAsync.reset();
			
			number_time_slot = call TimerAsync.reset_start(75);   //95 old val sem print
					
			// +process_tick_counter+52 //SOBI=3 52 //SOBI=0 
			//#endif
			on_sync=1;
			
			printfUART("sE\n", "");
	}
	else
	{
		I_AM_IN_PARENT_CAP = 1;
		
		call TimerAsync.set_track_beacon(1);
		
		//#ifdef PLATFORM_MICAZ
		//	call TimerAsync.set_track_beacon_start_ticks(parent_offset,0x00001E00,(start_reset_ct+process_tick_counter+18));
		//#else
			call TimerAsync.set_track_beacon_start_ticks(parent_offset,0x00001E00,4);//(start_reset_ct)
		//#endif
		
		printfUART("sP \n", "");
	}
	
	call Leds.led1Toggle();
	signal MLME_BEACON_NOTIFY.indication((uint8_t)packet->seq_num,pan_descriptor,0, 0, mac_PIB.macBeaconPayloadLenght, packet->data);
		
return;
}


void process_gts_request(MPDU *pdu)
{
		error_t status;
		cmd_gts_request *mac_gts_request;
		
		mac_gts_request= (cmd_gts_request*) &pdu->data;
		
atomic{		
		if ( get_characteristic_type(mac_gts_request->gts_characteristics) == 1)
		{
		//allocation
	
	//process the gts request
		status = add_gts_entry(get_gts_length(mac_gts_request->gts_characteristics),get_gts_direction(mac_gts_request->gts_characteristics),mac_gts_request->source_address);
		
		}
		else
		{
		//dealocation
	
		status = remove_gts_entry(mac_gts_request->source_address);
		}
		
		signal MLME_GTS.indication(mac_gts_request->source_address, mac_gts_request->gts_characteristics, 0, 0);
		
		}

return;
}
/****************DATA indication functions******************/

void indication_data(MPDU *pdu, int8_t ppduLinkQuality)
{
	uint8_t data_len;
	
	uint8_t payload[80];
	uint8_t msdu_length=0;
	
	//int i;
	
	uint32_t SrcAddr[2];
	uint32_t DstAddr[2];
	
	
	//frame control variables
	uint8_t source_address=0;
	uint8_t destination_address=0;


	dest_short *dest_short_ptr;
	dest_long *dest_long_ptr;
	
	source_short *source_short_ptr;
	source_long *source_long_ptr;

	//implement the intra PAN data messages
	//intra_pan_source_short *intra_pan_source_short_ptr;
	//intra_pan_source_long *intra_pan_source_long_ptr;
	
	
	source_address=get_fc2_source_addr(pdu->frame_control2);
	destination_address=get_fc2_dest_addr(pdu->frame_control2);
	
	//decrement buffer count
	atomic buffer_count --;
	
	SrcAddr[0]=0x00000000;
	SrcAddr[1]=0x00000000;
	DstAddr[0]=0x00000000;
	DstAddr[1]=0x00000000;


	//printfUART("id %i %i \n",source_address,destination_address);


	if ( get_fc1_intra_pan(pdu->frame_control1)== 0 )
	{
	//INTRA PAN
		if (destination_address > 1 && source_address > 1)
		{
			// Destination LONG - Source LONG	
			if (destination_address == LONG_ADDRESS && source_address == LONG_ADDRESS)
			{
				dest_long_ptr = (dest_long *) &pdu->data[0];
				source_long_ptr = (source_long *) &pdu->data[DEST_LONG_LEN];
				
				//If a short destination address is included in the frame, it shall match either macShortAddress or the
				//broadcast address (0 x ffff). Otherwise, if an extended destination address is included in the frame, it
				//shall match aExtendedAddress.
				if ( dest_long_ptr->destination_address0 !=aExtendedAddress0 && dest_long_ptr->destination_address1 !=aExtendedAddress1 )
				{
					//////////printfUART("data rejected, ext destination not for me\n", ""); 
					return;
				}
				//If a destination PAN identifier is included in the frame, it shall match macPANId or shall be the
				//broadcast PAN identifier (0 x ffff).
				if(dest_long_ptr->destination_PAN_identifier != 0xffff && dest_long_ptr->destination_PAN_identifier != mac_PIB.macPANId )
				{
					//////////printfUART("data rejected, wrong destination PAN\n", ""); 
					return;
				}
				data_len = 20;
				
				
				DstAddr[1] = dest_long_ptr->destination_address0;
				DstAddr[0] =dest_long_ptr->destination_address1;
				
				SrcAddr[1] =source_long_ptr->source_address0;
				SrcAddr[0] =source_long_ptr->source_address1;
				
				msdu_length = pdu->length - data_len;

				memcpy(&payload,&pdu->data[data_len],msdu_length * sizeof(uint8_t));
				
				signal MCPS_DATA.indication((uint16_t)source_address, (uint16_t)source_long_ptr->source_PAN_identifier, SrcAddr,(uint16_t)destination_address, (uint16_t)dest_long_ptr->destination_PAN_identifier, DstAddr, (uint16_t)msdu_length, payload, (uint16_t)ppduLinkQuality, 0x0000,0x0000);  
				
			}
			
			// Destination SHORT - Source LONG
			if ( destination_address == SHORT_ADDRESS && source_address == LONG_ADDRESS )
			{
				dest_short_ptr = (dest_short *) &pdu->data[0];
				source_long_ptr = (source_long *) &pdu->data[DEST_SHORT_LEN];
				
				//If a short destination address is included in the frame, it shall match either macShortAddress or the
				//broadcast address (0 x ffff). Otherwise, if an extended destination address is included in the frame, it
				//shall match aExtendedAddress.
				if ( dest_short_ptr->destination_address != 0xffff && dest_short_ptr->destination_address != mac_PIB.macShortAddress)
				{
					//////////printfUART("data rejected, short destination not for me\n", ""); 
					return;
				}
				//If a destination PAN identifier is included in the frame, it shall match macPANId or shall be the
				//broadcast PAN identifier (0 x ffff).
				if(dest_short_ptr->destination_PAN_identifier != 0xffff && dest_short_ptr->destination_PAN_identifier != mac_PIB.macPANId )
				{
					//////////printfUART("data rejected, wrong destination PAN\n", ""); 
					return;
				}
				
				data_len = 14;
				
				DstAddr[0] =dest_short_ptr->destination_address;
				
				SrcAddr[1] =source_long_ptr->source_address0;
				SrcAddr[0] =source_long_ptr->source_address1;
				
				msdu_length = pdu->length - data_len;

				memcpy(&payload,&pdu->data[data_len],msdu_length * sizeof(uint8_t));
				
				signal MCPS_DATA.indication((uint16_t)source_address, (uint16_t)source_long_ptr->source_PAN_identifier, SrcAddr,(uint16_t)destination_address, (uint16_t)dest_short_ptr->destination_PAN_identifier, DstAddr, (uint16_t)msdu_length, payload, (uint16_t)ppduLinkQuality, 0x0000,0x0000);  

			}
			// Destination LONG - Source SHORT
			if ( destination_address == LONG_ADDRESS && source_address == SHORT_ADDRESS )
			{
				dest_long_ptr = (dest_long *) &pdu->data[0];
				source_short_ptr = (source_short *) &pdu->data[DEST_LONG_LEN];
				
				//If a short destination address is included in the frame, it shall match either macShortAddress or the
				//broadcast address (0 x ffff). Otherwise, if an extended destination address is included in the frame, it
				//shall match aExtendedAddress.
				if ( dest_long_ptr->destination_address0 !=aExtendedAddress0 && dest_long_ptr->destination_address1 !=aExtendedAddress1 )
				{
					//////////printfUART("data rejected, ext destination not for me\n", ""); 
					return;
				}
				//If a destination PAN identifier is included in the frame, it shall match macPANId or shall be the
				//broadcast PAN identifier (0 x ffff).
				if(dest_long_ptr->destination_PAN_identifier != 0xffff && dest_long_ptr->destination_PAN_identifier != mac_PIB.macPANId )
				{
					//////////printfUART("data rejected, wrong destination PAN\n", ""); 
					return;
				}
				
				data_len = 14;
				
				DstAddr[1] = dest_long_ptr->destination_address0;
				DstAddr[0] =dest_long_ptr->destination_address1;
				
				
				SrcAddr[0] =source_short_ptr->source_address;
				
				msdu_length = pdu->length - data_len;

				memcpy(&payload,&pdu->data[data_len],msdu_length * sizeof(uint8_t));
				
				signal MCPS_DATA.indication((uint16_t)source_address, (uint16_t)source_short_ptr->source_PAN_identifier, SrcAddr,(uint16_t)destination_address, (uint16_t)dest_long_ptr->destination_PAN_identifier, DstAddr, (uint16_t)msdu_length, payload, (uint16_t)ppduLinkQuality, 0x0000,0x0000);  

			}
			
			
			//Destination SHORT - Source SHORT
			if ( destination_address == SHORT_ADDRESS && source_address == SHORT_ADDRESS )	
			{
				dest_short_ptr = (dest_short *) &pdu->data[0];
				source_short_ptr = (source_short *) &pdu->data[DEST_SHORT_LEN];
				
				//If a short destination address is included in the frame, it shall match either macShortAddress or the
				//broadcast address (0 x ffff). Otherwise, if an extended destination address is included in the frame, it
				//shall match aExtendedAddress.
				if ( dest_short_ptr->destination_address != 0xffff && dest_short_ptr->destination_address != mac_PIB.macShortAddress)
				{
					//printfUART("data rejected, short destination not for me\n", ""); 
					return;
				}
				//If a destination PAN identifier is included in the frame, it shall match macPANId or shall be the
				//broadcast PAN identifier (0 x ffff).
				if(dest_short_ptr->destination_PAN_identifier != 0xffff && dest_short_ptr->destination_PAN_identifier != mac_PIB.macPANId )
				{
					//printfUART("SH SH data rejected, wrong destination PAN %x\n",mac_PIB.macPANId ); 
					return;
				}
				
				data_len = 8;
				
				if ( get_fc1_ack_request(pdu->frame_control1) == 1 ) 
				{
					build_ack(pdu->seq_num,0);
				}
				
				DstAddr[0] =dest_short_ptr->destination_address;
				
				SrcAddr[0] =source_short_ptr->source_address;
				
				msdu_length = (pdu->length - 5) - data_len;
				
				
				memcpy(&payload,&pdu->data[data_len],msdu_length * sizeof(uint8_t));
			
				signal MCPS_DATA.indication((uint16_t)source_address, (uint16_t)source_short_ptr->source_PAN_identifier, SrcAddr,(uint16_t)destination_address, (uint16_t)dest_short_ptr->destination_PAN_identifier, DstAddr, (uint16_t)msdu_length,payload, (uint16_t)ppduLinkQuality, 0x0000,0x0000);  

			}
		}
		
		/*********NO DESTINATION ADDRESS PRESENT ****************/
		
		if ( destination_address == 0 && source_address > 1 )
		{
				
			if (source_address == LONG_ADDRESS)
			{//Source LONG
				source_long_ptr = (source_long *) &pdu->data[0];
				
				//If only source addressing fields are included in a data or MAC command frame, the frame shall be
				//accepted only if the device is a PAN coordinator and the source PAN identifier matches macPANId.
				if ( PANCoordinator==0 || source_long_ptr->source_PAN_identifier != mac_PIB.macPANId )
				{
					//////////printfUART("data rejected, im not pan\n", ""); 
					return;
				}
				
				data_len = 10;
				
				SrcAddr[1] =source_long_ptr->source_address0;
				SrcAddr[0] =source_long_ptr->source_address1;
				
				msdu_length = pdu->length - data_len;

				memcpy(&payload,&pdu->data[data_len],msdu_length * sizeof(uint8_t));
				
				signal MCPS_DATA.indication((uint16_t)source_address,(uint16_t)source_long_ptr->source_PAN_identifier, SrcAddr,(uint16_t)destination_address, 0x0000, DstAddr, (uint16_t)msdu_length, payload, (uint16_t)ppduLinkQuality, 0x0000,0x0000);  

			}
			else
			{//Source SHORT

				source_short_ptr = (source_short *) &pdu->data[0];
				//If only source addressing fields are included in a data or MAC command frame, the frame shall be
				//accepted only if the device is a PAN coordinator and the source PAN identifier matches macPANId.
				if ( PANCoordinator==0 || source_short_ptr->source_PAN_identifier != mac_PIB.macPANId )
				{
					//////////printfUART("data rejected, im not pan\n", ""); 
					return;
				}
				
				data_len = 4;

				
				SrcAddr[0] =source_short_ptr->source_address;
				
				msdu_length = pdu->length - data_len;

				memcpy(&payload,&pdu->data[data_len],msdu_length * sizeof(uint8_t));
				
				signal MCPS_DATA.indication((uint16_t)source_address, (uint16_t)source_short_ptr->source_PAN_identifier, SrcAddr,(uint16_t)destination_address, 0x0000, DstAddr, (uint16_t)msdu_length, payload, (uint16_t)ppduLinkQuality, 0x0000,0x0000);  

			}
		}
		/*********NO SOURCE ADDRESS PRESENT ****************/
		
		if ( destination_address > 1 && source_address == 0 )
		{
			if (destination_address == LONG_ADDRESS)
			{//Destination LONG
				dest_long_ptr = (dest_long *) &pdu->data[0];
				
				//If a short destination address is included in the frame, it shall match either macShortAddress or the
				//broadcast address (0 x ffff). Otherwise, if an extended destination address is included in the frame, it
				//shall match aExtendedAddress.
				if ( dest_long_ptr->destination_address0 !=aExtendedAddress0 && dest_long_ptr->destination_address1 !=aExtendedAddress1 )
				{
					//////////printfUART("data rejected, ext destination not for me\n", ""); 
					return;
				}
				//If a destination PAN identifier is included in the frame, it shall match macPANId or shall be the
				//broadcast PAN identifier (0 x ffff).
				if(dest_long_ptr->destination_PAN_identifier != 0xffff && dest_long_ptr->destination_PAN_identifier != mac_PIB.macPANId )
				{
					//////////printfUART("data rejected, wrong destination PAN\n", ""); 
					return;
				}
				
				data_len = 10;
				
				DstAddr[1] = dest_long_ptr->destination_address0;
				DstAddr[0] =dest_long_ptr->destination_address1;
				
				msdu_length = pdu->length - data_len;

				memcpy(&payload,&pdu->data[data_len],msdu_length * sizeof(uint8_t));
			
				signal MCPS_DATA.indication((uint16_t)source_address,0x0000, SrcAddr,(uint16_t)destination_address, (uint16_t)dest_long_ptr->destination_PAN_identifier, DstAddr, (uint16_t)msdu_length, payload, (uint16_t)ppduLinkQuality, 0x0000,0x0000);  

			}
			else
			{//Destination SHORT
				dest_short_ptr = (dest_short *) &pdu->data[0];
				
				//If a short destination address is included in the frame, it shall match either macShortAddress or the
				//broadcast address (0 x ffff). Otherwise, if an extended destination address is included in the frame, it
				//shall match aExtendedAddress.
				if ( dest_short_ptr->destination_address != 0xffff && dest_short_ptr->destination_address != mac_PIB.macShortAddress)
				{
					//////////printfUART("data rejected, short destination not for me\n", ""); 
					return;
				}
				//If a destination PAN identifier is included in the frame, it shall match macPANId or shall be the
				//broadcast PAN identifier (0 x ffff).
				if(dest_short_ptr->destination_PAN_identifier != 0xffff && dest_short_ptr->destination_PAN_identifier != mac_PIB.macPANId )
				{
					//////////printfUART("data rejected, wrong destination PAN\n", ""); 
					return;
				}
				
				data_len = 4;
				
				DstAddr[0] =dest_short_ptr->destination_address;
				
				msdu_length = pdu->length - data_len;

				memcpy(&payload,&pdu->data[data_len],msdu_length * sizeof(uint8_t));
				
				
				signal MCPS_DATA.indication((uint16_t)source_address,0x0000, SrcAddr,(uint16_t)destination_address, (uint16_t)dest_short_ptr->destination_PAN_identifier, DstAddr, (uint16_t)msdu_length, payload, (uint16_t)ppduLinkQuality, 0x0000,0x0000);  

				data_len = 4;
			}
		}
		
	}
	else
	{
	//intra_pan == 1
	
	
	
	}
	
	
return;
}

void indication_cmd(MPDU *pdu, int8_t ppduLinkQuality)
{
		uint8_t cmd_type;
		//uint8_t pk_ptr;
		uint8_t addressing_fields_length=0;
		
		uint32_t SrcAddr[2];
		//uint32_t DstAddr[2];//NOT USED SO FAR
		
		//frame control variables
		uint8_t source_address=0;
		uint8_t destination_address=0;
	
		//NOT USED SO FAR
		//dest_short *dest_short_ptr;
		//dest_long *dest_long_ptr;
		//NOT USED SO FAR
		//source_short *source_short_ptr;
		source_long *source_long_ptr;
		
		dest_short *dest_short_ptr;
		dest_long *dest_long_ptr;
		
		//CHECK IMPLEMENT
		//intra_pan_source_short *intra_pan_source_short_ptr; 
		//intra_pan_source_long *intra_pan_source_long_ptr;
		
		destination_address=get_fc2_dest_addr(pdu->frame_control2);
		source_address=get_fc2_source_addr(pdu->frame_control2);
		
		//decrement buffer count
		atomic buffer_count --;
		
		switch(destination_address)
		{
			case LONG_ADDRESS: addressing_fields_length = DEST_LONG_LEN;
								dest_long_ptr = (dest_long *) &pdu->data[0];
								if(dest_long_ptr->destination_address0 !=aExtendedAddress0 && dest_long_ptr->destination_address1 !=aExtendedAddress1)
								{
									printfUART("NOT FOR ME","");
									return;
								}
								
								break;
			case SHORT_ADDRESS: addressing_fields_length = DEST_SHORT_LEN;
								dest_short_ptr= (dest_short *) &pdu->data[0];
								//destination command not for me
								if (dest_short_ptr->destination_address != mac_PIB.macShortAddress && dest_short_ptr->destination_address !=0xffff)
								{
									printfUART("NOT FOR ME","");
									//////////printfUART("NOT FOR ME %x me %e\n", dest_short_ptr->destination_address,mac_PIB.macShortAddress); 
									return;
								}
								break;
		}
		switch(source_address)
		{
			case LONG_ADDRESS: addressing_fields_length = addressing_fields_length + SOURCE_LONG_LEN;
								break;
			case SHORT_ADDRESS: addressing_fields_length = addressing_fields_length + SOURCE_SHORT_LEN;
								break;
		}

		cmd_type = pdu->data[addressing_fields_length];
		
				
		switch(cmd_type)
		{
		
		case CMD_ASSOCIATION_REQUEST: 	
									//check if association is allowed, if not discard the frame		
									
									//////printfUART("CMD_ASSOCIATION_REQUEST \n", "");
									
										
											if (mac_PIB.macAssociationPermit == 0 )
											{
												//////////printfUART("Association not alowed\n", "");
												if ( get_fc1_ack_request(pdu->frame_control1) == 1 ) 
												{
													build_ack(pdu->seq_num,0);
												}
												return;
											}
											
											if ( PANCoordinator==0 )
											{
												//////////printfUART("i�m not a pan\n", ""); 
												return;
											}
									atomic{
											source_long_ptr = (source_long *) &pdu->data[DEST_SHORT_LEN];
											
											SrcAddr[1] =source_long_ptr->source_address0;
											SrcAddr[0] =source_long_ptr->source_address1;
											
											
											signal MLME_ASSOCIATE.indication(SrcAddr, pdu->data[addressing_fields_length+1] , 0, 0);

											}
											
											if ( get_fc1_ack_request(pdu->frame_control1) == 1 ) 
											{
												build_ack(pdu->seq_num,1);
											}	

											
									break;
		
		case CMD_ASSOCIATION_RESPONSE: atomic{
												printfUART("CMD_ASSOCIATION_RESPONSE\n", ""); 
												
												associating =0;
												call T_ResponseWaitTime.stop();
												
												if ( get_fc1_ack_request(pdu->frame_control1) == 1 ) 
												{
													build_ack(pdu->seq_num,0);
												}
											
												signal MLME_ASSOCIATE.confirm((uint16_t)(pdu->data[addressing_fields_length+1] + (pdu->data[addressing_fields_length+2] << 8)), pdu->data[addressing_fields_length+3]);
												}
										break;

		case CMD_DISASSOCIATION_NOTIFICATION: 	//////////printfUART("Received CMD_DISASSOCIATION_NOTIFICATION\n", ""); 
												
												if ( get_fc1_ack_request(pdu->frame_control1) == 1 ) 
												{
													build_ack(pdu->seq_num,0);
												}
												
												process_dissassociation_notification(pdu);
												break;
		case CMD_DATA_REQUEST: 
								//printfUART("CMD_DATA_REQUEST\n", ""); 
									//////printfUART("DR\n", "");
									if ( get_fc1_ack_request(pdu->frame_control1) == 1 ) 
									{
										//TODO
										//Problems with consecutive reception of messages
										
										build_ack(pdu->seq_num,0);
									}
									
									//cmd_data_request_0_3_reception = (cmd_data_request_0_3 *) pdu->data;
									
									source_long_ptr = (source_long *) &pdu->data[0];
											
									SrcAddr[1] =source_long_ptr->source_address0;
									SrcAddr[0] =source_long_ptr->source_address1;
									
									send_ind_trans_addr(SrcAddr);

								break;
		case CMD_PANID_CONFLICT:
								break;
								
		case CMD_ORPHAN_NOTIFICATION:
									//printfUART("CMD_ORPHAN_NOTIFICATION\n", ""); 
									
									source_long_ptr = (source_long *) &pdu->data[DEST_SHORT_LEN];
											
									SrcAddr[1] =source_long_ptr->source_address0;
									SrcAddr[0] =source_long_ptr->source_address1;
									
									signal MLME_ORPHAN.indication(SrcAddr, 0x00,0x00);
								
		
								break;
		case CMD_BEACON_REQUEST:
								break;
		case CMD_COORDINATOR_REALIGNMENT:
									printfUART("CMD_COORDINATOR_REALIGNMENT\n", ""); 
									
									process_coordinator_realignment(pdu);
									
								break;
		case CMD_GTS_REQUEST: 	
								////////////printfUART("Received CMD_GTS_REQUEST\n", ""); 
								if ( get_fc1_ack_request(pdu->frame_control1) == 1 ) 
								{
									build_ack(pdu->seq_num,0);
								}
								process_gts_request(pdu);
								break;
		default: break;

		}

return;
}

void indication_ack(MPDU *pdu, int8_t ppduLinkQuality)
{
	//decrement buffer count

	atomic buffer_count --;

	////////////printfUART("ACK Received\n",""); 
	
	atomic{
			if (send_ack_check == 1 && ack_sequence_number_check == pdu->seq_num)
			{
				//transmission SUCCESS
				call T_ackwait.stop();
				
				send_buffer_count --;
				send_buffer_msg_out++;
				
				//failsafe
				if(send_buffer_count > SEND_BUFFER_SIZE)
				{
					send_buffer_count =0;
					send_buffer_msg_out=0;
					send_buffer_msg_in=0;
				}
				
				if (send_buffer_msg_out == SEND_BUFFER_SIZE)
					send_buffer_msg_out=0;
				
				//received an ack for the association request
				if( associating == 1 && association_cmd_seq_num == pdu->seq_num )
				{
					//////////printfUART("ASSOC ACK\n",""); 
					call T_ResponseWaitTime.startOneShot(response_wait_time);
					//call T_ResponseWaitTime.start(TIMER_ONE_SHOT, response_wait_time);
				}
				
				if (gts_request == 1 && gts_request_seq_num == pdu->seq_num)
				{
				
					call T_ResponseWaitTime.startOneShot(response_wait_time);
					//call T_ResponseWaitTime.start(TIMER_ONE_SHOT, response_wait_time);
				}
				
				//////////printfUART("TRANSMISSION SUCCESS\n",""); 

				if (send_indirect_transmission > 0 )
				{	//the message send was indirect
					//remove the message from the indirect transmission queue
					indirect_trans_queue[send_indirect_transmission-1].handler=0x00;
					indirect_trans_count--;
					//////////printfUART("SU id:%i ct:%i\n", send_indirect_transmission,indirect_trans_count);
				}
				
				send_ack_check=0;
				retransmit_count=0;
				ack_sequence_number_check=0;
				
				
				if (send_buffer_count > 0)
					post send_frame_csma();
				
				
			}
		}
	
			//CHECK
		if (get_fc1_frame_pending(pdu->frame_control1) == 1 && pending_request_data ==1)// && associating == 1
		{		
				//////////printfUART("Frame_pending\n",""); 
				pending_request_data=0;
				create_data_request_cmd();
		}
		
		//GTS mechanism, after the confirmation of the GTS request, must check if the beacon has the gts
		/*
		if (gts_ack == 1)
		{
			gts_ack=0;
			gts_confirm=1;
			call T_ResponseWaitTime.stop();
		
		}
	*/
		if(gts_send_pending_data==1)
			post start_gts_send();
		
		if(coordinator_gts_send_pending_data==1 && coordinator_gts_send_time_slot == number_time_slot)
			post start_coordinator_gts_send();
	
return;
}


void process_dissassociation_notification(MPDU *pdu)
{
atomic{
		cmd_disassociation_notification *mac_disassociation_notification;
		
		//creation of a pointer to the disassociation notification structure
		mac_disassociation_notification = (cmd_disassociation_notification*) pdu->data;									

		signal MLME_DISASSOCIATE.indication(&mac_disassociation_notification->source_address0, mac_disassociation_notification->disassociation_reason, 0, 0);
		}

return;
}




void process_coordinator_realignment(MPDU *pdu)
{

atomic{
	cmd_coord_realignment *cmd_realignment = 0;
	
	dest_long *dest_long_ptr=0;
	source_short *source_short_ptr=0;

	cmd_realignment = (cmd_coord_realignment*) &pdu->data[DEST_LONG_LEN + SOURCE_SHORT_LEN];
	
	//creation of a pointer the addressing structures
	dest_long_ptr = (dest_long *) &pdu->data[0];
	source_short_ptr = (source_short *) &pdu->data[DEST_LONG_LEN];
		
	mac_PIB.macCoordShortAddress = ((cmd_realignment->coordinator_short_address0 << 8) | cmd_realignment->coordinator_short_address0 );
	mac_PIB.macShortAddress = cmd_realignment->short_address;
	
	
	printfUART("PCR %i %i\n",mac_PIB.macCoordShortAddress,mac_PIB.macShortAddress); 
	
	}
return;
}


/*****************************************************************************************************/
/*****************************************************************************************************/
/*****************************************************************************************************/
/************************		BUILD FRAMES FUNCTIONS   			**********************************/
/*****************************************************************************************************/ 
/*****************************************************************************************************/
/*****************************************************************************************************/


task void create_beacon()
{
	int i=0;
	uint8_t packet_length = 25;
	int data_count=0;
	int pending_data_index=0;
	MPDU* pkt_ptr=0;
	//pending frames
	uint8_t short_addr_pending=0;
	uint8_t long_addr_pending=0;
		
	uint8_t gts_directions=0x00;
	
	uint16_t frame_control;

	
	atomic{
		
		beacon_addr_short *mac_beacon_addr_short_ptr;
		//mac_beacon_addr_short_ptr = (beacon_addr_short*) &mac_txmpdu.data[0];
		mac_beacon_addr_short_ptr = (beacon_addr_short*) &mac_beacon_txmpdu.data[0];
		//call PLME_SET_TRX_STATE.request(PHY_TX_ON);
		
		mac_beacon_txmpdu_ptr->length = 15;
		
		frame_control = set_frame_control(TYPE_BEACON,0,0,0,1,SHORT_ADDRESS,SHORT_ADDRESS);
		
		mac_beacon_txmpdu_ptr->frame_control1 = (uint8_t)( frame_control);
		
		mac_beacon_txmpdu_ptr->frame_control2 = (uint8_t)( frame_control >> 8);
		
		//mac_beacon_txmpdu_ptr->frame_control = set_frame_control(TYPE_BEACON,0,0,0,1,SHORT_ADDRESS,SHORT_ADDRESS);
		mac_beacon_txmpdu_ptr->seq_num = mac_PIB.macBSN;
		mac_PIB.macBSN++;
		
		
		//relocation error
		mac_beacon_addr_short_ptr->destination_PAN_identifier= mac_PIB.macPANId;
		//relocation error
		mac_beacon_addr_short_ptr->destination_address = 0xffff;
		//relocation error
		mac_beacon_addr_short_ptr->source_address = mac_PIB.macShortAddress;
		if (mac_PIB.macShortAddress == 0x0000)
		{	//the device is the PAN Coordinator
			mac_beacon_addr_short_ptr->superframe_specification = set_superframe_specification(mac_PIB.macBeaconOrder,(uint8_t)mac_PIB.macSuperframeOrder,final_CAP_slot,0,1,mac_PIB.macAssociationPermit);
		}
		else
		{
			mac_beacon_addr_short_ptr->superframe_specification = set_superframe_specification(mac_PIB.macBeaconOrder,(uint8_t)mac_PIB.macSuperframeOrder,final_CAP_slot,0,1,mac_PIB.macAssociationPermit);
		}
		
		mac_beacon_txmpdu_ptr->data[8] = set_gts_specification(GTS_descriptor_count,mac_PIB.macGTSPermit);
		
		mac_beacon_txmpdu_ptr->data[9] = set_pending_address_specification(short_addr_pending,long_addr_pending);
		
		data_count = 9;
		packet_length = 15;
		
		
		//BUILDING the GTS DESCRIPTORS
		if( (GTS_descriptor_count + GTS_null_descriptor_count) > 0 )
		{
			data_count++;
					
			for(i=0; i< 7 ; i++)
			{
				if( GTS_db[i].gts_id != 0x00 && GTS_db[i].DevAddressType != 0x0000) 
				{
					
					mac_beacon_txmpdu_ptr->data[data_count] = GTS_db[i].DevAddressType;
					////////////printfUART("B gts %i\n", (GTS_db[i].DevAddressType >> 8 ) ); 
					
					data_count++;
					mac_beacon_txmpdu_ptr->data[data_count] = (GTS_db[i].DevAddressType >> 8 );
					////////////printfUART("B gts %i\n",  GTS_db[i].DevAddressType ); 
					
					data_count++;
					
					mac_beacon_txmpdu_ptr->data[data_count] = set_gts_descriptor(15-i,GTS_db[i].length);
					data_count++;
					////printfUART("B gts %i\n", set_gts_descriptor(GTS_db[i].starting_slot,GTS_db[i].length) ); 
					
					packet_length = packet_length + 3;
					
					if ( GTS_db[i].direction == 1 )
					{
						gts_directions = gts_directions | (1 << i); 
					}
					else
					{
						gts_directions = gts_directions | (0 << i); 
					}
					////printfUART("dir %i\n", gts_directions); 
				}
			}
			mac_beacon_txmpdu_ptr->data[9] = gts_directions;
			//CHECK
			packet_length++;
			//BUILDING the NULL GTS DESCRIPTORS
			if ( GTS_null_descriptor_count > 0 )
			{
				for(i=0; i< 7 ; i++)
				{
					if( GTS_null_db[i].DevAddressType != 0x0000) 
					{
						mac_beacon_txmpdu_ptr->data[data_count] = GTS_null_db[i].DevAddressType;
						////////////printfUART("B gts %i\n", (GTS_db[i].DevAddressType >> 8 ) ); 
						data_count++;
						mac_beacon_txmpdu_ptr->data[data_count] = (GTS_null_db[i].DevAddressType >> 8 );
						////////////printfUART("B gts %i\n",  GTS_db[i].DevAddressType ); 
						data_count++;
						mac_beacon_txmpdu_ptr->data[data_count] = 0x00;
						data_count++;
						////////////printfUART("B gts %i\n", set_gts_descriptor(GTS_db[i].starting_slot,GTS_db[i].length) ); 
						packet_length = packet_length +3;
					}
				}
			}
			//resetting the GTS specification field
			mac_beacon_txmpdu_ptr->data[8] = set_gts_specification(GTS_descriptor_count + GTS_null_descriptor_count,mac_PIB.macGTSPermit);
			

		}

			pending_data_index = data_count;
			data_count++;
		//IMPLEMENT PENDING ADDRESSES
		//temporary
		//indirect_trans_count =0;
		
		if (indirect_trans_count > 0 )
		{
				//IMPLEMENT THE PENDING ADDRESSES CONSTRUCTION

			for(i=0;i<INDIRECT_BUFFER_SIZE;i++)
			{
				if (indirect_trans_queue[i].handler > 0x00)
				{
					pkt_ptr = (MPDU *)&indirect_trans_queue[i].frame;
					//ADD INDIRECT TRANSMISSION DESCRIPTOR
					if(get_fc2_dest_addr(pkt_ptr->frame_control2) == SHORT_ADDRESS)
					{
						short_addr_pending++;
						packet_length = packet_length + 2;
						mac_beacon_txmpdu_ptr->data[data_count]=pkt_ptr->data[2];
						data_count++;
						mac_beacon_txmpdu_ptr->data[data_count]=pkt_ptr->data[3];
						data_count++;
					}
				}
			}
			for(i=0;i<INDIRECT_BUFFER_SIZE;i++)
			{
				if (indirect_trans_queue[i].handler > 0x00)
				{
					if(get_fc2_dest_addr(pkt_ptr->frame_control2) == LONG_ADDRESS)
					{
						long_addr_pending++;
						packet_length = packet_length + 8;

						mac_beacon_txmpdu_ptr->data[data_count]=pkt_ptr->data[0];
						data_count++;
						mac_beacon_txmpdu_ptr->data[data_count]=pkt_ptr->data[1];
						data_count++;
						mac_beacon_txmpdu_ptr->data[data_count]=pkt_ptr->data[2];
						data_count++;
						mac_beacon_txmpdu_ptr->data[data_count]=pkt_ptr->data[3];
						data_count++;
						mac_beacon_txmpdu_ptr->data[data_count]=pkt_ptr->data[4];
						data_count++;
						mac_beacon_txmpdu_ptr->data[data_count]=pkt_ptr->data[5];
						data_count++;
						mac_beacon_txmpdu_ptr->data[data_count]=pkt_ptr->data[6];
						data_count++;
						mac_beacon_txmpdu_ptr->data[data_count]=pkt_ptr->data[7];
						data_count++;
						
					}
				}
			}
				
		}
		mac_beacon_txmpdu_ptr->data[pending_data_index] = set_pending_address_specification(short_addr_pending,long_addr_pending);
		
		/*
		//adding the beacon payload
		if (mac_PIB.macBeaconPayloadLenght > 0 )
		{
			for (i=0;i < mac_PIB.macBeaconPayloadLenght;i++)
			{
				mac_beacon_txmpdu_ptr->data[data_count] = mac_PIB.macBeaconPayload[i];
				data_count++;
				packet_length++;
			}
		
		
		}
		*/
		mac_beacon_txmpdu_ptr->data[data_count] = 0x12;
		data_count++;
		packet_length++;
		mac_beacon_txmpdu_ptr->data[data_count] = 0x34;
		data_count++;
		packet_length++;
		
		//short_addr_pending=0;
		//long_addr_pending=0;
		
		mac_beacon_txmpdu_ptr->length = packet_length;
		
		send_beacon_length = packet_length;
		
		send_beacon_frame_ptr = (uint8_t*)mac_beacon_txmpdu_ptr;
		}
}


void create_data_frame(uint8_t SrcAddrMode, uint16_t SrcPANId, uint32_t SrcAddr[], uint8_t DstAddrMode, uint16_t DestPANId, uint32_t DstAddr[], uint8_t msduLength, uint8_t msdu[],uint8_t msduHandle, uint8_t TxOptions,uint8_t on_gts_slot,uint8_t pan)
{
	
	int i_indirect_trans=0;

	dest_short *dest_short_ptr;
	dest_long *dest_long_ptr;
	
	source_short *source_short_ptr;
	source_long *source_long_ptr;

	//intra_pan_source_short *intra_pan_source_short_ptr;
	//intra_pan_source_long *intra_pan_source_long_ptr;
	
	//CHECK
	uint8_t intra_pan=0;
	uint8_t data_len=0;
	
	uint8_t current_gts_element_count=0;
	
	MPDU *frame_pkt=0;
	
	uint16_t frame_control;
	
	//printfUART("create df\n","");
	
	//decision of the buffer where to store de packet creation
	if (on_gts_slot > 0 )
	{
	
		if (PANCoordinator == 1)
		{
		//setting the coordinator gts frame pointer
			
			//get the number of frames in the gts_slot_list
			atomic current_gts_element_count = gts_slot_list[15-on_gts_slot].element_count;
			
			//////////printfUART("element count %i\n",gts_slot_list[15-on_gts_slot].element_count);
			
			if (current_gts_element_count  == GTS_SEND_BUFFER_SIZE || available_gts_index_count == 0)
			{
				//////////printfUART("FULL\n","");
				signal MCPS_DATA.confirm(0x00, MAC_TRANSACTION_OVERFLOW);
				return;
			}
			else
			{
				frame_pkt = (MPDU *) &gts_send_buffer[available_gts_index[available_gts_index_count]];
			}
			
		}
		else
		{
		//setting the device gts frame pointer
			////////////printfUART("start creation %i %i %i \n",gts_send_buffer_count,gts_send_buffer_msg_in,gts_send_buffer_msg_out);
		
			if(gts_send_buffer_count == GTS_SEND_BUFFER_SIZE)
			{
				signal MCPS_DATA.confirm(0x00, MAC_TRANSACTION_OVERFLOW);
				return;
			}
			if (gts_send_buffer_msg_in == GTS_SEND_BUFFER_SIZE)
				gts_send_buffer_msg_in=0;
			
				frame_pkt = (MPDU *) &gts_send_buffer[gts_send_buffer_msg_in];
		
		}
	}
	else
	{
	
		if ( get_txoptions_indirect_transmission(TxOptions) == 1)
		{
			
			//CREATE THE INDIRECT TRANSMISSION PACKET POINTER
			//check if the is enough space to store the indirect transaction
			if (indirect_trans_count == INDIRECT_BUFFER_SIZE)
			{
				signal MCPS_DATA.confirm(0x00, MAC_TRANSACTION_OVERFLOW);
				//////////printfUART("buffer full %i\n", indirect_trans_count);
				return;
			}
			
			for(i_indirect_trans=0;i_indirect_trans<INDIRECT_BUFFER_SIZE;i_indirect_trans++)
			{
				if (indirect_trans_queue[i_indirect_trans].handler == 0x00)
				{
					frame_pkt = (MPDU *) &indirect_trans_queue[i_indirect_trans].frame;
					break;
				}
			}
			
			
		}
		else
		{
			//CREATE NORMAL TRANSMISSION PACKET POINTER
				////printfUART("sb  %i\n", send_buffer_count);
			atomic{
			
			//TDBS Implementation
			if (get_txoptions_upstream_buffer(TxOptions) == 1)
			{
				////printfUART("sel up\n", "");
				
				if (upstream_buffer_count > UPSTREAM_BUFFER_SIZE)
					return;
				
				if(upstream_buffer_msg_in == UPSTREAM_BUFFER_SIZE)
					upstream_buffer_msg_in=0;
				
				frame_pkt = (MPDU *) &upstream_buffer[upstream_buffer_msg_in];
				
			}
			else
			{

				////printfUART("sb  %i\n", send_buffer_count);
			
				if ((send_buffer_count +1) > SEND_BUFFER_SIZE)	
					return;
			
				if (send_buffer_msg_in == SEND_BUFFER_SIZE)
					send_buffer_msg_in=0;
		
				frame_pkt = (MPDU *) &send_buffer[send_buffer_msg_in];
			}
			
			}
			

		}
	}
	
atomic{

	if (intra_pan == 0 )
	{
	
		if ( DstAddrMode > 1 && SrcAddrMode > 1 )
		{
			// Destination LONG - Source LONG	
			if (DstAddrMode == LONG_ADDRESS && SrcAddrMode == LONG_ADDRESS)
			{
				dest_long_ptr = (dest_long *) &frame_pkt->data[0];
				source_long_ptr = (source_long *) &frame_pkt->data[DEST_LONG_LEN];
				
				dest_long_ptr->destination_PAN_identifier=DestPANId;
				dest_long_ptr->destination_address0=DstAddr[1];
				dest_long_ptr->destination_address1=DstAddr[0];
				
				source_long_ptr->source_PAN_identifier=SrcPANId;
				source_long_ptr->source_address0=SrcAddr[1];
				source_long_ptr->source_address1=SrcAddr[0];
				
				data_len = 20;
			}
			
			// Destination SHORT - Source LONG
			if ( DstAddrMode == SHORT_ADDRESS && SrcAddrMode == LONG_ADDRESS )
			{
				dest_short_ptr = (dest_short *) &frame_pkt->data[0];
				source_long_ptr = (source_long *) &frame_pkt->data[DEST_SHORT_LEN];
				
				dest_short_ptr->destination_PAN_identifier=DestPANId;
				dest_short_ptr->destination_address=(uint16_t)DstAddr[1];
				
				source_long_ptr->source_PAN_identifier=SrcPANId;
				source_long_ptr->source_address0=SrcAddr[1];
				source_long_ptr->source_address1=SrcAddr[0];
				
				data_len = 14;
			}
			// Destination LONG - Source SHORT
			if ( DstAddrMode == LONG_ADDRESS && SrcAddrMode == SHORT_ADDRESS )
			{
				dest_long_ptr = (dest_long *) &frame_pkt->data[0];
				source_short_ptr = (source_short *) &frame_pkt->data[DEST_LONG_LEN];
				
				dest_long_ptr->destination_PAN_identifier=DestPANId;
				dest_long_ptr->destination_address0=DstAddr[1];
				dest_long_ptr->destination_address1=DstAddr[0];
				
				source_short_ptr->source_PAN_identifier=SrcPANId;
				source_short_ptr->source_address=(uint16_t)SrcAddr[1];
				
				data_len = 14;
			}
			
			
			//Destination SHORT - Source SHORT
			if ( DstAddrMode == SHORT_ADDRESS && SrcAddrMode == SHORT_ADDRESS )	
			{
				dest_short_ptr = (dest_short *) &frame_pkt->data[0];
				source_short_ptr = (source_short *) &frame_pkt->data[DEST_SHORT_LEN];
				
				dest_short_ptr->destination_PAN_identifier=DestPANId;
				dest_short_ptr->destination_address=(uint16_t)DstAddr[1];
				
				source_short_ptr->source_PAN_identifier=SrcPANId;
				source_short_ptr->source_address=(uint16_t)SrcAddr[1];
				
				data_len = 8;
			}
		}
		
		if ( DstAddrMode == 0 && SrcAddrMode > 1 )
		{
				
			if (SrcAddrMode == LONG_ADDRESS)
			{//Source LONG
				source_long_ptr = (source_long *) &frame_pkt->data[0];
				
				source_long_ptr->source_PAN_identifier=SrcPANId;
				source_long_ptr->source_address0=SrcAddr[1];
				source_long_ptr->source_address1=SrcAddr[0];
				
				data_len = 10;
			}
			else
			{//Source SHORT

				source_short_ptr = (source_short *) &frame_pkt->data[0];
				
				source_short_ptr->source_PAN_identifier=SrcPANId;
				source_short_ptr->source_address=(uint16_t)SrcAddr[1];
				
				data_len = 4;
			}
		}
		
		if ( DstAddrMode > 1 && SrcAddrMode == 0 )
		{
			if (DstAddrMode == LONG_ADDRESS)
			{//Destination LONG
				dest_long_ptr = (dest_long *) &frame_pkt->data[0];
		
				dest_long_ptr->destination_PAN_identifier=DestPANId;
				dest_long_ptr->destination_address0=DstAddr[1];
				dest_long_ptr->destination_address1=DstAddr[0];

				data_len = 10;
			}
			else
			{//Destination SHORT
				dest_short_ptr = (dest_short *) &frame_pkt->data[0];

				dest_short_ptr->destination_PAN_identifier=DestPANId;
				dest_short_ptr->destination_address=(uint16_t)DstAddr[1];
				
				data_len = 4;
			}
		}
	}
	else
	{
	//intra_pan == 1

	}
		
		memcpy(&frame_pkt->data[data_len],&msdu[0],msduLength*sizeof(uint8_t));
		
		if(on_gts_slot > 0)
		{
			//preparing a GTS transmission
			
			////////////printfUART("GTS send slt: %i count %i %u\n",on_gts_slot,gts_slot_list[15-on_gts_slot].element_count,mac_PIB.macDSN);
			frame_pkt->length = data_len + msduLength + MPDU_HEADER_LEN;
			
			frame_control = set_frame_control(TYPE_DATA,0,0,1,intra_pan,DstAddrMode,SrcAddrMode);
			frame_pkt->frame_control1 =(uint8_t)( frame_control);
			frame_pkt->frame_control2 =(uint8_t)( frame_control >> 8);
			
			frame_pkt->seq_num = mac_PIB.macDSN;
			mac_PIB.macDSN++;
						
			//ADDING DATA TO THE GTS BUFFER
			atomic{
					if (PANCoordinator == 1)
					{
						gts_slot_list[15-on_gts_slot].element_count ++;
						gts_slot_list[15-on_gts_slot].gts_send_frame_index[gts_slot_list[15-on_gts_slot].element_in] = available_gts_index[available_gts_index_count];
						//gts_slot_list[15-on_gts_slot].length = frame_pkt->length;
						
						gts_slot_list[15-on_gts_slot].element_in ++;
						
						if (gts_slot_list[15-on_gts_slot].element_in == GTS_SEND_BUFFER_SIZE)
							gts_slot_list[15-on_gts_slot].element_in=0;
						
						available_gts_index_count --;
						
						//current_gts_pending_frame++;
					}
					else
					{
						gts_send_buffer_count++;
						gts_send_buffer_msg_in++;
						////////////printfUART("end c %i %i %i \n",gts_send_buffer_count,gts_send_buffer_msg_in,gts_send_buffer_msg_out);
					}
			}
		}
		else
		{
			//////////printfUART("CSMA send %i\n", get_txoptions_ack(TxOptions));
			frame_pkt->length = data_len + msduLength + MPDU_HEADER_LEN;
			//frame_pkt->frame_control = set_frame_control(TYPE_DATA,0,0,get_txoptions_ack(TxOptions),intra_pan,DstAddrMode,SrcAddrMode);
			
			frame_control = set_frame_control(TYPE_DATA,0,0,get_txoptions_ack(TxOptions),intra_pan,DstAddrMode,SrcAddrMode);
			frame_pkt->frame_control1 =(uint8_t)( frame_control);
			frame_pkt->frame_control2 =(uint8_t)( frame_control >> 8);
			
			frame_pkt->seq_num = mac_PIB.macDSN;
			
			//////printfUART("sqn %i\n", mac_PIB.macDSN);
			
			mac_PIB.macDSN++;
			
			if ( get_txoptions_indirect_transmission(TxOptions) == 1)
			{
					indirect_trans_queue[i_indirect_trans].handler = indirect_trans_count + 1;
					indirect_trans_queue[i_indirect_trans].transaction_persistent_time = 0x0000;
	
					indirect_trans_count++;
	
					//////////printfUART("ADDED HDL: %i ADDR: %i\n",indirect_trans_count,DstAddr[1]); 
			}
			else
			{
				if (get_txoptions_upstream_buffer(TxOptions) == 1)
				{
					upstream_buffer[upstream_buffer_msg_in].retransmission =0;
					upstream_buffer[upstream_buffer_msg_in].indirect =0;
				
					upstream_buffer_count++;
					
					upstream_buffer_msg_in++;
					
					//printfUART("up bc %i\n", upstream_buffer_count);
					post send_frame_csma_upstream();
					
				}
				else
				{
				
					//enable retransmissions
					send_buffer[send_buffer_msg_in].retransmission = 1;
					send_buffer[send_buffer_msg_in].indirect = 0;
					
					send_buffer_count++;
					
					send_buffer_msg_in++;
					
					post send_frame_csma();
				}
					
			}
			
		}
		
	}
return;
}


error_t create_association_response_cmd(uint32_t DeviceAddress[],uint16_t shortaddress, uint8_t status)
{

	cmd_association_response *mac_association_response;
	dest_long *dest_long_ptr;
	source_long *source_long_ptr;
	
	int i=0;
	
	MPDU *frame_pkt=0;
	
	uint16_t frame_control;
	
	//atomic{
	/*
			if (send_buffer_msg_in == SEND_BUFFER_SIZE)
			send_buffer_msg_in=0;
	
		frame_pkt = (MPDU *) &send_buffer[send_buffer_msg_in];
	*/
	
	//check if the is enough space to store the indirect transaction
	if (indirect_trans_count == INDIRECT_BUFFER_SIZE)
	{
		printfUART("i full","");
		return MAC_TRANSACTION_OVERFLOW;
	}
	
	for(i=0;i<INDIRECT_BUFFER_SIZE;i++)
	{
		if (indirect_trans_queue[i].handler == 0x00)
		{
			//memcpy(&indirect_trans_queue[i].frame,frame_ptr,sizeof(MPDU));
			frame_pkt = (MPDU *) &indirect_trans_queue[i].frame;
			printfUART("found slot","");
			break;
		}
	}
	
	//creation of a pointer to the association response structure
	dest_long_ptr = (dest_long *) &frame_pkt->data[0];
	source_long_ptr = (source_long *) &frame_pkt->data[DEST_LONG_LEN];
	
	mac_association_response = (cmd_association_response *) &frame_pkt->data[DEST_LONG_LEN + SOURCE_LONG_LEN];									
	
	frame_pkt->length = 29;
	//frame_pkt->frame_control = set_frame_control(TYPE_CMD,0,0,1,0,LONG_ADDRESS,LONG_ADDRESS);
	
	frame_control = set_frame_control(TYPE_CMD,0,0,1,0,LONG_ADDRESS,LONG_ADDRESS);
	
	frame_pkt->frame_control1 =(uint8_t)( frame_control);
	frame_pkt->frame_control2 =(uint8_t)( frame_control >> 8);
	
	frame_pkt->seq_num = mac_PIB.macDSN;
	mac_PIB.macDSN++;
	
	dest_long_ptr->destination_PAN_identifier = mac_PIB.macPANId;

	dest_long_ptr->destination_address0 = DeviceAddress[1];
	dest_long_ptr->destination_address1 = DeviceAddress[0];
	
	source_long_ptr->source_PAN_identifier = mac_PIB.macPANId;
	
	source_long_ptr->source_address0 = aExtendedAddress0;
	source_long_ptr->source_address1 = aExtendedAddress1;

	mac_association_response->command_frame_identifier = CMD_ASSOCIATION_RESPONSE;
	
	//mac_association_response->short_address = shortaddress;
	mac_association_response->short_address1 = (uint8_t)(shortaddress);
	mac_association_response->short_address2 = (uint8_t)(shortaddress >> 8);


	mac_association_response->association_status = status;
/*

		//increment the send buffer variables
		send_buffer_count++;
		send_buffer_msg_in++;
			}	
		post send_frame_csma();
*/
	printfUART("ASS RESP S: %i\n",shortaddress); 

	indirect_trans_queue[i].handler = indirect_trans_count+1;

	indirect_trans_queue[i].transaction_persistent_time = 0x0000;
	
	indirect_trans_count++;
	
	printfUART("IAD\n", "");

return MAC_SUCCESS;
}


void create_association_request_cmd(uint8_t CoordAddrMode,uint16_t CoordPANId,uint32_t CoordAddress[],uint8_t CapabilityInformation)
{
atomic{

		cmd_association_request *cmd_association_request_ptr;
		dest_short *dest_short_ptr;
		source_long *source_long_ptr;
	
		MPDU *frame_pkt=0;
		
		uint16_t frame_control;
		
		if (send_buffer_msg_in == SEND_BUFFER_SIZE)
			send_buffer_msg_in=0;
	
		frame_pkt = (MPDU *) &send_buffer[send_buffer_msg_in];
		
		//creation of a pointer to the association response structure
		dest_short_ptr = (dest_short *) &frame_pkt->data[0];
		source_long_ptr = (source_long *) &frame_pkt->data[DEST_SHORT_LEN];
		
		cmd_association_request_ptr = (cmd_association_request *) &send_buffer[send_buffer_msg_in].data[DEST_SHORT_LEN + SOURCE_LONG_LEN];
		
		frame_pkt->length = 21;
		//frame_pkt->frame_control = set_frame_control(TYPE_CMD,0,0,1,0,SHORT_ADDRESS,LONG_ADDRESS);
		
		frame_control = set_frame_control(TYPE_CMD,0,0,1,0,SHORT_ADDRESS,LONG_ADDRESS);
		frame_pkt->frame_control1 =(uint8_t)( frame_control);
		frame_pkt->frame_control2 =(uint8_t)( frame_control >> 8);
		
		frame_pkt->seq_num = mac_PIB.macDSN;
		
		association_cmd_seq_num =  mac_PIB.macDSN;
		
		mac_PIB.macDSN++;
		
		//enable retransmissions
		send_buffer[send_buffer_msg_in].retransmission =1;
		send_buffer[send_buffer_msg_in].indirect = 0;
		
		dest_short_ptr->destination_PAN_identifier = CoordPANId; //mac_PIB.macPANId;
		
		if (CoordAddrMode == SHORT_ADDRESS )
		{
			dest_short_ptr->destination_address = (uint16_t)(CoordAddress[1] & 0x000000ff) ;  //mac_PIB.macPANId;
		}
		else
		{
		//CHECK
		
		//implement the long address version
		
		}
		
		source_long_ptr->source_PAN_identifier = 0xffff;
		
		source_long_ptr->source_address0 = aExtendedAddress0;
		source_long_ptr->source_address1 = aExtendedAddress1;
		
		cmd_association_request_ptr->command_frame_identifier = CMD_ASSOCIATION_REQUEST;
		
		cmd_association_request_ptr->capability_information = CapabilityInformation;

		//increment the send buffer variables
		send_buffer_count++;
		send_buffer_msg_in++;
		
		pending_request_data=1;
		
		////printfUART("Association request %i %i \n", send_buffer_count,send_buffer_msg_in);
		
		
		post send_frame_csma();

	}
return;
}

void create_data_request_cmd()
{
	//////////printfUART("create_data_request_cmd\n", ""); 

atomic{
		//dest_short *dest_short_ptr;
		source_long *source_long_ptr;

		
		MPDU *frame_pkt;
		
		uint16_t frame_control;
		
		if (send_buffer_msg_in == SEND_BUFFER_SIZE)
			send_buffer_msg_in=0;
	
		frame_pkt = (MPDU *) &send_buffer[send_buffer_msg_in];
	
	
		source_long_ptr= (source_long *) &send_buffer[send_buffer_msg_in].data[0];
	
		//creation of a pointer to the association response structure
		//dest_short_ptr = (dest_short *) &frame_pkt->data[0];
		source_long_ptr = (source_long *) &frame_pkt->data[0];
	
	
		frame_pkt->length = 16;							
		//frame_pkt->frame_control = set_frame_control(TYPE_CMD,0,0,1,1,0,LONG_ADDRESS);   //dest | source
		
		frame_control = set_frame_control(TYPE_CMD,0,0,1,1,0,LONG_ADDRESS);
		frame_pkt->frame_control1 =(uint8_t)( frame_control);
		frame_pkt->frame_control2 =(uint8_t)( frame_control >> 8);
		
		frame_pkt->seq_num = mac_PIB.macDSN;
		
		mac_PIB.macDSN++;
		
		//enable retransmissions
		send_buffer[send_buffer_msg_in].retransmission =1;
		send_buffer[send_buffer_msg_in].indirect = 0;
		
		
		source_long_ptr->source_PAN_identifier = mac_PIB.macPANId;
		
		source_long_ptr->source_address0 = aExtendedAddress0;//aExtendedAddress0;
		source_long_ptr->source_address1 = aExtendedAddress1;
		
		//command_frame_identifier = CMD_DATA_REQUEST;
		frame_pkt->data[SOURCE_LONG_LEN]=CMD_DATA_REQUEST;
		
		//increment the send buffer variables
		send_buffer_count++;
		send_buffer_msg_in++;
				
		post send_frame_csma();
		
		
		}
return;
}

void create_beacon_request_cmd()
{

atomic{
		cmd_beacon_request *mac_beacon_request;
	
		MPDU *frame_pkt;
		
		uint16_t frame_control;
		
		if (send_buffer_msg_in == SEND_BUFFER_SIZE)
			send_buffer_msg_in=0;
	
		frame_pkt = (MPDU *) &send_buffer[send_buffer_msg_in];
	
		mac_beacon_request= (cmd_beacon_request*) &send_buffer[send_buffer_msg_in].data;
	
		frame_pkt->length = 10;							
		//frame_pkt->frame_control = set_frame_control(TYPE_CMD,0,0,0,0,SHORT_ADDRESS,0);   //dest | source
		
		frame_control = set_frame_control(TYPE_CMD,0,0,0,0,SHORT_ADDRESS,0);
		frame_pkt->frame_control1 =(uint8_t)( frame_control);
		frame_pkt->frame_control2 =(uint8_t)( frame_control >> 8);
		
		frame_pkt->seq_num = mac_PIB.macDSN;
		
		mac_PIB.macDSN++;
		
		//enable retransmissions
		send_buffer[send_buffer_msg_in].retransmission =1;
		send_buffer[send_buffer_msg_in].indirect = 0;
		
		mac_beacon_request->destination_PAN_identifier = 0xffff;
		
		mac_beacon_request->destination_address = 0xffff;
	
		mac_beacon_request->command_frame_identifier = CMD_BEACON_REQUEST;
		
		
		//increment the send buffer variables
		send_buffer_count++;
		send_buffer_msg_in++;
		
		post send_frame_csma();

		}

return;
}

void create_orphan_notification()
{

	atomic{
	
		cmd_default *cmd_orphan_notification=0;
		
		dest_short *dest_short_ptr=0;
		source_long *source_long_ptr=0;

		MPDU *frame_pkt=0;
			
		uint16_t frame_control=0;
		
		if (send_buffer_msg_in == SEND_BUFFER_SIZE)
			send_buffer_msg_in=0;
	
		frame_pkt = (MPDU *) &send_buffer[send_buffer_msg_in];
		
		frame_pkt->length = 20;							
				
		cmd_orphan_notification = (cmd_default*) &send_buffer[send_buffer_msg_in].data[DEST_SHORT_LEN + SOURCE_LONG_LEN];
		
		//creation of a pointer the addressing structures
		dest_short_ptr = (dest_short *) &frame_pkt->data[0];
		source_long_ptr = (source_long *) &frame_pkt->data[DEST_SHORT_LEN];
		
		
		frame_control = set_frame_control(TYPE_CMD,0,0,0,0,SHORT_ADDRESS,LONG_ADDRESS);
		frame_pkt->frame_control1 =(uint8_t)( frame_control);
		frame_pkt->frame_control2 =(uint8_t)( frame_control >> 8);
		
		
		frame_pkt->seq_num = mac_PIB.macDSN;
		
		mac_PIB.macDSN++;
		
		
		dest_short_ptr->destination_PAN_identifier = 0xffff; //mac_PIB.macPANId;
		
		dest_short_ptr->destination_address = 0xffff ;  //mac_PIB.macPANId;
		
		source_long_ptr->source_PAN_identifier = 0xffff;
		
		source_long_ptr->source_address0 = aExtendedAddress0;
		source_long_ptr->source_address1 = aExtendedAddress1;
				
		
		cmd_orphan_notification->command_frame_identifier = CMD_ORPHAN_NOTIFICATION;
		
		//increment the send buffer variables
		send_buffer_count++;
		send_buffer_msg_in++;
		
		post send_frame_csma();
	}

return;
}


void create_coordinator_realignment_cmd(uint32_t device_extended0, uint32_t device_extended1, uint16_t device_short_address)
{

atomic{

	cmd_coord_realignment *cmd_realignment =0;
	
	dest_long *dest_long_ptr=0;
	source_short *source_short_ptr=0;
	
	MPDU *frame_pkt=0;
	
	uint16_t frame_control=0;
	
	if (send_buffer_msg_in == SEND_BUFFER_SIZE)
		send_buffer_msg_in=0;

	frame_pkt = (MPDU *) &send_buffer[send_buffer_msg_in];
	
	frame_pkt->length = 27;							
	//frame_pkt->frame_control = set_frame_control(TYPE_CMD,0,0,0,0,SHORT_ADDRESS,0);   //dest | source
	
	cmd_realignment = (cmd_coord_realignment*) &send_buffer[send_buffer_msg_in].data[DEST_LONG_LEN + SOURCE_SHORT_LEN];
	
	//creation of a pointer the addressing structures
	dest_long_ptr = (dest_long *) &frame_pkt->data[0];
	source_short_ptr = (source_short *) &frame_pkt->data[DEST_LONG_LEN];

	
	frame_control = set_frame_control(TYPE_CMD,0,0,0,0,LONG_ADDRESS,SHORT_ADDRESS);
	frame_pkt->frame_control1 =(uint8_t)( frame_control);
	frame_pkt->frame_control2 =(uint8_t)( frame_control >> 8);
		
	frame_pkt->seq_num = mac_PIB.macDSN;
	
	mac_PIB.macDSN++;
	
	dest_long_ptr->destination_PAN_identifier = 0xffff;
	dest_long_ptr->destination_address0 = device_extended0;
	dest_long_ptr->destination_address1 = device_extended1;
	
	source_short_ptr->source_PAN_identifier = mac_PIB.macPANId;
	source_short_ptr->source_address = mac_PIB.macCoordShortAddress;
	
	
	cmd_realignment->command_frame_identifier = CMD_COORDINATOR_REALIGNMENT;
	
	mac_PIB.macPANId = 0x1234;
	
	mac_PIB.macCoordShortAddress =0x0000;
	
	cmd_realignment->PAN_identifier0 = (mac_PIB.macPANId);
	cmd_realignment->PAN_identifier1 = (mac_PIB.macPANId >> 8);

	cmd_realignment->coordinator_short_address0 = (mac_PIB.macCoordShortAddress);
	cmd_realignment->coordinator_short_address1 = (mac_PIB.macCoordShortAddress >> 8);
	
	cmd_realignment->logical_channel = LOGICAL_CHANNEL;
	cmd_realignment->short_address = device_short_address;

	
	//increment the send buffer variables
	send_buffer_count++;
	send_buffer_msg_in++;
	
	post send_frame_csma();

	}

return;
}


void create_gts_request_cmd(uint8_t gts_characteristics)
{
atomic{
		cmd_gts_request *mac_gts_request;
		
		MPDU *frame_pkt;
		
		uint16_t frame_control;
		////printfUART("create_gts_request_cmd\n", "");
		
		
		if (send_buffer_msg_in == SEND_BUFFER_SIZE)
			send_buffer_msg_in=0;

		frame_pkt = (MPDU *) &send_buffer[send_buffer_msg_in];
		
		mac_gts_request= (cmd_gts_request*) &send_buffer[send_buffer_msg_in].data;

		frame_pkt->length = 11;
	
		if ( get_characteristic_type(gts_characteristics) != 0 )
		{   
			//frame_pkt->frame_control = set_frame_control(TYPE_CMD,0,0,1,1,0,SHORT_ADDRESS);   //dest | source
		
			frame_control = set_frame_control(TYPE_CMD,0,0,1,1,0,SHORT_ADDRESS); 
			frame_pkt->frame_control1 =(uint8_t)( frame_control);
			frame_pkt->frame_control2 =(uint8_t)( frame_control >> 8);
		}
		else
		{	
			//frame_pkt->frame_control = set_frame_control(TYPE_CMD,0,0,1,1,0,SHORT_ADDRESS);
			
			frame_control = set_frame_control(TYPE_CMD,0,0,1,1,0,SHORT_ADDRESS);
			frame_pkt->frame_control1 =(uint8_t)( frame_control);
			frame_pkt->frame_control2 =(uint8_t)( frame_control >> 8);
		}
		
		frame_pkt->seq_num = mac_PIB.macDSN;
		
		gts_request_seq_num = frame_pkt->seq_num;
		
		mac_PIB.macDSN++;
		
		//enable retransmissions
		send_buffer[send_buffer_msg_in].retransmission =1;
		send_buffer[send_buffer_msg_in].indirect = 0;
		
		//mac_gts_request->source_PAN_identifier = 0x0001;
		mac_gts_request->source_PAN_identifier = mac_PIB.macPANId;
		
		mac_gts_request->source_address = mac_PIB.macShortAddress;
	
		mac_gts_request->command_frame_identifier = CMD_GTS_REQUEST;
		
		//mac_gts_request->gts_characteristics = set_gts_characteristics(2,1,1);
		mac_gts_request->gts_characteristics =gts_characteristics;
		
		//increment the send buffer variables
		send_buffer_count++;
		send_buffer_msg_in++;
		
		post send_frame_csma();
		
		}

return;
}

void create_disassociation_notification_cmd(uint32_t DeviceAddress[],uint8_t disassociation_reason)
{

	atomic{
		cmd_disassociation_notification *mac_disassociation_notification;
		MPDU *frame_pkt;
		
		uint16_t frame_control;
		
		if (send_buffer_msg_in == SEND_BUFFER_SIZE)
			send_buffer_msg_in=0;
	
		frame_pkt = (MPDU *) &send_buffer[send_buffer_msg_in];
		
		//creation of a pointer to the disassociation notification structure
		mac_disassociation_notification = (cmd_disassociation_notification*) &send_buffer[send_buffer_msg_in].data;								
		
		
		frame_pkt->length = 27;
		
		//frame_pkt->frame_control = set_frame_control(TYPE_CMD,0,0,1,0,LONG_ADDRESS,LONG_ADDRESS);
		
		frame_control = set_frame_control(TYPE_CMD,0,0,1,0,LONG_ADDRESS,LONG_ADDRESS);
		frame_pkt->frame_control1 =(uint8_t)( frame_control);
		frame_pkt->frame_control2 =(uint8_t)( frame_control >> 8);
		
		frame_pkt->seq_num = mac_PIB.macDSN;
		
		mac_PIB.macDSN++;
		
		//enable retransmissions
		send_buffer[send_buffer_msg_in].retransmission =1;
		send_buffer[send_buffer_msg_in].indirect = 0;
		
		mac_disassociation_notification->destination_PAN_identifier = mac_PIB.macPANId;

		mac_disassociation_notification->destination_address0 = DeviceAddress[0];
		mac_disassociation_notification->destination_address1 = DeviceAddress[1];
	
		mac_disassociation_notification->source_PAN_identifier = mac_PIB.macPANId;
	
		mac_disassociation_notification->source_address0 = aExtendedAddress0;
		mac_disassociation_notification->source_address1 = aExtendedAddress1;
	
		mac_disassociation_notification->command_frame_identifier = CMD_DISASSOCIATION_NOTIFICATION;
		
		mac_disassociation_notification->disassociation_reason = disassociation_reason;
		
		//increment the send buffer variables
		send_buffer_count++;
		send_buffer_msg_in++;
		
		post send_frame_csma();

	}
return;
}



void build_ack(uint8_t sequence,uint8_t frame_pending)
{
	uint16_t frame_control;
	atomic{
			mac_ack_ptr->length = ACK_LENGTH;
			//mac_ack_ptr->frame_control = set_frame_control(TYPE_ACK,0,frame_pending,0,0,0,0);
			
			frame_control = set_frame_control(TYPE_ACK,0,frame_pending,0,0,0,0);
			mac_ack_ptr->frame_control1 =(uint8_t)( frame_control);
			mac_ack_ptr->frame_control2 =(uint8_t)( frame_control >> 8);
			
			mac_ack_ptr->seq_num = sequence;
			
			call PD_DATA.request(mac_ack_ptr->length,(uint8_t*)mac_ack_ptr);
	}
}



/*****************************************************************************************************/
/*****************************************************************************************************/
/*****************************************************************************************************/
/************************		INTERFACES PROVIDED   			**********************************/
/*****************************************************************************************************/ 
/*****************************************************************************************************/
/*****************************************************************************************************/

/*********************************************************/
/**************MLME_SCAN********************************/
/*********************************************************/

task void data_channel_scan_indication()
{
	uint8_t link_qual;
	
	beacon_addr_short *beacon_ptr;
	
	//printfUART("data_channel_scan_indication\n","");

	atomic link_qual = link_quality;

	atomic buffer_count--;

	switch(scan_type)
	{
		case ED_SCAN: 
						if (scanned_values[current_scanning-1] < link_qual)
								scanned_values[current_scanning-1] = link_qual;
						break;
		
		case ACTIVE_SCAN:break;
					
		case PASSIVE_SCAN: 
							switch( (buffer_msg[current_msg_out].frame_control1 & 0x7) )
							{
								case TYPE_BEACON:
								////////////printfUART("Received Beacon\n","");
								beacon_ptr = (beacon_addr_short*) (&buffer_msg[current_msg_out].data);

								//Beacon NOTIFICATION
								//BUILD the PAN descriptor of the COORDINATOR
								//assuming that the adress is short
								scan_pans[current_scanning-1].CoordPANId = beacon_ptr->destination_PAN_identifier;
								scan_pans[current_scanning-1].CoordAddress=beacon_ptr->source_address;
								scan_pans[current_scanning-1].LogicalChannel=current_channel;
								//superframe specification field
								scan_pans[current_scanning-1].SuperframeSpec = beacon_ptr->superframe_specification;
								
								if (scan_pans[current_scanning-1].lqi < link_qual)
								scan_pans[current_scanning-1].lqi = link_qual;
							
								break;
								
								default: break;
							//atomic buffer_count--;
							////////////printfUART("Invalid frame type\n","");

							}
							break;
		case ORPHAN_SCAN: 
							//printfUART("osrm\n","");
							switch( (buffer_msg[current_msg_out].frame_control1 & 0x7) )
							{
								case TYPE_CMD:
										//printfUART("received cmd\n","");
										if (buffer_msg[current_msg_out].data[SOURCE_SHORT_LEN+ DEST_LONG_LEN] == CMD_COORDINATOR_REALIGNMENT)
										{	
											printfUART("pf\n","");
											atomic scanning_channels = 0;
											call T_ScanDuration.stop();
											process_coordinator_realignment(&buffer_msg[current_msg_out]);
											
										}
										
										break;
							default: break;
							}
							break;
		
	}
	
	atomic{
			current_msg_out++;
		if ( current_msg_out == RECEIVE_BUFFER_SIZE )	
			current_msg_out = 0;
		}
return;
}
/*******************T_ScanDuration**************************/
event void T_ScanDuration.fired() {

	current_scanning++;
	
	printfUART("cs%i c%i\n",current_scanning,(0x0A + current_scanning));
						
	call PLME_SET.request(PHYCURRENTCHANNEL, (0x0A + current_scanning));

	current_channel = (0x0A + current_scanning);
	

	if (current_scanning == 16 )
	{
		//printfUART("scan end\n","");
		
		atomic scanning_channels = 0;
		
		switch(scan_type)
		{
			case ED_SCAN: 
							signal MLME_SCAN.confirm(MAC_SUCCESS,scan_type, 0x00, 16 , scanned_values,0x00);
							break;
			
			case ACTIVE_SCAN:break;

			case PASSIVE_SCAN: 
							//event result_t confirm(uint8_t status,uint8_t ScanType, uint32_t UnscannedChannels, uint8_t ResultListSize, uint8_t EnergyDetectList[], SCAN_PANDescriptor PANDescriptorList[]);
							signal MLME_SCAN.confirm(MAC_SUCCESS,scan_type, 0x00, 16 , 0x00, scan_pans);
							break;
			
			case ORPHAN_SCAN: 
							//orphan scan
							//send opphan command on every channel directed to the current PAN coordinator
							printfUART("oph s end not found\n","");
							signal MLME_SCAN.confirm(MAC_SUCCESS,scan_type, 0x00, 16 , 0x00, scan_pans);
							
							break;
		}
	}
	else
	{
		switch(scan_type)
		{
			case ORPHAN_SCAN:	printfUART("con\n","");
								create_orphan_notification();
								break;
		}
		
		call T_ScanDuration.startOneShot(scan_duration);
	}
  
}



command error_t MLME_SCAN.request(uint8_t ScanType, uint32_t ScanChannels, uint8_t ScanDuration)
{
//pag 93
	printfUART("MLME_SCAN.request\n", ""); 
		
	atomic scanning_channels = 1;
	scan_type = ScanType;
	channels_to_scan = ScanChannels;
	
	atomic current_scanning=0;
	
	
	switch(ScanType)
	{
		//ED SCAN only FFD			
		case ED_SCAN:	
					call TimerAsync.set_timers_enable(0x00);
					/*
				
					scanning_channels = 1;
					scan_type = ScanType;
					current_scanning=0;
					scan_count=0;
					channels_to_scan = ScanChannels;
					scan_duration = ((aBaseSuperframeDuration * pow(2,ScanDuration)) * 4.0) / 250.0;
					
					//////////printfUART("channels_to_scan %y scan_duration %y\n", channels_to_scan,scan_duration); 
					
					call T_ed_scan.start(TIMER_REPEAT,1);
					
					call T_scan_duration.start(TIMER_ONE_SHOT,scan_duration);	
					*/
					
					
					//calculate the scan_duration in miliseconds
					//#ifdef PLATFORM_MICAZ
						scan_duration = ((aBaseSuperframeDuration * (powf(2,ScanDuration)+1)) * EFFECTIVE_SYMBOL_VALUE) / 1000.0;
					//#else
					//	scan_duration = ((aBaseSuperframeDuration * (powf(2,ScanDuration)+1)) * EFFECTIVE_SYMBOL_VALUE) / 1000.0;
					//#endif
			//scan_duration = 2000;
					
					call T_ScanDuration.startOneShot(scan_duration);
					
					//printfUART("channels_to_scan %y scan_duration %y\n", channels_to_scan,scan_duration); 
					break;
		//active scan only FFD
		case ACTIVE_SCAN:
					call TimerAsync.set_timers_enable(0x00);
					break;
		//passive scan
		case PASSIVE_SCAN:	
					call TimerAsync.set_timers_enable(0x00);
							
					//calculate the scan_duration in miliseconds
					//#ifdef PLATFORM_MICAZ
					//	scan_duration = ((aBaseSuperframeDuration * (powf(2,ScanDuration)+1)) * EFFECTIVE_SYMBOL_VALUE) / 1000.0;
					//#else
					//	scan_duration = ((aBaseSuperframeDuration * (powf(2,ScanDuration)+1)) * EFFECTIVE_SYMBOL_VALUE) / 1000.0;
					//#endif
					
					
					//defines the time (miliseconds) that the device listen in each channel
					scan_duration = 2000;
					
					printfUART("channels_to_scan %y scan_duration %i\n", channels_to_scan,scan_duration); 
					
					call T_ScanDuration.startOneShot(scan_duration);
					
					//printfUART("channels_to_scan %y scan_duration %i\n", channels_to_scan,scan_duration); 
					
					//atomic trx_status = PHY_RX_ON;
					//call PLME_SET_TRX_STATE.request(PHY_RX_ON); 
		
		
		
					break;
		//orphan scan
		case ORPHAN_SCAN:
		
					call TimerAsync.set_timers_enable(0x01);
					
				    scan_duration = 4000;
					
					printfUART("orphan cts %y sdur %i\n", channels_to_scan,scan_duration); 
					
					call T_ScanDuration.startOneShot(scan_duration);

					break;
	
		default:
					break;
	}

return SUCCESS;
}



/*********************************************************/
/**************MLME_ORPHAN********************************/
/*********************************************************/

command error_t MLME_ORPHAN.response(uint32_t OrphanAddress[1],uint16_t ShortAddress,uint8_t AssociatedMember, uint8_t security_enabled)
{

	if (AssociatedMember==0x01)
	{
		create_coordinator_realignment_cmd(OrphanAddress[0], OrphanAddress[1], ShortAddress);
	}
	
return SUCCESS;
}

/*********************************************************/
/**************MLME_SYNC********************************/
/*********************************************************/


command error_t MLME_SYNC.request(uint8_t logical_channel,uint8_t track_beacon)
{
	call PLME_SET.request(PHYCURRENTCHANNEL,logical_channel);	
	
	call TimerAsync.set_timers_enable(0x01);
	
	printfUART("sync req\n", ""); 
	
	atomic findabeacon = 1;

return SUCCESS;
}

/*********************************************************/
/**************MLME_RESET********************************/
/*********************************************************/


command error_t MLME_RESET.request(uint8_t set_default_PIB)
{
printfUART("MLME_RESET.request\n", "");

return SUCCESS;
}

/*********************************************************/
/**************MLME_GTS***********************************/
/*********************************************************/

command error_t MLME_GTS.request(uint8_t GTSCharacteristics, bool security_enable)
{

	//uint32_t wait_time;
	//if there is no short address asigned the node cannot send a GTS request
	if (mac_PIB.macShortAddress == 0xffff)
			signal MLME_GTS.confirm(GTSCharacteristics,MAC_NO_SHORT_ADDRESS);
	
	//gts_ack=1;
	
	gts_request =1;
	
	create_gts_request_cmd(GTSCharacteristics);

return SUCCESS;
}


/*********************************************************/
/**************MLME_START*********************************/
/*********************************************************/

command error_t MLME_START.request(uint32_t PANId, uint8_t LogicalChannel, uint8_t beacon_order, uint8_t superframe_order,bool pan_coodinator,bool BatteryLifeExtension,bool CoordRealignment,bool securityenable,uint32_t StartTime)
{

	uint32_t BO_EXPONENT;
	uint32_t SO_EXPONENT;

	printfUART("MLME_START.request\n", "");
	//pag 102
	atomic {
	PANCoordinator=1;
	Beacon_enabled_PAN=1;
	//TEST
	//atomic mac_PIB.macShortAddress = 0x0000;


		if ( mac_PIB.macShortAddress == 0xffff)
		{
		
			signal MLME_START.confirm(MAC_NO_SHORT_ADDRESS);
			return SUCCESS;
		}
		else
		{
			atomic mac_PIB.macBeaconOrder = beacon_order;
			
			if (beacon_order == 15) 
				atomic mac_PIB.macSuperframeOrder = 15;
			else
				atomic mac_PIB.macSuperframeOrder = superframe_order;
		
		
			//PANCoordinator is set to TRUE
			if (pan_coodinator == 1)
			{
				atomic mac_PIB.macPANId = PANId;
				call PLME_SET.request(PHYCURRENTCHANNEL,LogicalChannel);
			}
			if (CoordRealignment == 1)
			{
				//generates and broadcasts a coordinator realignment command containing the new PANId and LogicalChannels
			}
			if (securityenable == 1)
			{
			//security parameters
			}
		}
	
		if (mac_PIB.macSuperframeOrder == 0)
			SO_EXPONENT = 1;
		else
		{
			SO_EXPONENT = powf(2,mac_PIB.macSuperframeOrder);
		
		}
		if ( mac_PIB.macBeaconOrder == 0)
			BO_EXPONENT = 1;
		else
		{
			BO_EXPONENT = powf(2,mac_PIB.macBeaconOrder);
		
		}	
	}
	
	BI = aBaseSuperframeDuration * BO_EXPONENT; 
		
	SD = aBaseSuperframeDuration * SO_EXPONENT; 
	//backoff_period
	backoff = aUnitBackoffPeriod;

	
	atomic time_slot = SD / NUMBER_TIME_SLOTS;

	call TimerAsync.set_backoff_symbols(backoff);

	call TimerAsync.set_bi_sd(BI,SD);
	
	atomic{
	
		call TimerAsync.set_timers_enable(0x01);
		
		call TimerAsync.reset();
		
	}
	
	////////////////////////////////////////////////////
	/////////////////TDBS IMPLEMENTATION////////////////
	////////////////////////////////////////////////////
	if(TYPE_DEVICE == ROUTER)
	{
		atomic parent_offset = StartTime;
	
		call TimerAsync.set_track_beacon(1);
		//initialization of the timer that shedules the beacon transmission offset
		call TimerAsync.set_track_beacon_start_ticks(StartTime,0x00001E00,0x00000000);
	}
	else
	{
		atomic I_AM_IN_PARENT_CAP = 1;
	}
		
	signal MLME_START.confirm(MAC_SUCCESS);

	return SUCCESS;
}

/*************************************************************/
/**************MLME_ASSOCIATE*********************************/
/*************************************************************/

command error_t MLME_ASSOCIATE.request(uint8_t LogicalChannel,uint8_t CoordAddrMode,uint16_t CoordPANId,uint32_t CoordAddress[],uint8_t CapabilityInformation,bool securityenable)
{
	//update current channel
	//call PLME_SET.request(PHYCURRENTCHANNEL,LogicalChannel);
	
	//printfUART("MLME_ASSOCIATE.request\n", "");
	
	//updates the PAN ID
	atomic{ 
		mac_PIB.macPANId = CoordPANId;
		mac_PIB.macCoordShortAddress = (uint16_t)(CoordAddress[1] & 0x000000ff);
		}
		
	associating=1; //boolean variable stating that the device is trying to associate
	
	call TimerAsync.set_timers_enable(1);
	
	//call PLME_SET.request(PHYCURRENTCHANNEL, LogicalChannel);

	current_channel = LogicalChannel;
	
	//printfUART("SELECTED cord id %i\n", mac_PIB.macPANId);
	//printfUART("CoordAddress %i\n", mac_PIB.macCoordShortAddress);
	//printfUART("LogicalChannel %i\n", LogicalChannel);
	//printfUART("Cordaddr %i\n",CoordAddress[0]);
	//printfUART("Cordaddr %i\n",CoordAddress[1]);
	/*
	a_CoordAddrMode = CoordAddrMode;
	a_CoordPANId=CoordPANId;
	a_CoordAddress[0]=CoordAddress[0];
	a_CoordAddress[1]=CoordAddress[1];
	a_CapabilityInformation=CapabilityInformation;
	a_securityenable=securityenable;
	*/
	create_association_request_cmd(CoordAddrMode,CoordPANId,CoordAddress,CapabilityInformation);
	
	return SUCCESS;
}

command error_t MLME_ASSOCIATE.response(uint32_t DeviceAddress[], uint16_t AssocShortAddress, uint8_t status, bool securityenable)
{
	
	error_t status_response;
	
	//////printfUART("MAR\n", "");
	
	status_response = create_association_response_cmd(DeviceAddress,AssocShortAddress,status);
	////////////printfUART("MLME_ASSOCIATE.response\n", "");


return SUCCESS;
}

/*************************************************************/
/**************MLME_DISASSOCIATE*********************************/
/*************************************************************/

command error_t MLME_DISASSOCIATE.request(uint32_t DeviceAddress[], uint8_t disassociate_reason, bool securityenable)
{
	create_disassociation_notification_cmd(DeviceAddress,disassociate_reason);
return SUCCESS;
}

/*********************************************************/
/**************MLME_GET***********************************/
/*********************************************************/
command error_t MLME_GET.request(uint8_t PIBAttribute)
{

	switch(PIBAttribute)
	{
		case MACACKWAITDURATION :		signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute,&mac_PIB.macAckWaitDuration);
										break;
		case MACASSOCIATIONPERMIT:  	signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute,&mac_PIB.macAssociationPermit);
										break;
		case MACAUTOREQUEST : 			signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute,&mac_PIB.macAutoRequest);
										break;
		case MACBATTLIFEEXT:			signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute,&mac_PIB.macBattLifeExt);
										break;
		case MACBATTLIFEEXTPERIODS:		signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute,&mac_PIB.macBattLifeExtPeriods);
										break;
		case MACBEACONPAYLOAD:			signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute, mac_PIB.macBeaconPayload);
										break;
		case MACMAXBEACONPAYLOADLENGTH:	signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute,&mac_PIB.macBeaconPayloadLenght);
										break;
		case MACBEACONORDER:			signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute,&mac_PIB.macBeaconOrder);
										break;
		case MACBEACONTXTIME:			signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute,(uint8_t *)&mac_PIB.macBeaconTxTime);
										break;
		case MACBSN:					signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute,&mac_PIB.macBSN);
										break;
		case MACCOORDEXTENDEDADDRESS:	signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute,(uint8_t *) &mac_PIB.macCoordExtendedAddress0);
										break;
		case MACCOORDSHORTADDRESS:		signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute,(uint8_t *) &mac_PIB.macCoordShortAddress);
										break;
		case MACDSN:					signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute,&mac_PIB.macDSN);
										break;
		case MACGTSPERMIT:				signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute,&mac_PIB.macGTSPermit);
										break;
		case MACMAXCSMABACKOFFS:		signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute,&mac_PIB.macMaxCSMABackoffs);
										break;
		case MACMINBE:					signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute,&mac_PIB.macMinBE);
										break;
		case MACPANID:					signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute,(uint8_t *) &mac_PIB.macPANId);
										break;
		case MACPROMISCUOUSMODE:		signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute,&mac_PIB.macPromiscuousMode);
										break;
		case MACRXONWHENIDLE:			signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute,&mac_PIB.macRxOnWhenIdle);
										break;
		case MACSHORTADDRESS:			signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute,(uint8_t *) &mac_PIB.macShortAddress);
										break;
		case MACSUPERFRAMEORDER:		signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute,&mac_PIB.macSuperframeOrder);
										break;
		case MACTRANSACTIONPERSISTENCETIME:	signal MLME_GET.confirm(MAC_SUCCESS,PIBAttribute,(uint8_t *) &mac_PIB.macTransactionPersistenceTime);
											break;
											
		default:						signal MLME_GET.confirm(MAC_UNSUPPORTED_ATTRIBUTE,PIBAttribute,0x00);
										break;
	}

return SUCCESS;
}

/*********************************************************/
/**************MLME_SET***********************************/
/*********************************************************/
command error_t MLME_SET.request(uint8_t PIBAttribute,uint8_t PIBAttributeValue[])
{

//int i;

//printfUART("set %i\n",PIBAttribute);

atomic{

	switch(PIBAttribute)
	{
	
	
		case MACACKWAITDURATION :		mac_PIB.macAckWaitDuration = PIBAttributeValue[0];
										//////////printfUART("mac_PIB.macAckWaitDuration: %x\n",mac_PIB.macAckWaitDuration);
										signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
										break;
									
		case MACASSOCIATIONPERMIT:  	if ((uint8_t)PIBAttributeValue[1] == 0x00)
										{
											mac_PIB.macAssociationPermit = 0x00;
										}
										else
										{
											mac_PIB.macAssociationPermit = 0x01;
										}
										////////printfUART("mac_PIB.macAssociationPermit: %i %y\n",mac_PIB.macAssociationPermit,PIBAttributeValue[1]);
										signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
										break;
										
		case MACAUTOREQUEST : 			mac_PIB.macAutoRequest = PIBAttributeValue[0];
										//////////printfUART("mac_PIB.macAutoRequest: %i\n",mac_PIB.macAutoRequest);
										signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
										break;
										
		case MACBATTLIFEEXT:			mac_PIB.macBattLifeExt = PIBAttributeValue[0];
										//////////printfUART("mac_PIB.macBattLifeExt %i\n",mac_PIB.macBattLifeExt);
										signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
										break;
		case MACBATTLIFEEXTPERIODS:		mac_PIB.macBattLifeExtPeriods = PIBAttributeValue[0];
										//////////printfUART("mac_PIB.macBattLifeExtPeriods %i\n",mac_PIB.macBattLifeExtPeriods);
										signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
										break;
										
		case MACBEACONPAYLOAD:			/*for(i=0;i < mac_PIB.macBeaconPayloadLenght;i++) 
										{
											mac_PIB.macBeaconPayload[i] = PIBAttributeValue[i];
										}*/
									
										memcpy(&PIBAttributeValue[0],&mac_PIB.macBeaconPayload[0],mac_PIB.macBeaconPayloadLenght * sizeof(uint8_t));
										
										signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
										break;
				
		case MACMAXBEACONPAYLOADLENGTH:	mac_PIB.macBeaconPayloadLenght = PIBAttributeValue[0];
										//////////printfUART("mac_PIB.macBeaconPayloadLenght %i\n",mac_PIB.macBeaconPayloadLenght);
										signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
										break;
										
		case MACBEACONORDER:			mac_PIB.macBeaconOrder = PIBAttributeValue[0];
										//////////printfUART("mac_PIB.macBeaconOrder %i\n",mac_PIB.macBeaconOrder);
										signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
										break;
		case MACBEACONTXTIME:			mac_PIB.macBeaconTxTime =PIBAttributeValue[0];
										//////////printfUART("mac_PIB.macBeaconTxTime %i\n",mac_PIB.macBeaconTxTime);
										signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
										break;
		case MACBSN:					mac_PIB.macBSN = PIBAttributeValue[0];
										//////////printfUART("mac_PIB.macBSN %i\n",mac_PIB.macBSN);
										signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
										break;

		case MACCOORDEXTENDEDADDRESS:	//mac_PIB.macCoordExtendedAddress0 = ((PIBAttributeValue[0] >> 24) | (PIBAttributeValue[1] >> 16) | (PIBAttributeValue[2] >> 8) | (PIBAttributeValue[3])) ;
										//mac_PIB.macCoordExtendedAddress1 = ((PIBAttributeValue[4] >> 24) | (PIBAttributeValue[5] >> 16) | (PIBAttributeValue[6] >> 8) | (PIBAttributeValue[7]));

										//////////printfUART("mac_PIB.macCoordExtendedAddress0 %y\n",mac_PIB.macCoordExtendedAddress0);
										//////////printfUART("mac_PIB.macCoordExtendedAddress1 %y\n",mac_PIB.macCoordExtendedAddress1);
										signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
										break;
										
									
		case MACCOORDSHORTADDRESS:		mac_PIB.macCoordShortAddress= ((PIBAttributeValue[0] << 8) |PIBAttributeValue[1]);
										//printfUART("mac_PIB.macCoordShortAddress: %x\n",mac_PIB.macCoordShortAddress);
										signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
										break;
		
		case MACDSN:					mac_PIB.macDSN = PIBAttributeValue[0];
										//////////printfUART("mac_PIB.macDSN: %x\n",mac_PIB.macDSN);
										signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
										break;
		case MACGTSPERMIT:				mac_PIB.macGTSPermit = PIBAttributeValue[0];
										//////////printfUART("mac_PIB.macGTSPermit: %x\n",mac_PIB.macGTSPermit);
										signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
										break;
		case MACMAXCSMABACKOFFS:		mac_PIB.macMaxCSMABackoffs = PIBAttributeValue[0];
										//////////printfUART("mac_PIB.macMaxCSMABackoffs: %x\n",mac_PIB.macMaxCSMABackoffs);
										signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
										break;
		case MACMINBE:					mac_PIB.macMinBE = PIBAttributeValue[0];
										//////////printfUART("mac_PIB.macMinBE: %x\n",mac_PIB.macMinBE);
										signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
										break;
		
		case MACPANID:					mac_PIB.macPANId = ((PIBAttributeValue[0] << 8)| PIBAttributeValue[1]);
										printfUART("mac_PIB.macPANId: %x\n",mac_PIB.macPANId);
										
										//TODO ENABLE HARDWARE VERIFICATION
										//call CC2420Config.setPanAddr(mac_PIB.macPANId);
										//call CC2420Config.setAddressRecognition(TRUE);
										//call CC2420Config.sync(); 
										
										call AddressFilter.set_coord_address(mac_PIB.macCoordShortAddress, mac_PIB.macPANId);
										
										
										signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
										break;
		
		case MACPROMISCUOUSMODE:		mac_PIB.macPromiscuousMode = PIBAttributeValue[0];
										//////////printfUART("mac_PIB.macPromiscuousMode: %x\n",mac_PIB.macPromiscuousMode);
										signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
										break;
		case MACRXONWHENIDLE:			mac_PIB.macRxOnWhenIdle = PIBAttributeValue[0];
										//////////printfUART("mac_PIB.macRxOnWhenIdle: %x\n",mac_PIB.macRxOnWhenIdle);
										signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
										break;
										
										
		case MACSHORTADDRESS:			mac_PIB.macShortAddress = ((PIBAttributeValue[0] << 8) |PIBAttributeValue[1]);
										
										printfUART("mac_PIB.macShortAddress: %y\n",mac_PIB.macShortAddress);
																			
										//TODO ENABLE HARDWARE VERIFICATION
										//call CC2420Config.setPanAddr(0x0000);
										//call CC2420Config.setShortAddr(0x0001);
										//call CC2420Config.setAddressRecognition(TRUE);
										//call CC2420Config.sync(); 
										
										call AddressFilter.set_address(mac_PIB.macShortAddress, aExtendedAddress0, aExtendedAddress0);
										
										
										signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
										break;
										
		case MACSUPERFRAMEORDER:		mac_PIB.macSuperframeOrder = PIBAttributeValue[0];
										//////////printfUART("mac_PIB.macSuperframeOrder: %x\n",mac_PIB.macSuperframeOrder);
										signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
										break;
										
		case MACTRANSACTIONPERSISTENCETIME:	 mac_PIB.macTransactionPersistenceTime = PIBAttributeValue[0];
											 //////////printfUART("mac_PIB.macTransactionPersistenceTime: %y\n",mac_PIB.macTransactionPersistenceTime);
											 signal MLME_SET.confirm(MAC_SUCCESS,PIBAttribute);
											 break;
											
		default:						signal MLME_SET.confirm(MAC_UNSUPPORTED_ATTRIBUTE,PIBAttribute);
										break;
										
		
	}

}

return SUCCESS;
}
/*************************************************************/
/**************        MCPS - DATA         *******************/
/*************************************************************/

command error_t MCPS_DATA.request(uint8_t SrcAddrMode, uint16_t SrcPANId, uint32_t SrcAddr[], uint8_t DstAddrMode, uint16_t DestPANId, uint32_t DstAddr[], uint8_t msduLength, uint8_t msdu[],uint8_t msduHandle, uint8_t TxOptions)
{
	int i;
	//uint8_t valid_gts=0;
	uint32_t total_ticks;
	
	//////printfUART("MCPS_DATA.request\n", ""); 
	//check conditions on page 58
	
	//atomic mac_PIB.macShortAddress = TOS_LOCAL_ADDRESS;
	
	/*
	//printfUART("SrcAddrMode %x\n", SrcAddrMode);
	//printfUART("SrcPANId %x\n", SrcPANId);
	//printfUART("SrcAddr %x\n", SrcAddr[0]);
	//printfUART("SrcAddr %x\n", SrcAddr[1]);
	//printfUART("DstAddrMode %x\n", DstAddrMode);
	//printfUART("DestPANId %x\n", DestPANId);
	//printfUART("DstAddr %x\n", DstAddr[0]);
	//printfUART("DstAddr %x\n", DstAddr[1]);
	//printfUART("msduLength %x\n", msduLength);
	//printfUART("msduHandle %x\n", msduHandle);
	//printfUART("TxOptions %x\n", TxOptions);
		*/
	
	atomic{
	
	if (mac_PIB.macShortAddress == 0xffff)
		return FAIL;
	}
	
	if(PANCoordinator == 1)
	{
	//PAN COORDINATOR OPERATION
		////////////printfUART("GTS TRANS: %i TxOptions: %u dest:%u\n", get_txoptions_gts(TxOptions),TxOptions,DstAddr[1]); 
		
		if (get_txoptions_gts(TxOptions) == 1)
		{
		//GTS TRANSMISSION
			for (i=0 ; i < 7 ; i++)
			{
				//SEARCH FOR A VALID GTS
				if ( GTS_db[i].DevAddressType == (uint16_t)DstAddr[1] && GTS_db[i].direction == 1 && GTS_db[i].gts_id != 0)
				{
					
				//atomic{
						////////////printfUART("BUFFER UNTIL GTS SLOT n: %i ss: %i\n",number_time_slot,GTS_db[valid_gts].starting_slot);
						create_data_frame(SrcAddrMode, SrcPANId, SrcAddr, DstAddrMode, DestPANId, DstAddr, msduLength, msdu, msduHandle, TxOptions,GTS_db[i].starting_slot,1);
					//}
					return SUCCESS;
					break;
				}
			}
			signal MCPS_DATA.confirm(msduHandle, MAC_INVALID_GTS);
			return FAIL;
		}
		else
		{
		//NORMAL/INDIRECT TRANSMISSION
		
			////////////printfUART("IND TRANS: %i TxOptions: %u\n", get_txoptions_indirect_transmission(TxOptions),TxOptions);
			//check if its an indirect transmission
			//if ( get_txoptions_indirect_transmission(TxOptions) == 1)
			//{
				//INDIRECT TRANSMISSION
				
				////////////printfUART("CREATE INDIRECT TRANSMISSION\n","");
				
				
				
				
			//}
			//else
			//{
				//NORMAL TRANSMISSION
				//printfUART("SEND NO GTS NO IND\n","");
				create_data_frame(SrcAddrMode, SrcPANId, SrcAddr, DstAddrMode, DestPANId, DstAddr, msduLength, msdu, msduHandle, TxOptions,0,0);
			//}
		}
	}
	else
	{
	//NON PAN COORDINATOR OPERATION
		atomic{
				
				////////////printfUART("sslot: %i ini %i\n",s_GTSss,init_s_GTSss);
				//check if it a gts transmission
				if (get_txoptions_gts(TxOptions) == 1)
				{
				//GTS TRANSMISSION
					if (s_GTSss == 0x00)
					{
						////////////printfUART("NO VALID GTS \n","");
						signal MCPS_DATA.confirm(msduHandle, MAC_INVALID_GTS);
					}
					else
					{
							total_ticks = call TimerAsync.get_total_tick_counter();
							msdu[0] =(uint8_t)(total_ticks >> 0 );
							msdu[1] =(uint8_t)(total_ticks >> 8);
							msdu[2] =(uint8_t)(total_ticks >> 16);
							msdu[3] =(uint8_t)(total_ticks >> 24);
							
							if (on_sync == 1 && s_GTSss > 0)
							create_data_frame(SrcAddrMode, SrcPANId, SrcAddr, DstAddrMode, DestPANId, DstAddr, msduLength, msdu, msduHandle, TxOptions,s_GTSss,0);
					}
				}
				else
				{
				//NORMAL TRANSMISSION
					printfUART("TRnsm\n","");
					create_data_frame(SrcAddrMode, SrcPANId, SrcAddr, DstAddrMode, DestPANId, DstAddr, msduLength, msdu, msduHandle, TxOptions,0,0);
				}
			}
	}
	return SUCCESS;
}




/*************************************************************/
/**************        MCPS - PURGE         *******************/
/*************************************************************/

command error_t MCPS_PURGE.request(uint8_t msduHandle)
{



return SUCCESS;
}

/*****************************************************************************************************/
/*****************************************************************************************************/
/*****************************************************************************************************/
/************************		OTHER FUNCTIONS   			**********************************/
/*****************************************************************************************************/ 
/*****************************************************************************************************/
/*****************************************************************************************************/

task void signal_loss()
{
	//TODO
	atomic signal MLME_SYNC_LOSS.indication(beacon_loss_reason); //MAC_BEACON_LOSS
	return;
}

//inicialization of the mac constants
void init_MacCon()
{
/*****************************************************/
/*				Boolean Variables					 */
/*****************************************************/  
PANCoordinator = 0;
//(0 NO beacon transmission; 1 beacon transmission);
Beacon_enabled_PAN = 0;
//(SYNC)the device will try to track the beacon ie enable its receiver just before the espected time of each beacon
TrackBeacon=0;
//(SYNC)the device will try to locate one beacon
findabeacon=0;
//(RESET) when the reset command arrives it checks whether or not to reset the PIB
SetDefaultPIB=0;
/*****************************************************/
/*				Integer Variables					 */
/*****************************************************/  
/*
//Beacon Interval
uint32_t BI;
//Superframe duration
uint32_t SD;
*/
//(SYNC)number of beacons lost before sending a Beacon-Lost indication comparing to aMaxLostBeacons
missed_beacons=0;
//current_channel
current_channel=0;


/*****************************************************/
/*				Other Variables					 */
/*****************************************************/ 
pending_reset=0;

}

//inicialization of the mac PIB
void init_MacPIB()
{

atomic{
	//mac PIB default values
	
	//mac_PIB.macAckWaitDuration = 54; OLD VALUE//Number os symbols to wait for an acknowledgment
	mac_PIB.macAckWaitDuration = 65;
	
	mac_PIB.macAssociationPermit = 1; //1 - PAN allowing associations
	mac_PIB.macAutoRequest = 1; //indication if a device automatically sends a data request command if address is listed in the beacon frame
	
	mac_PIB.macBattLifeExt= 0; //batery life extension CSMA-CA
	
	mac_PIB.macBattLifeExtPeriods=6;
	//mac_PIB.macBeaconPayload; //payload of the beacon
	mac_PIB.macBeaconPayloadLenght=0; //beacon payload lenght
	
	mac_PIB.macBeaconTxTime=(0xffffff << 24); //*****
	
	
	mac_PIB.macBSN=call Random.rand16(); //sequence number of the beacon frame
	
	
	mac_PIB.macCoordExtendedAddress0 = 0x00000000; //64bits address of the coordinator with witch the device is associated
	mac_PIB.macCoordExtendedAddress1 = 0x00000000;
	
	mac_PIB.macCoordShortAddress = 0x0000; //16bits address of the coordinator with witch the device is associated
	
	
	if (DEVICE_DEPTH == 0x01)
		mac_PIB.macCoordShortAddress =D1_PAN_SHORT;
	if (DEVICE_DEPTH == 0x02)
		mac_PIB.macCoordShortAddress =D2_PAN_SHORT;
	if (DEVICE_DEPTH == 0x03)
		mac_PIB.macCoordShortAddress =D3_PAN_SHORT;
	if (DEVICE_DEPTH == 0x04)
		mac_PIB.macCoordShortAddress =D4_PAN_SHORT;
	
	
	mac_PIB.macDSN=call Random.rand16(); //sequence number of the transmited data or MAC command frame
	
	//alowing gts requests (used in beacon)
	mac_PIB.macGTSPermit=1; //
	
	//Number of maximum CSMA backoffs
	mac_PIB.macMaxCSMABackoffs=4;
	mac_PIB.macMinBE=0;
	
	//mac_PIB.macPANId=0xffff; //16bits identifier of the PAN on witch this device is operating
	mac_PIB.macPANId = MAC_PANID;
	
	mac_PIB.macPromiscuousMode=0;
	mac_PIB.macRxOnWhenIdle=0;
 
	//mac_PIB.macShortAddress=TOS_LOCAL_ADDRESS; //16bits short address
	mac_PIB.macShortAddress=0xffff;


	mac_PIB.macBeaconOrder=7;  //specification of how often the coordinator transmits a beacon
	mac_PIB.macSuperframeOrder=3;
	
	//default mac_PIB.macTransactionPersistenceTime=0x01f4;
	mac_PIB.macTransactionPersistenceTime=0x0010;
	
	//*******************************************

	}
}

//////////////////////////////////////////////////////////////
////////////////////////CSMA-CA functions////////////////////
/////////////////////////////////////////////////////////////

/*****************************************************/
/*				SEND FRAME FUNCTION   			 */
/*****************************************************/ 

task void send_frame_csma_upstream()
{//used in TDBS
	atomic{
	
		////////printfUART("sf %i, %i \n",send_buffer_count,upstream_buffer_count);
		////////printfUART("I_AM_IN_IP %i \n",I_AM_IN_IP);
		////printfUART("send up IPCAP %i %i \n",I_AM_IN_PARENT_CAP,upstream_buffer_count);
	
		//beacon synchronization
		if(upstream_buffer_count > 0 && I_AM_IN_PARENT_CAP == 1)
		{
		
			////////printfUART("s up\n","");
			sending_upstream_frame =1;
			
			performing_csma_ca = 1;

			perform_csma_ca();
		}
		
		
	}
	
}


task void send_frame_csma()
{
	atomic{
	
		//
		///printfUART("I_AM_IN_IP %i %i\n",I_AM_IN_IP,send_buffer_count);
	
		if ((send_buffer_count > 0 && send_buffer_count <= SEND_BUFFER_SIZE && performing_csma_ca == 0) || I_AM_IN_IP != 0)
		{
			////printfUART("sf %i\n",send_buffer_count);
			//////printfUART("peform\n","");
			
			performing_csma_ca = 1;

			perform_csma_ca();
		}
		else
		{
			//printfUART("NOT SEND\n","");
		}

		
	}
	
}


task void perform_csma_ca_slotted()
{
	uint8_t random_interval;
	
		
		
		//DEFERENCE CHANGE
		if (check_csma_ca_send_conditions(send_buffer[send_buffer_msg_out].length,send_buffer[send_buffer_msg_out].frame_control1) == 1 )
		{
			cca_deference = 0;
		}
		else
		{
			//nao e necessario
			cca_deference = 1;
			return;
		}
		
	atomic{
		//printfUART("CCA: %i\n", call CCA.get()) ;
	
		if(call CCA.get() == CCA_BUSY )
		{
			////////////printfUART("CCA: 1\n", "") ;
			//STEP 5
			CW--;
			if (CW == 0 )
			{
				//send functions
				csma_cca_backoff_boundary =0;
				
				////////printfUART("s_up_f %i\n",sending_upstream_frame);
				//TDBS Implementation
				if(sending_upstream_frame == 0)
				{
				
					//////printfUART("rts %i\n",get_ack_request(send_buffer[send_buffer_msg_out].frame_control));

						//verify if the message must be ack
						if ( get_fc1_ack_request(send_buffer[send_buffer_msg_out].frame_control1) == 1 )
						{
							send_ack_check=1;
							ack_sequence_number_check=send_buffer[send_buffer_msg_out].seq_num;	
							//verify retransmission
							send_retransmission = send_buffer[send_buffer_msg_out].retransmission;
							//verify if its an indirect transmission
							send_indirect_transmission = send_buffer[send_buffer_msg_out].indirect;
							//SEND WITH ACK_REQUEST
							call PD_DATA.request(send_buffer[send_buffer_msg_out].length,(uint8_t *)&send_buffer[send_buffer_msg_out]);
							
							//////printfUART("out ck\n","");
							
							
							call T_ackwait.startOneShot(ackwait_period);
						}
						else
						{
						
							call PD_DATA.request(send_buffer[send_buffer_msg_out].length,(uint8_t *)&send_buffer[send_buffer_msg_out]);
							
							send_buffer_count --;
							send_buffer_msg_out++;
						
							//failsafe
							if(send_buffer_count > SEND_BUFFER_SIZE)
							{
								send_buffer_count =0;
								send_buffer_msg_out=0;
								send_buffer_msg_in=0;
							}
							
							if (send_buffer_msg_out == SEND_BUFFER_SIZE)
								send_buffer_msg_out=0;
							
							if (send_buffer_count > 0 && send_buffer_count <= SEND_BUFFER_SIZE)
								post send_frame_csma();
							
							//printfUART("sk %i\n",send_buffer_count);
							
							////////printfUART("%i %i %i\n",send_buffer_count,send_buffer_msg_in,send_buffer_msg_out);
						}
						
				}
				else
				{
					//TDBS Implementation
						
						call PD_DATA.request(upstream_buffer[upstream_buffer_msg_out].length,(uint8_t *)&upstream_buffer[upstream_buffer_msg_out]);
						
						upstream_buffer_count --;
						upstream_buffer_msg_out++;
					
						if (upstream_buffer_msg_out == UPSTREAM_BUFFER_SIZE)
							upstream_buffer_msg_out=0;
							
						sending_upstream_frame=0;
				}		
				performing_csma_ca = 0;
			}
		}
		else
		{
			//CHECK NOT USED
			//csma_backoff_counter++;
			//csma_backoff_counter_inst++;

			if (NB < mac_PIB.macMaxCSMABackoffs)
			{
				//////////printfUART("NB:%i BE:%i L CW: %i\n",NB,BE,CW);
				//STEP 4
				CW = 2;
				NB++;
				BE = min(BE+1,aMaxBE);
				
				//STEP 2
				//random_interval = pow(2,BE) - 1;
				
				//delay_backoff_period = (call Random.rand() & random_interval);
				//verification of the backoff_deference
				//DEFERENCE CHANGE
				if (backoff_deference == 0)
				{
					random_interval = powf(2,BE) - 1;
					delay_backoff_period = (call Random.rand16() & random_interval );
						
					if (check_csma_ca_backoff_send_conditions((uint32_t) delay_backoff_period) == 1)
					{
							backoff_deference = 1;
					}
				}
				else
				{
					backoff_deference = 0;
				}
				
				
				//delay_backoff_period=0;
				
				//printfUART("delay_backoff_period:%i\n",delay_backoff_period);
				csma_delay=1;
			}
			else
			{
				//CSMA/CA FAIL
				csma_delay=0;
				csma_cca_backoff_boundary=0;
				
				send_buffer_count --;
				send_buffer_msg_out++;
			
				//failsafe
				if(send_buffer_count > SEND_BUFFER_SIZE)
				{
					send_buffer_count =0;
					send_buffer_msg_out=0;
					send_buffer_msg_in=0;
				}
				
				if (send_buffer_msg_out == SEND_BUFFER_SIZE)
					send_buffer_msg_out=0;
				
				if (send_buffer_count > 0 && send_buffer_count <= SEND_BUFFER_SIZE)
					post send_frame_csma();
					
				performing_csma_ca = 0;
				
				//printfUART("SLOTTED FAIL\n","");
				/*
				if(associating == 1)
				{
					associating=0;
					signal MLME_ASSOCIATE.confirm(0x0000,MAC_CHANNEL_ACCESS_FAILURE);
				}*/
			}
		}
	}
return;
}

task void perform_csma_ca_unslotted()
{
	uint8_t random_interval;
	
	atomic{
		if (NB < mac_PIB.macMaxCSMABackoffs)
		{
			//STEP 3
			//perform CCA
			//////////printfUART("CCA: %i\n", TOSH_READ_CC_CCA_PIN()) ;
			
			//if CCA is clear send message
			if(call CCA.get() == CCA_BUSY)
			{
				//send functions
				//////////printfUART("UNSLOTTED SUCCESS\n","");
				atomic{
				csma_delay =0;
				

						
				if (check_csma_ca_send_conditions(send_buffer[send_buffer_msg_out].length,send_buffer[send_buffer_msg_out].frame_control1) == 1 )
				{
					call PD_DATA.request(send_buffer[send_buffer_msg_out].length,(uint8_t *)&send_buffer[send_buffer_msg_out]);
					
					send_buffer_count --;
					send_buffer_msg_out++;
				
					//failsafe
					if(send_buffer_count > SEND_BUFFER_SIZE)
					{
						send_buffer_count =0;
						send_buffer_msg_out=0;
						send_buffer_msg_in=0;
					}
				
					if (send_buffer_msg_out == SEND_BUFFER_SIZE)
						send_buffer_msg_out=0;
				}
					
				
				performing_csma_ca =0;

				}
				return; //SUCCESS
			
			}

			//CCA is not clear, perform new iteration of the CSMA/CA UNSLOTTED
			
			//STEP 4
			NB++;
			BE = min(BE+1,aMaxBE);
		
			//////////printfUART("NB:%i BE:%i\n",NB,BE);
			
			//STEP 2
			//#ifdef PLATFORM_MICAZ
				random_interval = powf(2,BE) - 1;
			//#else
			//	random_interval = powf(2,BE) - 1;
			//#endif
			delay_backoff_period = (call Random.rand16() & random_interval );
			//delay_backoff_period=1;
			csma_delay=1;
			
			////////////printfUART("delay_backoff_period:%i\n",delay_backoff_period);
		}
		else
		{
			atomic csma_delay=0;
			//////////printfUART("UNSLOTTED FAIL\n","");
		}
	}
return;
}


void perform_csma_ca()
{
	uint8_t random_interval;
	csma_slotted=1;
	//STEP 1
	if (csma_slotted == 0 )
	{
		atomic{
			//UNSLOTTED version
			init_csma_ca(csma_slotted);
			//STEP 2
			random_interval = powf(2,BE) - 1;
			delay_backoff_period = (call Random.rand16() & random_interval );
			
			csma_delay=1;
			//////////printfUART("delay_backoff_period:%i\n",delay_backoff_period);
		}
		return;
	}
	else
	{
		//SLOTTED version
		atomic{
			//DEFERENCE CHANGE
			if (cca_deference==0)
			{
				init_csma_ca(csma_slotted);
				if (mac_PIB.macBattLifeExt == 1 )
				{
					BE = min(2,	mac_PIB.macMinBE);
				}
				else
				{
					BE = mac_PIB.macMinBE;
				}
				csma_locate_backoff_boundary = 1;
			}
			else
			{
				cca_deference = 0;
				csma_delay=0;
				csma_locate_backoff_boundary=0;
				csma_cca_backoff_boundary = 1;
			
			}
		}
		return;
	}
}


uint8_t min(uint8_t val1, uint8_t val2)
{
	if (val1 < val2)
	{
		return val1;
	}
	else
	{
		return val2;
	}
}

void init_csma_ca(bool slotted)
{

//initialization of the CSMA/CA protocol variables
	////////////printfUART("init_csma_ca\n", "") ;
	
	csma_delay=0;
	
	if (slotted == 0 )
	{
		NB=0;
		BE=mac_PIB.macMinBE;
	}
	else
	{
		NB=0;
		CW=2;
		
		csma_cca_backoff_boundary=0;
		csma_locate_backoff_boundary=0;
	}

return;
}


uint8_t calculate_ifs(uint8_t pk_length)
{
	if (pk_length > aMaxSIFSFrameSize)
		return aMinLIFSPeriod; // + ( ((pk_length * 8) / 250.00) / 0.34 );
	else
		return aMinSIFSPeriod; // + ( ((pk_length * 8) / 250.00) / 0.34 );
}

uint32_t calculate_gts_expiration()
{
	uint32_t exp_res;
	if( mac_PIB.macBeaconOrder > 9 )
		exp_res= 1;
	else
	{
		//#ifdef PLATFORM_MICAZ
			exp_res= powf(2,(8-mac_PIB.macBeaconOrder));
		//#else
		//	exp_res= powf(2,(8-mac_PIB.macBeaconOrder));
		//#endif
	}	
	//////////printfUART("alculat %i\n",exp_res ) ;
	return exp_res;
}

uint8_t check_csma_ca_send_conditions(uint8_t frame_length,uint8_t frame_control1)
{
	uint8_t ifs_symbols;
	uint32_t frame_tx_time;
	uint32_t remaining_gts_duration;
	
	
	ifs_symbols=calculate_ifs(frame_length);
	//wait_ifs=1;
	//call TimerAsync.set_ifs_symbols(ifs_symbols);
	
	////////////printfUART("ifs_symbols %i\n",ifs_symbols ) ;
	
	if (get_fc1_ack_request(frame_control1) == 1 )
		frame_tx_time =  frame_length + ACK_LENGTH + aTurnaroundTime + ifs_symbols;
	else
		frame_tx_time =  frame_length + ifs_symbols;
		
	atomic remaining_gts_duration = time_slot - ( call TimerAsync.get_current_number_backoff_on_time_slot() * aUnitBackoffPeriod);
	
	////////////printfUART("frame_tx %d remaing %d\n",frame_tx_time,remaining_gts_duration ) ;
	
	if (frame_tx_time < remaining_gts_duration)
		return 1;
	else
		return 0;

}

//DEFERENCE CHANGE
uint8_t check_csma_ca_backoff_send_conditions(uint32_t delay_backoffs)
{

	uint32_t number_of_sd_ticks=0;
	uint32_t current_ticks=0;
	uint32_t ticks_remaining =0;
	uint32_t number_of_backoffs_remaining =0;
	
	number_of_sd_ticks = call TimerAsync.get_sd_ticks();
	
	current_ticks = call TimerAsync.get_current_ticks();
	
	ticks_remaining = number_of_sd_ticks - current_ticks;
	
	number_of_backoffs_remaining = ticks_remaining / 5;
	
	if (number_of_backoffs_remaining > delay_backoffs)
		return 0;
	else
		return 1;



}

uint8_t check_gts_send_conditions(uint8_t frame_length)
{
	uint8_t ifs_symbols;
	uint32_t frame_tx_time;
	uint32_t remaining_gts_duration;
	

	ifs_symbols=calculate_ifs(frame_length);
	//wait_ifs=1;
	//call TimerAsync.set_ifs_symbols(ifs_symbols);
	
	////////////printfUART("ifs_symbols %i\n",ifs_symbols ) ;
	
	frame_tx_time =  frame_length + ACK_LENGTH + aTurnaroundTime + ifs_symbols;
	
	remaining_gts_duration = time_slot - ( call TimerAsync.get_current_number_backoff_on_time_slot() * aUnitBackoffPeriod);
	
	////////////printfUART("frame_tx %d remaing %d\n",frame_tx_time,remaining_gts_duration ) ;
	
	if (frame_tx_time < remaining_gts_duration)
		return 1;
	else
		return 0;
}

//////////////////////////////////////////////////////////////
////////////////////////GTS functions////////////////////////
/////////////////////////////////////////////////////////////

void init_GTS_db()
{
	//initialization of the GTS database
	int i;
atomic{
		for (i=0 ; i < 7 ; i++)
		{
			GTS_db[i].gts_id=0x00;
			GTS_db[i].starting_slot=0x00;
			GTS_db[i].length=0x00;
			GTS_db[i].direction=0x00;
			GTS_db[i].DevAddressType=0x0000;
		
		}
	}
return;
}

error_t remove_gts_entry(uint16_t DevAddressType)
{
	uint8_t r_lenght=0;
	//int r_start_slot=7;
	int i;
	
	atomic{
		for (i=0; i < 7 ; i++)
		{
			if( GTS_db[i].DevAddressType == DevAddressType )
			{
				
				r_lenght = GTS_db[i].length;
				//r_start_slot = i;
				//delete the values
				GTS_db[i].gts_id=0x00;
				GTS_db[i].starting_slot=0x00;
				GTS_db[i].length=0x00;
				GTS_db[i].direction=0x00;
				GTS_db[i].DevAddressType=0x0000;
				GTS_db[i].expiration=0x00;
				
				////////////printfUART("GTS Entry removed dev:%i len:%i pos %i\n", DevAddressType,r_lenght,i);
				GTS_startslot = GTS_startslot + r_lenght;
				GTS_descriptor_count--;
				final_CAP_slot = final_CAP_slot + r_lenght;
			}
			
			if ( r_lenght > 0)
			{
				if ( GTS_db[i].gts_id != 0x00 && GTS_db[i].DevAddressType !=0x0000)
				{				
					GTS_db[i-r_lenght].gts_id = GTS_db[i].gts_id;
					GTS_db[i-r_lenght].starting_slot = i-r_lenght;
					GTS_db[i-r_lenght].length = GTS_db[i].length;
					GTS_db[i-r_lenght].direction = GTS_db[i].direction;
					GTS_db[i-r_lenght].DevAddressType = GTS_db[i].DevAddressType;
					GTS_db[i-r_lenght].expiration = GTS_db[i].expiration;
					
					//delete the values
					GTS_db[i].gts_id=0x00;
					GTS_db[i].starting_slot=0x00;
					GTS_db[i].length=0x00;
					GTS_db[i].direction=0x00;
					GTS_db[i].DevAddressType=0x0000;
					GTS_db[i].expiration=0x00;
					
					////////////printfUART("UPDATED\n","" );
				}
			}
		}
	}
return SUCCESS;
}

error_t add_gts_entry(uint8_t gts_length,bool direction,uint16_t DevAddressType)
{
	int i;
	////////////printfUART("ADDING gts_length: %i\n", gts_length); 
	////////////printfUART("dir: %i\n", direction); 
	////////////printfUART("addr: %i\n", DevAddressType);

	//check aMinCAPLength
	if ( (GTS_startslot - gts_length) < 5 )
	{
		////////////printfUART("ADD FAIL%i\n", ""); 
		
	}
	
	//if it has more than 7 timeslots alocated
	if ( (GTS_startslot -gts_length) < 9 )
	{
		return FAIL;
	}
	
	//check if the address already exists in the GTS list
	for (i=0 ; i < 7 ; i++)
	{
		if ( GTS_db[i].DevAddressType == DevAddressType && GTS_db[i].direction == direction && GTS_db[i].gts_id > 0)
		{
			////////////printfUART("ALREADY ADDED\n", ""); 
			return FAIL;
		}
		if ( GTS_null_db[i].DevAddressType == DevAddressType && GTS_null_db[i].gts_id > 0)
		{
			////////////printfUART("REJECTED\n", ""); 
			return FAIL;
		}
		
		
	}
	
atomic{	
	
	////////////printfUART("GTS_startslot: %i\n", GTS_startslot); 
	GTS_startslot = GTS_startslot - gts_length;

	GTS_db[15-GTS_startslot].gts_id=GTS_id;
	GTS_db[15-GTS_startslot].starting_slot=GTS_startslot;
	GTS_db[15-GTS_startslot].length=gts_length;
	GTS_db[15-GTS_startslot].direction=direction;
	GTS_db[15-GTS_startslot].DevAddressType=DevAddressType;
	GTS_db[15-GTS_startslot].expiration=0x00;

	////////////printfUART("GTS Entry added start:%i len:%i\n", GTS_startslot,gts_length); 
	
	GTS_id++;
	GTS_descriptor_count++;
	
	final_CAP_slot = final_CAP_slot - gts_length;
	
	}
	return SUCCESS;
}


//GTS null functions
void init_GTS_null_db()
{
	//initialization of the GTS database
	int i;
	atomic{
		for (i=0 ; i < 7 ; i++)
		{
			GTS_null_db[i].gts_id=0x00;
			GTS_null_db[i].starting_slot=0x00;
			GTS_null_db[i].length=0x00;
			//GTS_null_db[i].direction=0x00;
			GTS_null_db[i].DevAddressType=0x0000;
			GTS_null_db[i].persistencetime=0x00;
		}
	}
return;
}


error_t add_gts_null_entry(uint8_t gts_length,bool direction,uint16_t DevAddressType)
{
	int i;
		
	//check if the address already exists in the GTS list
	for (i=0 ; i < 7 ; i++)
	{
		if ( GTS_null_db[i].DevAddressType == DevAddressType && GTS_null_db[i].gts_id > 0)
		{
			////////////printfUART("ALREADY ADDED null\n", ""); 
			return FAIL;
		}
	}
	
	for (i=0 ; i < 7 ; i++)
	{
		if ( GTS_null_db[i].DevAddressType==0x0000 && GTS_null_db[i].gts_id == 0x00)
		{
			GTS_null_db[i].gts_id=GTS_id;
			GTS_null_db[i].starting_slot=0x00;
			GTS_null_db[i].length=0x00;
			//GTS_null_db[i].direction=0x00;
			GTS_null_db[i].DevAddressType=DevAddressType;
			GTS_null_db[i].persistencetime=0x00;
			
			
			////////////printfUART("GTS null Entry added addr:%x\n", DevAddressType); 
			
			GTS_id++;
			GTS_null_descriptor_count++;
			
		return SUCCESS;
		}
	}

	
return FAIL;	
}

task void increment_gts_null()
{
	int i;
	
	////////////printfUART("init inc\n",""); 
atomic{
	for (i=0 ; i < 7 ; i++)
	{
		if ( GTS_null_db[i].DevAddressType != 0x0000 && GTS_null_db[i].gts_id != 0x00)
		{
			////////////printfUART("increm %x\n", GTS_null_db[i].DevAddressType); 
			GTS_null_db[i].persistencetime++;
		
		}
		
		if ( GTS_null_db[i].persistencetime > (aGTSDescPersistenceTime -1)  )
		{
			GTS_null_db[i].gts_id=0x00;
			GTS_null_db[i].starting_slot=0x00;
			GTS_null_db[i].length=0x00;
			//GTS_null_db[i].direction=0x00;
			GTS_null_db[i].DevAddressType=0x0000;
			GTS_null_db[i].persistencetime=0x00;
			
			////////////printfUART("GTS null removed addr:%x\n", GTS_null_db[i].DevAddressType); 
		
			atomic GTS_null_descriptor_count--;
		}
			
	}
	
	}
////////////printfUART("end inc\n",""); 
return;
}

task void check_gts_expiration()
{
	int i;
////////////printfUART("init exp\n",""); 
atomic{	
	atomic gts_expiration=calculate_gts_expiration();
	////////////printfUART("gts_expiration:%i\n", gts_expiration); 
	atomic gts_expiration=2;
	////////////printfUART("gts_expiration:%i\n", gts_expiration); 
	
	for (i=0 ; i < 7 ; i++)
	{
		
		if ( GTS_db[i].DevAddressType != 0x0000 && GTS_db[i].gts_id != 0x00)
		{
			if( GTS_db[i].expiration == (gts_expiration + 1) && GTS_db[i].direction ==0x00)
			{
				////////////printfUART("GTS expired addr:%x\n", GTS_null_db[i].DevAddressType); 
				//remove gts, indicate on the gts null list
				atomic{
				
					add_gts_null_entry(GTS_db[i].length,GTS_db[i].direction,GTS_db[i].DevAddressType);
					
					remove_gts_entry(GTS_db[i].DevAddressType);
				}
			}
			else
			{
				atomic GTS_db[i].expiration ++;
			}
		}
	}
	
	
	}
	////////////printfUART("end exp\n",""); 
return;
}

void init_available_gts_index()
	{
		int i=0;
		atomic{
			available_gts_index_count = GTS_SEND_BUFFER_SIZE;
			for(i=0;i < GTS_SEND_BUFFER_SIZE;i++)
			{
				available_gts_index[i]=i;
			}
		}
		return;
	}
/*****************************GTS BUFFER******************************/
void init_gts_slot_list()
{
	int i=0;
	for(i=0;i<7;i++)
	{
		gts_slot_list[i].element_count = 0x00;
		gts_slot_list[i].element_in = 0x00;
		gts_slot_list[i].element_out = 0x00;
	}
}


task void start_coordinator_gts_send()
{
atomic{

	coordinator_gts_send_pending_data =0;
	
	if(gts_slot_list[15-number_time_slot].element_count > 0)
	{
		if (check_gts_send_conditions(gts_send_buffer[gts_slot_list[15-number_time_slot].gts_send_frame_index[gts_slot_list[15-number_time_slot].element_out]].length) == 1 )
		{
			
			gts_send_buffer[gts_slot_list[15-number_time_slot].gts_send_frame_index[gts_slot_list[15-number_time_slot].element_out]].length = gts_send_buffer[gts_slot_list[15-number_time_slot].gts_send_frame_index[gts_slot_list[15-number_time_slot].element_out]].length -2;
			
			call PD_DATA.request(gts_send_buffer[gts_slot_list[15-number_time_slot].gts_send_frame_index[gts_slot_list[15-number_time_slot].element_out]].length,(uint8_t *)&gts_send_buffer[gts_slot_list[15-number_time_slot].gts_send_frame_index[gts_slot_list[15-number_time_slot].element_out]]);
	
			available_gts_index_count++;
			available_gts_index[available_gts_index_count] = gts_slot_list[15-number_time_slot].gts_send_frame_index[gts_slot_list[15-number_time_slot].element_out];
			
			gts_slot_list[15-number_time_slot].element_count--;
			gts_slot_list[15-number_time_slot].element_out++;
			
			if (gts_slot_list[15-number_time_slot].element_out == GTS_SEND_BUFFER_SIZE)
				gts_slot_list[15-number_time_slot].element_out=0;

			if(gts_slot_list[15-number_time_slot].element_count > 0 )
			{
				coordinator_gts_send_pending_data =1;
				coordinator_gts_send_time_slot = number_time_slot;
			}
		}
	}
}
return;
}

task void start_gts_send()
{

	atomic{
	gts_send_pending_data = 0;
	
	if(gts_send_buffer_count > 0)
	{
		if (check_gts_send_conditions(gts_send_buffer[gts_send_buffer_msg_out].length) == 1 )
		{

			gts_send_buffer[gts_send_buffer_msg_out].length = gts_send_buffer[gts_send_buffer_msg_out].length -2;

			call PD_DATA.request(gts_send_buffer[gts_send_buffer_msg_out].length,(uint8_t *)&gts_send_buffer[gts_send_buffer_msg_out]);
	
			gts_send_buffer_count --;
			gts_send_buffer_msg_out++;

			if (gts_send_buffer_msg_out == GTS_SEND_BUFFER_SIZE)
				gts_send_buffer_msg_out=0;

			////////////printfUART("after send %i %i %i \n",gts_send_buffer_count,gts_send_buffer_msg_in,gts_send_buffer_msg_out);
			
			if (gts_send_buffer_count > 0)
				gts_send_pending_data = 1;	
		}
	}

}
return;
}

//////////////////////////////////////////////////////////////
//////////Indirect transmission functions////////////////////
/////////////////////////////////////////////////////////////

void init_indirect_trans_buffer()
{
	int i;
	for(i=0;i<INDIRECT_BUFFER_SIZE;i++)
	{
		indirect_trans_queue[i].handler = 0x00;
		indirect_trans_count=0;
	}

return;
}


error_t remove_indirect_trans(uint8_t handler)
{

	int i;
	uint8_t removed_ok=0;
	for(i=0;i<INDIRECT_BUFFER_SIZE;i++)
	{
		if (indirect_trans_queue[i].handler == handler)
		{
			indirect_trans_queue[i].handler = 0x00;
			removed_ok = 1;
			indirect_trans_count--;
			break;
		}
	}

	if (removed_ok == 0) 
	{
		return MAC_INVALID_HANDLE;
	}
	else
	{
		return SUCCESS;
	}
}


void increment_indirect_trans()
{
	int i;
	for(i=0;i<INDIRECT_BUFFER_SIZE;i++)
	{
		if (indirect_trans_queue[i].handler != 0x00)
		{
			indirect_trans_queue[i].transaction_persistent_time++;
			if (indirect_trans_queue[i].transaction_persistent_time == mac_PIB.macTransactionPersistenceTime )
				remove_indirect_trans(indirect_trans_queue[i].handler);
		}
	}

return;
}

void send_ind_trans_addr(uint32_t DeviceAddress[])
{
	
	uint8_t destination_address=0;
	
	dest_short *dest_short_ptr =0;
	dest_long *dest_long_ptr=0;
	
	int i=0;
	MPDU *frame_ptr=0;
	
	//printfUART("send_ind_trans_addr DeviceAddress0: %y DeviceAddress1: %y \n",DeviceAddress[0],DeviceAddress[1]);

    //list_indirect_trans_buffer();

		for(i=0;i<INDIRECT_BUFFER_SIZE;i++)
		{
			if (indirect_trans_queue[i].handler > 0x00)
			{
				frame_ptr = (MPDU *)indirect_trans_queue[i].frame;
				destination_address=get_fc2_dest_addr(frame_ptr->frame_control2);
				
				switch(destination_address)
				{
					case LONG_ADDRESS: dest_long_ptr = (dest_long *) frame_ptr->data;
										break;
					case SHORT_ADDRESS: dest_short_ptr = (dest_short *) frame_ptr->data; 								
										break;
				}
				
				//check the full address
				if ( (dest_long_ptr->destination_address0 == DeviceAddress[1] && dest_long_ptr->destination_address1 == DeviceAddress[0]) || ( dest_short_ptr->destination_address == (uint16_t)DeviceAddress[0] ))
				{
					
					if (send_buffer_msg_in == SEND_BUFFER_SIZE)
						send_buffer_msg_in=0;
						
					memcpy(&send_buffer[send_buffer_msg_in],(MPDU *) &indirect_trans_queue[i].frame,sizeof(MPDU));
					
					//enable retransmissions
					send_buffer[send_buffer_msg_in].retransmission =0;
					send_buffer[send_buffer_msg_in].indirect = i + 1;
					
					//check upon reception
					indirect_trans_queue[i].handler=0x00;
					//verify temporary error on the association request
					
					indirect_trans_count--;
					if(indirect_trans_count > INDIRECT_BUFFER_SIZE )
					{
						indirect_trans_count=0;
					}
					
					atomic send_buffer_count++;
					atomic send_buffer_msg_in++;
			
					post send_frame_csma();
					
					//printfUART("i send\n","");
					
					return;
				}
			}
		}
		//printfUART("i not found","");

	
return;
} 
/*
  event void CC2420Config.syncDone( error_t error )
  {
  
	//printfUART("CC2420Config %i p %x sa %x\n",call CC2420Config.isAddressRecognitionEnabled(),call CC2420Config.getPanAddr(), call CC2420Config.getShortAddr()); 
  
  return;
  }

*/

/***************************DEBUG FUNCTIONS******************************/
/* This function are list functions with the purpose of debug, to use then uncomment the declatarion
on top of this file*/
/*

void list_mac_pib()
{
//////////printfUART("mac_PIB.macAckWaitDuration: %x\n",mac_PIB.macAckWaitDuration);
//////////printfUART("mac_PIB.macAssociationPermit: %i\n",mac_PIB.macAssociationPermit);
//////////printfUART("mac_PIB.macAutoRequest: %i\n",mac_PIB.macAutoRequest);
//////////printfUART("mac_PIB.macBattLifeExt %i\n",mac_PIB.macBattLifeExt);
//////////printfUART("mac_PIB.macBattLifeExtPeriods %i\n",mac_PIB.macBattLifeExtPeriods);
//beacon payload
//////////printfUART("mac_PIB.macBeaconPayloadLenght %i\n",mac_PIB.macBeaconPayloadLenght);
//////////printfUART("mac_PIB.macBeaconOrder %i\n",mac_PIB.macBeaconOrder);
//////////printfUART("mac_PIB.macBeaconTxTime %i\n",mac_PIB.macBeaconTxTime);
//////////printfUART("mac_PIB.macBSN %i\n",mac_PIB.macBSN);
//////////printfUART("mac_PIB.macCoordExtendedAddress0 %y\n",mac_PIB.macCoordExtendedAddress0);
//////////printfUART("mac_PIB.macCoordExtendedAddress1 %y\n",mac_PIB.macCoordExtendedAddress1);
//////////printfUART("mac_PIB.macCoordShortAddress: %x\n",mac_PIB.macCoordShortAddress);
//////////printfUART("mac_PIB.macDSN: %x\n",mac_PIB.macDSN);
//////////printfUART("mac_PIB.macGTSPermit: %x\n",mac_PIB.macGTSPermit);
//////////printfUART("mac_PIB.macMaxCSMABackoffs: %x\n",mac_PIB.macMaxCSMABackoffs);
//////////printfUART("mac_PIB.macMinBE: %x\n",mac_PIB.macMinBE);
//////////printfUART("mac_PIB.macPANId: %x\n",mac_PIB.macPANId);
//////////printfUART("mac_PIB.macPromiscuousMode: %x\n",mac_PIB.macPromiscuousMode);
//////////printfUART("mac_PIB.macRxOnWhenIdle: %x\n",mac_PIB.macRxOnWhenIdle);
//////////printfUART("mac_PIB.macShortAddress: %y\n",mac_PIB.macShortAddress);
//////////printfUART("mac_PIB.macSuperframeOrder: %x\n",mac_PIB.macSuperframeOrder);
//////////printfUART("mac_PIB.macTransactionPersistenceTime: %y\n",mac_PIB.macTransactionPersistenceTime);

return;
}

void list_gts()
{
	int i;
	//////////printfUART("GTS list%i\n", GTS_descriptor_count); 
	
	for (i=0; i< 7;i++)
	{
		//////////printfUART("GTSID: %i",GTS_db[i].gts_id); 	
		//////////printfUART("start slot: %i",GTS_db[i].starting_slot);
		//////////printfUART("lenght: %i",GTS_db[i].length); 	
		//////////printfUART("dir: %i",GTS_db[i].direction); 	
		//////////printfUART("DevAddressType: %i",GTS_db[i].DevAddressType);
	 	//////////printfUART("expiration: %i \n",GTS_db[i].expiration);
	}
	
}

void list_my_gts()
{
atomic{
		//////////printfUART("SEND GTS s_GTSss: %i s_GTS_length: %i\n",s_GTSss,s_GTS_length); 	
		
		//////////printfUART("RECEIVE GTS r_GTSss: %i r_GTS_length: %i\n",r_GTSss,r_GTS_length); 
}
}
*/

void list_indirect_trans_buffer()
{
	int i;
	printfUART("indirect_trans_count %i\n", indirect_trans_count); 
	
	for (i=0; i< INDIRECT_BUFFER_SIZE;i++)
	{
		printfUART("hand: %i \n",indirect_trans_queue[i].handler); 
		
		//printfUART("start slot: %i",GTS_db[i].starting_slot);

	}
	
}
/*
void list_gts_null()
{
	int i;
	//////////printfUART("GTS null list%i\n", GTS_null_descriptor_count); 
	
	for (i=0; i< GTS_null_descriptor_count;i++)
	{
		////////////printfUART("GTSID: %i",GTS_null_db[i].gts_id); 	
		//////////printfUART("start slot: %i",GTS_null_db[i].starting_slot);
		//////////printfUART("lenght: %i",GTS_null_db[i].length); 	
		////////////printfUART("dir: %i",GTS_null_db[i].direction); 	
		//////////printfUART("DevAddressType: %i \n",GTS_null_db[i].DevAddressType); 
		//////////printfUART("persistencetime: %i \n",GTS_null_db[i].persistencetime); 
	}
	
}

*/


}

