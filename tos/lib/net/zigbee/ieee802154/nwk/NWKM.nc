/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 *
 */
#include <Timer.h>
#include "printfUART.h"

module NWKM {
	
//uses
	uses interface Leds;

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


	uses interface Random;

//provides

	provides interface Init;
	provides interface NLDE_DATA;

	//NLME NWK Management services
    provides interface NLME_NETWORK_FORMATION;
   	provides interface NLME_NETWORK_DISCOVERY;
	provides interface NLME_START_ROUTER;
	provides interface NLME_JOIN;
	provides interface NLME_LEAVE;
	provides interface NLME_SYNC;
 
	/*  
	provides interface NLME_PERMIT_JOINING;
	provides interface NLME_DIRECT_JOIN;
	provides interface NLME_RESET;
*/	
	provides interface NLME_GET;
	provides interface NLME_SET;

  
}
implementation {


	nwkIB nwk_IB;
	
	uint8_t device_type = END_DEVICE;
	
/*****************************************************/
/*************Neighbourtable Variables****************/
/*****************************************************/ 

	//neighbour table array:
	neighbortableentry neighbortable[NEIGHBOUR_TABLE_SIZE];
	//number of neigbourtable entries:
	uint8_t neighbour_count;
	//the index of the parents neighbortable entry
	uint8_t parent;
	

/*****************************************************/
/****************ASSOCIATION Variables********************/
/*****************************************************/ 

	//CURRENT NETWORK ADDRESS
	uint16_t networkaddress=0x0000;

	//COORDINATOR
	//address assignement variables
	uint8_t depth=0;
	uint8_t cskip=0;
	
	uint8_t cskip_routing=0;

	//neighbour table parent index
	uint8_t parent_index;

	//NON COORDINATOR

	//current pan characteristics
	uint16_t panid;
	uint8_t beaconorder;
	uint8_t superframeorder;
	
	//next child router address
	uint16_t next_child_router_address;
	uint8_t number_child_router=0x01;
	uint8_t number_child_end_devices=0x01;
/*****************************************************/
/****************Integer Variables********************/
/*****************************************************/ 

	uint8_t joined=0;
	uint8_t sync_loss=0;
	//uint8_t synchronizing=0;
	uint8_t syncwait;
	
	
	//USED AFTER DE SCAN //GIVE SOME TIME TO THE DEVICE TO SYNC WITH THE PARENT
	uint8_t received_beacon_count=0;
	
	uint8_t go_associate =0;
	
	PANDescriptor pan_des;
	uint32_t coordinator_addr[2];
/******************************************************/
/*********NEIGHBOuRTABLE  MANAGEMENT FUNCTIONS*********/
/******************************************************/ 

	void init_nwkIB();
	
	uint8_t check_neighbortableentry(uint8_t addrmode,uint32_t Extended_Address0,uint32_t Extended_Address1);
	
	void add_neighbortableentry	(uint16_t PAN_Id,uint32_t Extended_Address0,uint32_t Extended_Address1,uint32_t Network_Address,uint8_t Device_Type,uint8_t Relationship);
	void update_neighbortableentry (uint16_t PAN_Id,uint32_t Extended_Address0,uint32_t Extended_Address1,uint32_t Network_Address,uint8_t Device_Type,uint8_t Relationship);	
	
	uint8_t find_suitable_parent();
	
	uint16_t Cskip(uint8_t d);
	
	uint16_t nexthopaddress(uint16_t destinationaddress,uint8_t d);
	
	void list_neighbourtable();



 command error_t Init.init() {
  	
	printfUART_init();//make the possibility to print
		
	init_nwkIB();
	
	nwk_IB.nwkSequenceNumber=call Random.rand16();
  
	return SUCCESS;
 }


 
/*****************************************************************************************************/  
/**************************************MLME-SCAN*******************************************************/
/*****************************************************************************************************/ 
event error_t MLME_SCAN.confirm(uint8_t status,uint8_t ScanType, uint32_t UnscannedChannels, uint8_t ResultListSize, uint8_t EnergyDetectList[], SCAN_PANDescriptor PANDescriptorList[])
{
//FAULT-TOLERANCE

//the device channel scan ends with a scan confirm containing a list of the PANs (beacons received during the scan) 

	int i;
	uint8_t max_lqi=0;
	uint8_t best_pan_index=0;
	
	
	networkdescriptor networkdescriptorlist[1];
	
	
	//call Leds.redOff();
	
	printfUART("4 rec scan\n", "");
	
	//printfUART("MLME_SCAN.confirm %i\n", ScanType);
	
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
	
	
	
	/*
	
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
	
	*/

	
	
	printfUART("5 en sync %x \n", PANDescriptorList[best_pan_index].LogicalChannel);
	// the sync enables the TimerAsync events, in order to enable the synchronization with the PAN coordinator
	call MLME_SYNC.request(PANDescriptorList[best_pan_index].LogicalChannel,0);
	
	
	
	//The networkdescriptorlist must contain information about every network that was heard
	
	//make NetworkDescriptorList out of the PanDescriptorList


    printfUART("6 add neigh\n", "");

	networkdescriptorlist[0].PANId=PANDescriptorList[best_pan_index].CoordPANId;
	networkdescriptorlist[0].LogicalChannel=LOGICAL_CHANNEL;
	networkdescriptorlist[0].StackProfile=0x00;
	networkdescriptorlist[0].ZigBeeVersion=0x01;
	networkdescriptorlist[0].BeaconOrder=7;
	networkdescriptorlist[0].SuperframeOrder=6;
	networkdescriptorlist[0].PermitJoining=1;

	add_neighbortableentry(networkdescriptorlist[0].PANId,0x00000000,0x00000000,PANDescriptorList[best_pan_index].CoordAddress,COORDINATOR,NEIGHBOR_IS_PARENT);
	
	signal NLME_NETWORK_DISCOVERY.confirm(1,networkdescriptorlist, NWK_SUCCESS);
	
	
	
	return SUCCESS;
}

/*****************************************************************************************************/  
/**************************************MLME-ORPHAN****************************************************/
/*****************************************************************************************************/ 
event error_t MLME_ORPHAN.indication(uint32_t OrphanAddress[1], uint8_t SecurityUse, uint8_t ACLEntry)
{

	
		
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
	////printfUART("MLME_SYNC_LOSS.indication\n", ""); 
	sync_loss = 1;
	syncwait=1;
	//signal NLME_SYNC.indication();
/*

printfUART("SL\n","");
		
		call MLME_SCAN.request(ORPHAN_SCAN,0xFFFFFFFF,7);
*/
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
	
	uint32_t destinaddress[2];
	printfUART("BN\n", "");

	
	if (go_associate==1)
	{
		received_beacon_count++;
		
		printfUART("bn %i\n", received_beacon_count);
		
		if (received_beacon_count==5)
		{
				printfUART("sa \n", "");
				
				go_associate=0;
				//call MLME_ASSOCIATE.request(pan_des.LogicalChannel,SHORT_ADDRESS,pan_des.CoordPANId,coordinator_addr,0x00,0x00);
		
		destinaddress[0]=0x00000000;
		destinaddress[1]=0x00000000;
		
		
		call MLME_ASSOCIATE.request(LOGICAL_CHANNEL,SHORT_ADDRESS,0x1234,destinaddress, set_capability_information(0x00,0x00,0x00,0x00,0x00,0x01),0);
		
		}
		
	}

	return SUCCESS;
}
/*****************************************************************************************************/  
/**************************************MLME-START*****************************************************/
/*****************************************************************************************************/ 
event error_t MLME_START.confirm(uint8_t status)
{
		////printfUART("MLME_START.confirm\n", "");
	if (device_type==COORDINATOR)
	{
		signal NLME_NETWORK_FORMATION.confirm(status);
		joined=1;
	}
	else
	{
		signal NLME_START_ROUTER.confirm(status);
	}

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
	
	//notification that an other device wants to associate
	//THIS DEVICE IS EITHER A COORDINATOR OR A ROUTER
		
	uint8_t cindex=0;

atomic{

	//check the neighbour table
	cindex = check_neighbortableentry(LONG_ADDRESS,DeviceAddress[0] , DeviceAddress[1]);
	

	if( cindex > 0 )
	{
		call MLME_ASSOCIATE.response(DeviceAddress,neighbortable[cindex - 1].Network_Address,MAC_SUCCESS,0);
	}
	else
	{	
			if(nwk_IB.nwkAvailableAddresses > 0)
			{
			
				//verify if the device is associating as a router or an end device
				if ( get_alternate_PAN_coordinator(CapabilityInformation) == 1)
				{
					//add device to the neighbour table
					add_neighbortableentry(panid,DeviceAddress[0],DeviceAddress[1],next_child_router_address,ROUTER,NEIGHBOR_IS_CHILD);
					
					printfUART("An_cr %x\n",next_child_router_address);

					//send response, this shall lead to confirm in child device
					call MLME_ASSOCIATE.response(DeviceAddress,next_child_router_address,MAC_SUCCESS,0);
					//calculate the next address
					next_child_router_address = networkaddress + ((number_child_router-1) * cskip) +1 ;
					//increment the number of associated routers
					number_child_router++;
					//decrese the number of available addresses //the available addresses are influenced by the network configurations
					nwk_IB.nwkAvailableAddresses--;
					
					printfUART("Dn_cr %x\n",next_child_router_address);
				}
				else
				{
					//verify if its possible to associate children in the address space
					//the number of end devices must be greater than 1 and lesser or iqual to maximum children minus maximum routers
					if (number_child_end_devices > 1 && number_child_end_devices > (MAXCHILDREN - MAXROUTERS))
					{
						call MLME_ASSOCIATE.response(DeviceAddress,0xffff,CMD_RESP_PAN_CAPACITY,0);
						//return SUCCESS;
					}
					else
					{
						//CHECK COMMENTED ON SHORT VERSION
						add_neighbortableentry(panid,DeviceAddress[0],DeviceAddress[1],nwk_IB.nwkNextAddress,END_DEVICE,NEIGHBOR_IS_CHILD);
						//send response, this shall lead to confirm in child device
						call MLME_ASSOCIATE.response(DeviceAddress,nwk_IB.nwkNextAddress,MAC_SUCCESS,0);
						
						nwk_IB.nwkNextAddress=nwk_IB.nwkNextAddress + nwk_IB.nwkAddressIncrement;
						
						number_child_end_devices++;
						
						nwk_IB.nwkAvailableAddresses--;
						
					}
				}
				
				if (nwk_IB.nwkAvailableAddresses == 0 )
				{
					call MLME_SET.request(MACASSOCIATIONPERMIT,(uint8_t *)0x00000000);
				}
			}
			else
			{
				//if there are no available addresses the coordinator/router shall not respond to the association request
				call MLME_ASSOCIATE.response(DeviceAddress,0xffff,CMD_RESP_PAN_CAPACITY,0);
			}
	}
}
	return SUCCESS;
}

event error_t MLME_ASSOCIATE.confirm(uint16_t AssocShortAddress, uint8_t status)
{

	uint8_t v_temp[2];
	////printfUART("MLME_ASSOCIATE.confirm\n","");

	if (AssocShortAddress == 0xffff)
	{
		//association failed
		//printfUART("nwkass fail\n","");
		signal NLME_JOIN.confirm(panid,NWK_NOT_PERMITTED);
	
	}
	else
	{
	
		networkaddress = AssocShortAddress;
		//add_neighbortableentry(panid,DeviceAddress[0],DeviceAddress[1],nwk_IB.nwkNextAddress,END_DEVICE,NEIGHBOR_IS_CHILD);
		//set the short address
		
		if (status == MAC_SUCCESS)
		{
			joined = 0x01;
			v_temp[0] = (uint8_t)(networkaddress >> 8);
			v_temp[1] = (uint8_t)(networkaddress );

			//call MLME_SET.request(MACSHORTADDRESS,(uint32_t*)(uint32_t)&networkaddress);
			call MLME_SET.request(MACSHORTADDRESS,v_temp);
			
			signal NLME_JOIN.confirm(panid, NWK_SUCCESS);
		}
		else
		{
			signal NLME_JOIN.confirm(panid,NWK_NOT_PERMITTED);
		}
	}
	return SUCCESS;
}
/*****************************************************************************************************/  
/**************************************MLME-DISASSOCIATE**********************************************/
/*****************************************************************************************************/ 
event error_t MLME_DISASSOCIATE.indication(uint32_t DeviceAddress[], uint8_t DisassociateReason, bool SecurityUse, uint8_t ACLEntry)
{
	////printfUART("MLME_DISASSOCIATE.indication:SUCCESS\n", "");
	signal NLME_LEAVE.confirm(DeviceAddress, NWK_SUCCESS);

	return SUCCESS;
}
  
event error_t MLME_DISASSOCIATE.confirm(uint8_t status)
{
	if (status == MAC_SUCCESS)
	{
		signal NLME_LEAVE.confirm(0, status);
		////printfUART("MLME_DISASSOCIATE.confirm:SUCCESS\n", "");
	}
	else
	{
		signal NLME_LEAVE.confirm(0, NWK_LEAVE_UNCONFIRMED);
		////printfUART("MLME_DISASSOCIATE.confirm:leave unconfirmed\n", "");
	}

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
	////printfUART("MCPS_DATA.confirm\n", "");
	signal NLDE_DATA.confirm(1,status);
	
	return SUCCESS;
}  
event error_t MCPS_DATA.indication(uint16_t SrcAddrMode, uint16_t SrcPANId, uint32_t SrcAddr[2], uint16_t DstAddrMode, uint16_t DestPANId, uint32_t DstAddr[2], uint16_t msduLength,uint8_t msdu[100],uint16_t mpduLinkQuality, uint16_t SecurityUse, uint16_t ACLEntry)
{
	uint8_t payload[100];
	uint32_t route_destination_address[2];
	uint32_t net_addr[2];
	uint8_t next_hop_index;
	
	routing_fields *routing_fields_ptr;
	routing_fields_ptr = (routing_fields *)&msdu[0];
	
	net_addr[1] =(uint32_t) networkaddress;
	net_addr[0]=0x00000000;

	if ( routing_fields_ptr->destination_address == networkaddress)
	{
		//I am the destination
		memcpy(&payload,&msdu[8],(msduLength-8)*sizeof(uint8_t));
		
		//pass data on to APL layer
		signal NLDE_DATA.indication(routing_fields_ptr->source_address,(uint16_t)(msduLength-8),payload, mpduLinkQuality);
		
		return SUCCESS;	
	}
	else
	{
		//I am not the destination
		if(device_type != COORDINATOR)
		{
			if( (networkaddress < routing_fields_ptr->destination_address) && (routing_fields_ptr->destination_address < (networkaddress + cskip_routing ) ) )
			{
				printfUART("route down to appropriate child\n", "");
				
				//check if destination is one of my children
				next_hop_index = check_neighbortableentry(SHORT_ADDRESS,(uint32_t)routing_fields_ptr->destination_address,0x00000000);

				if (next_hop_index == 0)
				{
					//destination is not my child
					route_destination_address[0]=0x00000000;
					route_destination_address[1]=nexthopaddress(routing_fields_ptr->destination_address,depth);
				}
				else
				{
					//Im routing to my child
					route_destination_address[0]=0x00000000;
					route_destination_address[1]=neighbortable[next_hop_index-1].Network_Address;
				}
				//send message
				call MCPS_DATA.request(SHORT_ADDRESS, panid, net_addr, SHORT_ADDRESS, DestPANId, route_destination_address, msduLength, msdu,1,set_txoptions(1,0,0,0));
			}
			else
			{
				
				//changes to meet with the BEACON SYNCHRONIZATION requirements
				//route up to the parent
				atomic{
					route_destination_address[0]=0x00000000;
					route_destination_address[1]=neighbortable[parent].Network_Address;

					call MCPS_DATA.request(SHORT_ADDRESS, panid, net_addr, SHORT_ADDRESS, DestPANId, route_destination_address, msduLength, msdu,1,set_txoptions_upstream(1,0,0,0,1));
				}
			}
		}
		else
		{
			//I AM THE PAN COORDINATOR
			//THE COORDINATOR ALWAYS ROUTES DOWN
			
			//route down to appropriate child
			//check if destination is one of my children
			next_hop_index = check_neighbortableentry(SHORT_ADDRESS,(uint32_t)routing_fields_ptr->destination_address,0x00000000);
			
			if (next_hop_index == 0 )
			{
				//no entry in neigbortable
				//calculate route address
				route_destination_address[0]=0x00000000;
				route_destination_address[1]=nexthopaddress(routing_fields_ptr->destination_address,depth);
					
				call MCPS_DATA.request(SHORT_ADDRESS, panid, net_addr, SHORT_ADDRESS, DestPANId, route_destination_address, msduLength, msdu,1,set_txoptions(1,0,0,0));
			}
			else
			{
				//is my child
				route_destination_address[0]=0x00000000;
				route_destination_address[1]=neighbortable[next_hop_index-1].Network_Address;

				call MCPS_DATA.request(SHORT_ADDRESS, panid, net_addr, SHORT_ADDRESS, DestPANId, route_destination_address, msduLength, msdu,1,set_txoptions(1,0,0,0));
			}
			
		}
		
		
	}
	
return SUCCESS;
}


/*************************************************************/
/*******************NLDE IMPLEMENTATION***********************/
/*************************************************************/
	
/*************************************************************/
/*************************NLDE - DATA*************************/
/*************************************************************/

//This primitive requests the transfer of a data PDU
//page 159-161

command error_t NLDE_DATA.request(uint16_t DstAddr, uint16_t NsduLength, uint8_t Nsdu[100], uint8_t NsduHandle, uint8_t Radius, uint8_t DiscoverRoute, uint8_t SecurityEnable)
{	

	uint32_t srcadd[2];
	//prefixed size because the devices reset itself when there is an error in the length
	uint8_t MSDU[100];
	uint32_t route_destination_address[2];
	routing_fields *routing_fields_ptr;
	uint8_t next_hop_index;
	
	routing_fields_ptr = (routing_fields *)&MSDU[0];
	
	if(joined==0)
	{	
		signal NLDE_DATA.confirm(NsduHandle, NWK_INVALID_REQUEST);
	}
	else
	{
		routing_fields_ptr->frame_control= set_route_frame_control(0x00,0x01,DiscoverRoute,SecurityEnable);
		routing_fields_ptr->destination_address=DstAddr;
		routing_fields_ptr->source_address=networkaddress;
		routing_fields_ptr->radius=Radius;
		routing_fields_ptr->sequence_number=nwk_IB.nwkSequenceNumber;
		nwk_IB.nwkSequenceNumber++;
		
		memcpy(&MSDU[8],&Nsdu[0],NsduLength*sizeof(uint8_t));

		srcadd[0] = 0x00000000;
		srcadd[1] = (uint32_t)networkaddress;
		
		if (device_type == END_DEVICE)
		{
			//if the device is an end device always sends the message to the parent

			route_destination_address[0]=0x00000000;
			route_destination_address[1]=neighbortable[parent].Network_Address;
																																						//ack
			call MCPS_DATA.request(SHORT_ADDRESS, panid, srcadd, SHORT_ADDRESS,panid, route_destination_address, (NsduLength + 8), MSDU,1,set_txoptions(1,0,0,0));
			return SUCCESS;
		}
		
		//send message if the device is the COORDINATOR or a ROUTER
		if( (networkaddress < routing_fields_ptr->destination_address) && (routing_fields_ptr->destination_address < (networkaddress + cskip_routing ) ) )
		{
			//route down to appropriate child
			//check if destination is one of my children
			next_hop_index = check_neighbortableentry(SHORT_ADDRESS,(uint32_t)routing_fields_ptr->destination_address,0x00000000);

			if (next_hop_index == 0)
			{
				//destination is not my child
				route_destination_address[0]=0x00000000;
				route_destination_address[1]=nexthopaddress(routing_fields_ptr->destination_address,depth);
			}
			else
			{
				//Im routing to my child
				route_destination_address[0]=0x00000000;
				route_destination_address[1]=neighbortable[next_hop_index-1].Network_Address;
			}
			//send the data																																	//ack
			call MCPS_DATA.request(SHORT_ADDRESS, panid, srcadd, SHORT_ADDRESS, panid, route_destination_address, (NsduLength + 8), MSDU,1,set_txoptions(1,0,0,0));
		}
		else
		{
			//route up to parent
			atomic{
				route_destination_address[0]=0x00000000;
				route_destination_address[1]=neighbortable[parent].Network_Address;
																																					//ack
				call MCPS_DATA.request(SHORT_ADDRESS, panid, srcadd, SHORT_ADDRESS, panid, route_destination_address, (NsduLength + 8), MSDU,1,set_txoptions_upstream(1,0,0,0,1));
			}
		}
		
	}
	
	return SUCCESS;
}

/*************************************************************/
/*******************NLME IMPLEMENTATION***********************/
/*************************************************************/

/*************************************************************/
/*******************NLME - START - ROUTER*********************/
/*************************************************************/

//This primitive allows the NHL of a ZigBee Router to initialize or change its superframe configuration.
//p171 and 210
command error_t NLME_START_ROUTER.request(uint8_t BeaconOrder, uint8_t SuperframeOrder, bool BatteryLifeExtension,uint32_t StartTime)
{	
	//printfUART("NLME_START_ROUTER.request\n", "");
	
	device_type = ROUTER;
	
	if(TYPE_DEVICE == ROUTER)
	{
	
		//assign current BO and SO
		beaconorder = BeaconOrder;
		superframeorder = SuperframeOrder;
	
		call MLME_SET.request(MACBEACONORDER, (uint8_t *)&BeaconOrder);
		
		call MLME_SET.request(MACSUPERFRAMEORDER, (uint8_t *)&SuperframeOrder);
		
		//*******************************************************
		//***********SET PAN VARIABLES***************************
		depth=DEVICE_DEPTH;
		
		nwk_IB.nwkAvailableAddresses=AVAILABLEADDRESSES;
		nwk_IB.nwkAddressIncrement= ADDRESSINCREMENT;
		
		nwk_IB.nwkMaxChildren=MAXCHILDREN;	//number of children a device is allowed to have on its current network
		nwk_IB.nwkMaxDepth=MAXDEPTH;	//the depth a device can have
		nwk_IB.nwkMaxRouters=MAXROUTERS;
		
		cskip = Cskip(depth);
		
		cskip_routing = Cskip(depth -1);
		
		nwk_IB.nwkNextAddress = networkaddress + (cskip * nwk_IB.nwkMaxRouters) + nwk_IB.nwkAddressIncrement;
	
		next_child_router_address = networkaddress +((number_child_router-1) * cskip) +1;
	
		
		number_child_router++;
		
		
		printfUART("cskip  %d\n", cskip);
		printfUART("C %d D %d r %d\n", MAXCHILDREN,MAXDEPTH,MAXROUTERS);
	
		//  command error_t request(uint32_t PANId, uint8_t LogicalChannel, uint8_t BeaconOrder, uint8_t SuperframeOrder,bool PANCoordinator,bool BatteryLifeExtension,bool CoordRealignment,bool SecurityEnable);
		call MLME_START.request(panid,LOGICAL_CHANNEL,BeaconOrder, SuperframeOrder, 0, 0,0,0,StartTime);
		
	}
	else
	{
	
		signal NLME_START_ROUTER.confirm(NWK_INVALID_REQUEST);
		
	}
	return SUCCESS;
}


/*************************************************************/
/******************NLME - NETWORK - FORMATION*****************/
/*************************************************************/

//This primitive allows the NHL to request to start a ZigBee network with itself as the coordinator
//Page 167-169
command error_t NLME_NETWORK_FORMATION.request(uint32_t ScanChannels, uint8_t ScanDuration, uint8_t BeaconOrder, uint8_t SuperframeOrder, uint16_t PANId, bool BatteryLifeExtension)
{

	uint8_t v_temp[6];

	v_temp[0] = 0x06;
	
	device_type = COORDINATOR;
	//device_type = ROUTER;
	
	call MLME_SET.request(MACMAXBEACONPAYLOADLENGTH,v_temp);
	
	//protocol ID
	v_temp[0] = 0x00;
	//uint8_t nwk_payload_profile_protocolversion(uint8_t stackprofile,uint8_t nwkcprotocolversion)
	v_temp[1] = nwk_payload_profile_protocolversion(0x00,0x00);
	//uint8_t nwk_payload_capacity(uint8_t routercapacity,uint8_t devicedepth,uint8_t enddevicecapacity)
	v_temp[2] = nwk_payload_capacity(0x01,0x00,0x01);
	
	//TX OFFSET (3 bytes)
	v_temp[3] = 0x56;
	v_temp[4] = 0x34;
	v_temp[5] = 0x12;
	
	
	call MLME_SET.request(MACBEACONPAYLOAD,v_temp);
	

	////printfUART("NLME_NETWORK_FORMATION.request\n", "");
	//perform an energydetection scan
	//perform an active scan
	//and select a suitable channel
	//panid must be less than or equal to 0x3fff
	
	//assign current panid
	panid=PANId;
	
	//assign current BO and SO
	beaconorder = BeaconOrder;
	superframeorder = SuperframeOrder;
	
	call MLME_SET.request(MACBEACONORDER, (uint8_t *)&BeaconOrder);

	call MLME_SET.request(MACSUPERFRAMEORDER, (uint8_t *)&SuperframeOrder);
	
	v_temp[0] = (uint8_t)(PANId >> 8);
	v_temp[1] = (uint8_t)PANId;
	
	call MLME_SET.request(MACPANID, v_temp);

	//static assignement of the coordinator address
	networkaddress=0x0000;//Network address of the ZC of a network always 0x0000;
	
	//////printfUART("setting short addr: %i\n", networkaddress);
	
	v_temp[0] = (uint8_t)(networkaddress >> 8);
	v_temp[1] = (uint8_t)(networkaddress);

	
	call MLME_SET.request(MACSHORTADDRESS,v_temp);
	
	
	//*******************************************************
	//***********SET PAN VARIABLES***************************
	//nwk_IB.nwkNextAddress=networkaddress+0x0001;
	depth=DEVICE_DEPTH;
	nwk_IB.nwkAvailableAddresses=AVAILABLEADDRESSES;
	nwk_IB.nwkAddressIncrement= ADDRESSINCREMENT;
	
	nwk_IB.nwkMaxChildren=MAXCHILDREN;	//number of children a device is allowed to have on its current network
	nwk_IB.nwkMaxDepth=MAXDEPTH;	//the depth a device can have
	nwk_IB.nwkMaxRouters=MAXROUTERS;
	
	cskip = Cskip(depth);
	
	cskip_routing = Cskip(depth -1 );
	
	nwk_IB.nwkNextAddress = networkaddress + (cskip * nwk_IB.nwkMaxRouters) + nwk_IB.nwkAddressIncrement;
	
	next_child_router_address = networkaddress +((number_child_router-1) * cskip) +1;
	
	number_child_router++;
	
	printfUART("cskip  %d\n", cskip);
	printfUART("C %d D %d r %d\n", MAXCHILDREN,MAXDEPTH,MAXROUTERS);
	
	
	call MLME_START.request(PANId, LOGICAL_CHANNEL,BeaconOrder ,SuperframeOrder,1,0,0,0,0);
	
	return SUCCESS;
}
	
/*************************************************************/
/***************NLME - NETWORK - DISCOVERY *******************/
/*************************************************************/

//This primitive allows the next higher layer to request that the NWK layer discover networks currently operating within the POS.
//p164 and 210
command error_t NLME_NETWORK_DISCOVERY.request(uint32_t ScanChannels, uint8_t Scanduration)
{
	
	//ISSUE an MLME_SCAN.request to find the available networks
	//Temporary descover of the network
	//Channel Scan is not working properly
	//manually assign the network descriptor
	
	/*
	networkdescriptor networkdescriptorlist[1];
*/
	printfUART("2 lauch passive scan\n", "");
	//The networkdescriptorlist must contain information about every network that was heard
	
	//make NetworkDescriptorList out of the PanDescriptorList

    call MLME_SCAN.request(PASSIVE_SCAN,0xFFFFFFFF,7);

/*

	networkdescriptorlist[0].PANId=0x1234;
	networkdescriptorlist[0].LogicalChannel=LOGICAL_CHANNEL;
	networkdescriptorlist[0].StackProfile=0x00;
	networkdescriptorlist[0].ZigBeeVersion=0x01;
	networkdescriptorlist[0].BeaconOrder=7;
	networkdescriptorlist[0].SuperframeOrder=6;
	networkdescriptorlist[0].PermitJoining=1;
	
	//temporary assignement on the neighbout table of the suitable PAN coordinator
	if (DEVICE_DEPTH == 0x01)
		add_neighbortableentry(networkdescriptorlist[0].PANId,D1_PAN_EXT0,D1_PAN_EXT1,D1_PAN_SHORT,COORDINATOR,NEIGHBOR_IS_PARENT);
	if (DEVICE_DEPTH == 0x02)
		add_neighbortableentry(networkdescriptorlist[0].PANId,D2_PAN_EXT0,D2_PAN_EXT1,D2_PAN_SHORT,COORDINATOR,NEIGHBOR_IS_PARENT);
	if (DEVICE_DEPTH == 0x03)
		add_neighbortableentry(networkdescriptorlist[0].PANId,D3_PAN_EXT0,D3_PAN_EXT1,D3_PAN_SHORT,COORDINATOR,NEIGHBOR_IS_PARENT);
	if (DEVICE_DEPTH == 0x04)
		add_neighbortableentry(networkdescriptorlist[0].PANId,D4_PAN_EXT0,D4_PAN_EXT1,D4_PAN_SHORT,COORDINATOR,NEIGHBOR_IS_PARENT);
	
	
	
	signal NLME_NETWORK_DISCOVERY.confirm(1,networkdescriptorlist, NWK_SUCCESS);
*/
	return SUCCESS;
}

/*************************************************************/
/************************NLME - JOIN**************************/
/*************************************************************/
//This primitive allows the NHL to request to join a network either through association.
//p173 and 210
command error_t NLME_JOIN.request(uint16_t PANId, bool JoinAsRouter, bool RejoinNetwork, uint32_t ScanChannels, uint8_t ScanDuration, uint8_t PowerSource, uint8_t RxOnWhenIdle, uint8_t MACSecurity)
{	

	//Assume we have selected a suitable parent and all previous conditions were true
	uint32_t destinaddress[2];
	
	printfUART("9 find parent\n", "");
	
	//list_neighbourtable();
	
	parent_index = find_suitable_parent();
	
	panid = PANId;
	
	//printfUART("NLME_JOIN %i %i\n", parent_index,panid); 
	
	if(parent_index == 0)
	{
		signal NLME_JOIN.confirm(PANId,NWK_NOT_PERMITTED);
	}
	else
	{
		//assign the true value to parent index
		parent_index = parent_index - 1;
				
		//destinaddress[0]=neighbortable[parent_index].Extended_Address0;
		//destinaddress[1]=neighbortable[parent_index].Extended_Address1;
		//verificar o endereço do pan coordinator
		destinaddress[0]=0x00000000;
		
		
		destinaddress[1] = neighbortable[parent_index].Network_Address;
		
		/*
		if (DEVICE_DEPTH == 0x01)
			destinaddress[1]=D1_PAN_SHORT;
		if (DEVICE_DEPTH == 0x02)
			destinaddress[1]=D2_PAN_SHORT;
		if (DEVICE_DEPTH == 0x03)
			destinaddress[1]=D3_PAN_SHORT;
		if (DEVICE_DEPTH == 0x04)
			destinaddress[1]=D4_PAN_SHORT;
		*/	
			
		printfUART("10 associate to %i\n", destinaddress[1]);	
		//set_capability_information(uint8_t alternate_PAN_coordinator, uint8_t device_type, uint8_t power_source, uint8_t receiver_on_when_idle, uint8_t security, uint8_t allocate_address)
		
		if (JoinAsRouter == 0x01)
			call MLME_ASSOCIATE.request(LOGICAL_CHANNEL,SHORT_ADDRESS,PANId,destinaddress, set_capability_information(JoinAsRouter,0x01,PowerSource,RxOnWhenIdle,MACSecurity,0x01),0);
		else
		{
		
			printfUART("11 go ass\n", "");	
		
			coordinator_addr[0]=0x00000000;
			coordinator_addr[1] = neighbortable[parent_index].Network_Address;
			//BUILD the PAN descriptor of the COORDINATOR
			//assuming that the adress is short
			pan_des.CoordAddrMode = SHORT_ADDRESS;
			pan_des.CoordPANId = panid;
			pan_des.CoordAddress0=0x00000000;
			pan_des.CoordAddress1=(uint32_t)neighbortable[parent_index].Network_Address;
			pan_des.LogicalChannel=neighbortable[parent_index].Logical_Channel;
			//superframe specification field
			//pan_des.SuperframeSpec = neighbortable[parent_index].SuperframeSpec;

			pan_des.GTSPermit=0x01;
			pan_des.LinkQuality=0x00;
			pan_des.TimeStamp=0x000000;
			pan_des.SecurityUse=0;
			pan_des.ACLEntry=0x00;
			pan_des.SecurityFailure=0x00;
	
			received_beacon_count=0;
			go_associate=1;
			
			//call MLME_ASSOCIATE.request(LOGICAL_CHANNEL,SHORT_ADDRESS,PANId,destinaddress, set_capability_information(JoinAsRouter,0x00,PowerSource,RxOnWhenIdle,MACSecurity,0x01),0);
		}
	}
	
	return SUCCESS;
}


/*************************************************************/
/************************NLME - LEAVE*************************/
/*************************************************************/

//This primitive allows the NHL to request that it or another device leaves the network
//page 181-183
command error_t NLME_LEAVE.request(uint32_t DeviceAddress[],bool RemoveChildren, bool MACSecurityEnable)
{ 	
	uint32_t devaddr[2];
	////printfUART("NLME_LEAVE.request\n", ""); 
	if (DeviceAddress == 0)//child asked to leave
	{	
		if(RemoveChildren == 0)//implemented like it is always 0
		{	
			//send leave request command frame: RemoveChildren subfield=0 of the command option field of the command frame payload
			//call MCPS_DATA.request(uint8_t SrcAddrMode, uint16_t SrcPANId, uint8_t SrcAddr[], uint8_t DstAddrMode, uint16_t DestPANId, uint8_t DstAddr[], uint8_t msduLength, uint8_t msdu[],uint8_t msduHandle, uint8_t TxOptions);
			devaddr[0]=neighbortable[parent].Extended_Address0;
			devaddr[1]=neighbortable[parent].Extended_Address1;
			call MLME_DISASSOCIATE.request(devaddr,0x02,0);
		}
		else
		{
			//send leave request command frame: RemoveChildren subfield=1
			//try to remove the children, call NLME_LEAVE.request(uint32_t DeviceAddress[]=address of child,bool RemoveChildren, bool MACSecurityEnable)
			//call MCPS_DATA.request(uint8_t SrcAddrMode, uint16_t SrcPANId, uint8_t SrcAddr[], uint8_t DstAddrMode, uint16_t DestPANId, uint8_t DstAddr[], uint8_t msduLength, uint8_t msdu[],uint8_t msduHandle, uint8_t TxOptions);
		}
	}
	else//parent forced a child to leave
	{
		//if(check_neighbortableentry(DeviceAddress[0], DeviceAddress[1]) == 0)
		//{
		//	signal NLME_LEAVE.confirm(DeviceAddress,NWK_UNKNOWN_DEVICE);
		//	//call MCPS_DATA.request(uint8_t SrcAddrMode, uint16_t SrcPANId, uint8_t SrcAddr[], uint8_t DstAddrMode, uint16_t DestPANId, uint8_t DstAddr[], uint8_t msduLength, uint8_t msdu[],uint8_t msduHandle, uint8_t TxOptions);
		//}
		
	}
	
	
	return SUCCESS;
}

/*************************************************************/
/************************NLME - SYNC**************************/
/*************************************************************/

//This primitive allows the NHL to synchronize or extract data from its ZigBee coordinator or router
//page 186-187
command error_t NLME_SYNC.request(bool Track)
{

	return SUCCESS;
}
  
/*************************************************************/
/*****************        NLME-SET     ********************/
/*************************************************************/
	
command error_t NLME_SET.request(uint8_t NIBAttribute, uint16_t NIBAttributeLength, uint16_t NIBAttributeValue)
{

	atomic{
	
		switch(NIBAttribute)
		{
			case NWKSEQUENCENUMBER :		nwk_IB.nwkSequenceNumber = (uint8_t) NIBAttributeValue;
											//////printfUART("nwk_IB.nwkSequenceNumber: %x\n",nwk_IB.nwkSequenceNumber);
											signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
											break;
											
			case NWKPASSIVEACKTIMEOUT :		nwk_IB.nwkPassiveAckTimeout = (uint8_t) NIBAttributeValue;
											//////printfUART("nwk_IB.nwkPassiveAckTimeout: %x\n",nwk_IB.nwkPassiveAckTimeout);
											signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
											break;
			
			
			case NWKMAXBROADCASTRETRIES :	nwk_IB.nwkMaxBroadcastRetries = (uint8_t) NIBAttributeValue;
											//////printfUART("nwk_IB.nwkMaxBroadcastRetries: %x\n",nwk_IB.nwkMaxBroadcastRetries);
											signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
											break;
											
			case NWKMAXCHILDREN :			nwk_IB.nwkMaxChildren = (uint8_t) NIBAttributeValue;
											//////printfUART("nwk_IB.nwkMaxChildren: %x\n",nwk_IB.nwkMaxChildren);
											signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
											break;
											
			case NWKMAXDEPTH :				nwk_IB.nwkMaxDepth = (uint8_t) NIBAttributeValue;
											//////printfUART("nwk_IB.nwkMaxDepth: %x\n",nwk_IB.nwkMaxDepth);
											signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
											break;
	
			case NWKMAXROUTERS :			nwk_IB.nwkMaxRouters = (uint8_t) NIBAttributeValue;
											//////printfUART("nwk_IB.nwkMaxRouters: %x\n",nwk_IB.nwkMaxRouters);
											signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
											break;
	
			case NWKMETWORKBROADCASTDELIVERYTIME :		nwk_IB.nwkNetworkBroadcastDeliveryTime = (uint8_t) NIBAttributeValue;
														//////printfUART("nwk_IB.nwkNetworkBroadcastDeliveryTime: %x\n",nwk_IB.nwkNetworkBroadcastDeliveryTime);
														signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
														break;
			case NWKREPORTCONSTANTCOST :	nwk_IB.nwkReportConstantCost = (uint8_t) NIBAttributeValue;
											//////printfUART("nwk_IB.nwkReportConstantCost: %x\n",nwk_IB.nwkReportConstantCost);
											signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
											break;
			case NWKROUTEDISCOVERYRETRIESPERMITED :		nwk_IB.nwkRouteDiscoveryRetriesPermitted = (uint8_t) NIBAttributeValue;
														//////printfUART("nwk_IB.nwkRouteDiscoveryRetriesPermitted: %x\n",nwk_IB.nwkRouteDiscoveryRetriesPermitted);
														signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
														break;
	
			case NWKSYMLINK :				nwk_IB.nwkSymLink = (uint8_t) NIBAttributeValue;
											//////printfUART("nwk_IB.nwkSymLink: %x\n",nwk_IB.nwkSymLink);
											signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
											break;
			
			case NWKCAPABILITYINFORMATION :	nwk_IB.nwkCapabilityInformation = (uint8_t) NIBAttributeValue;
											//////printfUART("nwk_IB.nwkCapabilityInformation: %x\n",nwk_IB.nwkCapabilityInformation);
											signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
											break;
											
			case NWKUSETREEADDRALLOC :		nwk_IB.nwkUseTreeAddrAlloc = (uint8_t) NIBAttributeValue;
											//////printfUART("nwk_IB.nwkUseTreeAddrAlloc: %x\n",nwk_IB.nwkUseTreeAddrAlloc);
											signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
											break;
											
			case NWKUSETREEROUTING :		nwk_IB.nwkUseTreeRouting = (uint8_t) NIBAttributeValue;
											//////printfUART("nwk_IB.nwkUseTreeRouting: %x\n",nwk_IB.nwkUseTreeRouting);
											signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
											break;
											
			case NWKNEXTADDRESS :			nwk_IB.nwkNextAddress = NIBAttributeValue;
											//////printfUART("nwk_IB.nwkNextAddress: %x\n",nwk_IB.nwkNextAddress);
											signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
											break;
											
			case NWKAVAILABLEADDRESSES :	nwk_IB.nwkAvailableAddresses = NIBAttributeValue;
											//////printfUART("nwk_IB.nwkAvailableAddresses: %x\n",nwk_IB.nwkAvailableAddresses);
											signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
											break;
											
			case NWKADDRESSINCREMENT :		nwk_IB.nwkAddressIncrement =NIBAttributeValue;
											//////printfUART("nwk_IB.nwkAddressIncrement: %x\n",nwk_IB.nwkAddressIncrement);
											signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
											break;
											
			case NWKTRANSACTIONPERSISTENCETIME :	nwk_IB.nwkTransactionPersistenceTime = (uint8_t) NIBAttributeValue;
													//////printfUART("nwk_IB.nwkTransactionPersistenceTime: %x\n",nwk_IB.nwkTransactionPersistenceTime);
													signal NLME_SET.confirm(NWK_SUCCESS,NIBAttribute);
													break;
											
			default:						signal NLME_SET.confirm(NWK_UNSUPPORTED_ATTRIBUTE,NIBAttribute);
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
	switch(NIBAttribute)
	{
		case NWKSEQUENCENUMBER :		signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkSequenceNumber);
										break;
									
		case NWKPASSIVEACKTIMEOUT :		signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkPassiveAckTimeout);
										break;
		
		case NWKMAXBROADCASTRETRIES :	signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkMaxBroadcastRetries);
										break;

		case NWKMAXCHILDREN :			signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkMaxChildren);
										break;

		case NWKMAXDEPTH :				signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkMaxDepth);
										break;

		case NWKMAXROUTERS :			signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkMaxRouters);
										break;

		case NWKMETWORKBROADCASTDELIVERYTIME :		signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkNetworkBroadcastDeliveryTime);
													break;

		case NWKREPORTCONSTANTCOST :	signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkReportConstantCost);
										break;

		case NWKROUTEDISCOVERYRETRIESPERMITED :		signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkRouteDiscoveryRetriesPermitted);
													break;

		case NWKSYMLINK :				signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkSymLink);
										break;
		
		case NWKCAPABILITYINFORMATION :	signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkCapabilityInformation);
										break;
										
		case NWKUSETREEADDRALLOC :		signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkUseTreeAddrAlloc);
										break;
										
		case NWKUSETREEROUTING :		signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkUseTreeRouting);
										break;
										
		case NWKNEXTADDRESS :			signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0002,(uint16_t)&nwk_IB.nwkNextAddress);
										break;

		case NWKAVAILABLEADDRESSES :	signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0002,(uint16_t)&nwk_IB.nwkAvailableAddresses);
										break;
										
		case NWKADDRESSINCREMENT :		signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0002,(uint16_t)&nwk_IB.nwkAddressIncrement);
										break;
										
		case NWKTRANSACTIONPERSISTENCETIME :	signal NLME_GET.confirm(NWK_SUCCESS,NIBAttribute,0x0001,(uint16_t)&nwk_IB.nwkTransactionPersistenceTime);
												break;

		default:						signal NLME_GET.confirm(NWK_UNSUPPORTED_ATTRIBUTE,NIBAttribute,0x0000,0x00);
										break;
	}
	
	return SUCCESS;
}

