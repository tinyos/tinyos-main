/*Header file for Neighbour Discovery

@author Md.Jamal <mjmohiuddin@cdac.in>
@version $Revision: 1.0

*/
#ifndef ND_H
#define ND_H

#include <lib6lowpan/ip.h>



#define ICMPV6_ND_CODE 0
#define LOWPAN_CONTEXT_MAX	16

/* ICMP types of these messages are present in ip.h */

/* ICMPv6 Header */

struct icmpv6_header {
  uint8_t	type;			//type field indicates the type of the message
  uint8_t	code;			//code field depends on the message type to create additional level of granularity
  nx_uint16_t	checksum;		//used to detect data corruption in the ICMPv6 message
}__attribute__((packed));


/*  Neighbour Discovery Messages */


/* Neighbour Solicitation Message Format 
    A node send Neighbour Solicitation to request the link-layer address of a target node while also providing their own link-layer address to the target
   Possible Options:SLLA(Source Link Layer Address) which contains the link-layer address for the sender
*/
typedef struct {
  struct icmpv6_header icmpv6;
  uint32_t reserved;			//field unused and must be initialized to zero by the sender
  struct in6_addr target;		//IP address of the target of the solicitation
}__attribute__((packed)) neighbr_solicit;



/* Neighbour Advertisement Message Format    
   A node sends Neighbour Advertisement in response to Neighbour Solicitation in order to propogate new information quickly
Possible Options:TLLA(Target Link Layer Address) which contains the link layer address of sender of advt 
*/

typedef struct  {
  struct icmpv6_header icmpv6;
  uint8_t r_bit:1;		//if set indicates that the sender is a router
  uint8_t s_bit:1;		//if set indicates that the advt was sent in response to a solicitation
  uint8_t o_bit:1;		//if set advt should override an existing cache entry and update it
  uint8_t reserved:5;		//field unused and should be set to zero by sender
  uint8_t reserved1;
  uint16_t reserved2;
  struct in6_addr target;	//IPv6 address of the node that prompted this advt
}__attribute__((packed)) neighbr_advt;


/* Router Solicitation Message Format
   Hosts send Router solicitations in order to prompt routers to generate Router Advertisements quickly
  Possible Options: SLLA(Source Link Layer Address) which contains the link layer address of the sender
*/


typedef struct  {
  struct icmpv6_header icmpv6;
  uint32_t 	reserved;		//field unused and should be set to zero by sender
}__attribute__((packed)) router_solicit;


/* Router Advertisement Message Format
    	Routers send out Router Advertisement messages periodically or in response of an Router solicit 
   Possible Options: SLLA,MTU,Prefix Information
*/

typedef struct {
  struct icmpv6_header icmpv6;
  uint8_t cur_hop_limit;	//default value that should be placed in the Hop Count field of IP header
  uint8_t m_bit:1;		//if set indicates that the address are available via DHCPv6 and o flag is redundant
  uint8_t o_bit:1;		//if set indicates that other config info such as DNS info is available via DHCPv6
  uint8_t reserved:6;		//must be initialized to zero by sender
  uint16_t router_lifetime;    //lifetime associated with the default router 
  uint32_t reachable_time;	//time in sec a node will assume that node is reachable after reachable confirmation
  uint32_t retrans_timer;	//time in ms b/w retransmitted neighbour solicitation message
}__attribute__((packed)) router_advt;



/* Duplicate Address Request and Duplicate Address Confirmation Message Format

	These are used for multihop DAD exchanges between a 6LR and 6LBR
*/

typedef struct  {
  struct icmpv6_header icmpv6;
  uint8_t status;		//indicates the status of a registration in the DAC
  uint8_t reserved;		//set to zero by sender
  uint16_t reg_lifetime;	//amount of time in units of 60 seconds that the 6LBR should keep the DAD table entry
  ieee_eui64_t eui64;		//Used to uniquely identify the interface of the Registered Address
  struct in6_addr reg_addr;	//carries the host address that was contained in the IPv6 Source field in the NS that contained 				the ARO sent by the host
} __attribute__((packed)) darc;


/* Neighbour Discovery options */

/* Source Target Link layer address option format
Description: SLLAO contains the link-layer address of the sender

 */

typedef struct {
  uint8_t  type;		
  uint8_t length;
}__attribute__((packed)) opt_hdr;

typedef struct  {
  opt_hdr option_header;		
  ieee_eui64_t ll_addr;		//link-layer address of the sender
  uint8_t reserved[6];		//for padding(RFC 4944)
 }  __attribute__((packed)) stlla_opt;


/* Prefix Information Option
Description:Appears only in Router Advertisements.This option provides the on-link prefixes and prefixes for Address Autoconfiguration

*/

