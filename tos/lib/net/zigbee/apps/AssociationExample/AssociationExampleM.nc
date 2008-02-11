/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 *
 */
#include <Timer.h>
#include "printfUART.h"

module AssociationExampleM {

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


	//number of data frames sent after association and before dissassociation
	uint16_t frame_counter=0;

	//associated devices
	uint16_t address_poll = 0x0003;
		
	neighbour_table associated_devices[4];
	
	uint16_t search_associated_devices(uint32_t ext1, uint32_t ext2);
	
	uint8_t number_associations =0;
	
	PANDescriptor pan_des;

	void try_disassociation();
	
	uint16_t my_short_address= 0xffff;
	
	uint8_t received_beacon_count=0;
	uint32_t coordinator_addr[2];
	
	uint8_t go_associate =0;

  event void Boot.booted() {
    	
	printfUART_init();
	
	if (TYPE_DEVICE == COORDINATOR)
	{
		//assign the short address of the device
		my_short_address = 0x0000;
		call Timer0.startOneShot(3000);
	}
	else
	{
		call Timer0.startOneShot(8000);
	}

  }

 

event void Timer0.fired() {
    
	uint8_t v_temp[2];
	uint32_t c_addr[2];

	if (TYPE_DEVICE == COORDINATOR)
	{
	
		associated_devices[0].extended1=0x00000002;
		associated_devices[0].extended2=0x00000002;
		associated_devices[0].assigned_short=0x0004;
	
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
		
		//call Timer_Send.startPeriodic(3000);
	}
	else
	{
		//the device will try to scan all the channels looking for a suitable PAN coordinator
		//only the ACTIVE SCAN/ED SCAN  and a full channel scan is implemented
		//call MLME_SCAN.request(PASSIVE_SCAN,0xFFFFFFFF,7);
		//call MLME_SCAN.request(ED_SCAN,0xFFFFFFFF,0x10);
		
		c_addr[0] = 0x00000000;
		c_addr[1] = 0x00000000;
		
		call MLME_ASSOCIATE.request(0x15,SHORT_ADDRESS,0x1234,c_addr,0x00,0x00);
		
		//call Leds.redOn();
		call Timer0.stop();
	}
}
  
event void Timer_Send.fired() {

	uint32_t SrcAddr[2];
	uint32_t DstAddr[2];
	
	uint8_t msdu_payload[4];
	
	frame_counter++;
	
	if (frame_counter == 5)
	{
		//after sending 5 data frames the device tries to dissassociate from the PAN
		call Timer_Send.stop();
		try_disassociation();
	
	}
	else
	{
		if (my_short_address == 0x0000ffff)
			return;
		
		SrcAddr[0]=0x00000000;
		SrcAddr[1]=my_short_address;
		
		DstAddr[0]=0x00000000;
		DstAddr[1]=0x00000000;
				
		call MCPS_DATA.request(SHORT_ADDRESS, MAC_PANID, SrcAddr, SHORT_ADDRESS, MAC_PANID, DstAddr, 4, msdu_payload,1,set_txoptions(1,0,0,0));
	}
}

/*****************************************************************************************************/  
/**************************************MLME-SCAN*******************************************************/
/*****************************************************************************************************/ 
event error_t MLME_SCAN.confirm(uint8_t status,uint8_t ScanType, uint32_t UnscannedChannels, uint8_t ResultListSize, uint8_t EnergyDetectList[], SCAN_PANDescriptor PANDescriptorList[])
{
//the device channel scan ends with a scan confirm containing a list of the PANs (beacons received during the scan) 

	int i;
	uint8_t max_lqi=0;
	uint8_t best_pan_index=0;
	
	//call Leds.redOff();
	
	printfUART("MLME_SCAN.confirm %i\n", ScanType);
	
	if (ScanType == ORPHAN_SCAN)
	{
		printfUART("new scan \n", "");
	
		call MLME_SCAN.request(PASSIVE_SCAN,0xFFFFFFFF,7);
		return SUCCESS;
	}
	
	
	
	if(ScanType == ED_SCAN)
	{
		for(i=0;i<ResultListSize;i++)
		{
			printfUART("ED SCAN %i %i\n", (0x0A + i),EnergyDetectList[i]);
		}
		return SUCCESS;
	}
	
	for (i=0; i<ResultListSize;i++)
	{		/*
			printfUART("cord id %i", PANDescriptorList[i].CoordPANId);
			printfUART("CoordAddress %i", PANDescriptorList[i].CoordAddress);
			printfUART("LogicalChannel %i", PANDescriptorList[i].LogicalChannel);
			printfUART("SuperframeSpec %i", PANDescriptorList[i].SuperframeSpec);
			printfUART("lqi %i\n", PANDescriptorList[i].lqi);
			*/
		if(max_lqi < PANDescriptorList[i].lqi)
		{
			max_lqi =PANDescriptorList[i].lqi;
			best_pan_index = i;
		}
	}
	
	printfUART("SELECTED cord id %i", PANDescriptorList[best_pan_index].CoordPANId);
	printfUART("CoordAddress %i", PANDescriptorList[best_pan_index].CoordAddress);
	printfUART("LogicalChannel %i", PANDescriptorList[best_pan_index].LogicalChannel);
	printfUART("SuperframeSpec %i", PANDescriptorList[best_pan_index].SuperframeSpec);
	printfUART("lqi %i\n", PANDescriptorList[best_pan_index].lqi);
	
	coordinator_addr[0] = 0x00000001;
	
	coordinator_addr[1] = (uint32_t)PANDescriptorList[best_pan_index].CoordAddress;
	
	//pan_des = PANDescriptorList[best_pan_index];

	
	//BUILD the PAN descriptor of the COORDINATOR
	//assuming that the adress is short
	pan_des.CoordAddrMode = SHORT_ADDRESS;
	pan_des.CoordPANId = PANDescriptorList[best_pan_index].CoordAddress;
	pan_des.CoordAddress0=0x00000000;
	pan_des.CoordAddress1=0x00000000;
	pan_des.LogicalChannel=PANDescriptorList[best_pan_index].LogicalChannel;
	//superframe specification field
	pan_des.SuperframeSpec = PANDescriptorList[best_pan_index].SuperframeSpec;
	
	pan_des.GTSPermit=0x01;
	pan_des.LinkQuality=0x00;
	pan_des.TimeStamp=0x000000;
	pan_des.SecurityUse=0;
	pan_des.ACLEntry=0x00;
	pan_des.SecurityFailure=0x00;
	
	received_beacon_count=0;
	go_associate=1;
	//enables the TimerAsync events, in order to enable the synchronization with the PAN coordinator
	call MLME_SYNC.request(PANDescriptorList[best_pan_index].LogicalChannel,0);
	
	
	
	return SUCCESS;
}

/*****************************************************************************************************/  
/**************************************MLME-ORPHAN****************************************************/
/*****************************************************************************************************/ 
event error_t MLME_ORPHAN.indication(uint32_t OrphanAddress[1], uint8_t SecurityUse, uint8_t ACLEntry)
{

	uint16_t assigned_address;
	
	assigned_address = search_associated_devices(OrphanAddress[0],OrphanAddress[1]);
	
	if (assigned_address == 0x0000)
	{
		printfUART("not my child\n","");
	}
	else
	{
		//printfUART("my child\n","");
		call MLME_ORPHAN.response(OrphanAddress,assigned_address,0x01, 0x00);
	}

	return SUCCESS;
}