/*************************************************************/
/**************neighbor table management functions************/
/*************************************************************/

//check if a specific neighbourtable Entry is present
//Return 0:Entry is not present
//Return i:Entry is present and return the index of the entry + 1
	uint8_t check_neighbortableentry(uint8_t addrmode,uint32_t Address0,uint32_t Address1)
	{	
		
		int i=0;
		
		
		//printfUART("neighbourtable check c %i\n", neighbour_count);
	
		if (neighbour_count == 0)
		{
			//printfUART("no neib\n", "");
			return 0;
		}
		
		if(addrmode == SHORT_ADDRESS)
		{	
			for(i=0; i < neighbour_count; i++)
			{	
				///printfUART("compare %i %i\n", neighbortable[i].Network_Address, test);
				
				if(neighbortable[i].Network_Address == (uint16_t) Address0)
				{
					//printfUART("already present \n", "" );
					return i+1;
				}
			}
			return 0;
		}
		else
		{
			for(i=0; i<neighbour_count; i++)
			{	
				////printfUART("compare %x %x\n", neighbortable[i].Extended_Address0, Address0);
				if( (neighbortable[i].Extended_Address0 == Address0) && (neighbortable[i].Extended_Address1 == Address1))
				{
					//printfUART("already present \n", "" );
					return i+1;
				}
			}
			return 0;
		}
		
		return 0;
	}
	
	//function user to find a parent in the neighbour table
	//Return 0:no parent is present
	//Return i:parent is present and return the index of the entry + 1
	uint8_t find_suitable_parent()
	{
		int i =0;
		for (i=0; i<neighbour_count; i++)
		{
			if(neighbortable[i].Relationship == NEIGHBOR_IS_PARENT)
			{
				return i+1;
			}
		}
		return 0;
	}


	//add a neighbortable entry	
	void add_neighbortableentry	(uint16_t PAN_Id,uint32_t Extended_Address0,uint32_t Extended_Address1,uint32_t Network_Address,uint8_t Device_Type,uint8_t Relationship)
	{
	
	atomic{
		neighbortable[neighbour_count].PAN_Id=PAN_Id;
		neighbortable[neighbour_count].Extended_Address0=Extended_Address0;
		neighbortable[neighbour_count].Extended_Address1=Extended_Address1;
		neighbortable[neighbour_count].Network_Address=Network_Address;
		neighbortable[neighbour_count].Device_Type=Device_Type;
		neighbortable[neighbour_count].Relationship=Relationship;
		
		neighbour_count++;
		}
		
	}


	
	//update a neighbourtable entry
	void update_neighbortableentry(uint16_t PAN_Id,uint32_t Extended_Address0,uint32_t Extended_Address1,uint32_t Network_Address,uint8_t Device_Type,uint8_t Relationship)
	{
		//search entry with correct extended address
		uint8_t nrofEntry=0;
		nrofEntry = check_neighbortableentry(0x01,Extended_Address0,Extended_Address1) - 1;
		
		//update every attribute
		neighbortable[nrofEntry].PAN_Id=PAN_Id;
		neighbortable[nrofEntry].Extended_Address0=Extended_Address0;
		neighbortable[nrofEntry].Extended_Address1=Extended_Address1;
		neighbortable[nrofEntry].Network_Address=Network_Address;
		neighbortable[nrofEntry].Device_Type=Device_Type;
		neighbortable[nrofEntry].Relationship=Relationship;
		
		////printfUART("updated neighbourtable entry\n", "");
	}


	void list_neighbourtable()
	{
		int i;
		////printfUART("N List Count: %u\n", neighbour_count);
	
		for(i=0;i<neighbour_count;i++)
		{
			printfUART("Panid %x", neighbortable[i].PAN_Id);
			printfUART("Extaddr0 %x", neighbortable[i].Extended_Address0);
			printfUART("Extaddr1 %x", neighbortable[i].Extended_Address1);
			printfUART("nwkaddr %u", neighbortable[i].Network_Address);
			printfUART("devtype %u", neighbortable[i].Device_Type);
			printfUART("relation %u", neighbortable[i].Relationship);
			printfUART("depth %u\n", neighbortable[i].Depth);		
		}
	}
