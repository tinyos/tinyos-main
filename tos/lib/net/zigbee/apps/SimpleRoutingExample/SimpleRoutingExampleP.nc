/*
 *
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 *
 */

#include <Timer.h>
#include "printfUART.h"

module SimpleRoutingExampleP {

	uses interface Boot;
	uses interface Leds;
	
	uses interface Timer<TMilli> as Timer0;
	
	uses interface Timer<TMilli> as Timer_Send;
	//MAC interfaces
	
	uses interface MLME_START;
	
	uses interface MLME_GET;
	uses interface MLME_SET;
	
	uses interface MLME_BEACON_NOTIFY;
	uses interface MLME_GTS;
	
	uses interface MLME_ASSOCIATE;
	uses interface MLME_DISASSOCIATE;
	
	uses interface MLME_ORPHAN;
	
	uses interface MLME_SYNC;
	uses interface MLME_SYNC_LOSS;
	
	uses interface MLME_RESET;
	
	uses interface MLME_SCAN;
	
	uses interface MCPS_DATA;
  
}
implementation {

	PANDescriptor pan_des;
	
	uint32_t my_short_address=0x00000000;

	uint32_t DestinationMote[2];
	uint32_t SourceMoteAddr[2];
	
	//number of routed packet (coordinator)
	uint8_t routed_packets = 0x00;
	

  event void Boot.booted() {
    	
	printfUART_init();
	
	printfUART("i_am_pan: %i\n", TYPE_DEVICE);
	
	DestinationMote[0]=0x00000000;
	DestinationMote[1]=0x00000002;
	
	if (TYPE_DEVICE == COORDINATOR)
	{
		my_short_address = 0x0000;
		call Timer0.startOneShot(4000);
	}
	else
	{
		call Timer0.startOneShot(4000);
	}

  }
 

  event void Timer0.fired() {
    
	uint8_t v_temp[2];
	
	
	if (TYPE_DEVICE == END_DEVICE)
	{
	
		my_short_address = TOS_NODE_ID;
		
		//set the MAC short address variable
		v_temp[0] = (uint8_t)(my_short_address >> 8);
		v_temp[1] = (uint8_t)(my_short_address );
		
		call MLME_SET.request(MACSHORTADDRESS,v_temp);
	
		//set the MAC PANID variable
		v_temp[0] = (uint8_t)(MAC_PANID >> 8);
		v_temp[1] = (uint8_t)(MAC_PANID );
		
		call MLME_SET.request(MACPANID,v_temp);
		
		call Timer_Send.startPeriodic(3000);

	}
	else
	{
		//set the MAC short address variable
		v_temp[0] = (uint8_t)(my_short_address >> 8);
		v_temp[1] = (uint8_t)(my_short_address );
		
		call MLME_SET.request(MACSHORTADDRESS,v_temp);
	
		//set the MAC PANID variable
		v_temp[0] = (uint8_t)(MAC_PANID >> 8);
		v_temp[1] = (uint8_t)(MAC_PANID );
		
		call MLME_SET.request(MACPANID,v_temp);
	
		//start sending beacons
		call MLME_START.request(MAC_PANID, LOGICAL_CHANNEL, BEACON_ORDER, SUPERFRAME_ORDER,1,0,0,0,0);
		
		//call Timer_send.start(TIMER_REPEAT,8000);
	}
		
  }
  
event void Timer_Send.fired() {
	
	
	uint8_t msdu_payload[4];
	
	DestinationMote[0]=0x00000000;
	DestinationMote[1]=0x00000000;
	
	//NKL destination address, coordinator will route packet to this address
	msdu_payload[0] = 0x00;
	msdu_payload[1] = 0x03;
	
	SourceMoteAddr[0]=0x00000000;
	SourceMoteAddr[1]=TOS_NODE_ID;
	
	if (TOS_NODE_ID == 0x02)
	{
		call Leds.led2Toggle();																									//set_txoptions(ack, gts, indirect_transmission, security)
		call MCPS_DATA.request(SHORT_ADDRESS, MAC_PANID, SourceMoteAddr, SHORT_ADDRESS, MAC_PANID, DestinationMote, 2, msdu_payload,1,set_txoptions(1,0,0,0));
	}

	
	}

/*****************************************************************************************************/  
/**************************************MLME-SCAN*******************************************************/
/*****************************************************************************************************/ 
event error_t MLME_SCAN.confirm(uint8_t status,uint8_t ScanType, uint32_t UnscannedChannels, uint8_t ResultListSize, uint8_t EnergyDetectList[], SCAN_PANDescriptor PANDescriptorList[])
{

	return SUCCESS;
}

/*****************************************************************************************************/  
/**************************************MLME-ORPHAN****************************************************/
/*****************************************************************************************************/ 
event error_t MLME_ORPHAN.indication(uint32_t OrphanAddress[1], uint8_t SecurityUse, uint8_t ACLEntry)
{

	return SUCCESS;
}
/*****************************************************************************************************/  
/**************************************MLME-RESET*****************************************************/
/*****************************************************************************************************/ 
event error_t MLME_RESET.confirm(uint8_t status)
{



	return SUCCESS;
}
/*****************************************************************************************************/  
/**************************************MLME-SYNC-LOSS*************************************************/
/*****************************************************************************************************/ 
event error_t MLME_SYNC_LOSS.indication(uint8_t LossReason)
{

	return SUCCESS;
}
   
/*****************************************************************************************************/  
/**************************************MLME-GTS*******************************************************/
/*****************************************************************************************************/ 
event error_t MLME_GTS.confirm(uint8_t GTSCharacteristics, uint8_t status)
{
	
	return SUCCESS;
}

event error_t MLME_GTS.indication(uint16_t DevAddress, uint8_t GTSCharacteristics, bool SecurityUse, uint8_t ACLEntry)
{
	return SUCCESS;
}
/*****************************************************************************************************/  
/**************************************MLME-BEACON NOTIFY*********************************************/
/*****************************************************************************************************/ 
event error_t MLME_BEACON_NOTIFY.indication(uint8_t BSN,PANDescriptor pan_descriptor, uint8_t PenAddrSpec, uint8_t AddrList, uint8_t sduLength, uint8_t sdu[])
{

	return SUCCESS;
}
/*****************************************************************************************************/  
/**************************************MLME-START*****************************************************/
/*****************************************************************************************************/ 
event error_t MLME_START.confirm(uint8_t status)
{


return SUCCESS;
}
 /*****************************************************************************************************/  
/**********************				  MLME-SET		  	    ******************************************/
/*****************************************************************************************************/ 
  
event error_t MLME_SET.confirm(uint8_t status,uint8_t PIBAttribute)
{


return SUCCESS;
}
/*****************************************************************************************************/  
/*************************			MLME-GET			    ******************************************/
/*****************************************************************************************************/ 
event error_t MLME_GET.confirm(uint8_t status,uint8_t PIBAttribute, uint8_t PIBAttributeValue[])
{


return SUCCESS;
}
	
	
/*****************************************************************************************************/  
/**************************************MLME-ASSOCIATE*************************************************/
/*****************************************************************************************************/ 
event error_t MLME_ASSOCIATE.indication(uint32_t DeviceAddress[], uint8_t CapabilityInformation, bool SecurityUse, uint8_t ACLEntry)
{

	return SUCCESS;
}

event error_t MLME_ASSOCIATE.confirm(uint16_t AssocShortAddress, uint8_t status)
{

	return SUCCESS;
}
	/*****************************************************************************************************/  
/**************************************MLME-DISASSOCIATE**********************************************/
/*****************************************************************************************************/ 
event error_t MLME_DISASSOCIATE.indication(uint32_t DeviceAddress[], uint8_t DisassociateReason, bool SecurityUse, uint8_t ACLEntry)
{
	return SUCCESS;
}
  
event error_t MLME_DISASSOCIATE.confirm(uint8_t status)
{
	return SUCCESS;
}
  /*****************************************************************************************************/  
/*****************************************************************************************************/  
/****************					MCPS EVENTS 				 *************************************/
/*****************************************************************************************************/ 
/*****************************************************************************************************/  


/*****************************************************************************************************/  
/*********************					MCPS-DATA 		  	   ***************************************/
/*****************************************************************************************************/ 
event error_t MCPS_DATA.confirm(uint8_t msduHandle, uint8_t status)
{
	
return SUCCESS;
}  
event error_t MCPS_DATA.indication(uint16_t SrcAddrMode, uint16_t SrcPANId, uint32_t SrcAddr[2], uint16_t DstAddrMode, uint16_t DestPANId, uint32_t DstAddr[2], uint16_t msduLength,uint8_t msdu[100],uint16_t mpduLinkQuality, uint16_t SecurityUse, uint16_t ACLEntry)
{

//routing procedure, the short address of the destination device is the first 2 bytes of the data payload
		if (TYPE_DEVICE == COORDINATOR)
		{
			
			//route to the desired address
			DestinationMote[0]=0x00000000;
			DestinationMote[1]=(uint32_t) msdu[1];
			
			routed_packets++;
			msdu[0] = routed_packets;
																										//set_txoptions(ack, gts, indirect_transmission, security)
			call MCPS_DATA.request(SHORT_ADDRESS, MAC_PANID, SrcAddr, SHORT_ADDRESS, MAC_PANID, DestinationMote, 1, msdu,1,set_txoptions(1,0,0,0));
		}
		else
		{
		
			call Leds.led1Toggle();
		
		}
		
	
	
return SUCCESS;
}

  
}