	uint16_t search_associated_devices(uint32_t ext1, uint32_t ext2)
	{
		int i;
		
		for(i=0;i<4;i++)
		{
			//printfUART("ad %i %i %i\n",associated_devices[i].extended1,associated_devices[i].extended2,associated_devices[i].assigned_short);
			if(associated_devices[i].extended1 == ext1 && associated_devices[i].extended2 == ext2 )
			{
			
				return associated_devices[i].assigned_short;
			}
		
		}
		
		return 0x0000;
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
		printfUART("SL\n","");
		
		call MLME_SCAN.request(ORPHAN_SCAN,0xFFFFFFFF,7);


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
	
	if (go_associate==1)
	{
		received_beacon_count++;
		
		printfUART("bn %i\n", received_beacon_count);
		
		if (received_beacon_count==5)
		{
				printfUART("sa \n", "");
				go_associate=0;
				call MLME_ASSOCIATE.request(pan_des.LogicalChannel,SHORT_ADDRESS,pan_des.CoordPANId,coordinator_addr,0x00,0x00);
		
		
		}
		
	}

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
		//the coordinator device receives the association request and assigns the device with a short address
		address_poll ++;
		number_associations++;
		
		printfUART("address pool: %i %i\n", address_poll,number_associations);
		
		call MLME_ASSOCIATE.response(DeviceAddress,address_poll, CMD_RESP_ASSOCIATION_SUCCESSFUL, 0);
	return SUCCESS;
}

event error_t MLME_ASSOCIATE.confirm(uint16_t AssocShortAddress, uint8_t status)
{

//the end device receives the association confirm and activates the data frame send timer
	uint8_t v_temp[2];
	
	printfUART("MLME_ASSOCIATE.confirm\n", "");

	printfUART("Short: %x\n", AssocShortAddress);
	printfUART("Status: %i\n", status);
	
	if (AssocShortAddress == 0x0000)
	{
		//call Timer0.startOneShot(8000);
	
	}
	else
	{
		
		my_short_address = AssocShortAddress;
			
		v_temp[0] = (my_short_address >> 8);
		v_temp[1] = my_short_address;
		
		//call Leds.redOn();
		call MLME_SET.request(MACSHORTADDRESS,v_temp);
		
		call Timer_Send.startPeriodic(3000);
		
		call Timer0.stop();
	}
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
	//call Leds.led1Toggle();
	
return SUCCESS;
}



void try_disassociation()
{

	uint32_t coordinator_addr1[2];
	
	coordinator_addr1[0] = 0x00000001;
	
	coordinator_addr1[1] = 0x00000001;
	
	call MLME_DISASSOCIATE.request(coordinator_addr1,MAC_PAN_DEVICE_LEAVE,0x00);
	

return;
}
  
}