/*************************************************************/
/*****************Address Assignment functions****************/
/*************************************************************/

//calculate the size of the address sub-block for a router at depth d
uint16_t Cskip(uint8_t d)
{	
	uint8_t skip;
	uint8_t power;
	uint8_t x=1;
	uint8_t Cm = nwk_IB.nwkMaxChildren;
	uint8_t Rm = nwk_IB.nwkMaxRouters;
	uint8_t Lm = nwk_IB.nwkMaxDepth;
	/*////printfUART("nwk_IB.nwkMaxChildren: %i\n",  nwk_IB.nwkMaxChildren);
	////printfUART("nwk_IB.nwkMaxRouters: %i\n", nwk_IB.nwkMaxRouters);
	////printfUART("nwk_IB.nwkMaxDepth: %i\n", nwk_IB.nwkMaxDepth);*/
	if (Rm == 1)
	{
		skip = 1 + Cm * (Lm - d - 1);
	}
	else
	{	
		int i;
		
		power=(Lm - d - 1);
		for(i=0;i<power;i++)
		{
			x=x*Rm;
		}
		skip = (1 + Cm - Rm - (Cm * x))/(1-Rm);
	}
	////printfUART("Cksip function calculated: %i\n", skip);
	return skip;
}

//Calculate the nexthopaddress of the appropriate child if route down is required
uint16_t nexthopaddress(uint16_t destinationaddress,uint8_t d)
{
	uint16_t next_hop;

	next_hop=(networkaddress + 1 + ((destinationaddress-(networkaddress+1))/cskip)* cskip);
	
	////printfUART("Nexthop address calculated: %i\n", next_hop);
	return next_hop;
}

