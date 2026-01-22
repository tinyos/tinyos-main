/*Implementation of Neighbour Discovery

@author Md.Jamal <mjmohiuddin@cdac.in>
@version $Revision: 1.0

*/

#include <lib6lowpan/ip_malloc.h>
#include <lib6lowpan/ip.h>
#include <lib6lowpan/in_cksum.h>
#include <lib6lowpan/lib6lowpan.h>
#include <AM.h>
#include "Neighbr.h"


module NDP {

  provides interface SplitControl;
  uses interface SplitControl as RadioControl;
  uses interface IPAddress;
  uses interface SetIPAddress;
  uses interface Leds;
  uses interface IP as IP_RS;		//Router Solicitations	
  uses interface IP as IP_RA;	 
  uses interface IP as IP_NS;
  uses interface IP as IP_NA;
  uses interface IP as IP_DAR;
  uses interface IP as IP_DAC;
  uses interface Timer<TMilli> as RSTimer;
  uses interface Timer<TMilli> as NSTimer;
  uses interface MinuteTimer as AROTimer;
  uses interface Ieee154Address;
  uses interface Option;
  uses interface NeighbrCache;
  uses interface Node;
  uses interface Random;
  uses interface RouterList;
}


implementation {


  struct in6_addr ALL_RTR_MULTICAST_ADDR;	
  bool running= FALSE;
  struct in6_addr LLAddress;	//contains the Link Local Address formed with interface identifier being the EUI-64		
  struct in6_addr global;//contains the global address of the node formed with the prefix received from Router Advertisement		
  struct in6_addr NS_DEST;//contains the destination address of the NS message			
  struct in6_addr TENTATIVE_ADDRESS;//This contains the tentative address formed after getting prefix
  struct in6_addr NA_DEST;//contains the destination address of the NA message	
  struct in6_addr NA_SRC;		
  struct in6_addr target;//contains the target received in the NS message
  ieee_eui64_t extended_addr;//contains the EUI-64 extended address	
  ieee_eui64_t NA_EUI;	//contains the EUI-64 OF THE destination of NA message useful when the status is not zero		
  uint8_t numRSSent=0;		//variable that will hold the count of number of RS messages sent			
  uint8_t numNSSent=0;		//variable that will hold the count of number of NS messages sent		
  uint32_t RSInterval=RTR_SOLICITATION_INTERVAL; //Interval of the RS message
  uint8_t NODESTATE=UNDEFINED; 		//contains the state of the node such as Host,Router,LBR
  uint8_t HOP_LIMIT=0;				
  uint8_t RSSTATE=UNDEFINED;
  uint8_t NSSTATE=UNDEFINED;
  uint8_t SplitControlSTATE=NOTSENT;
  bool RSSENT=FALSE;
  uint32_t time=RTR_SOLICITATION_INTERVAL;
  uint32_t remain;				
  uint16_t reachable_lifetime;		
  uint32_t RETRANSMISSION_TIME;		
  struct ip6_packet pkt;
  context_opt context_option;

#define ADD_BUFFER(DATA, LENGTH) ip_memcpy(buffer, (uint8_t *)(DATA), LENGTH);\
buffer += (LENGTH);
/*******************************************Tasks and Fn*************************************************************************/
  void init()
  {
	memset(ALL_RTR_MULTICAST_ADDR.s6_addr, 0, 16);
	ALL_RTR_MULTICAST_ADDR.s6_addr[0] = 0xFF;
    	ALL_RTR_MULTICAST_ADDR.s6_addr[1] = 0x2;
        ALL_RTR_MULTICAST_ADDR.s6_addr[15] = 0x02;
	extended_addr=call Ieee154Address.getExtAddr();		
	call IPAddress.getEUILLAddress(&LLAddress);
//	printf("link layer address:");	
//	printf_buf(extended_addr.data,8);
//	printf("\nLink Local Address");
//	printf_in6addr(&LLAddress);
//	printfflush();

  }

  void fillSAO(stlla_opt *sao)
  {
	int i;
	sao->option_header.type=SLLAO;
	sao->option_header.length=LENGTH_SLLAO;
	sao->ll_addr=extended_addr;
//	for(i=0;i<8;i++)
		//sao->ll_addr.data[i]=extended_addr.data[7-i];	//byte ordering works at the linux side only
	//filling the padding with zeroes
	memset(&sao->reserved,0,sizeof(uint8_t)*6);
	
  }

   void fillTAO(stlla_opt *sao)
  {
	int i;
	sao->option_header.type=TLLAO;
	sao->option_header.length=LENGTH_SLLAO;
	sao->ll_addr=extended_addr;
//	for(i=0;i<8;i++)
		//sao->ll_addr.data[i]=extended_addr.data[7-i];	//byte ordering works at the linux side only
	//filling the padding with zeroes
	memset(&sao->reserved,0,sizeof(uint8_t)*6);
	
  }

  void fillPacket(uint16_t length,struct ip6_packet *packet,struct ip_iovec *v)
  {
	

	packet->ip6_hdr.ip6_nxt=IANA_ICMP;
	packet->ip6_hdr.ip6_plen=htons(length);
	packet->ip6_hdr.ip6_hops=HOP_LIMIT;
	packet->ip6_data=v;
	//call Leds.led0Toggle();

  }

  void fillARO(aro_opt *addr_opt)
  {
	addr_opt->option_header.type=ARO;
	addr_opt->option_header.length=LENGTH_ARO;
	addr_opt->status=0;
	addr_opt->reserved1=0;
	addr_opt->reserved2=0;
	if(call Node.getRouterState())
		addr_opt->reg_lifetime=10;	//10*60 Seconds=10 Minutes
	else
		addr_opt->reg_lifetime=5;	//5*60 seconds=5 Minutes
	addr_opt->eui64=call Ieee154Address.getExtAddr();
  }
  #ifdef NODE_LBR
  void fillPIOABRO(prefix_opt *pio,abro_opt *abr)
  {
	//filling Prefix Information Option first
	pio->option_header.type=PREFIX_INFORMATION;
	pio->option_header.length=LENGTH_PREFIX;	
	pio->prefix_information.prefix_length=PREFIX_LENGTH;		//no. of leading bits in the prefix that are valid
	pio->prefix_information.a_bit=1;		//this can be used for stateless address autoconfiguration
	pio->prefix_information.l_bit=0;
	pio->prefix_information.valid_lifetime=PREFIX_VALID_LIFETIME;//lifetime in seconds that prefix is valid for on-link determination
	pio->prefix_information.preferrd_lifetime=PREFIX_PREF_LIFETIME;//(500min)lifetime in seconds that prefix is valid for stateless 									address autoconfiguration
	//inet_pton6(GLOBAL_PREFIX,&pio->prefix_information.prefix);	
	inet_pton6(IN6_PREFIX,&pio->prefix_information.prefix);
	//filling the Authoritative Border Router Option
	abr->option_header.type=ABRO;
	abr->option_header.length=LENGTH_ABRO;
	abr->abro_information.ver_low=ABR_VER_LOW;
	abr->abro_information.ver_high=ABR_VER_HIGH;
	abr->abro_information.valid_lifetime=ABR_LIFETIME;		//500 minutes
	memcpy(&abr->abro_information.lbr_addr,call RPLRoute.getDodagId(),sizeof(struct in6_addr));
  }
  #endif

  void fillmsgicmp(struct icmpv6_header *icmpv6,uint8_t type)
  {
	icmpv6->type=type;
	icmpv6->code=ICMPV6_ND_CODE;
	icmpv6->checksum=0;
  }

  /* Section 5.5.1(RFC 6775)Host triggers sending NS messages containing an ARO when a new address is configured,when it discovers a new default router,or well before the registration lifetime expires.Such an NS must include an SLLAO,since the router needs to record the link-layer address of the host*/
  void sendMsg(struct in6_addr ip,uint8_t type)
  {
	//messages
	router_solicit solicit_msg;
	neighbr_solicit msg;
	//options
	stlla_opt sao;
	aro_opt addr_opt;
	
	struct ip_iovec v[1];
	uint8_t *buffer;
    	uint8_t data[MSG_SIZE];
        uint16_t length=0;


	memset(&pkt,0,sizeof(struct ip6_packet));

	
   	if(!running)
		return;
	/* Filling the Message */
	if(type==RS)
	{
		fillmsgicmp(&solicit_msg.icmpv6,ICMP_TYPE_ROUTER_SOL);
		solicit_msg.reserved=0;	
		
	}
	if(type==NS)
	{
		fillmsgicmp(&msg.icmpv6,ICMP_TYPE_NEIGHBOR_SOL);
		msg.reserved=0;
		if(NSSTATE==ARO)
		{	
		//	printf("\n NS asking for registration");
		//	printf_in6addr(&TENTATIVE_ADDRESS);
			memcpy(&msg.target,&TENTATIVE_ADDRESS,sizeof(struct in6_addr));//TODO:Has to change this and make some 				generic one
			//filling the Address Registration Option
			fillARO(&addr_opt);
		}
		if(NSSTATE==NUD)
		{
		//	printf("\n Checking Neighbor Reachability of:");		
			memcpy(&msg.target,&ip,sizeof(struct in6_addr));
		//	printf_in6addr(&ip);
		}

	}
	//filling the options for RS message we just fill the SLLAO whereas for NS message fill SLLAO and ARO if required	
	fillSAO(&sao);
	
        buffer = (uint8_t *)&data;
	if(type==RS)
	{
		ADD_BUFFER(&solicit_msg,sizeof(router_solicit));
		length=sizeof(router_solicit);
	}
	if(type==NS)
	{
		ADD_BUFFER(&msg,sizeof(neighbr_solicit));
		length=sizeof(neighbr_solicit);
		if(NSSTATE==ARO)
		{
			ADD_BUFFER(&addr_opt,sizeof(aro_opt));
			length=length+sizeof(aro_opt);
		}
	}	
	ADD_BUFFER(&sao,sizeof(stlla_opt));
	length=length+sizeof(stlla_opt);
	v[0].iov_base=(uint8_t *)data;
	v[0].iov_len=length;
	v[0].iov_next=NULL;
	fillPacket(length,&pkt,&v[0]);


	if(type==RS)
	{
		memcpy(&pkt.ip6_hdr.ip6_src,&LLAddress,sizeof(struct in6_addr));	
		if(RSSTATE==MULTICAST)
			memcpy(&pkt.ip6_hdr.ip6_dst,&ALL_RTR_MULTICAST_ADDR,16);

	      	if(RSSTATE==UNICAST)
			memcpy(&pkt.ip6_hdr.ip6_dst,&ip,16);	
				
		pkt.ip6_hdr.ip6_hops=0xff;	//according to rfc 4861
		call IP_RS.send(&pkt);

		//printfflush();
		numRSSent++;

		call RSTimer.startOneShot(time);
		//printf("\n Send RS message With destination address");				
		//printf_in6addr(&pkt.ip6_hdr.ip6_dst);
	}
	if(type==NS)
	{
		pkt.ip6_hdr.ip6_hops=HOP_LIMIT;
		#ifdef NODE_LBR
		memcpy(&pkt.ip6_hdr.ip6_src,call RPLRoute.getDodagId(),sizeof(struct in6_addr));	
		#else
		memcpy(&pkt.ip6_hdr.ip6_src,&LLAddress,sizeof(struct in6_addr));	
		#endif
		if(NSSTATE==ARO)
		{
			if(call Node.getRouterState()&&NODESTATE==ROUTER)
			{
		//		printf("\ndirectly refresh its registration with lbr");
				call NeighbrCache.getLBRAddress(&pkt.ip6_hdr.ip6_dst);
	
			}
			else
			{
		//		printf("\nRefreshing Registrations with router");
				call RouterList.getRouterIP(&pkt.ip6_hdr.ip6_dst);
			}				

		}
		if(NSSTATE==NUD)
		{
			memcpy(&pkt.ip6_hdr.ip6_dst,&ip,sizeof(struct in6_addr));
		}
		call NSTimer.startOneShot(RETRANS_TIMER);
		//printf("\n Sending the NS message to ");
		//printf_in6addr(&pkt.ip6_hdr.ip6_dst);
		numNSSent++;
		pkt.ip6_hdr.ip6_hops=0xff;	//according to rfc 4861
		
		call IP_NS.send(&pkt);
	}
  }

  void chooseInterval()
  {

	RSSENT=TRUE;
	RSInterval*=2;
	if(RSInterval>MAX_RTR_SOLICITATION_INTERVAL)
	{
		RSInterval=MAX_RTR_SOLICITATION_INTERVAL;

	}
	time=RSInterval;
	time/=2;
	time+=call Random.rand32()%time;
	sendMsg(ALL_RTR_MULTICAST_ADDR,RS);
  }


 void remainInterval()
 {
	RSSENT=FALSE;
	remain=RSInterval-time;
	call RSTimer.startOneShot(remain);
 }

 #ifndef NODE_HOST
 

   void fill6CO(context_opt *ctx_opt)
  {
	
	//fill in the option header
 	ctx_opt->option_header.type = CONTEXT_0PTION;

	//fill in the length
	ctx_opt->option_header.length = LENGTH_CONTEXT2;

	//fill in the header

	ctx_opt->c_bit = 1;

	ctx_opt->cid=1;

	ctx_opt->valid_lifetime = 30;

	ctx_opt->prefix.s6_addr[0] = 0x20;
	ctx_opt->prefix.s6_addr[1] = 0x00;
	ctx_opt->prefix.s6_addr[7] = 0x01;

  } 


  void sendRA(struct in6_addr address)
  {

	router_advt advt_msg;
	stlla_opt sao;
	abro_opt abr;
	prefix_opt pio;
	struct ip_iovec v[1];
	#ifdef NODE_ROUTER
		prefix_list *send_prefix;
	#endif
	uint8_t *buffer;
	uint8_t data[RA_MSG_SIZE];
	uint16_t length;	//it contains the length of the payload
	uint8_t prefix_count,i;
	if(!running)
		return;

	//printf("\n SendRA function");
	memset(&advt_msg,0,sizeof(router_advt));
	fillmsgicmp(&advt_msg.icmpv6,ICMP_TYPE_ROUTER_ADV);
	#ifdef NODE_LBR
		/*Filling the Router Advertisement structure */

		prefix_count=1;	
		advt_msg.cur_hop_limit=RTR_HOP_LIMIT;
		advt_msg.router_lifetime=RTR_LIFE_TIME;	//section 5.4(RFC 6775) Maximum value of the RA router Lifetime	may be 								upto 0xffff
		advt_msg.reachable_time=RTR_REACHABLE_TIME;//3 min it will be reachable after confirmation(should not be > 1 hour)
		advt_msg.retrans_timer=RETRANS_TIMER;		//30 sec between NS message
	#else
		//filling the  sllao option
		advt_msg.cur_hop_limit=HOP_LIMIT;
		advt_msg.router_lifetime=RTR_LIFE_TIME;	//section 5.4(RFC 6775) Maximum value of the RA router Lifetime	may be 								upto 0xffff
		advt_msg.reachable_time=RTR_REACHABLE_TIME;//3 min it will be reachable after confirmation(should not be > 1 hour)
		advt_msg.retrans_timer=RETRANS_TIMER;		//30 sec between NS message
		prefix_count=call NeighbrCache.prefixes_count();
	#endif
	fillSAO(&sao);
	//filling the Prefix Information Option and ABRO
	for(i=0;i<prefix_count;i++)
	{
		#ifdef NODE_ROUTER
			send_prefix=call NeighbrCache.getPrefixIndex(i);
			if(send_prefix)
			{
				pio.option_header.type=PREFIX_INFORMATION;
				pio.option_header.length=LENGTH_PREFIX;	
				memcpy(&pio.prefix_information,send_prefix,sizeof(prefix_info));
				abr.option_header.type=ABRO;
				abr.option_header.length=LENGTH_ABRO;
				memcpy(&abr.abro_information,&send_prefix->abro_information,sizeof(abro_info));
			}
		#endif
		#ifdef NODE_LBR		
			fillPIOABRO(&pio,&abr);
			fill6CO(&context_option);
		#endif
		//adding both the payload and the options
        	buffer = (uint8_t *)&data;
		ADD_BUFFER(&advt_msg,sizeof(router_advt));
		ADD_BUFFER(&sao,sizeof(stlla_opt));
		ADD_BUFFER(&pio,sizeof(prefix_opt));
		ADD_BUFFER(&context_option,sizeof(context_opt));
		ADD_BUFFER(&abr,sizeof(abro_opt));		
		length=sizeof(router_advt)+sizeof(stlla_opt)+sizeof(abro_opt)+sizeof(prefix_opt)+sizeof(context_opt);
		v[0].iov_base=(uint8_t *)data;
		v[0].iov_len=length;
		v[0].iov_next=NULL;
		fillPacket(length,&pkt,&v[0]);
		memcpy(&pkt.ip6_hdr.ip6_dst,&address,16);
		#ifdef NODE_LBR
		memcpy(&pkt.ip6_hdr.ip6_src,call RPLRoute.getDodagId(),sizeof(struct in6_addr));	
		#else	
		memcpy(&pkt.ip6_hdr.ip6_src,&LLAddress,sizeof(struct in6_addr));
		#endif
		call IP_RA.send(&pkt);	
	}
  }
  #endif
 
  /* If Status==3 it means responding to an NS message for NUD */
  void sendNA(uint8_t status,ieee_eui64_t eui, uint16_t reg_lifetime)
  {
	neighbr_advt na;
	struct ip_iovec v[1];
	aro_opt addr_opt;
	stlla_opt sao;	
	uint8_t *buffer;
	uint8_t data[NA_MSG_SIZE];
	
	uint16_t length;	//it contains the length of the payload
	if(!running)
		return;

	////printf("\n In SendNA function");

	
	fillmsgicmp(&na.icmpv6,ICMP_TYPE_NEIGHBOR_ADV);
	if(call Node.getRouterState()||call Node.getLBRState())
		na.r_bit=1;		
	if(call Node.getHostState())
		na.r_bit=0;
	na.s_bit=0;
	na.reserved=15;
	na.reserved1=0;
	na.reserved2=0;
	memcpy(&na.target,&target,sizeof(struct in6_addr));	//TODO:Dont use global variables
	//printf("\n SendNA:status is %d",status);
	//filling the aro structure
	if(status!=3)
	{
		addr_opt.option_header.type=ARO;
		addr_opt.option_header.length=LENGTH_ARO;	
		addr_opt.status=status;
		addr_opt.reserved1=0;
		addr_opt.reserved2=0;
		addr_opt.reg_lifetime=reg_lifetime;
		memcpy(&addr_opt.eui64,&eui,sizeof(ieee_eui64_t));			
	}
	fillTAO(&sao);
	buffer=(uint8_t *)&data;
	ADD_BUFFER(&na,sizeof(neighbr_advt));
	ADD_BUFFER(&sao,sizeof(stlla_opt));
	length=sizeof(neighbr_advt)+sizeof(stlla_opt);
	if(status!=3)
	{
		ADD_BUFFER(&addr_opt,sizeof(aro_opt));
		length=length+sizeof(aro_opt);
	}
	
	v[0].iov_base=(uint8_t *)data;
	v[0].iov_len=length;
	v[0].iov_next=NULL;
	fillPacket(length,&pkt,&v[0]);
	memcpy(&pkt.ip6_hdr.ip6_dst,&NA_DEST,sizeof(struct in6_addr));
	#ifdef NODE_LBR
	memcpy(&pkt.ip6_hdr.ip6_src,call RPLRoute.getDodagId(),sizeof(struct in6_addr));	
	#else
	if(NA_SRC.s6_addr16[0]==htons(0xff02))	//if multicasts a NS we will copy target as multicasts only happens during address resolution not during address registration
		memcpy(&pkt.ip6_hdr.ip6_src,&target,sizeof(struct in6_addr));
	else
		memcpy(&pkt.ip6_hdr.ip6_src,&NA_SRC,sizeof(struct in6_addr));	//this is because neighbor cache of the NS sender does not have cache entry 
	#endif
	//printf("\nNA solicited flag:%d",na.s_bit);
	//printf_in6addr(&pkt.ip6_hdr.ip6_dst);
	pkt.ip6_hdr.ip6_hops=0xff;
	call IP_NA.send(&pkt);
   }

 #ifdef NODE_ROUTER
  void sendDAR(uint16_t reg_lifetime,ieee_eui64_t eui64,struct in6_addr ip)	/*Section 8.2.3 */
  {
		darc request;
		struct ip_iovec v[1];
		uint8_t *buffer;
		uint8_t data[DAR_MSG_SIZE];
		uint16_t length;	//it contains the length of the payload
	//	printf("\n Send DAR function");
		//filling the Duplicate Address Request Structure
		fillmsgicmp(&request.icmpv6,ICMP_TYPE_DUPLICATE_REQ);
		request.status=0;
		request.reserved=0;
		request.reg_lifetime=reg_lifetime;

		memcpy(&request.eui64,&eui64,sizeof(ieee_eui64_t));
		memcpy(&request.reg_addr,&ip,sizeof(struct in6_addr));
	
		//filling the IP Packet
		buffer=(uint8_t *)&data;
		ADD_BUFFER(&request,sizeof(darc));
	        length=sizeof(darc);
	
		v[0].iov_base=(uint8_t *)data;
		v[0].iov_len=length;
		v[0].iov_next=NULL;	
		fillPacket(length,&pkt,&v[0]);
		memcpy(&pkt.ip6_hdr.ip6_src,&global,sizeof(struct in6_addr));
		call NeighbrCache.getLBRAddress(&pkt.ip6_hdr.ip6_dst);
		call IP_DAR.send(&pkt);
  }

 #endif
  #ifdef NODE_LBR
   void sendDAC(uint8_t status,struct ip6_hdr *hdr,void *packet)
   {

	darc reply;
	struct ip_iovec v[1];
	uint8_t *buffer;
	uint8_t data[DAC_MSG_SIZE];
	uint16_t length;	//it contains the length of the payload
	darc *request;
	request=(darc *)packet;
	//printf("\n Send DAC function");

	
	//filling the DAC structure

	fillmsgicmp(&reply.icmpv6,ICMP_TYPE_DUPLICATE_CONFIRM);
	reply.status=status;
	reply.reserved=0;
	reply.reg_lifetime=request->reg_lifetime;
	memcpy(&reply.eui64,&request->eui64,sizeof(ieee_eui64_t));
	memcpy(&reply.reg_addr,&request->reg_addr,sizeof(struct in6_addr));
	
	buffer=(uint8_t *)&data;
	ADD_BUFFER(&reply,sizeof(darc));
        length=sizeof(darc);

	v[0].iov_base=(uint8_t *)data;
	v[0].iov_len=length;
	v[0].iov_next=NULL;
	fillPacket(length,&pkt,&v[0]);


	memcpy(&pkt.ip6_hdr.ip6_src,call RPLRoute.getDodagId(),sizeof(struct in6_addr));
	memcpy(&pkt.ip6_hdr.ip6_dst,&hdr->ip6_src,sizeof(struct in6_addr));
	
	
	call IP_DAC.send(&pkt);
    }
   #endif
  /*******************************************COMMANDS*************************************************************************/
  command error_t SplitControl.start()
  {
	
	running=TRUE;
	init();		
	call RadioControl.start();		//starting the radio
 	call NeighbrCache.init();
	#if! defined NODE_LBR && !defined NODE_HOST && !defined NODE_ROUTER
		/*this is to make sure that user has selected one type of role of the node*/
		//call Node.setHost();
	        signal SplitControl.startDone(FAIL);	
		SplitControlSTATE=SENT;
		call Leds.led1Toggle();
		#warning "*** NO Neighbor role set ***"
		return FAIL;		
	#endif
	#ifdef NODE_LBR
		NODESTATE=LBR;
		call Node.setLBR();
		//call RootControl.setRoot();
		//printf("\n Iam a LBR so Iam the Root of this network");
		call NeighbrCache.startNUD();
		signal SplitControl.startDone(SUCCESS);
		SplitControlSTATE=SENT;

	#endif
	#ifdef NODE_ROUTER	
		call Node.setRouter();		//again setting to host for autoconfiguration
		call Node.setHost();
		NODESTATE=HOST;	
		RSSTATE=MULTICAST;
		sendMsg(ALL_RTR_MULTICAST_ADDR,RS);
	#endif
	#ifdef NODE_HOST	
		call Node.setHost();
		NODESTATE=HOST;
		RSSTATE=MULTICAST;
		sendMsg(ALL_RTR_MULTICAST_ADDR,RS);

	#endif
	//more than one role has been specified
	if((call Node.getHostState()&&(call Node.getRouterState()&&NODESTATE!=HOST))||(call Node.getRouterState()&&call Node.getLBRState())||(call Node.getLBRState()&&call Node.getHostState()))
	{
		call Leds.led0On();
		signal SplitControl.startDone(FAIL);
		SplitControlSTATE=SENT;
		return FAIL;
	}
//	call RoutingControl.start();			//starting the rpl        
	return SUCCESS;

  }


 command error_t SplitControl.stop()
 {
 	running= FALSE;
	call RadioControl.stop();
	//call RoutingControl.stop();
	return SUCCESS;
	
 }

/*******************************************EVENTS*************************************************************************/


   event void RSTimer.fired()
   {


	if(call Node.getRouterState()&&NODESTATE==ROUTER){
	//this is required when suppose prefix lifetime expires and has	to send RS unicastly if no response then they will go for MULTICAST
		NODESTATE=HOST;
		call Node.setHost();
	}
	//NO RA received transmit RS again;
  	if(numRSSent<MAX_RTR_SOLICITATIONS){
		//printf("RSTimer fired as no of RS messages sent is not equals to MAXRTR sending with same interval");
		sendMsg(ALL_RTR_MULTICAST_ADDR,RS);
	}
	else{		/* (RFC 6775 Section 5.3)After the initial retransmissions,the host should do truncated binary exponential backoff of the retransmission timer for each subsequent retransmissions,truncating the increase of the retransmission timer at 60 seconds(MAX_RTR_SOLICITATION_INTERVAL) */
		//printf("\n Performing Exponential BackOff ");
		if(RSSENT)
		{
			remainInterval();
		}
		else
		{
			chooseInterval();
		}
		
	    }
		////printfflush();
   }

   event void NSTimer.fired()
   {
	if(numNSSent<MAX_UNICAST_SOLICIT)
	{
		 //printf("\n NSTimer fired with count:%d",numNSSent);
		 sendMsg(NS_DEST,NS);
	}
	else
	{
		//printf("\n Sent More than MAX_UNICAST_SOLICIT times");
		call NSTimer.stop();
		numNSSent=0;
		//delete the router entry
		if(NSSTATE==ARO)
		{
			if(call RouterList.getRouterIP(&NS_DEST)==SUCCESS)
			{
				if(call RouterList.remove(NS_DEST)==SUCCESS)
				{
					if(call RouterList.getRouterIP(&NS_DEST)==SUCCESS)//check any other router is available 												or not
						sendMsg(NS_DEST,NS);
					else
						call RSTimer.startOneShot(RSInterval);	//No Routers available go for 												Multicasting RS
				}
			}
			else
				call RSTimer.startOneShot(RSInterval);	//No Routers available go for 												Multicasting RS
		}
	}
   }

   event void AROTimer.fired()
   {
		//printf("\n In AROTimer Fired");
		//if(call Node.getHostState())
		NSSTATE=ARO;	
		if(call RouterList.getRouterIP(&NS_DEST)==SUCCESS)		
			sendMsg(NS_DEST,NS);
		else
			call RSTimer.startOneShot(RSInterval);
		//if(call Node.getRouterState() && NODESTATE==ROUTER)
		//{
		//	sendDAR(registration_lifetime,extended_addr,global);
		//}		

    }

   /* Router Solicitation Received */
   event void IP_RS.recv(struct ip6_hdr *hdr, void *packet, 
                  size_t len, struct ip6_metadata *meta){

	/*A host must silently discard any received Router Solicitation messages*/
	#ifndef NODE_HOST
		neighbr_info info;
		router_solicit *solicit;
		stlla_opt *option;  
		solicit=(router_solicit *)packet;
	//	call Leds.led1Toggle();
	
		/* Validation of RS Message (Section 6.1.1 of RFC 4861) */	
		/* ICMP Code is 0 */	
		/*ICMP Length(Derived from the IP length) is 8 or more octets*/
	
		if((solicit->icmpv6.code!=0)||(len<8))	
			return;


		option=(stlla_opt *)call Option.findoption(packet,LENGTH_RS,SLLAO);
		/* If there is no Source Link Layer Option Available */
		if(option==0)
			return;
		//printf("\n RS Message Received");
		////printf_buf(option->ll_addr.data,8);	
		if((call Node.getRouterState()&&NODESTATE==ROUTER)||NODESTATE==LBR)
		{
			info.isRouter=0;
			info.next_ndtime=RETRANS_TIMER;
			info.type=TENTATIVE;
			info.timer=TENTATIVE_NCE_LIFETIME;
			info.state=STALE;
			//adding an entry in his neighbor cache	
			if(call NeighbrCache.addentry(hdr->ip6_src,option->ll_addr,info)==SUCCESS)
			{
	//			printf("\n RS message Receivd added entry in the Neighbor Cache:");
	//			printf_in6addr(&hdr->ip6_src);
			}
			sendRA(hdr->ip6_src);			
		}
	#endif	
    }

   /* Router Advertisement Received */
   event void IP_RA.recv(struct ip6_hdr *hdr, void *packet, 
                  size_t len, struct ip6_metadata *meta){
	
	neighbr_cache *cache;
	router_advt *adv;
	stlla_opt *opt;
	prefix_opt * prefix_option;	
	neighbr_info info;
	abro_opt *abro;
	context_opt *ctx;

	prefix_option=(prefix_opt *)call Option.findoption(packet,LENGTH_RA,PREFIX_INFORMATION);
	abro=(abro_opt *)call Option.findoption(packet,LENGTH_RA,ABRO);
	opt=(stlla_opt *)call Option.findoption(packet,LENGTH_RA,SLLAO);
	ctx=(context_opt *)call Option.findoption(packet,LENGTH_RA,CONTEXT_0PTION);
	adv=(router_advt *)packet;

	//printf("\n ABRO:version:%d",abro->abro_information.ver_low);
	
	//printf("\n RA receive function with address");
	/*if(prefix_option)
		printf("\n Prefix information option is present");
	else
		printf("\n NO Prefix information option present");

	if(opt)
		printf("\n SLLAO Option present");
	else
		printf("\n No SLLAO ");

	if(abro)
		printf("\n ABRO Present");
	else
		printf("\n ABRO Not Present");
	printfflush();
	printf_in6addr(&hdr->ip6_src);
        */
	/* Validation of RA message (Section 6.1.2 of RFC 4861) */
	/* If the IP Source Address should be a link-local address so that hosts can uniquely identify routers */
	/* ICMP Code is 0 */	
	/*ICMP Length(Derived from the IP length) is 16 or more octets*/	

	//this is to make sure that entries received from LBR should not be discarded
	if((!call IPAddress.isLLAddress(&hdr->ip6_src))||(adv->icmpv6.code!=0)||(len<16))
	{
		/*if(!(memcmp(&hdr->ip6_src,call RPLRoute.getDodagId(),sizeof(struct in6_addr))))
		{
			printf("\n Leaving just LBR entries");
		}		
		else
			return;
		*/
	}	
	if(opt==0)	//No SLLAO dont process(RFC  6775 Section 5.4)	
	{	
		//printf("\n no sllaoo dont process");
		//printfflush();
		return;
	}
	else
	{	
		RSInterval=RTR_SOLICITATION_INTERVAL;
		time=RSInterval;
		numRSSent=0;
		//stop the timer as RS message is received
		call RSTimer.stop();
		cache=call NeighbrCache.findEntry(hdr->ip6_src);//check whether the address is already present in the hosts default router 								list
		if(cache==0)	//if not present
		{
			if(adv->router_lifetime)//advertisement Router Lifetime is non-zero
			{//create a new entry and initialize its invalidaton timer value from the advertisements 							Router Lifetime field							
				info.isRouter=1;	//As the Router Advertisements are received only from 									Routers
				RETRANSMISSION_TIME=adv->retrans_timer;
	//			printf("retransmission time:%ld\n",RETRANSMISSION_TIME);
	//			printfflush();
				info.next_ndtime=adv->reachable_time;
				info.type=REGISTERED;
				info.timer=adv->router_lifetime;
				/*Section 6.3.4 of RFC4861 If a Neighbor Cache entry is created for the router,its reachability 				state should be set to STALE*/
				info.state=STALE;		
				if(call NeighbrCache.addentry(hdr->ip6_src,opt->ll_addr,info)==SUCCESS)
				{
					//printf("\n RA message received adding entry in the Neighbor Cache");
					//printf_in6addr(&hdr->ip6_src);
				}
				if(call RouterList.add(hdr->ip6_src)!=SUCCESS)	
				{
	//				printf("\n Router cannot be added due to some reasons");			
	//				printfflush();
				}
				else{
					call NeighbrCache.startNUD();
	//				printf("\nRouter Added");
				    }
			 }
			else	//discarding as the router has zero lifetime
			{
				return;
			}
		}
	//if address is present in the Default Router List,as a result of previously received advertisement,reset its 			invalidation timer to the Router Lifetime in the newly received advertisement
	/*If a cache entry already exists,the reachability state MUST also be set to STALE*/
		else
		{	
			////printf("\n Already IP address exists in the cache Update its cache timer %ld",cache->info.timer);
			cache->info.state=STALE;
			cache->info.timer=adv->router_lifetime;		
		}

	
		/* If the received Cur Hop Limit value is non-zero,the host should set its CurHopLimit Variable to the received 		value*/
		if(adv->cur_hop_limit!=0)
		{
			HOP_LIMIT=adv->cur_hop_limit;
		}
		/* After extracting information from the fixed part of Router Advertisement message,the advertisement is scanned 			for 			valid options*/
	
		if(abro!=0&&abro->option_header.type==ABRO)
		{	
		if(call NeighbrCache.checkPrefix(prefix_option->prefix_information.prefix,abro->abro_information.lbr_addr,
			abro->abro_information.ver_high,abro->abro_information.ver_low)==FAIL)
			{
				//As the information is already present discard the info
	//			printf("\n ABRO Information already exists discarding");
				return ;
			}

			if(adv->m_bit)	//if this bit is set then we have to go for DHCP
			{
				signal SplitControl.startDone(SUCCESS);	//has to use linklocal address because DHCP is to be done 										later
			}
			else
			{
				if(prefix_option!=0&&!prefix_option->prefix_information.l_bit)	//address autoconfiguration
				{
				//printf("\n received.prefix length:%d",prefix_option->prefix_information.prefix_length);
				//printf("\n received .valid_lifetime:%ld",prefix_option->prefix_information.valid_lifetime);
				//filling the prefix information
					call NeighbrCache.addPrefix(prefix_option->prefix_information,abro->abro_information);
	memcpy(&TENTATIVE_ADDRESS,&prefix_option->prefix_information.prefix,sizeof(struct in6_addr));
					TENTATIVE_ADDRESS.s6_addr16[7]=htons(call Ieee154Address.getShortAddr());
					memcpy(&global,&TENTATIVE_ADDRESS,sizeof(struct in6_addr));	
					call RouterList.getRouterIP(&NS_DEST);

				//store the 6CO Option if present

					if(ctx!=0)
					{

						//Section 5.4.2 of RFC 6775
						//store the cid,prefix and lifetime
		call NeighbrCache.storeCtx(ctx->prefix,ctx->cid,ctx->valid_lifetime);



					}
				

					//NSSTATE=NUD;
					NSSTATE=ARO;
	//				printf("\n sending ns");
					sendMsg(NS_DEST,NS);				
					//call NSTimer.startOneShot(RETRANS_TIMER);
				}else{
	//				printf("\n l bit not set");
				
				}
			}
		}
		else//Either No Prefix Information Option available or No ABRO available.Sending RS message again
		{
	//		printf("no ns");
			//call RSTimer.startOneShot(RSInterval);//for sending task
			if(SplitControlSTATE==NOTSENT)
			{
				SplitControlSTATE=SENT;
				call Leds.led2On();
				signal SplitControl.startDone(SUCCESS);	//if no prefix information is received node will use 					link-local address		
			}	
		}
	}
	//printfflush();
}

   /* Neighbor Advertisement Received */
   event void IP_NA.recv(struct ip6_hdr *hdr, void *packet, 
                  size_t len, struct ip6_metadata *meta)
   {
	aro_opt *reg;
	neighbr_advt *na;
	neighbr_cache *cache;
	stlla_opt *opt;
	struct in6_addr lbr_addr;
	na=(neighbr_advt *)packet;

	numNSSent=0;		//resetting the variable as we are receiving the NA message 


	/* Validation of NA Message According to RFC 4861 (Section 7.1.2) */
	/*ICMP Code is 0*/
	/*ICMP Length is 24 or more octets */
	/*Target Address is not a  Multicast Address*/
	if(na->icmpv6.code!=0 || len<24 ||na->target.s6_addr[0]==0xff)
		return;

	/* RFC 4861:7.2.5:When a valid Neighbor Advertisement is received,the Neighbr Cache is searched for the target's entry.If 			no entry exist,the advertisement should be silently discarded.There is no need to create an entry if none exists*/

	cache=call NeighbrCache.findEntry(hdr->ip6_src);
	if(cache==0){
		call NeighbrCache.getLBRAddress(&lbr_addr);
		if(!(memcmp(&hdr->ip6_src,&lbr_addr,sizeof(struct in6_addr))))
		{
	//		printf("\n Leaving just LBR entries");
			goto done;
		}		
		else{

	//		printf("\n Returning because no entry exist in the cache:");
	//		printf_in6addr(&hdr->ip6_src);
			return;
		}
	}

	//	printf("\n In NA Receive Function from");
	//	printf_in6addr(&hdr->ip6_src);
	/* If the override flag is set,or the supplied link-layer address is the same as that in the cache,or no Target Link-Layer address was supplied */

	if(na->o_bit||opt==0||call NeighbrCache.findIPEUI64(na->target,opt->ll_addr))
	{
		/*If the solicited flag is set,the state of the entry MUST be set to  REACHABLE*/
		if(na->s_bit)
		{
	//		printf("\n Setting the State to Reachable");
			cache->info.state=REACHABLE;
		}else{
	//		printf("\n not setting state");
		}	
	//	printfflush();
		//TODO:When the isRouter flag changes from TRUE to FALSE as a result of this update,the node must remve the
		//router from the default router list.
		if(cache->info.isRouter==TRUE&&cache->info.isRouter!=na->r_bit){

			call RouterList.remove(na->target);	
		}
		
		/*The ISRouter flag in the cache entry MUST be set based on the Router flag in the received advertisement*/
		cache->info.isRouter=na->r_bit;


	}
done:
	call NSTimer.stop();	
	reg=(aro_opt *)call Option.findoption(packet,LENGTH_NA,ARO);
	if(reg!=0)		//this may be reply of ARO registration
	{

		/*Section 5.5.2 of RFC6775  */
		/*If the length field is not two the option is silently ignored,If the EUI-64 field does not match the EUI-64 of 			the interface,the option is silently ignored*/
		if(reg->option_header.length!=2&&(memcmp(&reg->eui64,&extended_addr,sizeof(struct in6_addr))))
			return;

		if(reg->status==0)
		{	
			/*The host chooses a lifetime of the registration and repeats the ARO periodically(before the lifetime 				runs out) to maintain the registration */		
			//printf("\n the registration lifetime is %d",reg->reg_lifetime);	
			call AROTimer.startOneShot(reg->reg_lifetime-2);
			//printf("\n successfully registered with the router");
			call SetIPAddress.setAddress(&na->target);
			//printf("\n The Global IP Address is:");
			call IPAddress.getGlobalAddr(&global);
			//printf_in6addr(&global);

			#ifdef NODE_ROUTER
			if(call Node.getRouterState()&&NODESTATE==HOST)	//now change back to router		
			{
				call Node.unsetHost();
				NODESTATE=ROUTER;
				if(call RouterList.removeAll()==SUCCESS){}
					//printf("\n Removing all the routers from the router list");
			}
			#endif
			call NSTimer.stop();			//stop the timer as the NA is received with status=0
			if(SplitControlSTATE==NOTSENT)	//this is required so that Signal SplitControl is sent one time only
			{
								SplitControlSTATE=SENT;
			signal SplitControl.startDone(SUCCESS);	//if no prefix information is received node will use link-local address		
			}			
		}
		/*If status=1 then use EUI-64 to generate the IP and send a NS message with ARO to the router*/
		else if(reg->status==1)
		{		
			//printf("\nDuplicate Address");
			//printf_in6addr(&na->target);
			//printf("\n Using EUI-64 to generate the IP");
			memcpy(&TENTATIVE_ADDRESS.s6_addr16[4],&extended_addr,sizeof(ieee_eui64_t));
			////printf("\n The IP Address after using EUI-64 as interface identifier is:");
			////printf_in6addr(&TENTATIVE_ADDRESS);
			sendMsg(NS_DEST,NS);
			NSSTATE=ARO;
			//call NSTimer.stop();		//TODO:has to remove this thing
		}	

	}
   }
   /* Neighbor Solicitation Received */
   event void IP_NS.recv(struct ip6_hdr *hdr, void *packet, 
                  size_t len, struct ip6_metadata *meta)
   {

	aro_opt *add_opt;
	neighbr_solicit *ns;
	stlla_opt *option;
	#if defined NODE_ROUTER 
		neighbr_info info;
	#endif
	ns=(neighbr_solicit *)packet;
	/*A valid Neighbor Solicitation that does not meet any of the following requirements MUST be silently discarded*/
	/* The target address is a valid unicast or anycast address(RFC 4861 Section 7.2.3)*/


	if(ns->target.s6_addr[0]==0xff)
		return;	

	memcpy(&target,&ns->target,sizeof(struct in6_addr));
	memcpy(&NA_DEST,&hdr->ip6_src,sizeof(struct in6_addr));
	memcpy(&NA_SRC,&hdr->ip6_dst,sizeof(struct in6_addr));
	option=(stlla_opt *)call Option.findoption(packet,LENGTH_NS,SLLAO);
	add_opt=(aro_opt *)call Option.findoption(packet,LENGTH_NS,ARO);
	if(option==0)					//section 6.5 dont process ARO
		return;
	else
	{
		//call Leds.led0Toggle();
		//printf("\n In NS receive function");
		//checking for valid ARO If present
		if(add_opt!=0)
		{
			if(add_opt->option_header.length!=LENGTH_ARO||add_opt->status!=0)	//section 6.5
			{
				//printf("\n Discarding the Message as status is not zero");			
				return;
			}
		}	
		
			/*If no entry exist,the node will create an new one and set the ISRouter Flag to FALSE(RFC 4861 Section 			7.2.3) */
			if(call IPAddress.isLocalAddress(&ns->target))
			{
				//printf("\n i think this message is for NUD");
				sendNA(3,add_opt->eui64,add_opt->reg_lifetime);
				return;
			}else{
				//printf("Not Local:");
				//printf_in6addr(&ns->target);
			}
			#if defined NODE_ROUTER
		//	printf("\n NS Receive: target checking in the entry");
		//	printf_in6addr(&ns->target);
			memcpy(&NA_EUI,&add_opt->eui64,sizeof(ieee_eui64_t));
			if(!call NeighbrCache.findEntry(ns->target))
			{
				if(add_opt->reg_lifetime)
				{
					//it isn't a duplicate
					info.isRouter=0;
					info.next_ndtime=RETRANS_TIMER;
					info.type=TENTATIVE;
					info.timer=TENTATIVE_NCE_LIFETIME;
					if(call NeighbrCache.addentry(ns->target,add_opt->eui64,info)==SUCCESS)
					{
		//				printf("\n Adding entry in the Neighbr Cache NS message received:");
		//				printf_in6addr(&ns->target);
					}
					if(*(uint8_t *)add_opt!=0)	//if ARO is present then only send the DAR
					{	
						sendDAR(add_opt->reg_lifetime,add_opt->eui64,ns->target);
						return;
					}		
				}
				else{	//if the registration lifetime is zero dont add the entry and send it to LBR
						
						sendDAR(add_opt->reg_lifetime,add_opt->eui64,ns->target);
					}
			
			}
			else if(call NeighbrCache.findIPEUI64(ns->target,add_opt->eui64))
			{
				if(*(uint8_t *)add_opt!=0)	//if ARO is present then only send the DAR
				{
					if(add_opt->reg_lifetime)
					{
						sendDAR(add_opt->reg_lifetime,add_opt->eui64,ns->target);
						return;
					}
					else //if registration lifetime is zero delete the entry and send it to the LBR
					{						
						call NeighbrCache.removeentry(ns->target);
						sendDAR(add_opt->reg_lifetime,add_opt->eui64,ns->target);
					}
				}					
			}	
			else{//it is a duplicate
				if(*(uint8_t *)add_opt!=0)	//Only when the ARO is present
				{
					sendNA(1,add_opt->eui64,add_opt->reg_lifetime);
				}	
			}		
		#endif

		#ifdef NODE_LBR	/* This is required because initially there may be router and 6lbr then no need
							of DAR,DAC*/
			
		//	printf("NS Recv:IP Address receive for checking");
		//	printf_in6addr(&ns->target);
			//If the IPAddress is not found,it returns a NA with status set to zero and updates the lifetime
			if(!call NeighbrCache.DADfindEntry(ns->target))
			{				
				if(add_opt->reg_lifetime)
				{
					call NeighbrCache.DADaddEntry(ns->target,add_opt->eui64,add_opt->reg_lifetime);
					sendNA(0,add_opt->eui64,add_opt->reg_lifetime);
				}
				else		//Delete the entry
				{
					sendNA(0,add_opt->eui64,add_opt->reg_lifetime);
				}
				
			}
			else		
			{
				int i;
				i=call NeighbrCache.DADfindIPEUI64(ns->target,add_opt->eui64);
				//printf("NS:value of i is %d",i);
				if(i!=-1)
				{
					dad_cache *cache;
					cache=call NeighbrCache.getDADEntry(i);
					if(!add_opt->reg_lifetime)	//if registration lifetime is zero delete the entry
					{
						call NeighbrCache.DADremoveEntry(ns->target);
					}
					else
					{
						if(cache->reg_lifetime==0)
						{
							call NeighbrCache.DADremoveEntry(ns->target);
						call NeighbrCache.DADaddEntry(ns->target,add_opt->eui64,add_opt->reg_lifetime);
						}
						else
						{
							cache->reg_lifetime=add_opt->reg_lifetime;
						}
					}
					sendNA(0,add_opt->eui64,add_opt->reg_lifetime);					
				}
				else
				{
					sendNA(1,add_opt->eui64,add_opt->reg_lifetime);
				}				
			}			
		#endif		
	}
   }

   event void IP_DAR.recv(struct ip6_hdr *hdr, void *packet, 
                  size_t len, struct ip6_metadata *meta){/* Section 8.2.4 */	
	#ifdef NODE_LBR			//As the DAR are processed only by the 6LBR
		darc *request;
		request=(darc *)packet; 

		/* Check Whether the DAR is Valid*/
	
		/* If the ICMP length is 32 or more bytes,ICMP code is 0 */
		if(len<sizeof(darc)||request->icmpv6.code!=0)
			return;
		/* If the registered address is a multicast address*/
		if(request->reg_addr.s6_addr[0]==0xff)
			return;
	
	//	printf("\n In SendDAR receive");
	
		/* If no entry is found in the DAD Table and the Reg Lifetime is Non-zero,then an entry is created and the EUI-64
		and Registered Address from the DAR are stored in that entry*/ 
		if(!call NeighbrCache.DADfindEntry(request->reg_addr))
		{
			if(request->reg_lifetime!=0)
			{
				call NeighbrCache.DADaddEntry(request->reg_addr,request->eui64,request->reg_lifetime);
				
			}
			sendDAC(0,hdr,packet);

		}
		else/* If the IPAddress is found and EUI-64 in the table is different from the EUI-64 from the DAC message then 			it is 			Duplicate and DAC is sent with status set to 1*/
		{
		
			int i;
			i=call NeighbrCache.DADfindIPEUI64(request->reg_addr,request->eui64);
			if(i==-1)
			{
				sendDAC(1,hdr,packet);
			}
			/*If an entry is found in the DAD Table,the EUI-64 matches,and the Reg Lifetime is zero then the 					  entry is deleted from the table*/
			else
			{
				dad_cache *cache;
				cache=call NeighbrCache.getDADEntry(i);
				if(cache->reg_lifetime==0&&request->reg_lifetime)
				{
					call NeighbrCache.DADremoveEntry(request->reg_addr);
					call NeighbrCache.DADaddEntry(request->reg_addr,request->eui64,request->reg_lifetime);
					sendDAC(0,hdr,packet);
				}
				else
				{
					cache->reg_lifetime=request->reg_lifetime;
					sendDAC(0,hdr,packet);
				}
			}
		}
	#endif
	//call Leds.led2Toggle();
 }

  event void IP_DAC.recv(struct ip6_hdr *hdr, void *packet, 
                  size_t len, struct ip6_metadata *meta){
	#if defined NODE_ROUTER
	 	darc *reply;
		uint8_t i;
		neighbr_cache *neighbr;
		reply=(darc *)packet; 	

		/* Validation of the DAC message */
		/* If the ICMP length is 32 or more bytes,ICMP code is 0 */
		if(len<sizeof(darc)||reply->icmpv6.code!=0)
			return;
		/* If the registered address is a multicast address*/
		if(reply->reg_addr.s6_addr[0]==0xff)
			return;
		
		//printf("\n In DAC Receive Event");
		
		/* For a valid DAC,if there is no Tentative NCE matching the Registered Address and EUI-64,then the DAC is 			silently   ignored */
	//	printf("\n DAC checking Neighbor Exists or not");
	//	printf_in6addr(&reply->reg_addr);
		neighbr=call NeighbrCache.findEntry(reply->reg_addr);
		if(neighbr==0){
	//		printf("DAC:Neighbor Not FOund");
			return;
		}
		/*In the case where the DAC indicates an error(the status in non-zero),the NA is returned to the host and the 			TENTATIVE NCE for the registered Address is Removed. Otherwise ,it is made into a Registered NCE*/
		if(reply->status!=0)
		{
			//Generating link local address with EUI-64 to send the NA
			NA_DEST.s6_addr16[0] = htons(0xfe80);
			for (i=0;i<8;i++)
        			NA_DEST.s6_addr[8+i] = NA_EUI.data[7-i];	
			 NA_DEST.s6_addr[8] ^= 0x2; 
	//		printf("\n As it is duplicate we are removing the entry");
			call NeighbrCache.removeentry(neighbr->ip_address);			
		}
		else
		{
			/* A router must not modify the Neighbor Cache as a result of receiving a DAC,unless there is a Tentative 				NCE matching the IPv6 address and EUI-64*/
			if(neighbr->info.type==TENTATIVE)
			{		
				neighbr->info.timer=reply->reg_lifetime;
	//			printf("\n timer after changing state is %ld",neighbr->info.timer);
				printf_buf(reply->eui64.data,8);
				neighbr->info.type=REGISTERED;
				neighbr->info.state=STALE;
			}
			/* This may be refreshing his entry with the router*/
			if(neighbr->info.type==REGISTERED)
			{
				neighbr->info.timer=reply->reg_lifetime;
				neighbr->info.state=STALE;
			}
		}	
		sendNA(reply->status,NA_EUI,reply->reg_lifetime);
	#endif
  }

  event void NeighbrCache.prefixReg()
  {
	struct in6_addr def_rtr;
	//printf("\n Prefix Registration is going to complete");
	#ifdef NODE_HOST
		call RouterList.getRouterIP(&def_rtr);
	#endif
	#ifdef NODE_ROUTER
		call NeighbrCache.getLBRAddress(&def_rtr);
	#endif
	RSSTATE=UNICAST;
	sendMsg(def_rtr,RS);
	call RSTimer.startOneShot(RSInterval);
	//TODO: Get the Default Router and send a RS message to Him
	
  }

  event void NeighbrCache.NUD_reminder(struct in6_addr ip_address)
  {
		neighbr_cache *cache;
		
		//if(call Node.getHostState())
		//{
			NSSTATE=NUD;
			//NODESTATE=HOST;		//this is required because NS message will otherwise send the message to 6LBR.Has 							to chnge	
		//	printf("\n The IP address for which reachability is checked:");
			cache=call NeighbrCache.findEntry(ip_address);
			if(cache!=0)
			{
				cache->info.next_ndtime=RETRANSMISSION_TIME;	//TODO:Change this	
				memcpy(&NS_DEST,&ip_address,sizeof(struct in6_addr));
				//printf_in6addr(&NS_DEST);
				sendMsg(NS_DEST,NS);
			}
		
		//}
  }


  default event void SplitControl.startDone(error_t error)
  {

  }

  event void RadioControl.startDone(error_t error)
  {


  }

  default  event void SplitControl.stopDone(error_t error)
  { 
  }
  
  event void RadioControl.stopDone(error_t error)
  {
	signal SplitControl.stopDone(error);
  }


  event void IPAddress.changed(bool valid)
  {
  }

/* This event will be signalled whenver the default rtr list is empty*/
  event void NeighbrCache.default_rtrlistempty()
  {
	#ifdef NODE_HOST
		//printf("\nIn default rtr list event");
		RSSTATE=MULTICAST;
		sendMsg(ALL_RTR_MULTICAST_ADDR,RS);
	#endif
  }
  event void Ieee154Address.changed()	{	}
}