typedef struct {
 uint8_t prefix_length;	//number of leading bits in the prefix that are valid.value ranges from 0 to   128	
  uint8_t l_bit:1;		//on-link flag when set indicates that this prefix can be used for on-link determination
  uint8_t a_bit:1;		//Autonomous Address Configuration Flag.When set indicates that prefix can be used for stateless 					address configuration
  uint8_t reserved1:6;		//set to zero by the sender
  uint32_t valid_lifetime;	//length of the time in seconds the prefix is valid for on-link prefix determination
  uint32_t preferrd_lifetime;	//length of the time in seconds that addresses generated from the prefix via stateless address 					autoconfiguration remain valid
  uint32_t reserved2;		//must be set to zero by the sender
  struct in6_addr prefix;	//An IP Address or a prefix of an IP Address.A router should not send a prefix option for 					link-local prefix and host should ignore such a prefix

}__attribute__((packed)) prefix_info;

typedef struct   {
  opt_hdr option_header; 
  prefix_info prefix_information;
}__attribute__((packed)) prefix_opt;


/* Address Registration Option  Format
Description:ARO is used for registration of IP Address along with its link layer address at the router

*/

typedef struct   {
  opt_hdr option_header;		
  uint8_t status;		//Indicates the status of the registration in the NA response.Must be set to 0 in NS messages
  uint8_t reserved1;
  uint16_t reserved2;		//should be set to zero by the sender
  uint16_t reg_lifetime;	//Amount of time in units of 60 seconds that the router should keep the NCE for sender of NS
  ieee_eui64_t eui64;		//Used to uniquely identify the interface of the Registered Address
}__attribute__((packed)) aro_opt;

/* 6LoWPAN Context Option Format
Description:Carries Prefix Information for LOWPAN header compression and is similar to PIO
*/	

typedef struct {
  opt_hdr option_header;		
  uint8_t context_length;	//no. of leading bits in the context prefix field that are valid.value ranges from 0 to 128
  uint8_t c_bit:1;		//one-bit context compression which indicates whether the context is valid for compression
  uint8_t cid:4;		//used for context based header compression
  uint8_t res:3;		//set to zero by the sender
  uint16_t reserved;		//set to zero by the sender
  uint16_t valid_lifetime;	//length of time in units of 60 seconds that the context is valid for
  struct in6_addr prefix;	//IPv6 prefix or address corresponding to the CID field
}__attribute__((packed)) context_opt;



/* Authoritative Border Routr Option Format
Description:Needed when RA messages are used to disseminate prefixes and context information across a route-over topology
*/

typedef struct {
  uint16_t ver_low;
  uint16_t ver_high;		//ver_low and ver_high together constitute the version number field
  uint16_t valid_lifetime;	//length of time in units of 60 sec that the border router information is valid for
  struct in6_addr lbr_addr;	//IPv6 address of the 6LBR
}__attribute__((packed))abro_info;

typedef struct {
  opt_hdr option_header;		
  abro_info abro_information;
}__attribute__((packed)) abro_opt;


/* Type defined by IANA for the various options */
enum option_types {
  SLLAO=1,
  TLLAO=2,
  PREFIX_INFORMATION=3,
  ARO=33,
  CONTEXT_0PTION=34,
  ABRO=35,
};


/* Length of the Options Predefined */	
enum option_length {
  LENGTH_ICMPHEADER=4,
  LENGTH_RS=4,			//Excluding ICMP header and options
  LENGTH_RA=12,
  LENGTH_NS=20,
  LENGTH_NA=20,
  LENGTH_SLLAO=2,		//Including Options Header
  LENGTH_TLLAO=2,
  LENGTH_PREFIX=4,
  LENGTH_ARO=2,
  LENGTH_ABRO=3,
  LENGTH_CONTEXT1=2,
  LENGTH_CONTEXT2=3,

};   


/*Reachability States*/
/* The receipt of a solicited Neighbor Advertisement serves as reachability confirmation,since the advertisements with the solicited flag set to one are sent only in response to a Neighbor Solicitation */
enum {
/* Section 5.5.3 of RFC 6775 says that the procedure for maintaining reachability information about a neighbor is same as in RFC 4861 Section 7.3,with the exception that  the address resolution is not performed So there is no INCOMPLETE state*/

  REACHABLE=2,		//Confirmation is received within ReachableTime milliseconds
  STALE=3,		//More than Reachable Time milliseconds has been elapsed since the confirmation was received
  DELAY=4,		//When the packet is going to be sent it enters DELAY state and wait for DELAY_FIRST_PROBE_TIME seconds 
  PROBE=5,		//after the timer expires it enters into PROBE state and retransmitting NS every RetransTimer ms until a 				reachability confirmation is received
};