/*************************************************************/
/*****************Initialization functions********************/
/*************************************************************/
	//initialization of the nwk IB
	void init_nwkIB()
	{	
		//nwk IB default values p 204-206
		nwk_IB.nwkPassiveAckTimeout=0x03;
		nwk_IB.nwkMaxBroadcastRetries=0x03;
		nwk_IB.nwkMaxChildren=0x07;	//number of children a device is allowed to have on its current network
		nwk_IB.nwkMaxDepth=0x05;	//the depth a device can have
		nwk_IB.nwkMaxRouters=0x02;	//number of routers anyone device is allowed to have on its current network
		//neighbortableentry nwkNeighborTable[];//null set
		nwk_IB.nwkNetworkBroadcastDeliveryTime=( nwk_IB.nwkPassiveAckTimeout * nwk_IB.nwkMaxBroadcastRetries );
		nwk_IB.nwkReportConstantCost=0x00;
		nwk_IB.nwkRouteDiscoveryRetriesPermitted=nwkcDiscoveryRetryLimit;
	//set? nwkRouteTable;//Null set
		nwk_IB.nwkSymLink=0;
		nwk_IB.nwkCapabilityInformation=0x00;
		nwk_IB.nwkUseTreeAddrAlloc=1;
		nwk_IB.nwkUseTreeRouting=1;
		nwk_IB.nwkNextAddress=0x0000;
		nwk_IB.nwkAvailableAddresses=0x0000;
		nwk_IB.nwkAddressIncrement=0x0001;
		nwk_IB.nwkTransactionPersistenceTime=0x01f4;
	}


  
}

