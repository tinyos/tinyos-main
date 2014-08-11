#include "sslp.h"
#define DA_SCOPE "embd"
module SSLP_DA
{
	provides interface SplitControl;
	uses interface SplitControl as RadioControl;
	uses interface Timer<TMilli> as DeleteTimer;
	uses interface Timer<TMilli> as DATimer;		//this can be macroed
	uses interface UDP as UDPSend;
	uses interface UDP as UDPReceive;
	uses interface IPAddress;
	uses interface Leds;




}

implementation
{

	uint32_t pkt_count=0;
	uint8_t running=FALSE;		//Indicates Whether the SSLP is On or OFF.ON=TRUE,OFF=FALSE
	reg_services registered_services[STORE_MAX_SERVICES];	//DA store all the registered services in this buffer
	struct in6_addr SRVLOC_DA;	//This is the address for receiving UA and SA has to join for receiving DA-ADVT messages
	struct in6_addr SRVLOC;	//this is the address for receiving Service Type Request and Attribute Type Request messages
	service_reply_msg  srep_msg;			//Service Reply Message
	servicetype_reply_msg strep_msg;		//Service Type Reply Message
	directory_advt_msg dadv_msg;			//Directory Advertisement Message
	service_ack_msg sack_msg;			//Service Acknowledgment Message
		

	uint32_t DA_PERIOD=CONFIG_DA_BEAT;
	
	struct sockaddr_in6 dest;	//Structure used for filling the UDP address(IP+Port)
	char buff[64];	

	

	//Initialize all the IPAddresses here
	void init()
	{
		inet_pton6("ff02::116",&SRVLOC_DA);
		inet_pton6("ff02::123",&SRVLOC);
		call DeleteTimer.startPeriodic(60000U);	//Timer every one minute
	}

	/*This function returns the length of the string*/
	uint8_t stringlength(char *data)
	{
		uint8_t i;
		uint8_t count=0;
		for(i=0;*(data+i)!='\0';i++)
			count++;	
		return count;
	}


	//This function converts ip address to string
	char * IPtoString(struct in6_addr *ip)
	{
		inet_ntop6(ip,buff,64);
		return buff;
	}

	//This function is used to fill the header of the SSLP Messages
	void fillHeader(struct sslp_hdr *header,uint8_t type,uint16_t seq_no)
	{
		header->version=SSLP_VERSION;
		header->msgid=type;
		if(type==SERVICE_REGISTRATION)		//Section 4 of the draft
			header->F_flag=1;
		header->seq_no=seq_no;	
		//printf("\n the sequence number sent is %d",seq_no);
	}

	//Used only in DA so can be macroed
	void getDirectoryURL(char *DirectoryURL)
	{
		struct in6_addr LLAddress;
		call IPAddress.getLLAddr(&LLAddress);
		//memcpy(&DirectoryURL[stringlength(DirectoryURL)],"service:directory-agent://",stringlength("service:directory-agent://"));
		memcpy(&DirectoryURL[stringlength(DirectoryURL)],IPtoString(&LLAddress),stringlength(IPtoString(&LLAddress)));

		DirectoryURL[stringlength(DirectoryURL)]='\0';


	}

	//Returns 0 when it is duplicate else returns 1 when it is  not duplicate or when no entry exists
	int duplicate(char *service,char *scope,char *url)
	{
		uint8_t i;
	
		for(i=0;i<STORE_MAX_SERVICES&&registered_services[i].lifetime;i++)
		{
			if(!(memcmp(&registered_services[i].servicetype,service,stringlength(registered_services[i].servicetype)))&&
			    !(memcmp(&registered_services[i].scope,scope,stringlength(registered_services[i].scope))) &&
		 	  !(memcmp(&registered_services[i].url,url,stringlength(registered_services[i].url))))
				return 0;
		}
		return 1;
	}
		
	//returns index if the service is present else returns -1
	int findService(char *servicetype)
	{

		uint8_t i;
		for(i=0;i<STORE_MAX_SERVICES&&stringlength(registered_services[i].servicetype);i++)
		{
		if(!memcmp(servicetype,&registered_services[i].servicetype,stringlength(registered_services[i].servicetype)))
			{
				//printf("\n comparing %s with %s",servicetype,registered_services[i].servicetype);
				return i;
			}
		}

		return -1;
	}


	int RegisterService(serviceregistration *sreg)	
	{
		//First find  the index . check the lifetime field to know whether the location is free
		uint8_t index;
		
		
		//First check whether we got a Service with non-zero lifetime
		if(!sreg->location_entry.lifetime)
			return ILLEGAL_REGISTRATION;

		if(sreg->sslp_header.F_flag) //Fresh Registration
		{
			//printf("\n Fresh Registration");
			for(index=0;index<STORE_MAX_SERVICES;index++)
			{
				if(registered_services[index].lifetime==0)
					break;
			}
			if(index!=STORE_MAX_SERVICES)//TODO: IF Fresh registration check whether the given scope and service is 				duplicate or not.for Renewing the registration directly approve it
			{
				if(duplicate(sreg->service_type,sreg->scope,sreg->location_entry.url))
				{
				memcpy(&registered_services[index].servicetype,sreg->service_type,sreg->length_service_type+1);
				registered_services[index].servicetype[stringlength(registered_services[index].servicetype)]='\0';
				memcpy(&registered_services[index].url,sreg->location_entry.url,sreg->location_entry.length_url);
				memcpy(&registered_services[index].scope,sreg->scope,sreg->length_scope_type);
				registered_services[index].lifetime=sreg->location_entry.lifetime;
				printf("%s registered with length:%d\n",sreg->service_type,
						sreg->length_service_type);
				printfflush();
				return 0;
				}
				else{

					return ILLEGAL_REGISTRATION;
				}	
			}
			else{

					return ILLEGAL_REGISTRATION;
			}
			
		}
		else{	//update the registration lifetime here
			int i = findService(sreg->service_type);
			if(i==-1) //If it is a renewal registration but no service is present in the cache
			{

				return ILLEGAL_REGISTRATION;
	
			}
			registered_services[i].lifetime= sreg->location_entry.lifetime;
			//printf("\n Renewal in the registration");			
			
			return 0;

		}
		
	}

	int DeRegisterService(servicederegistration *sdereg)
	{
		//first find the index
		uint8_t index;
		for(index=0;index<STORE_MAX_SERVICES;index++)
		{
			if(!(memcmp(sdereg->service_type,&registered_services[index].servicetype,sdereg->length_service_type))&&
			   !(memcmp(sdereg->scope,&registered_services[index].scope,sdereg->length_scope_type)))
			{
				memset(&registered_services[index],0,sizeof(registered_services[index]));
				break;
			}


		}
		if(index==STORE_MAX_SERVICES)
			return ILLEGAL_REGISTRATION;

		return 0;
	}

	void printRegisteredServices()
	{
		uint8_t index;
		printf("\nservices present");
		for(index=0;index<STORE_MAX_SERVICES;index++)
		{

			printf("\n %s",registered_services[index].servicetype);
		}

	printfflush();


	}

	//DA Fills all the services present with it
	void fillAllServices(char *service,char *scope)
	{
		uint8_t i;
		printRegisteredServices();
		for(i=0;i<STORE_MAX_SERVICES;i++)
		{
			if(((!(memcmp(&registered_services[i].scope,scope,stringlength(scope)))||(!memcmp(scope,"default",stringlength("default"))))&&(stringlength(registered_services[i].servicetype))))
			{
				memcpy(&service[stringlength(service)],registered_services[i].servicetype,
				stringlength(registered_services[i].servicetype));
				printf("\n after adding service:%s",service);
				printfflush();
				service[stringlength(service)]=',';
			}
			else
			{
				//printf("\n scope %s is not present with scope %s",scope,registered_services[i].scope);
			}

		}
		service[stringlength(service)-1]='\0';
	

	}

		struct sslp_hdr * getHeader(void *data)
	{
		struct sslp_hdr *hdr;
		uint32_t *buffer = (uint32_t *)data;
		*buffer=(((*buffer)>>4)&0x0f) |  //Adding the version
	 	     (((*buffer)>>10)&0x30) | //getting the two bits of msgid
		      (((*buffer)<<6)&0x3c0) | //getting the four bits of msgid
 		      (((*buffer)>>2)&0xc00) | //getting the flags
		      (((*buffer)<<4)&0xf000) | //getting the reserved
		      (((*buffer)<<8)&0xff000000) | //getting the 8 bits of the seq
		     (((*buffer)>>8)&0x00ff0000) ; //getting the next 8 bits of the sequence number

		hdr=(struct sslp_hdr *)buffer;
		return hdr;
	}

/***********************************************Send Handlers******************************************************************/

	//Handler to send the Service Acknowledgement Message

	void srvack_send(struct sockaddr_in6 *destination,uint16_t seq_no,uint8_t error_code)
	{
		memset(&sack_msg,0,sizeof(sack_msg));

		//Filling the Service Acknowledgment Message Header

		fillHeader(&sack_msg.sslp_header,SERVICE_ACKNOWLEDGE,seq_no);

		//Filling the Message Details
		sack_msg.error_code=error_code;

		call UDPSend.sendto(destination,&sack_msg,sizeof(sack_msg));
		//printf("\n sending the service acknowledgement message");

	}

	//Handler to send the Directory Advertisement Message
	//This is used only by the Directory Agent and it can be macroed
	//Parameter: the destination address either the multicast address or unicast address
	void directoryadv_send(struct in6_addr *destination)
	{
		memset(&dadv_msg,0,sizeof(dadv_msg));
		//Filling the Directory Advertisement Message Header
		fillHeader(&dadv_msg.sslp_header,DA_ADVERTISEMENT,1234);	//TODO:macro the sequence number
		
		//Filling the Message Details

		dadv_msg.error_code= NO_ERROR;

		dadv_msg.location_entry.lifetime=600;
		dadv_msg.location_entry.LT =URL_ADDR;
		getDirectoryURL(dadv_msg.location_entry.url);
		dadv_msg.location_entry.length_url=stringlength(dadv_msg.location_entry.url);
		memcpy(dadv_msg.scope,DA_SCOPE,stringlength(DA_SCOPE));
		//printf("\n scope is %s",dadv_msg.scope);
		dadv_msg.length_scope_list = stringlength(dadv_msg.scope);
		printf("\nDirectory URL is %s",dadv_msg.location_entry.url);
		printf("\n Directory URL Length :%d",dadv_msg.location_entry.length_url);
		printfflush();

		//Filling the UDP Header
		dest.sin6_port=htons(SSLP_LISTENING_PORT);	
		memcpy(&dest.sin6_addr,destination,sizeof(struct in6_addr));
		//Sending the Message
		call UDPSend.sendto(&dest,&dadv_msg,sizeof(dadv_msg));
		//printf("\n sending the Directory Advertisement Message");	
		//printfflush();	
	}


	//Handler to send the Service Type Reply Message
	
	void srvtyperep_send(servicetype_request_msg *msg,uint16_t error_code,struct sockaddr_in6 *destination)
	{

		memset(&strep_msg,0,sizeof(strep_msg));
		//Filling the Service Type Reply Message Header
		fillHeader(&strep_msg.sslp_header,SERVICE_TYPE_REPLY,msg->sslp_header.seq_no);

		//Filling the Message Details
		//printf("\n the scope received is %s",msg->scope);
		strep_msg.error_code=error_code;		
		fillAllServices(strep_msg.servicetype,msg->scope);
		strep_msg.length_servicetype=stringlength(strep_msg.servicetype);
		printf("\n length of the services sent  is %d",strep_msg.length_servicetype);printfflush();
		//Sending the Message
		destination->sin6_port=htons(SSLP_LISTENING_PORT);
		call UDPSend.sendto(destination,&strep_msg,sizeof(strep_msg));
		//printf("\n sending service type reply message sent to with length:%d ",sizeof(strep_msg));
		//printf_in6addr(&destination->sin6_addr);
		//printf("port is %u",ntohs(destination->sin6_port));
		//printfflush();
	}
	
/*****************************************Receive Handlers**********************************************************************/

	//Receive Handler for the service Request Message
	void srvrqst_rcv(struct sockaddr_in6 *from, void *data)
	{
		service_request_msg *servicemsg=(service_request_msg *)data;
		uint8_t index;
	
		//check whether the service request is directory-agent

		if(!memcmp(&servicemsg->service_type,"service:directory-agent",stringlength("service:directory-agent")))
		{
			//printf("\n iam da and i have to send a unicast service request");
			directoryadv_send(&from->sin6_addr);
		}
		else
		{
			
			printRegisteredServices();
			if(findService(servicemsg->service_type)!=-1)
			{
				//printf("\nservice :%s is present with scope length:%d",servicemsg->service_type,
				//servicemsg->length_scope_list);
				//Send a Service reply with those service type
				memset(&srep_msg,0,sizeof(srep_msg));
				//Filling the service reply message header
				fillHeader(&srep_msg.sslp_header,SERVICE_REPLY,servicemsg->sslp_header.seq_no);
				index=findService(servicemsg->service_type);
				if((memcmp(servicemsg->scope,&registered_services[index].scope,
					stringlength(registered_services[index].scope))) &&
					((memcmp(servicemsg->scope,"default",stringlength("default"))) &&
					(servicemsg->length_scope_list)))
					{	
						//Filling the Message Details
						srep_msg.error_code=SCOPE_ERROR;
						//printf("\nSCOPE ERROR");
					}
					else
					{
						//printf("\nNO Error");
						srep_msg.error_code = NO_ERROR;
						srep_msg.location_entry_count=1;					
						srep_msg.location_entry.lifetime= registered_services[index].lifetime;
						srep_msg.location_entry.LT=URL_ADDR;
						memcpy(&srep_msg.location_entry.url,&registered_services[index].url,
						stringlength(registered_services[index].url));
						srep_msg.location_entry.length_url=stringlength(registered_services[index].url);
					}
				
			}
			else	//service is not found and will send a service reply with zero service location entries
			{
				memset(&srep_msg,0,sizeof(srep_msg));
				//Filling the Service Reply Message Header
				fillHeader(&srep_msg.sslp_header,SERVICE_REPLY,servicemsg->sslp_header.seq_no);	
	
				//Filling the Message details

				srep_msg.error_code=NO_ERROR;
				srep_msg.location_entry_count=0;	//TODO:Make dynamic
				//printf("\n sending service reply message with zero location entries");
					
			}
			from->sin6_port=htons(SSLP_LISTENING_PORT);
			call UDPSend.sendto(from,&srep_msg,sizeof(service_reply_msg));					
			//printf("\n service url sent is %s",registered_services[index].url);
			//printfflush();

			//printfflush();
		}
		
	}
	

	//Receive Handler for the Service Type Request Message
	void srvtyperqst_rcv(struct sockaddr_in6 *from,void *data)
	{		
		//sending a service type reply message
		printf("service type request received from");
		printf_in6addr(&from->sin6_addr);
		printfflush();
		srvtyperep_send((servicetype_request_msg *)data,NO_ERROR,from);

	}
	


/***************************************SplitControl Implementation***********************************************************/	

	command error_t SplitControl.start()
	{
		running=TRUE;  
		init();
		call UDPSend.bind(SSLP_TRANSMIT_PORT);
		call UDPReceive.bind(SSLP_LISTENING_PORT);
		
	

		//call RadioControl.start();	

		//printf("\n starting the  DA Timer");
		//printfflush();
		//TODO:Uncomment the following two lines after ND Works:Jamal
		directoryadv_send(&SRVLOC_DA);		
		call DATimer.startPeriodic(DA_PERIOD);	
		
		return SUCCESS;


	}

	command error_t SplitControl.stop()
	{



	}




/********************************************EVENTS****************************************************************************/

	event void UDPSend.recvfrom(struct sockaddr_in6 *from, void *data, 
                             uint16_t len, struct ip6_metadata *meta) {

	}


	event void UDPReceive.recvfrom(struct sockaddr_in6 *from, void *data, 
                             uint16_t len, struct ip6_metadata *meta) {

		
			struct sslp_hdr *header;	
			if(call IPAddress.isLLAddress(&from->sin6_addr))	
			{
				//printf("\n local address");
				//printfflush();
				header=(struct sslp_hdr *)data;			
			}
			else{
				//printf("\n globaladdress");
				//printf_in6addr(&from->sin6_addr);
				header=getHeader(data);
				//printfflush();
			}header=getHeader(data);
			//printf("\n sequence number received is %u",header->seq_no);
			//printf("\n version is %d",header->version);
			printf("\n message id is %d",header->msgid);printfflush();
			//printf("\n o flag is %d",header->O_flag);
			//printf("\n f flag is %d",header->F_flag);
			//printf("\n reserved is %d",header->rsv);
			//printfflush();
			call Leds.led0Toggle();
		//printf("\n checking the type of the message received");
		if(header->msgid==SERVICE_REQUEST)
		{
			
			printf("\n Service Request Message is received");
			srvrqst_rcv(from,data);	
		}
		else if(header->msgid==SERVICE_REGISTRATION)
		{
			serviceregistration *sreg=(serviceregistration *)data;
			//Send the service acknowledgement and add it in his buffer
			printf("\n service registration message is received");
			printfflush();
			srvack_send(from,header->seq_no,RegisterService(sreg));
		}
		else if(header->msgid==SERVICE_DEREGISTRATION)
		{
			servicederegistration *sdereg = (servicederegistration *)data;
			//Deregister the service 		
			//send the service acknowledgement	
			//printf("\n service deregistration message is received");
			srvack_send(from,header->seq_no,DeRegisterService(sdereg));		
		}
		else if(header->msgid==SERVICE_TYPE_REQUEST)
		{

			servicetype_request_msg *msg=(servicetype_request_msg *)data;
						call Leds.led1Toggle();
			printf("\n Service Type Request Message is Received");
			printf("\n scope received is %s",msg->scope);
			printfflush();
			srvtyperqst_rcv(from,data);			
		}else if(header->msgid==DA_ADVERTISEMENT){
			call Leds.led2Toggle();
			printf("Directory Advertisement Message is received");	
			printfflush();
		}
		else{
		//	call Leds.led0Toggle();

			//printf("\n some other message is received with message id :%d",header->msgid);
			//printfflush();
		   }


	}

	event void RadioControl.startDone(error_t e) {
		

	}


	event void RadioControl.stopDone(error_t e) {
		signal SplitControl.stopDone(SUCCESS);  
  	}


	//macro this thing
	event void DATimer.fired()
	{
		directoryadv_send(&SRVLOC_DA);
		
	}

	event void DeleteTimer.fired()
	{
		uint8_t i;
		for(i=0;i<STORE_MAX_SERVICES;i++)
		{

			if(registered_services[i].lifetime)		//check if any has a lifetime greater than zero then reduce it by 1
			{
				registered_services[i].lifetime-=1;
				//printf("registered service lifetime :%d",registered_services[i].lifetime);
				if(!registered_services[i].lifetime)//check if any one has a lifetime becoming zero then deleting those entry
				{
					//printf("\n deleting the service :%sbecause the lifetime is zero",
					//registered_services[i].servicetype);
					memset(&registered_services[i],0,sizeof(registered_services[i]));
				}
				//printfflush();
			}
			
		}
	


	}

	event void IPAddress.changed(bool valid)
	{

	}


/*************************************Default Events****************************************************************************/
	default event void SplitControl.startDone(error_t error)
  	{
  	}

	default  event void SplitControl.stopDone(error_t error)
  	{ 
  	}







}