/* Different States for Sending Messages*/

enum {

  UNDEFINED=0,
  HOST=1,
  ROUTER=2,
  MULTICAST=3,
  UNICAST=4,
  ROUTER_RESPONSE=5,
  LBR_RESPONSE=6,
  SEND_ARO=7,
  NUD=8,
  LBR=9,
  NOTSENT=10,
  SENT=11,
};


/*Message Types*/

enum {

	RS=1,
	RA=2,
	NS=3,
	NA=4,


};



/* Context Table (RFC 6775 Section 5.4.2) 
Description: 	The host maintains a data structure called Context table to store the context information it receives  from the routers
*/

typedef struct  context_table_t {
  uint8_t cid:4;			//used for context based header compression
  struct in6_addr prefix;		//IPv6 prefix corresponding to the CID field
  uint8_t c_bit:1;			//bit indicates whether the context is valid or not
  uint16_t valid_lifetime;		//time in units of 60 seconds the context is valid for

}__attribute__((packed)) context_table_t; 




typedef  struct  abr_cache_t {
 uint16_t valid_lifetime;  	
 uint32_t version;
 struct in6_addr abr_addr;
 uint8_t cid[LOWPAN_CONTEXT_MAX] ;
}__attribute__((packed)) abr_cache;


/* Protocol Constants (RFC 6775 Section 9) */


/* 6LR Constants */


/*

MAX_RTR_ADVERTISEMENTS:Number of Maximum Router Advertisements messages should be transmitted,each separated by the interval in the range MIN_DELAY_BETWEEN_RAS and MAX_RA_DELAY_TIME

MaxRtrAdvInterval:	The maximum time allowed between sending unsolicited multicast Router Advertisements from the interface

MinRtrAdvInterval:	The minimum time allowed between sending unsolicited multicast Router Advertisements from the interface


*/

#define MAX_RTR_ADVERTISEMENTS 3
#define MIN_DELAY_BETWEEN_RAS	10000U	//10 seconds
#define MAX_RA_DELAY_TIME	2000	//2 seconds
#define MULTIHOP_HOPLIMIT	64
#define MaxRtrAdvInterval	600000		//600 seconds
#define MinRtrAdvInterval	0.33*MaxRtrAdvInterval
#define DELAY_FIRST_PROBE_TIME	60000U		//60Seconds

/* Host Constants */
/* 

RTR_SOLICITATION_INTERVAL:The interval after which next Router Solicitation is sent

MAX_RTR_SOLICITATIONS: Number of Router Solicitation messages host should transmit,each separated by  RTR_SOLICITATION_INTERVAL in order to receive Router Advertisement.

MAX_RTR_SOLICITATION_INTERVAL: It is the increase in the interval of retransmission timer after MAX_RTR_SOLICATIONS transmissions

RETRANS_TIMER: The time between	retransmissions of Neighbour Solicitation messages to a neighbour when resolving the address or when probing the reachability of a neighbor


MAX_UNICAST_SOLICIT: The number of solicitations after which we stop retransmitting Neighbour Solicitations and the entry should be deleted

*/




#define RTR_SOLICITATION_INTERVAL	10000U		//10 seconds	
#define MAX_RTR_SOLICITATIONS		3
#define MAX_RTR_SOLICITATION_INTERVAL	60000U		//60 seconds
#define RETRANS_TIMER			60000U		//60000 milliseconds(60 seconds)
#define MAX_UNICAST_SOLICIT 		3
#define REACHABLE_TIME			600U		//1 hour(3600000 milliseconds)	
#define RTR_HOP_LIMIT			255
#define RTR_LIFE_TIME			500		//500 Minutes
#define RTR_REACHABLE_TIME		2		//2minutes
#define PREFIX_PREF_LIFETIME		15		//400 Minutes
#define ABR_VER_LOW			1
#define ABR_VER_HIGH			0
#define ABR_LIFETIME			500		//500 Minutes
#define PREFIX_VALID_LIFETIME		0xffff
#define PREFIX_LENGTH			16


//IP Packet Size is  44 Bytes+RS Message size is 8 bytes + SLLAO is 10 Bytes + ARO is 15 Bytes + RA Message size is 16 bytes+ NS Message Size is 24 bytes + NA Message Size is 24 bytes + DAR Message size is 32+ DAC Message Size is 32 + prefix option size is   30 bytes+ abro option is  24 bytes  

#define MSG_SIZE	52	
#define RA_MSG_SIZE	120
#define NA_MSG_SIZE	52
#define DAR_MSG_SIZE	32
#define DAC_MSG_SIZE	32





#endif

