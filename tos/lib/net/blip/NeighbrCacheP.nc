
#include "Neighbr.h"

module NeighbrCacheP
{

	provides interface NeighbrCache;	
	provides interface RouterList;
	uses interface Leds;
	uses interface Timer<TMilli>;
	uses interface Timer<TMilli> as NUDTimer;
	uses interface NeighborDiscovery;
	uses interface Node;
}



implementation
{

	 neighbr_cache neighbr_table[NEIGHBR_TABLE_SZ];  //neighbour table which contains entries of the neighbour to whom traffic is recently sent

	struct in6_addr null;
	dad_cache dad_table[DAD_TABLE_SZ];	//dad Table which contains the registered entries

	default_rtrlist rtr_table[ROUTER_TABLE_SZ]; //default router list which contains the routers which can acts as default routers
	uint8_t started=FALSE;

	uint8_t no_rtr;

	uint16_t count[NEIGHBR_TABLE_SZ];
	uint32_t NUD_REACHBLE_PERIOD;
	prefix_list prefix_table[PREFIX_TABLE_SZ]; //list of prefixes 

	#define compare_ipv6(node1, node2)  (!memcmp((node1), (node2), sizeof(struct in6_addr)))
	int alloc_index()
	{
		uint8_t i;
		for(i=0;i<NEIGHBR_TABLE_SZ;i++)
		{
			if(neighbr_table[i].info.type==0)	//make sure whenever you remove entry memclr the entry
				return i;
		}
		return -1;		//Neighbr Table Full

	}

	int dad_index()
	{
		uint8_t i;
		for(i=0;i<DAD_TABLE_SZ;i++)
		{
			if(dad_table[i].reg_lifetime==0)
				return i;	
		}
		return -1;

	}

	int router_index()
	{
		uint8_t i;
		for(i=0;i<ROUTER_TABLE_SZ;i++)
		{
			if(rtr_table[i].rtr==0)
				return i;

		}
		return -1;

	}


	//-1 indicates that no ip found in the neighbr table else it returns the index in the neighbr table where the IP is present


	int find(struct in6_addr ip)
	{
		uint8_t i;
		for(i=0;i<NEIGHBR_TABLE_SZ;i++)
		{
			if(compare_ipv6(&ip,&neighbr_table[i].ip_address))
				return i;
		}
		return -1;		

	}
	
	/* Returns 0 if the entry does not exist. Returns 1 if the entry exist */
	int findEUI(ieee_eui64_t link_addr)
	{
		int i;
		for(i=0;i<NEIGHBR_TABLE_SZ;i++)
		{
			if(!memcmp(&link_addr,&neighbr_table[i].linklayer_addr,sizeof(link_addr)))
				return i;

		}
		return -1;

	}
	
	int findRouter(struct in6_addr ip)
	{
		int i;
		for(i=0;i<ROUTER_TABLE_SZ;i++)
		{
			if(!(memcmp(&ip,&rtr_table[i].rtr->ip_address,sizeof(struct in6_addr))))
			{
				return i;
			}
		}
		return -1;

	}

	int findPrefix(struct in6_addr ip)
	{
		int i;
		for(i=0;i<PREFIX_TABLE_SZ;i++)
		{
			if(!(memcmp(&ip,&prefix_table[i].abro_information.lbr_addr,sizeof(struct in6_addr))))
			{
				return i;
			}
		}
		return -1;
	}

	int findPrefixIndex(struct in6_addr ip)
	{
		int i;
		for(i=0;i<PREFIX_TABLE_SZ;i++)
		{
			if(!(memcmp(&ip,&prefix_table[i].prefix_information.prefix,sizeof(struct in6_addr))))
			{
				return i;
			}
		}
		return -1;


	}

	int findCtx(uint8_t context)
	{
		int i;
		for(i=0;i<PREFIX_TABLE_SZ;i++)
		{
			if(context==prefix_table[i].cid)
				return i;


		}
		return -1;
		

	}

	int DADfindEUI(ieee_eui64_t link_addr)
	{
		uint8_t i;
		for(i=0;i<DAD_TABLE_SZ;i++)
		{

			if(!memcmp(&link_addr,&dad_table[i].linklayer_addr,sizeof(link_addr)))
				return i;
		}
		return -1;

	}
	int findLarge()
	{

		uint8_t i;
		uint8_t index=0;
		for(i=0;i<NEIGHBR_TABLE_SZ;i++)
		{
			////printf("\n Value of i is %d",i);
			if(neighbr_table[i].info.isRouter)
			{
				if(index==0)
				{
					index=i;
					continue;
				}
				else
				{
					if(neighbr_table[i].info.timer>neighbr_table[index].info.timer)
						index=i;
				}
			}
		}
		return index;

	}


	int findDAD(struct in6_addr ip)
	{

		uint8_t i;
		for(i=0;i<DAD_TABLE_SZ;i++)
		{
			if(compare_ipv6(&ip,&dad_table[i].ip_address))
				return i;
		}
		return -1;


	}

	void PrefixPrint()
	{
	/*	uint8_t i;
		printf("\n Prefix List");
		printf("\n Prefix \t\t\t\t Registration Lifetime\t\t\t\tLBR Address\n");
		for(i=0;i<PREFIX_TABLE_SZ;i++)
		{
			printf_in6addr(&prefix_table[i].prefix_information.prefix);
			printf("\t\t\t\t\t\t");
			printf("%ld",prefix_table[i].prefix_information.preferrd_lifetime);
			printf("\t\t\t\t\t");
			printf_in6addr(&prefix_table[i].abro_information.lbr_addr);
			printf("\n");
		}
*/
	}

	void PrintRouterTable()
	{
		/*uint8_t i;
		printf("\n Router Table");
		printf("\n Router IP  \t\t\t\t Registration Lifetime\n");
		for(i=0;i<no_rtr&&i<MAX_RTRS;i++)
		{
			if(rtr_table[i].rtr!=0)
			{
				printf_in6addr(&rtr_table[i].rtr->ip_address);
				printf("\t\t\t\t");
				printf("%ld\n",rtr_table[i].rtr->info.timer);
			}
		}
	*/
	}

	command error_t NeighbrCache.init()
	{
				
		uint8_t i;

		/*clearing the Neighbor Table*/
		for(i=0;i<NEIGHBR_TABLE_SZ;i++)
		{			
			memset(&neighbr_table[i].ip_address,0,16);
			memset(&neighbr_table[i].linklayer_addr,0,8);
			memset(&neighbr_table[i].info,0,sizeof(neighbr_info));
		
		}
		/* Clearing the DAD Table*/
		for(i=0;i<DAD_TABLE_SZ;i++)
		{
			memset(&dad_table[i].ip_address,0,16);
			memset(&dad_table[i].linklayer_addr,0,8);
			memset(&dad_table[i].reg_lifetime,0,2);
		}

		for(i=0;i<ROUTER_TABLE_SZ;i++)
			memset(&rtr_table[i],0,sizeof(default_rtrlist));
		
		for(i=0;i<NEIGHBR_TABLE_SZ;i++)
			count[i]=0;
		no_rtr=0;
		memset(&null,0,sizeof(struct in6_addr));
		call Timer.startPeriodic(61440U);	//60 seconds
		return SUCCESS;

	}
	command error_t NeighbrCache.addentry(struct in6_addr ip,ieee_eui64_t lladdr,neighbr_info info)
	{

		uint8_t index=alloc_index();
		int i;	
		if(index>NEIGHBR_TABLE_SZ-1||index==-1)	//it means the Neighbour cache is Full
			return FAIL;		
		
		if(call NeighbrCache.findIPEUI64(ip,lladdr))	//dont add duplicates
 		{
			//printf("\n Neighbor add entry Returning FAIL because ip and link layer address already exist");
			return FAIL;
		}
		
		if((i=findEUI(lladdr))!=-1&&neighbr_table[i].info.type==TENTATIVE)		//overwriting tentative entries
		{
			
			index=i;
		}
	
		if(info.isRouter)		//if Router
		{

			/* To limit the storage needed for the default router list, a host may choose not to store all of the 				router addresses discovered via advertisements*/
			if(no_rtr>MAX_RTRS-1)
				return FAIL;			
			no_rtr++;
		}
	
		memcpy(&neighbr_table[index].ip_address,&ip,sizeof(struct in6_addr));
		memcpy(&neighbr_table[index].linklayer_addr,&lladdr,sizeof(ieee_eui64_t));
		memcpy(&neighbr_table[index].info,&info,sizeof(neighbr_info));
	  
		call NeighbrCache.PrintTable();
		
		return SUCCESS;
	}


	command error_t NeighbrCache.removeentry(struct in6_addr ip)		//remove after completion
	{
		int i;
		i=find(ip);
		

		if(i==-1)
			return NP;		//entry is not present in the neighbour table
		else
  	     	{
			//printf("\n NeighborCache Removeentry");
			//printf_in6addr(&neighbr_table[i].ip_address);
			memset(&neighbr_table[i],0,sizeof(neighbr_cache));
			return SUCCESS;
		}
		
		

	}

	command error_t NeighbrCache.delEntry(uint8_t i)
	{

		call NeighbrCache.PrintTable();	
		//printf("\n Deleting Neighbor Cache Entry index:%d",i);
		memset(&neighbr_table[i].ip_address,0,16);
		memset(&neighbr_table[i].linklayer_addr,0,8);
		memset(&neighbr_table[i].info,0,sizeof(neighbr_info));
		call NeighbrCache.PrintTable();
		return SUCCESS;
	}

	

	command error_t NeighbrCache.resolveIP(struct in6_addr *ip,ieee154_addr_t * linkaddr)
	{
		int i;
		i=find(*ip);
		//call Leds.led1Toggle();
		if(i==-1)
			return NP;		//entry is not present in the neighbour table
		else
		{	
			//printf("\n resolving ip");
			memcpy(&linkaddr->i_laddr.data,&neighbr_table[i].linklayer_addr,8);
			linkaddr->ieee_mode=IEEE154_ADDR_EXT;
			return SUCCESS;
		}
	}

	/* Returns 0 when no entry is present else returns the address of the entry*/
	command neighbr_cache * NeighbrCache.getEntryLL(ieee_eui64_t link_addr)
	{
		int i;
		i=findEUI(link_addr);
		if(i!=-1)	
			return &neighbr_table[i];
		else
			return 0;
	}


	/* Returns 0 when no entry is present else returns the address of the entry */

	command neighbr_cache * NeighbrCache.findEntry(struct in6_addr ip)
	{

		int i;
		i=find(ip);
		if(i==-1)
			return 0;
		else
			return &neighbr_table[i];
	}
	//returns 1 when ip and link layer address are found else returns 0
	command int NeighbrCache.findIPEUI64(struct in6_addr ip,ieee_eui64_t link_addr)
	{
		int i,j;		
		i=find(ip);
		j=findEUI(link_addr);
		if(i==j&&i!=-1)
			return 1;
		else
			return 0;
	}	
		

	command void NeighbrCache.PrintTable()
	{

		/*uint8_t i;

		printf("\n NeighborCache of the Node");

		printf("\n State\t\t\tTime Left\t\t IPAddress:\t\t\t\t LinkLayerAddress  \n");
		for(i=0;i<NEIGHBR_TABLE_SZ;i++)
		{			
		
			if(neighbr_table[i].info.timer!=0)
			{
				switch(neighbr_table[i].info.state)
				{
					case REACHABLE:
						printf("REACHABLE");
						break;
					case STALE:
						printf("STALE");
						break;

					case DELAY:
					  	printf("DELAY");
						break;
					case PROBE:
						printf("PROBE");
						break;
				
				}
				printf("\t\t");
				printf("%ld",neighbr_table[i].info.timer);
				printf("\t\t");
				printf_in6addr(&neighbr_table[i].ip_address);
				printf("\t\t");
				printf_buf(neighbr_table[i].linklayer_addr.data,8);	
			}
		
		}*/
					
	}


	command void NeighbrCache.PrintDADTable()
	{
		
		uint8_t i;		
		/*printf("\n DAD Table of the Node");
		printf("\n IPAddress\t\t\t\t Reg LifeTime\t\t\t\t LinkLayerAddress\n");
		for(i=0;i<DAD_TABLE_SZ&&dad_table[i].reg_lifetime!=0;i++)
		{
			printf_in6addr(&dad_table[i].ip_address);
			printf("\t\t\t\t\t");
			printf("%d",dad_table[i].reg_lifetime);
			printf("\t\t\t\t\t");
			printf_buf(dad_table[i].linklayer_addr.data,8);
		}
*/
	}
	/* Update the information for the IP*/

	command error_t NeighbrCache.updateEntry(struct in6_addr ip,ieee_eui64_t lladdr,neighbr_info info)
	{

		uint8_t i;
		i=find(ip);
		if(i==-1)
			return NP;
		else
		{
			neighbr_table[i].linklayer_addr=lladdr;
			memcpy(&neighbr_table[i].info,&info,sizeof(neighbr_info));
			return SUCCESS;
			
		}
	}


	command neighbr_cache * NeighbrCache.getEntry(uint8_t index)
	{
		return &neighbr_table[index];
	}
	

	/*Commands for DAD Table 6LR*/

	command error_t NeighbrCache.DADaddEntry(struct in6_addr ip,ieee_eui64_t lladdr,uint16_t reg_lifetime)
	{
		uint8_t index=dad_index();
		int i;
		if(index==-1||index>DAD_TABLE_SZ-1)
			return FAIL;

		if(call NeighbrCache.DADfindIPEUI64(ip,lladdr)!=-1)	//dont add duplicates
 		{
			//printf("\n DAD addentry Returning FAIL because ip and link layer address already exist");
			return FAIL;
		}
		
		if((i=DADfindEUI(lladdr))!=-1)		//overwriting tentative entries
		{
			index=i;
		}
	

		memcpy(&dad_table[index].ip_address,&ip,sizeof(struct in6_addr));
		memcpy(&dad_table[index].linklayer_addr,&lladdr,sizeof(ieee_eui64_t));
		dad_table[index].reg_lifetime=reg_lifetime;

		//printf("\n IPAddress registered in the DAD");
		//printf_in6addr(&ip);		
		return SUCCESS;		

	}

	command error_t NeighbrCache.DADremoveEntry(struct in6_addr ip)
	{

		int index=findDAD(ip);
		if(index==-1)
			return NP;
		else{
			//printf("\n DAD Removing entry");
			//printf_in6addr(&dad_table[index].ip_address);
			memset(&dad_table[index],0,sizeof(dad_table[index]));
			return SUCCESS;
		     }	
	}

       /* Returns 0 when the entry is not found or else returns 1 */

	command int NeighbrCache.DADfindEntry(struct in6_addr ip)
	{

		int index;
		index=findDAD(ip);
		//printf("\n findDAD index is %d",index);
		if(index==-1)
			return 0;
		else
			return 1;

	}	


	/*return i when both IP and EUI-64 are present else returns -1 */
	command int NeighbrCache.DADfindIPEUI64(struct in6_addr ip,ieee_eui64_t link_addr)
	{

		int i;
		if(call NeighbrCache.DADfindEntry(ip))
		{
			i=findDAD(ip);		//to get the index of the ip
			//printf("\n Source Comparison Link Layer Address");
			//printf_buf(link_addr.data,8);
			//printf("\n Destination Comparison Link Layer Address");
			//printf_buf(dad_table[i].linklayer_addr.data,8);
			if(!memcmp(&link_addr,&dad_table[i].linklayer_addr,sizeof(link_addr)))
			{
				return i;
			}
			else
				return -1;
		}	
		else
		{
			return -1;
		}

	}

	command dad_cache * NeighbrCache.getDADEntry(uint8_t index)
	{
		return &dad_table[index];

	}

	event void Timer.fired()	//working in minutes only
	{
		uint8_t i;
		if(no_rtr==0)
		{	
			//printf("\n Signalling the node that routers are zero");
			#ifndef NODE_LBR		//LBR should not receive this event ...
				signal NeighbrCache.default_rtrlistempty();
			#endif

		}
		for(i=0;i<NEIGHBR_TABLE_SZ&&neighbr_table[i].info.timer!=0;i++)
		{
			neighbr_table[i].info.timer-=1;
			////printf("\n the next nd time of the neighbor is %ld",neighbr_table[i].info.next_ndtime);
			////printf("\n the next nd time of the neighbor is %ld",neighbr_table[i].info.next_ndtime);

				
			if(neighbr_table[i].info.timer<=0)
			{	
				//printf("\n In Timer Fired Removing the entry as the time is not zero");
					call NeighbrCache.removeentry(neighbr_table[i].ip_address);
			
				if(neighbr_table[i].info.isRouter)
				{
					if(call RouterList.remove(neighbr_table[i].ip_address)!=SUCCESS)
					{	//printf("\n Unable to remove the router from the list");
					}
				}
			}
			
		}
		#ifdef  NODE_LBR
			call NeighbrCache.PrintDADTable();
			call NeighbrCache.PrintTable();
		#else
			call NeighbrCache.PrintTable();
			PrefixPrint();
			PrintRouterTable();
		#endif
		for(i=0;i<DAD_TABLE_SZ&&dad_table[i].reg_lifetime!=0;i++)
		{
			dad_table[i].reg_lifetime-=1;		//removing 1 minute every time
			if(dad_table[i].reg_lifetime==0)
			{
				//printf("\n as the registration lifetime is zero removing it");	
				//printf_in6addr(&dad_table[i].ip_address);
				memset(&dad_table[i],0,sizeof(dad_cache));
			}
		}
		

		for(i=0;i<PREFIX_TABLE_SZ&&prefix_table[i].prefix_information.preferrd_lifetime>0;i++)
		{
			prefix_table[i].prefix_information.preferrd_lifetime-=1;
			prefix_table[i].abro_information.valid_lifetime-=1;
			if(prefix_table[i].prefix_information.preferrd_lifetime<4 && 
				prefix_table[i].prefix_information.preferrd_lifetime>2)
				signal 	NeighbrCache.prefixReg();

			/*when the prefix information times out ,the information of the prefix should be discarded
			*/
			if(prefix_table[i].prefix_information.preferrd_lifetime<=0)
			{
				memset(&prefix_table[i].prefix_information,0,sizeof(prefix_info));

			}
			/*When the ABRO valid lifetime associated with a 6lbr times out,all information related to that 			6LBR Must be removed*/
			if(prefix_table[i].abro_information.valid_lifetime<=0)
			{
				memset(&prefix_table[i],0,sizeof(prefix_list));
			}
		}
	}
	command error_t NeighbrCache.startNUD()
	{
		struct in6_addr def_rtr_ip;
		int i;
		if(!call NUDTimer.isRunning())
		{
			call NUDTimer.stop();
		
		}

		if(call Node.getLBRState())
		{
			NUD_REACHBLE_PERIOD=RTR_REACHABLE_TIME;
			call NUDTimer.startPeriodic(1000);
			return SUCCESS;
		}
		else
		{
			if(call RouterList.getRouterIP(&def_rtr_ip)==SUCCESS)
			{
				i=find(def_rtr_ip);
				if(NUD_REACHBLE_PERIOD==neighbr_table[i].info.next_ndtime*60)
				{
					//printf("\nNUD Mechanism has not been started as it is the same ip");
				}
				else
				{
					NUD_REACHBLE_PERIOD=neighbr_table[i].info.next_ndtime*60;//converting into seconds
					//printf("\nNUD Mechanism has been started");
					call NUDTimer.startPeriodic(1000);		//1 Second
				}

				return SUCCESS;
			}
		}

		return FAIL;
	}


	event void NUDTimer.fired()
	{

		uint8_t i;	
		for(i=0;i<NEIGHBR_TABLE_SZ&&neighbr_table[i].info.timer>0;i++)
		{
			count[i]++;
			if(neighbr_table[i].info.state==PROBE)
			{
				//after Maximum unicast solicitation delete entry
				if(count[i]*1000==MAX_UNICAST_SOLICIT*RETRANS_TIMER){	
					call NeighbrCache.delEntry(i);
					//printf("\n Deleting entry because neighbor is not  reachable");
					count[i]=0;
				}
			}
			if(neighbr_table[i].info.state==DELAY)
			{
				neighbr_table[i].info.state=PROBE;
				//printf("\n Changing state of %d to PROBE",i);
				signal NeighbrCache.NUD_reminder(neighbr_table[i].ip_address);
				count[i]=0;
			}
			if(neighbr_table[i].info.state==STALE)
			{
				//printf("comparing count:%ld and DElAY:%ld",count[i],DELAY_FIRST_PROBE_TIME);
				if(count[i]*1000==DELAY_FIRST_PROBE_TIME)
				{
					//printf("\n changing state of %d to DELAY",i);
					neighbr_table[i].info.state=DELAY;		
					count[i]=0;
				}
			}
			if(neighbr_table[i].info.state==REACHABLE)
			{
				if(NUD_REACHBLE_PERIOD==count[i])	
				{		
					//printf("\n changing the state of %d to STALE",i);
					neighbr_table[i].info.state=STALE;
					count[i]=0;
				}
			}
						
			

		}
		//call NeighbrCache.PrintTable();	
		
	}


	command error_t NeighbrCache.storeCtx(struct in6_addr prefix,uint8_t cid,uint16_t lifetime)
	{

		int i=findPrefixIndex(prefix);
		if(i!=-1)
		{
			//printf("\n storing the context in index:%d",i);
			prefix_table[i].cid=cid;
			prefix_table[i].context_lifetime=lifetime;
			return SUCCESS;
		}
		return FAIL;	
	}

	//get the ip address based on the context
	command int NeighbrCache.getContext(uint8_t context,struct in6_addr *ctx)
	{

		/* if (!(call IPAddress.getGlobalAddr(&me))) return 0;
    if (context == 0) {
      // memset(ctx->s6_addr, 0, 8);
      // ctx->s6_addr16[0] = htons(0xaaaa);
      memcpy(ctx->s6_addr, me.s6_addr, 8);
      return 64;
    } else {
      return 0;
    }*/
		int i = findCtx(context);
		if(i!=-1)
		{
			memcpy(ctx->s6_addr,prefix_table[i].prefix_information.prefix.s6_addr,8);
			return 64;
		}else{
			return 0;
		}
		

	}


	//get the LBR Address

	command error_t NeighbrCache.getLBRAddress(struct in6_addr *lbr)
	{

		memcpy(lbr,&prefix_table[0].abro_information.lbr_addr,sizeof(struct in6_addr));
		return SUCCESS;


	}

	//used to get the context based on the ip address
	command int NeighbrCache.matchContext(struct in6_addr *ctx,uint8_t *context)
	{

		int i=findPrefixIndex(*ctx);
		if(i!=-1)
		{
			*context=prefix_table[i].cid;
			return 64;
		}
		return 0;
		
		

	}

	command error_t NeighbrCache.addPrefix(prefix_info prefix_information,abro_info info)
	{

		int i;
		//check whether we have to update it
		i=findPrefix(info.lbr_addr);
		if(i==-1)
		{
			for(i=0;i<PREFIX_TABLE_SZ-1;i++)
			{
				if(prefix_table[i].prefix_information.preferrd_lifetime==0)
				{	
					break;
				}
			}
			if(i>PREFIX_TABLE_SZ-1)
				return FAIL;
		}
		memcpy(&prefix_table[i].prefix_information,&prefix_information,sizeof(prefix_info));
		memcpy(&prefix_table[i].abro_information,&info,sizeof(abro_info));
		//printf("\n Prefix successfully added");
		return SUCCESS;		


	}

/* Return Success When no entry exist with the same info or returns FAIL*/
command error_t NeighbrCache.checkPrefix(struct in6_addr prefix,struct in6_addr lbr_addr,uint16_t ver_high,uint16_t ver_low)
{
	uint8_t i;
	for(i=0;i<=PREFIX_TABLE_SZ-1;i++)
	{

		if(!(memcmp(&prefix,&prefix_table[i].prefix_information.prefix,sizeof(struct in6_addr))) && 
		!(memcmp(&lbr_addr,&prefix_table[i].abro_information.lbr_addr,sizeof(struct in6_addr))) && 
	(ver_high==prefix_table[i].abro_information.ver_high) &&(ver_low==prefix_table[i].abro_information.ver_low))
	{		
		break;
	}


	}

	if(i>PREFIX_TABLE_SZ-1)
	{
		//printf("\n Return SUCCESS");
		return SUCCESS;
	}
	//printf("\n Return FAIL");
	//check whether the prefix lifetime is going to complete if so then update it
	if((prefix_table[i].prefix_information.preferrd_lifetime>0 && prefix_table[i].prefix_information.preferrd_lifetime<=4)||
	(prefix_table[i].abro_information.valid_lifetime>0&&prefix_table[i].abro_information.valid_lifetime<=4))
		return SUCCESS;
	else
		return FAIL;

}



	command uint8_t NeighbrCache.prefixes_count()
	{
		uint8_t i,prefix_count=0;
		for(i=0;i<PREFIX_TABLE_SZ;i++)
		{	
			if(prefix_table[i].prefix_information.preferrd_lifetime!=0)
				prefix_count++;

		}
		return prefix_count;
	}

	command error_t NeighbrCache.removePrefix(struct in6_addr prefix)
	{
		uint8_t i;
		for(i=0;i<PREFIX_TABLE_SZ;i++)
		{
			if(!memcmp(&prefix,&prefix_table[i].prefix_information.prefix,sizeof(struct in6_addr)))
				break;
		}
		if(i>PREFIX_TABLE_SZ-1)
			return FAIL;
		else	
		{
			memset(&prefix_table[i],0,sizeof(prefix_list));
			return SUCCESS;
		}
		
	}


	command prefix_list * NeighbrCache.getPrefixIndex(uint8_t index)
	{

		if(index>PREFIX_TABLE_SZ-1)
			return 0;
		else return &prefix_table[index];
	}

/************************************RouterList Commands and Interfaces*********************************************************/


	command error_t RouterList.add(struct in6_addr ip)
	{
		int i,j;
		i=router_index();
		if(i!=-1)
		{
			j=find(ip);
			if(j==-1)
			{
				//printf("\n Cannot be added to the default router list as no entry exists in the neighbor cache");printfflush();
				return FAIL;
			}
			else
			{
				rtr_table[i].rtr=&neighbr_table[j];
				return SUCCESS;
			}
		}
		else
			return FAIL;
	
	}

	command error_t RouterList.remove(struct in6_addr rtr_ip)
	{
		int i;
		//printf("\n Removing the router ip:");
		//printf_in6addr(&rtr_ip);
		i=findRouter(rtr_ip);
		if(i==-1||i>MAX_RTRS){
			return FAIL;
		}
		memset(&rtr_table[i],0,sizeof(default_rtrlist));
		no_rtr--;
		//printf("\n No. of Routers present are:%d",no_rtr);
		return SUCCESS;	
	}

	command error_t RouterList.getRouterIP(struct in6_addr *ip)
	{		
		//printf("\n Router IP");
		if(rtr_table[0].rtr->info.timer!=0)
		{
			*ip=rtr_table[0].rtr->ip_address;
			//printf_in6addr(ip);
			 return SUCCESS;
		}
		if(!compare_ipv6(&rtr_table[1].rtr->ip_address,&null))
		{
			*ip=rtr_table[1].rtr->ip_address;
			return SUCCESS;
		}
		return FAIL;

	}


	command error_t RouterList.removeAll()
	{
		memset(&rtr_table,0 ,sizeof(rtr_table[ROUTER_TABLE_SZ]));
		no_rtr=0;
		return SUCCESS;
	}

}

