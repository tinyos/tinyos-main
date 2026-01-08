#include "sslp.h"
#include <lib6lowpan/ip_malloc.h>
module SSLP
{
	provides interface SplitControl;
	provides interface ServiceLocation;


	uses interface SplitControl as RadioControl;		
	uses interface UDP as UDPSend;
	uses interface UDP as UDPReceive;
	uses interface Timer<TMilli> as RetransmitTimer;
	uses interface Timer<TMilli> as PrintTimer;	
	#ifdef NODE_UA
	uses interface Timer<TMilli> as StorageTimer;
	#endif
	uses interface Timer<TMilli> as DelayTimer;
	uses interface SSLPNode;
	uses interface IPAddress;
	uses interface Leds;
	uses interface Random;
	
}


implementation
{
	bool DA_AVAILABLE=FALSE;	//This variable will tell whether we can check whether DA is present or not

	uint8_t running=FALSE;		//Indicates Whether the SSLP is On or OFF.ON=TRUE,OFF=FALSE
	#ifdef NODE_UA
	services_available services[STORE_MAX_SERVICES];	//UA store the services information in this buffer
	servicelocation_entry entries[STORE_MAX_SERVICES];  //Storing the received location entries in this
	uint8_t location_entriescount=0;
	char services_received[64];		//store all the service types in this message
	#endif
	struct in6_addr DA_IP;
	char global_service[16],global_scope[16];	//these variables are mainly to be used at the retransmission.If u suppose send the message and u did not receive the message then we will use these variables
	uint8_t global_service_len,global_scope_len;
	sequencer available_sequences[STORE_MAX_SEQUENCES];	//This structure stores the scope and service  for a particular sequence
	
	
	

	uint8_t indexer=0;		//This is used in sequencer logic to overwrite  if the array is full

	char append[28];	//This is Mainly For appending the Service to the service String

	struct sockaddr_in6 dest;	//Structure used for filling the UDP address(IP+Port)

	bool FIRED=FALSE;

	uint32_t TIMER_PERIOD=CONFIG_RETRY;	//this variable contains the period for the retransmit Timer
	uint8_t MSGSTATE;			//this variable defines what the message should be sent when the Timer fires
	uint32_t remain;
	bool SENT;
	uint32_t time=CONFIG_RETRY;

	uint8_t SERVICEREQ_STATE;		//Whether Has to retransmit or just Unicast
	uint8_t SERVICETYPEREQ_STATE;
	struct in6_addr DA_ADDRESSES[MAX_DA_ADDR];	//Array which stores the Directory Agents present in the network
	uint8_t DA_Count=0;

	struct in6_addr SRVLOC_DA;	//This is the address for receiving UA and SA has to join for receiving DA-ADVT messages
	struct in6_addr SRVLOC;	//this is the address for receiving Service Type Request and Attribute Type Request messages
	struct in6_addr SERVICERequest_IP;//This is the address for receiving service request messages

/**************************************Messages*******************************************************************************/

//Service Request Messages asking for DAAdvt has to be sent to SRVLOC-DA address

//DA has to send Directory Advertisement to the SRVLOC-DA Address

//UA has to send the service request messages to a particular IP address based on the function

/*************************************Functions********************************************************************************/

	
	//Initialize all the IPAddresses here
	void init()
	{
		inet_pton6("ff02::116",&SRVLOC_DA);
		inet_pton6("ff02::123",&SRVLOC);
		#ifdef NODE_UA
			call SSLPNode.setUA();
		#elif NODE_SA
			call SSLPNode.setSA();
		#endif
		call UDPSend.bind(SSLP_TRANSMIT_PORT);
		call UDPReceive.bind(SSLP_LISTENING_PORT); 
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

	//URL is of the format service:directory-agent://IP
	struct in6_addr ExtractIP(char *url)
	{
		url[stringlength(url)-1]='\0';
		inet_pton6(&url[26],&DA_IP);
		return DA_IP;
	}

	
	/*This function gives the unique sequence number for each SREQ.It will give only from 1 to 5 for now if u want u can 		increase*/
	uint8_t seq_generator(char *service,char *scope)
	{
		uint8_t i;
		//check whether already there is a sequence number for this combination

		for(i=0;i<STORE_MAX_SEQUENCES;i++)		
		{
			if(!memcmp(service,available_sequences[i].service,stringlength(service))&&
			   !memcmp(scope,available_sequences[i].scope,stringlength(scope)))
				return i;
		}

		//else the combination is not there we have to add the combination
		
		for(i=0;i<STORE_MAX_SEQUENCES;i++)
		{
			if(!stringlength(available_sequences[i].service))
			{
				break;
			}
		}
		if(i==STORE_MAX_SEQUENCES)	//we will overwrite the already existing entries
		{
			if(indexer==5)
			{
				i=indexer=0;
			}
			else
			{
				i=indexer;				
			}
			indexer++;
		}
		memcpy(available_sequences[i].service,service,stringlength(service));
		memcpy(available_sequences[i].scope,scope,stringlength(scope));
		available_sequences[i].sequence_no=i;	

		return i;
	}

	//this function checks whether the particular service and scope already exists in the cache or not if exist it returns the index else it returns -1
	#ifdef NODE_UA
	int servicefinder(char *service,char *scope)
	{
		int i;
		printf("\n Looking for service:%s and Scope:%s",service,scope);
		for(i=0;i<STORE_MAX_SERVICES;i++)
		{
			if(!memcmp(service,services[i].service,stringlength(service))&&!memcmp(scope,services[i].scope,
			stringlength(scope)))
				return i;
		}
		return -1;

	}
	void addServiceURL(servicelocation_entry *entry)
	{
		
		memcpy(&entries[location_entriescount++],entry,sizeof(servicelocation_entry));

	}
	void addServiceType(char *servicetype)
	{
		
		if(stringlength(servicetype))
		{
			memcpy(&services_received[stringlength(services_received)],servicetype,stringlength(servicetype));
			services_received[stringlength(services_received)]=',';
		}
		
			
	}
	#endif

	//This function will just append the "service:" to the string passed

	char * addService(char *serv)
	{
		memset(&append,0,sizeof(append));
		memcpy(&append[stringlength(append)],"service:",stringlength("service:"));
		memcpy(&append[stringlength(append)],serv,stringlength(serv));
		return append;

	}

	//This function will remove the "service:" from the string passed

	char *removeService(char *serv)
	{
		return serv+stringlength("service:");
	}

	//This function is used to fill the header of the SSLP Messages
	void fillHeader(struct sslp_hdr *header,uint8_t type,uint16_t seq_no)
	{
		header->version=SSLP_VERSION;
		header->msgid=type;
		header->seq_no=seq_no;	
		//printf("\n the sequence number sent is %d",seq_no);
	}
	
	//Add DA into the DA Array
	void addDA(struct in6_addr *DA)	
	{
		if(DA_Count==0)
		{	
			DA_AVAILABLE=TRUE;
		}

		if(DA_Count<MAX_DA_ADDR)
		{
			memcpy(&DA_ADDRESSES[DA_Count],DA,sizeof(struct in6_addr));
			DA_Count++;
		}
	}

	
	
	//this will be used when packet is received frm global address
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


	


/*****************************************Send Handlers*************************************************************************/

	//Handler to Send the Service Request Message
	int srvrqst_snd(char *service,uint8_t length_service,char *scope,uint8_t length_scope)
	{

		service_request_msg *sreq_msg=(service_request_msg *)ip_malloc(sizeof(service_request_msg));//Service Request Message
		#ifdef NODE_UA
		//Before Sending Lets Check whether any information already exists for this service and scope in the cache
		int index=call ServiceLocation.findService(service,scope);
		//suppose if the service Location already exist
		if(index!=-1)
		{
			//just move all the services on the top just like sort it with the services will have to do
				//TODO:Has to do
			return 0;
		}
		#endif
		//no service information exist about that location has to send the service request message to get the info
		memset(sreq_msg,0,sizeof(*sreq_msg));
		//we will fill the header with the msg-id set to the SERVICE_REQUEST
		fillHeader(&sreq_msg->sslp_header,SERVICE_REQUEST,seq_generator(service,scope));

		

		//filling the message
		//first we will work with IP Address as the Addressing Mode we will implement the remaining later
		sreq_msg->AM=IP_ADDR;

		//setting the source address to the Link Local Address formed with EUI-64 
		call IPAddress.getLLAddr(&sreq_msg->ip_address);
		//adding the "service:" to the service string following the service template	

		

		service=addService(service);
		//copying the service and scope into the message
		memcpy(&sreq_msg->service_type,service,length_service+stringlength("service:"));

		sreq_msg->length_service_type=stringlength(service);
		printf("\n Service Request length :%d",sreq_msg->length_service_type);
		printfflush();
		memcpy(&sreq_msg->scope,scope,length_scope);
		sreq_msg->length_scope_list=stringlength(scope);
		//We will Fill the UDP Header(IP+Port)
		dest.sin6_port=htons(SSLP_LISTENING_PORT);
		//if(!memcmp(&sreq_msg.service_type,"service:directory-agent",stringlength("service:directory-agent")))

		if(DA_AVAILABLE)
		{
			memcpy(&dest.sin6_addr,&DA_ADDRESSES[0],sizeof(struct in6_addr));
			SERVICEREQ_STATE=SSLP_UNICAST;
			printf("\n as da is present directly unicasting it to da");
		}
		else	
			memcpy(&dest.sin6_addr,&SRVLOC_DA,sizeof(struct in6_addr));			
			//else
			//	inet_pton6("ff02::1",&dest.sin6_addr);	//filling the destination address as all-nodes address
			//do we have to create a separate address for SA Nodes????


		printf("\n sending a service request message with the service type :%s",sreq_msg->service_type);	
		printf("\n size of the message is %d",sizeof(*sreq_msg));	
		printfflush();
		call Leds.led2Toggle();
		call UDPSend.sendto(&dest,sreq_msg,sizeof(*sreq_msg));
		ip_free(sreq_msg);
		MSGSTATE=SERVICE_REQUEST;
		if(SERVICEREQ_STATE==RETRANSMIT)	//It is mainly so that sending a service request for service:directory-agent should not be retransmitted
		{//If the message is not received we have to retransmit for that we will use the Timer
			call RetransmitTimer.startOneShot(time);
			//printf("\n Timer period:%ld",time);
		}
		if(!FIRED&&memcmp(service,"service:directory-agent",stringlength("service:directory-agent")))
		{
			#ifdef NODE_UA	//clearing the previous data
			memset(&entries,0,sizeof(servicelocation_entry)*STORE_MAX_SEQUENCES);
			location_entriescount=0;
			call StorageTimer.startOneShot(WAIT_PERIOD_SREPLY);	
			FIRED=TRUE;
			#endif
		}			
		return 0;
	}

	//Handler to send the Service Reply Message
	#ifdef NODE_SA
	void srvrply_snd(service_request_msg *servicemsg,struct sockaddr_in6 *destination,uint16_t error)
	{

		char url[48];
		service_reply_msg  *srep_msg=(service_reply_msg *)ip_malloc(sizeof(service_reply_msg));	//Service Reply Message
		if(call SSLPNode.getServiceURL(removeService(servicemsg->service_type),servicemsg->scope,url)==SUCCESS)
		{
			printf("\n the service url is %s",url);
		}
		else{
			printf("\n Error in getting the service url");
		}
		//Filling the Service Reply Message Header
		fillHeader(&srep_msg->sslp_header,SERVICE_REPLY,servicemsg->sslp_header.seq_no);	
		
		//Filling the Message details

		srep_msg->error_code=error;
		srep_msg->location_entry_count=1;	//TODO:Make dynamic

		srep_msg->location_entry.lifetime=600;	//TODO: Define Macros for this
		srep_msg->location_entry.LT=URL_ADDR;	//fixing to URL here
		srep_msg->location_entry.length_url=stringlength(url);
		memcpy(srep_msg->location_entry.url,url,sizeof(url));
		printf("\n location entry :%s",srep_msg->location_entry.url);
		printfflush();
		call UDPSend.sendto(destination,srep_msg,sizeof(service_reply_msg));
		ip_free(srep_msg);

	}


	//Handler to send the Service Registration Message

	void srvreg_snd(servicelocation_entry *location_entry,char *servicetype,char *scope,uint8_t state)
	{
		serviceregistration *sreg_msg = (serviceregistration *)ip_malloc(sizeof(serviceregistration));//Service Registration Message
		memset(sreg_msg,0,sizeof(*sreg_msg));
		//Filling the Service Registration Message Header
		fillHeader(&sreg_msg->sslp_header,SERVICE_REGISTRATION,seq_generator(servicetype,scope));
		if(state==FRESH)	
			sreg_msg->sslp_header.F_flag=1;
		//Filling the Message Details
		sreg_msg->location_entry=*location_entry;
		sreg_msg->length_service_type=stringlength(servicetype)+stringlength("service:");	
		//adding the "service:" to the service string following the service template	
		
		servicetype=addService(servicetype);
		printf("\n service registering for %s",servicetype);
		printfflush();
		memcpy(&sreg_msg->service_type,servicetype,stringlength(servicetype));
		sreg_msg->length_scope_type=stringlength(scope);
		memcpy(&sreg_msg->scope,scope,stringlength(scope));

		//Sending the Message to the DA

		//Fill the Message
		dest.sin6_port=htons(SSLP_LISTENING_PORT);
		//DA Address
		if(DA_AVAILABLE)
		{
			printf("\n DA is available directly send it to the DA");
			memcpy(&dest.sin6_addr,&DA_ADDRESSES[0],sizeof(struct in6_addr));
		}else{
			inet_pton6("ff02::123",&dest.sin6_addr);
		}
		//printf("\n sending service registration message with length:%d",sizeof(*sreg_msg));
		

		call UDPSend.sendto(&dest,sreg_msg,sizeof(*sreg_msg));
		ip_free(sreg_msg);
	}

	//Handler to send the Service De Registration Message
	void srvdereg_snd(servicelocation_entry *location_entry,char *servicetype,char *scope)
	{
		servicederegistration *sdereg_msg=(servicederegistration *)ip_malloc(sizeof(servicederegistration));//Service De registration Message
		memset(sdereg_msg,0,sizeof(*sdereg_msg));
		
		//Filling the service deregistration message Header
		fillHeader(&sdereg_msg->sslp_header,SERVICE_DEREGISTRATION,seq_generator(servicetype,scope));

		//Filling the Message Details
		
		sdereg_msg->location_entry = *location_entry;
		sdereg_msg->length_service_type=stringlength(servicetype)+stringlength("service:");	
		servicetype=addService(servicetype);
		memcpy(&sdereg_msg->service_type,servicetype,stringlength(servicetype));
		sdereg_msg->length_scope_type=stringlength(scope);
		memcpy(&sdereg_msg->scope,scope,stringlength(scope));
		
		//Sending the Message to the DA

		//Fill the Message
		dest.sin6_port=htons(SSLP_LISTENING_PORT);
		//DA Address
		if(DA_AVAILABLE)
		{
			printf("\n DA is available directly send it to the DA");
			memcpy(&dest.sin6_addr,&DA_ADDRESSES[0],sizeof(struct in6_addr));
		}
		else
		{
			printf("\n DA is not available we have to multicast it");
			inet_pton6("ff02::123",&dest.sin6_addr);
		}	
		printf("\n sending service deregistration message with length :%d",sizeof(*sdereg_msg));
		printfflush();

		call UDPSend.sendto(&dest,sdereg_msg,sizeof(*sdereg_msg));
		ip_free(sdereg_msg);	
	}

	//Handler to send the Service Type Reply Message
	
	void srvtyperep_send(servicetype_request_msg *msg,uint16_t error_code,struct sockaddr_in6 *destination)
	{
		

		servicetype_reply_msg *strep_msg=(servicetype_reply_msg *)ip_malloc(sizeof(servicetype_reply_msg));    		//Service Type Reply Message
		memset(strep_msg,0,sizeof(*strep_msg));
		//Filling the Service Type Reply Message Header
		fillHeader(&strep_msg->sslp_header,SERVICE_TYPE_REPLY,msg->sslp_header.seq_no);

		//Filling the Message Details
		printf("\n the scope received is %s",msg->scope);
		strep_msg->error_code=error_code;
		if(call SSLPNode.getSAState())
			memcpy(&strep_msg->servicetype,call SSLPNode.getServices(msg->scope,msg->length_scope_list),
			sizeof(strep_msg->servicetype));		
		strep_msg->length_servicetype=stringlength(strep_msg->servicetype);

		//Sending the Message
		call UDPSend.sendto(destination,strep_msg,sizeof(*strep_msg));
		printf("\n sending service type reply message");printfflush();
		ip_free(strep_msg);
	}


	


	#else
	//Handler to send the Service Type Request Message

	void srvtypereq_send(char *scope)
        {
		servicetype_request_msg *streq_msg= (servicetype_request_msg *)ip_malloc(sizeof(servicetype_request_msg)); 			//Service Type Request Message
		memset(streq_msg,0,sizeof(*streq_msg));
		//Filling the Service Type Request Header Message
		fillHeader(&streq_msg->sslp_header,SERVICE_TYPE_REQUEST,seq_generator("default",scope));

		//Filling the Message Details

		streq_msg->AM= IP_ADDR;		//Fixing it here to the IP Address
		call IPAddress.getLLAddr(&streq_msg->ip_address);
		streq_msg->length_scope_list = stringlength(scope);
		memcpy(&streq_msg->scope,scope,streq_msg->length_scope_list);

		//Filling the UDP Header
		
		dest.sin6_port=htons(SSLP_LISTENING_PORT);
		
		if(DA_AVAILABLE)
		{
			memcpy(&dest.sin6_addr,&DA_ADDRESSES[0],sizeof(struct in6_addr));
			printf("\n as da is present directly unicasting it to da");
			SERVICETYPEREQ_STATE= SSLP_UNICAST;
		}
		else{
			SERVICETYPEREQ_STATE=RETRANSMIT;
			memcpy(&dest.sin6_addr,&SRVLOC,sizeof(struct in6_addr));	
		  }
		printf("\n sending the service type request message");
		printfflush();
		call UDPSend.sendto(&dest,streq_msg,sizeof(*streq_msg));
		ip_free(streq_msg);
		MSGSTATE=SERVICE_TYPE_REQUEST;
		//If the message is not received we have to retransmit for that we will use the Timer
		if(SERVICETYPEREQ_STATE==RETRANSMIT)
			call RetransmitTimer.startOneShot(time);

		//TODO:: HAS To change this such that it will unicast the message while sending to DA and should not start the DAtimer
		if(!FIRED)
		{
				//clearing the previous data
			memset(&services_received,0,sizeof(services_received));
			call StorageTimer.startOneShot(WAIT_PERIOD_SREPLY);
			FIRED=TRUE;
		}	
	}
	#endif
	

/*****************************************Receive Handlers**********************************************************************/

	#ifdef NODE_SA
	//Receive Handler for the service Request Message
	void srvrqst_rcv(struct sockaddr_in6 *from, void *data)
	{
		service_request_msg *servicemsg=(service_request_msg *)data;
		if(call SSLPNode.getSAState())
		{	
			printf("\n srvrqst_rcv:%s",servicemsg->service_type);
			//check Whether You have the Service or not
			switch(call SSLPNode.findService(removeService(servicemsg->service_type),servicemsg->scope))
			{
				case SERV_SCOPE :
			printf("\ni will send the service reply with the location info");					
				//Now we have to send a Service Reply
					srvrply_snd(servicemsg,from,NO_ERROR);
					break;	

				case SERV:
					srvrply_snd(servicemsg,from,SCOPE_ERROR);
					break;

				case NONE:
					printf("service not present :%s",removeService(servicemsg->service_type));
					break;
				default:
					printf("some error has occurred");
			}
		}
		else
		{
			printf("\n Iam UA and i should not process this message");
			return;
		}
	}
	
	//Receive Handler for the Service Reply Message

	void srvrply_rcv(struct sockaddr_in6 *from, void *data)
	{
		


	}


	//Receive Handler for the Service Acknowledgement Message
	void srvack_rcv(struct sockaddr_in6 *from,void *data)
	{



	}


	//Receive Handler for the Service Type Request Message
	void srvtyperqst_rcv(struct sockaddr_in6 *from,void *data)
	{
		
		if(call SSLPNode.getSAState())
		{
			if(call SSLPNode.servicesPresent(((servicetype_request_msg *)data)->scope))
			//sending a service type reply message
				srvtyperep_send((servicetype_request_msg *)data,NO_ERROR,from);

		}
		else{
			printf("\n Iam UA and i should not process this message");
			return;
		   }

	}

	#endif
/****************************************SplitControl Implementation*************************************************************/

	command error_t SplitControl.start()
  	{
	
		running=TRUE;  
		init();	  	
		if(!(call SSLPNode.getSAState()||call SSLPNode.getUAState()))		//If user forgets to set any role by default set 											it to UA	
			call SSLPNode.setUA();
	
		#warning "*** SSLP does not start the radio ***"
		SERVICEREQ_STATE=SSLP_UNICAST;
		//srvrqst_snd("directory-agent",stringlength("directory-agent"),"",0);	
		call DelayTimer.startOneShot(CONFIG_REG_ACTIVE);	//Wait to register services on Active DA discovery

		return SUCCESS;

  	}


 	command error_t SplitControl.stop()
 	{
		 running= FALSE;
		call RadioControl.stop();

 	}
	



/******************************************ServiceLocation Implementation******************************************************/

	#ifdef NODE_UA
	//return -1 when no service and scope are matching,else returns the index where the service is present
	command int ServiceLocation.findService(char *service,char *scope)
	{
		int index=servicefinder(service,scope);
		if(index!=-1)
		{
			return index;
		}
		else
			return -1;
	}

	//UA specifies the type of the service he want and the scope then we will signal him back with the service Location
	command error_t ServiceLocation.findServices(char *service,char *scope)
	{
		if(call SSLPNode.getUAState())		//Only UA should be able to send the service request message
		{
				
			//clearing the global varaibles to remove the old data and the service request message
			memset(&global_service,0,sizeof(global_service));
			memset(&global_scope,0,sizeof(global_scope));

			//copying the data so that it can be used for retransmission
			memcpy(&global_service,service,stringlength(service));	
			memcpy(&global_scope,scope,stringlength(scope));

			global_service_len=stringlength(global_service);
			global_scope_len=stringlength(global_scope);
			printf("\n setting the state to retransmit");
			printfflush();
			SERVICEREQ_STATE=RETRANSMIT;		//It means to retransmit the message if no reply is received
			srvrqst_snd(global_service,global_service_len,global_scope,global_scope_len);
			return SUCCESS;
		}
		return FAIL;

	}


	command error_t ServiceLocation.findAllServices(char *scope)
	{
		//Send a Service Type Request Message
		memset(&global_scope,0,sizeof(global_scope));
		
		memcpy(&global_scope,scope,stringlength(scope));
		srvtypereq_send(scope);
		return SUCCESS;
	}

	#else
	command error_t ServiceLocation.registerService(servicelocation_entry *location_entry,char *servicetype,char *scope,uint8_t state)
	{

		//Send a Service Registration Message
		srvreg_snd(location_entry,servicetype,scope,state);
		return SUCCESS;

	}

	command error_t ServiceLocation.deregisterService(servicelocation_entry *location_entry,char *servicetype,char *scope)
	{
		//Send a Service Deregistration Message
		printf("\n sending a service deregistration message");
		srvdereg_snd(location_entry,servicetype,scope);
		return SUCCESS	;

	}

	#endif




/********************************************EVENTS****************************************************************************/



	event void UDPSend.recvfrom(struct sockaddr_in6 *from, void *data, 
                             uint16_t len, struct ip6_metadata *meta) {
		struct sslp_hdr *header=(struct sslp_hdr *)data;
		#ifdef NODE_UA
		service_reply_msg  *srep;
		#else
		service_ack_msg *sack;
		#endif
		printf("\n the sequence number is %d",header->seq_no);

		switch(header->msgid){	
		#ifdef NODE_UA		
		case SERVICE_REPLY:
			srep=(service_reply_msg *)data;
			TIMER_PERIOD=CONFIG_RETRY;
			
			if(srep->location_entry.length_url)
			{
				printf("\n service reply message is received with length :%d",srep->location_entry.length_url);
				addServiceURL(&srep->location_entry);
				printf("\n url is %s",srep->location_entry.url);
			}
			else{
				printf("service reply message is received with zero entries and errorcode:%d",srep->error_code);
			}
			call RetransmitTimer.stop();
			//Add into an array and after some time signal it back
			printfflush();
			break;
		#else
		case SERVICE_ACKNOWLEDGE:				
			sack = (service_ack_msg *)data;	
			printf("\n Service Acknowledge message is received with error code:%d",sack->error_code);
			printfflush();
			break;
		#endif
		default :
			printf("\n some other message is received with id:%d",header->msgid);	
			break;	
		}
	  }

	event void UDPReceive.recvfrom(struct sockaddr_in6 *from, void *data, 
                             uint16_t len, struct ip6_metadata *meta) {


			struct sslp_hdr *header;
			printf_in6addr(&from->sin6_addr);	
			if(call IPAddress.isLLAddress(&from->sin6_addr))	
			{
				//printf("\n local address");
				//printfflush();
				//header=(struct sslp_hdr *)data;			
			}
			else{
				//printf("\n globaladdress");
				//printf_in6addr(&from->sin6_addr);
				//header=getHeader(data);
				//printfflush();
			}
			header=getHeader(data);
		printf("\n the sequence number receive is %d",header->seq_no);
		//printf("\n checking the type of the message received");
		if(header->msgid==DA_ADVERTISEMENT)
		{
			directory_advt_msg *msg = (directory_advt_msg *)data;
			struct in6_addr DA_Addr=ExtractIP(msg->location_entry.url);
		
			printf("\nDA Advertisement Message is received");
			printf("\nURL :%s",msg->location_entry.url);
			printf("\n DA_ADDRESS:");
			printf_in6addr(&DA_Addr);
			printf("\n scope is %s",msg->scope);
			printfflush();
			//add this DA Address into the array of DA_Addresses
			
			addDA(&DA_Addr);
			
		}
		#ifdef NODE_SA
		else if(header->msgid==SERVICE_TYPE_REQUEST)
		{
			servicetype_request_msg *msg=(servicetype_request_msg *)data;
			printf("\n Service Type Request Message is Received");
			printf("\n scope received is %s",msg->scope);
			printfflush();
			srvtyperqst_rcv(from,data);			
		}
		else if(header->msgid==SERVICE_REQUEST)	
		{
			printf("\n Service Request Message is received");
			srvrqst_rcv(from,data);	
		}else if(header->msgid==SERVICE_ACKNOWLEDGE)
		{
			call Leds.led2Toggle();
		}
		#else
		else if(header->msgid==SERVICE_TYPE_REPLY)
		{
			servicetype_reply_msg *strep=(servicetype_reply_msg *)data;
			TIMER_PERIOD=CONFIG_RETRY;
			call RetransmitTimer.stop();
			addServiceType(strep->servicetype);
			printf("\n Service Type Reply Message is received with services:%s",strep->servicetype);
		}
		#endif
		else
		{
			printf("\n some other message is received with message id :%d",header->msgid);
			printf("\n length of the message is %d",len);
			//call Leds.led2Toggle();
		}

	}
/*******************************************Timer Functions*********************************************************************/

	void chooseInterval()
  	{


		SENT=TRUE;		
		if(TIMER_PERIOD==CONFIG_MC_MAX)
			return;

		TIMER_PERIOD*=2;
		if(TIMER_PERIOD>CONFIG_MC_MAX)
			TIMER_PERIOD=CONFIG_MC_MAX;

		time=TIMER_PERIOD;
		time/=2;
		time+=call Random.rand32()%time;
		if(MSGSTATE==SERVICE_REQUEST){
			//printf("\nTimerfired:global_service:%s",global_service);	
			srvrqst_snd(global_service,global_service_len,global_scope,global_scope_len);
		}
		#ifdef NODE_UA
		else if(MSGSTATE==SERVICE_TYPE_REQUEST){
			srvtypereq_send(global_scope);
		}
		#endif
	  }


	 void remainInterval()
	 {
		SENT=FALSE;
		remain=TIMER_PERIOD-time;
		call RetransmitTimer.startOneShot(remain);
	 }



	
/**********************************************Timer Events**********************************************************************/
	event void RetransmitTimer.fired()		//Section6.3(RFC2608) Retransmission of SSLP Messages
	{
		printf("\n  retransmit timer fired");
		if(SENT)
		{
			remainInterval();
		}
		else
		{
			chooseInterval();
		}
		

	}
	event void PrintTimer.fired()
	{
		/*uint8_t i;
		for(i=0;i<STORE_MAX_SERVICES;i++)
		{
			if(services[i].lifetime)	//lifetime is in SECONDS
			{
				services[i].lifetime -= PRINTTIMER_PERIOD/1000;
				if(services[i].lifetime<=PRINTTIMER_PERIOD/1000)	
					call ServiceLocation.deleteServiceEntry(i);
			}

		}
		#ifdef PRINTFUART_ENABLED
			call ServiceLocation.printServices();
		#endif*/
	}

	#ifdef NODE_UA
	event void StorageTimer.fired()
	{
		printf("\n signalling the user back with the information");
		
		if(MSGSTATE==SERVICE_REQUEST)
		{
			signal ServiceLocation.receiveServices(entries,location_entriescount);	
		}
		else if(MSGSTATE==SERVICE_TYPE_REQUEST)
		{	
			services_received[stringlength(services_received)]  = '\0';
			signal ServiceLocation.receiveServiceTypes(services_received);
		}
		FIRED=FALSE;	
	}
	#endif
	

	event void DelayTimer.fired()
	{

		signal SplitControl.startDone(SUCCESS);  
	}


	
/*******************************************************************************************************************************/
	event void RadioControl.startDone(error_t e) {
		/*When the SA or UA is initialized they multicast a service request  with the service type :"service:directory-agent"
	*/
		/*printf("\n RadioControl");
		SERVICEREQ_STATE=SSLP_UNICAST;

		call DelayTimer.startOneShot(CONFIG_REG_ACTIVE);	//Wait to register services on Active DA discovery
	*/
        }

	event void RadioControl.stopDone(error_t e) {
		signal SplitControl.stopDone(SUCCESS);  
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


	default event void ServiceLocation.receiveServices(servicelocation_entry *service,uint8_t count){}
  
	default event void ServiceLocation.receiveServiceTypes(char *services_rec){}
}


